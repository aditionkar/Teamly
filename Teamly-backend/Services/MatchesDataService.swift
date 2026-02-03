//
//  MatchesDataService.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import Foundation
import Supabase

class MatchesDataService {
    
    // MARK: - Fetch Methods for Matches Screen
    
    func fetchMatchesForSportAndDate(
        sportName: String,
        date: String, // Format: "yyyy-MM-dd"
        collegeId: Int,
        currentUserId: String
    ) async throws -> [DBMatch] {
        
        print("Fetching matches for sport: \(sportName), date: \(date)")
        
        // First, get the sport ID from the sport name
        guard let sport = try await fetchSportByName(sportName) else {
            print("Sport not found: \(sportName)")
            return []
        }
        
        // Get the sport community for this college and sport
        guard let community = try await fetchSportCommunity(collegeId: collegeId, sportId: sport.id) else {
            print("No sport community found for college \(collegeId), sport \(sport.name)")
            return []
        }
        
        // Fetch matches for this sport community with match_type = 'sport_community'
        // for the specific date
        let response = try await SupabaseManager.shared.client
            .from("matches")
            .select("*")
            .eq("match_type", value: "sport_community")
            .eq("community_id", value: community.id)
            .eq("match_date", value: date)
            .order("match_time", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()
        let matchRecords = try decoder.decode([HomeDataService.MatchRecord].self, from: response.data)
        
        if matchRecords.isEmpty {
            print("No matches found for \(sportName) on \(date)")
            return []
        }
        
        print("Found \(matchRecords.count) matches for \(sportName) on \(date)")
        
        // Get all unique user IDs from the matches
        let userIds = Set(matchRecords.map { $0.posted_by_user_id.uuidString })
        
        // Fetch user names in batch
        let userNames = await fetchUserNames(for: Array(userIds))
        
        // Convert MatchRecord to DBMatch
        var dbMatches: [DBMatch] = []
        
        for matchRecord in matchRecords {
            // Fetch RSVP count
            let rsvpCount = await fetchRSVPCount(for: matchRecord.id.uuidString)
            
            // Get user name from fetched names
            let userName = userNames[matchRecord.posted_by_user_id.uuidString] ?? "Unknown User"
            
            // Check if poster is friend of current user
            let isFriend = await checkFriendship(currentUserId: currentUserId, friendId: matchRecord.posted_by_user_id.uuidString)
            
            // Create DBMatch object
            if let dbMatch = convertToDBMatch(
                matchRecord: matchRecord,
                sportName: sport.name,
                rsvpCount: rsvpCount,
                userName: userName,
                isFriend: isFriend
            ) {
                dbMatches.append(dbMatch)
            }
        }
        
        return dbMatches
    }
    
    private func fetchSportByName(_ name: String) async throws -> HomeDataService.Sport? {
        do {
            let response = try await SupabaseManager.shared.client
                .from("sports")
                .select("*")
                .eq("name", value: name)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            return try decoder.decode(HomeDataService.Sport.self, from: response.data)
        } catch {
            print("Error fetching sport by name \(name): \(error)")
            return nil
        }
    }
    
    private func fetchSportCommunity(collegeId: Int, sportId: Int) async throws -> HomeDataService.SportCommunity? {
        let response = try await SupabaseManager.shared.client
            .from("sport_communities")
            .select("*")
            .eq("college_id", value: collegeId)
            .eq("sport_id", value: sportId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(HomeDataService.SportCommunity.self, from: response.data)
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
            let profiles = try decoder.decode([HomeDataService.ProfileName].self, from: response.data)
            
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
    
    private func fetchRSVPCount(for matchId: String) async -> Int {
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
        matchRecord: HomeDataService.MatchRecord,
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
