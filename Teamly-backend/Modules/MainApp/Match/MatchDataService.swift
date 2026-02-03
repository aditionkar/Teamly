//
//  MatchDataService.swift - DEBUG VERSION
//
//  Teamly-backend
//
//  Created by user@37 on 27/01/26.
//

import Foundation
import Supabase

enum MatchDataServiceError: Error {
    case userNotLoggedIn
    case fetchFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .userNotLoggedIn:
            return "User not logged in"
        case .fetchFailed(let message):
            return "Failed to fetch matches: \(message)"
        }
    }
}

class MatchDataService {
    static let shared = MatchDataService()
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Main Fetch Method
    func fetchUserMatches(completion: @escaping (Result<[DBMatch], Error>) -> Void) {
        Task {
            do {
                guard let currentUserId = try await getCurrentUserId() else {
                    DispatchQueue.main.async {
                        completion(.failure(MatchDataServiceError.userNotLoggedIn))
                    }
                    return
                }
                
                print("🔍 [DEBUG] Starting fetch for user: \(currentUserId)")
                
                // STEP 1: Get match IDs from match_rsvps
                print("📋 [DEBUG] Step 1: Fetching match IDs from match_rsvps")
                let matchIds = try await fetchMatchIds(userId: currentUserId)
                
                if matchIds.isEmpty {
                    print("⚠️ [DEBUG] No matches found for user")
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                    return
                }
                
                print("✅ [DEBUG] Found \(matchIds.count) match IDs: \(matchIds)")
                
                // STEP 2: Get match details
                print("📋 [DEBUG] Step 2: Fetching match details")
                let matches = try await fetchMatchDetails(matchIds: matchIds)
                
                print("✅ [DEBUG] Successfully fetched \(matches.count) match details")
                
                DispatchQueue.main.async {
                    completion(.success(matches))
                }
                
            } catch {
                print("❌ [DEBUG] Error in fetchUserMatches: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(MatchDataServiceError.fetchFailed(error.localizedDescription)))
                }
            }
        }
    }
    
    // MARK: - Step-by-step Methods
    
    private func fetchMatchIds(userId: String) async throws -> [String] {
        let response = try await supabase
            .from("match_rsvps")
            .select("match_id")
            .eq("user_id", value: userId)
            .eq("rsvp_status", value: "going")
            .execute()
        
        print("📊 [DEBUG] Raw match_rsvps response: \(String(data: response.data, encoding: .utf8) ?? "No data")")
        
        let data: [[String: Any]] = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        let matchIds = data.compactMap { $0["match_id"] as? String }
        return matchIds
    }
    
    private func fetchMatchDetails(matchIds: [String]) async throws -> [DBMatch] {
        // Get matches
        let matchResponse = try await supabase
            .from("matches")
            .select()
            .in("id", values: matchIds)
            .execute()
        
        print("📊 [DEBUG] Raw matches response: \(String(data: matchResponse.data, encoding: .utf8) ?? "No data")")
        
        let matchData: [[String: Any]] = try JSONSerialization.jsonObject(with: matchResponse.data) as? [[String: Any]] ?? []
        print("📊 [DEBUG] Parsed \(matchData.count) match records")
        
        var matches: [DBMatch] = []
        
        for matchDict in matchData {
            print("📊 [DEBUG] Processing match dict: \(matchDict)")
            
            // Create MatchRecord
            guard let matchRecord = createMatchRecord(from: matchDict) else {
                print("❌ [DEBUG] Failed to create MatchRecord from dict")
                continue
            }
            
            print("✅ [DEBUG] Created MatchRecord for: \(matchRecord.venue)")
            
            // Get sport name
            let sportName = try await fetchSportName(sportId: matchRecord.sport_id)
            print("✅ [DEBUG] Sport name: \(sportName)")
            
            // Get poster name
            let postedByName = try await fetchUserName(userId: matchRecord.posted_by_user_id.uuidString)
            print("✅ [DEBUG] Poster name: \(postedByName)")
            
            // Get RSVP count
            let rsvpCount = try await fetchRSVPCount(matchId: matchRecord.id.uuidString)
            print("✅ [DEBUG] RSVP count: \(rsvpCount)")
            
            // Create DBMatch
            if let dbMatch = DBMatch.fromMatchRecord(
                matchRecord,
                sportName: sportName,
                postedByName: postedByName,
                rsvpCount: rsvpCount,
                isFriend: false
            ) {
                matches.append(dbMatch)
                print("✅ [DEBUG] Successfully created DBMatch for: \(matchRecord.venue)")
            } else {
                print("❌ [DEBUG] Failed to create DBMatch for: \(matchRecord.venue)")
            }
        }
        
        return matches
    }
    
    private func fetchSportName(sportId: Int) async throws -> String {
        let response = try await supabase
            .from("sports")
            .select("name")
            .eq("id", value: sportId)
            .execute()
        
        let data: [[String: Any]] = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        return data.first?["name"] as? String ?? "Unknown Sport"
    }
    
    private func fetchUserName(userId: String) async throws -> String {
        let response = try await supabase
            .from("profiles")
            .select("name")
            .eq("id", value: userId)
            .execute()
        
        let data: [[String: Any]] = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        return data.first?["name"] as? String ?? "Unknown"
    }
    
    private func fetchRSVPCount(matchId: String) async throws -> Int {
        let response = try await supabase
            .from("match_rsvps")
            .select("id")
            .eq("match_id", value: matchId)
            .eq("rsvp_status", value: "going")
            .execute()
        
        let data: [[String: Any]] = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        return data.count
    }
    
    private func createMatchRecord(from dict: [String: Any]) -> MatchRecord? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let decoder = JSONDecoder()
            return try decoder.decode(MatchRecord.self, from: jsonData)
        } catch {
            print("❌ [DEBUG] Failed to decode MatchRecord: \(error)")
            return nil
        }
    }
    
    private func getCurrentUserId() async throws -> String? {
        // Try UserDefaults first
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            print("✅ [DEBUG] Got user ID from UserDefaults: \(userId)")
            return userId
        }
        
        // Try auth session
        do {
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString
            print("✅ [DEBUG] Got user ID from auth session: \(userId)")
            return userId
        } catch {
            print("⚠️ [DEBUG] Could not get user ID from auth: \(error)")
            return nil
        }
    }
}

// MARK: - DBMatch Extension for Conversion (same as before)
extension DBMatch {
    static func fromMatchRecord(
        _ matchRecord: MatchRecord,
        sportName: String,
        postedByName: String,
        rsvpCount: Int,
        isFriend: Bool
    ) -> DBMatch? {
        // Parse date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let matchDate = dateFormatter.date(from: matchRecord.match_date) else {
            print("❌ Failed to parse date: \(matchRecord.match_date)")
            return nil
        }
        
        // Parse time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let matchTime = timeFormatter.date(from: matchRecord.match_time) else {
            print("❌ Failed to parse time: \(matchRecord.match_time)")
            return nil
        }
        
        // Parse created_at
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let createdAt = isoFormatter.date(from: matchRecord.created_at) ?? Date()
        
        return DBMatch(
            id: matchRecord.id,
            matchType: matchRecord.match_type,
            communityId: matchRecord.community_id,
            venue: matchRecord.venue,
            matchDate: matchDate,
            matchTime: matchTime,
            sportId: matchRecord.sport_id,
            sportName: sportName,
            skillLevel: matchRecord.skill_level,
            playersNeeded: matchRecord.players_needed,
            postedByUserId: matchRecord.posted_by_user_id,
            createdAt: createdAt,
            playersRSVPed: rsvpCount,
            postedByName: postedByName,
            isFriend: isFriend
        )
    }
}
