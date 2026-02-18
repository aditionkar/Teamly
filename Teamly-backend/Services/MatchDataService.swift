//
//  MatchDataService.swift - UPDATED VERSION
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
                
                print("🔍 [DEBUG] Fetching matches for user: \(currentUserId)")
                
                // Get matches the user has joined (RSVP'd)
                let joinedMatchIds = try await fetchJoinedMatchIds(userId: currentUserId)
                print("✅ [DEBUG] Found \(joinedMatchIds.count) joined matches")
                
                // Get matches the user has created
                let createdMatches = try await fetchCreatedMatches(userId: currentUserId)
                print("✅ [DEBUG] Found \(createdMatches.count) created matches")
                
                // Combine both sets, avoiding duplicates
                var allMatches: [DBMatch] = []
                var processedIds = Set<String>()
                
                // Add created matches first
                for match in createdMatches {
                    allMatches.append(match)
                    processedIds.insert(match.id.uuidString)
                }
                
                // If we have joined match IDs that aren't already in created matches, fetch them
                if !joinedMatchIds.isEmpty {
                    let matchesToFetch = joinedMatchIds.filter { !processedIds.contains($0) }
                    
                    if !matchesToFetch.isEmpty {
                        print("🔍 [DEBUG] Fetching details for \(matchesToFetch.count) joined matches not already in created")
                        let joinedMatches = try await fetchMatchDetails(matchIds: matchesToFetch, currentUserId: currentUserId)
                        allMatches.append(contentsOf: joinedMatches)
                    }
                }
                
                print("✅ [DEBUG] Total unique matches: \(allMatches.count)")
                
                DispatchQueue.main.async {
                    completion(.success(allMatches))
                }
                
            } catch {
                print("❌ [DEBUG] Error in fetchUserMatches: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(MatchDataServiceError.fetchFailed(error.localizedDescription)))
                }
            }
        }
    }
    
    // MARK: - Fetch Methods
    
    private func fetchJoinedMatchIds(userId: String) async throws -> [String] {
        let response = try await supabase
            .from("match_rsvps")
            .select("match_id")
            .eq("user_id", value: userId)
            .eq("rsvp_status", value: "going")
            .execute()
        
        let data: [[String: Any]] = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        let matchIds = data.compactMap { $0["match_id"] as? String }
        return matchIds
    }
    
    private func fetchCreatedMatches(userId: String) async throws -> [DBMatch] {
        // Get matches created by this user
        let matchResponse = try await supabase
            .from("matches")
            .select()
            .eq("posted_by_user_id", value: userId)
            .execute()
        
        let matchData: [[String: Any]] = try JSONSerialization.jsonObject(with: matchResponse.data) as? [[String: Any]] ?? []
        
        print("🔍 [DEBUG] Found \(matchData.count) matches created by user")
        
        var matches: [DBMatch] = []
        
        for matchDict in matchData {
            guard let matchRecord = createMatchRecord(from: matchDict) else {
                print("❌ [DEBUG] Failed to create MatchRecord from dict")
                continue
            }
            
            // For created matches, the posted_by_name will be "You" or the user's name
            let sportName = try await fetchSportName(sportId: matchRecord.sport_id)
            
            // For created matches, we can set postedByName to "You" or fetch the actual name
            let postedByName = try await fetchUserName(userId: matchRecord.posted_by_user_id.uuidString)
            
            let rsvpCount = try await fetchRSVPCount(matchId: matchRecord.id.uuidString)
            
            if let dbMatch = DBMatch.fromMatchRecord(
                matchRecord,
                sportName: sportName,
                postedByName: postedByName,
                rsvpCount: rsvpCount,
                isFriend: false,
                isCreatedByUser: true // Add this parameter
            ) {
                matches.append(dbMatch)
            } else {
                print("❌ [DEBUG] Failed to create DBMatch for: \(matchRecord.venue)")
            }
        }
        
        return matches
    }
    
    private func fetchMatchDetails(matchIds: [String], currentUserId: String) async throws -> [DBMatch] {
        // Get matches
        let matchResponse = try await supabase
            .from("matches")
            .select()
            .in("id", values: matchIds)
            .execute()
        
        let matchData: [[String: Any]] = try JSONSerialization.jsonObject(with: matchResponse.data) as? [[String: Any]] ?? []
        
        var matches: [DBMatch] = []
        
        for matchDict in matchData {
            guard let matchRecord = createMatchRecord(from: matchDict) else {
                print("❌ [DEBUG] Failed to create MatchRecord from dict")
                continue
            }
            
            let sportName = try await fetchSportName(sportId: matchRecord.sport_id)
            let postedByName = try await fetchUserName(userId: matchRecord.posted_by_user_id.uuidString)
            let rsvpCount = try await fetchRSVPCount(matchId: matchRecord.id.uuidString)
            
            // Check if this match was created by the current user
            let isCreatedByUser = (matchRecord.posted_by_user_id.uuidString == currentUserId)
            
            if let dbMatch = DBMatch.fromMatchRecord(
                matchRecord,
                sportName: sportName,
                postedByName: postedByName,
                rsvpCount: rsvpCount,
                isFriend: false,
                isCreatedByUser: isCreatedByUser
            ) {
                matches.append(dbMatch)
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

// MARK: - DBMatch Extension for Conversion
extension DBMatch {
    static func fromMatchRecord(
        _ matchRecord: MatchRecord,
        sportName: String,
        postedByName: String,
        rsvpCount: Int,
        isFriend: Bool,
        isCreatedByUser: Bool = false
    ) -> DBMatch? {
        // Parse date - keep as is since date doesn't have timezone issues
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let matchDate = dateFormatter.date(from: matchRecord.match_date) else {
            print("❌ Failed to parse date: \(matchRecord.match_date)")
            return nil
        }
        
        // FIX: Parse time WITHOUT forcing UTC timezone
        // This will parse the time string in the system's local timezone
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        // REMOVE the timeZone line - let it use the system's timezone
        
        guard let matchTime = timeFormatter.date(from: matchRecord.match_time) else {
            print("❌ Failed to parse time: \(matchRecord.match_time)")
            return nil
        }
        
        // Parse created_at
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
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
            postedByName: isCreatedByUser ? "You" : postedByName,
            isFriend: isFriend,
            isCreatedByUser: isCreatedByUser
        )
    }
}
