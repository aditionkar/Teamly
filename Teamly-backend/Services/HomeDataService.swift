//
//  HomeDataService.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import Foundation
import Supabase

class HomeDataService {
    
    // MARK: - Data Models
    
    struct UserProfile: Codable {
        let id: UUID
        let name: String?
        let college_id: Int
        let profile_pic: String?
    }
    
    struct College: Codable {
        let id: Int
        let name: String
        let location: String?
    }
    
    struct Sport: Codable {
        let id: Int
        let name: String
        let emoji: String
        
    }
    
    struct UserPreferredSport: Codable {
        let id: Int
        let user_id: UUID
        let sport_id: Int
        let skill_level: String?
    }
    
    struct SportCommunity: Codable {
        let id: String
        let college_id: Int
        let sport_id: Int
        let name: String
    }
    
    struct MatchRecord: Codable {
        let id: UUID
        let match_type: String
        let community_id: String?
        let venue: String
        let match_date: String
        let match_time: String
        let sport_id: Int
        let skill_level: String?
        let players_needed: Int
        let posted_by_user_id: UUID
        let created_at: String
    }
    
    struct ProfileName: Codable {
        let id: UUID
        let name: String?
    }
    
    // MARK: - Fetch Methods
    
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let response = try await SupabaseManager.shared.client
            .from("profiles")
            .select("*")
            .eq("id", value: userId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(UserProfile.self, from: response.data)
    }
    
    func fetchCollege(collegeId: Int) async throws -> College? {
        let response = try await SupabaseManager.shared.client
            .from("colleges")
            .select("*")
            .eq("id", value: collegeId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(College.self, from: response.data)
    }
    
    func fetchAllSports() async throws -> [Sport] {
        let response = try await SupabaseManager.shared.client
            .from("sports")
            .select("*")
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode([Sport].self, from: response.data)
    }
    
    func fetchUserPreferredSports(userId: String) async throws -> [UserPreferredSport] {
        let response = try await SupabaseManager.shared.client
            .from("user_preferred_sports")
            .select("*")
            .eq("user_id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode([UserPreferredSport].self, from: response.data)
    }
    
    func fetchSportCommunity(collegeId: Int, sportId: Int) async throws -> SportCommunity? {
        let response = try await SupabaseManager.shared.client
            .from("sport_communities")
            .select("*")
            .eq("college_id", value: collegeId)
            .eq("sport_id", value: sportId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(SportCommunity.self, from: response.data)
    }
    
    func fetchMatchesForSport(sportId: Int, collegeId: Int, currentUserId: String) async throws -> [DBMatch] {
        // Get current date and tomorrow's date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let calendar = Calendar.current
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        let tomorrow = dateFormatter.string(from: tomorrowDate)
        
        // First, get the sport community ID for this college and sport
        guard let community = try await fetchSportCommunity(collegeId: collegeId, sportId: sportId) else {
            return []
        }
        
        // Fetch matches for this sport community with match_type = 'sport_community'
        // and match_date is today or tomorrow
        let response = try await SupabaseManager.shared.client
            .from("matches")
            .select("*")
            .eq("match_type", value: "sport_community")
            .eq("community_id", value: community.id)
            .in("match_date", values: [today, tomorrow])
            .order("match_date", ascending: true)
            .order("match_time", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()
        let matchRecords = try decoder.decode([MatchRecord].self, from: response.data)
        
        if matchRecords.isEmpty {
            return []
        }
        
        // Filter out matches whose time has already passed for today
        let currentDateTime = Date()
        let filteredMatchRecords = matchRecords.filter { matchRecord in
            // If match date is tomorrow, always include it
            if matchRecord.match_date == tomorrow {
                return true
            }
            
            // If match date is today, check if the time has passed
            if matchRecord.match_date == today {
                // Combine match date and time to create a full datetime
                let matchDateTimeString = "\(matchRecord.match_date) \(matchRecord.match_time)"
                let fullDateTimeFormatter = DateFormatter()
                fullDateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                fullDateTimeFormatter.timeZone = TimeZone.current
                
                if let matchDateTime = fullDateTimeFormatter.date(from: matchDateTimeString) {
                    // Include only if match time is in the future
                    return matchDateTime > currentDateTime
                }
            }
            
            return true
        }
        
        // Get all unique user IDs from the filtered matches
        let userIds = Set(filteredMatchRecords.map { $0.posted_by_user_id.uuidString })
        
        // Fetch user names in batch
        let userNames = await fetchUserNames(for: Array(userIds))
        
        // Convert MatchRecord to DBMatch
        var dbMatches: [DBMatch] = []
        
        for matchRecord in filteredMatchRecords {
            // Fetch sport name for this match
            let sportName = await fetchSportName(for: matchRecord.sport_id)
            
            // Fetch RSVP count
            let rsvpCount = await fetchRSVPCount(for: matchRecord.id.uuidString)
            
            // Get user name from fetched names
            let userName = userNames[matchRecord.posted_by_user_id.uuidString] ?? "Unknown User"
            
            // Check if poster is friend of current user
            let isFriend = await checkFriendship(currentUserId: currentUserId, friendId: matchRecord.posted_by_user_id.uuidString)
            
            // Create DBMatch object
            if let dbMatch = convertToDBMatch(
                matchRecord: matchRecord,
                sportName: sportName,
                rsvpCount: rsvpCount,
                userName: userName,
                isFriend: isFriend
            ) {
                dbMatches.append(dbMatch)
            }
        }
        
        return dbMatches
    }
    private func fetchUserNames(for userIds: [String]) async -> [String: String] {
        guard !userIds.isEmpty else { return [:] }
        
        do {

            let response = try await SupabaseManager.shared.client
                .from("profiles")
                .select("id, name")
                .in("id", values: userIds)
                .execute()
            
            let decoder = JSONDecoder()
            let profiles = try decoder.decode([ProfileName].self, from: response.data)
            
            var userNames: [String: String] = [:]
            for profile in profiles {
                userNames[profile.id.uuidString] = profile.name ?? "Unknown User"
            }

            return userNames
            
        } catch {
            print("Error fetching user names: \(error)")
            return [:]
        }
    }
    
    private func fetchSportName(for sportId: Int) async -> String {
        do {
            let response = try await SupabaseManager.shared.client
                .from("sports")
                .select("name")
                .eq("id", value: sportId)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            let sportData = try decoder.decode([String: String].self, from: response.data)
            return sportData["name"] ?? "Unknown Sport"
        } catch {
            print("Error fetching sport name: \(error)")
            return "Unknown Sport"
        }
    }
    
    func fetchRSVPCount(for matchId: String) async -> Int {
        do {
            let response = try await SupabaseManager.shared.client
                .from("match_rsvps")
                .select("*", count: .exact)
                .eq("match_id", value: matchId)
                .eq("rsvp_status", value: "going")
                .execute()
            
            return response.count ?? 0
        } catch {
            print("Error fetching RSVP count: \(error)")
            return 0
        }
    }
    
    private func checkFriendship(currentUserId: String, friendId: String) async -> Bool {
        guard !currentUserId.isEmpty, !friendId.isEmpty else {
            return false
        }
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("friends")
                .select("*")
                .eq("user_id", value: currentUserId)
                .eq("friend_id", value: friendId)
                .eq("status", value: "accepted")
                .execute()
            
            let decoder = JSONDecoder()
            let friendships = try decoder.decode([[String: String]].self, from: response.data)
            return !friendships.isEmpty
        } catch {
            print("Error checking friendship: \(error)")
            return false
        }
    }
    
    private func convertToDBMatch(
        matchRecord: MatchRecord,
        sportName: String,
        rsvpCount: Int,
        userName: String,
        isFriend: Bool
    ) -> DBMatch? {
        // Parse date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let matchDate = dateFormatter.date(from: matchRecord.match_date) else {
            print("Failed to parse date: \(matchRecord.match_date)")
            return nil
        }
        
        // Parse time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let matchTime = timeFormatter.date(from: matchRecord.match_time) else {
            print("Failed to parse time: \(matchRecord.match_time)")
            return nil
        }
        
        // Parse created_at
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone.current
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
            postedByName: userName,
            isFriend: isFriend
        )
    }
}
