//
//  MatchInformationDataService.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import Foundation
import Supabase

class MatchInformationDataService {
    
    // MARK: - Data Models
    struct Profile: Codable {
        let id: UUID
        let name: String?
        let email: String?
        let gender: String?
        let age: Int?
        let college_id: Int?
        let profile_pic: String?
        let created_at: String
        let updated_at: String
        
        enum CodingKeys: String, CodingKey {
                case id
                case name
                case email
                case gender
                case age
                case college_id = "college_id"
                case profile_pic = "profile_pic"
                case created_at = "created_at"
                case updated_at = "updated_at"
            }
    }
    
    struct MatchRSVP: Codable {
        let id: Int
        let match_id: UUID
        let user_id: UUID
        let rsvp_status: String
        let rsvp_at: String
        let attended: Bool?
    }
    
    struct PlayerWithProfile {
        let userId: UUID
        let name: String
        let profile: Profile?
        let isFriend: Bool
    }
    
    // MARK: - Properties
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Public Methods
    
    // Fetch current user ID from session
    func fetchCurrentUserId() async throws -> String {
        let session = try await supabase.auth.session
        return session.user.id.uuidString
    }
    
    // Fetch host profile for a match
    func fetchHostProfile(for match: DBMatch) async throws -> Profile? {
        let response = try await supabase
            .from("profiles")
            .select("*")
            .eq("id", value: match.postedByUserId.uuidString)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try decoder.decode(Profile.self, from: response.data)
    }
    
    // Fetch RSVP players for a match with their profiles and friend status
    func fetchRSVPPlayers(for match: DBMatch, currentUserId: String) async throws -> [PlayerWithProfile] {
        // 1. Fetch all RSVPs for this match
        let rsvpResponse = try await supabase
            .from("match_rsvps")
            .select("*")
            .eq("match_id", value: match.id.uuidString)
            .eq("rsvp_status", value: "going")
            .execute()
        
        let decoder = JSONDecoder()
        let rsvps = try decoder.decode([MatchRSVP].self, from: rsvpResponse.data)
        
        // 2. Get all user IDs from RSVPs
        let userIds = rsvps.map { $0.user_id.uuidString }
        
        guard !userIds.isEmpty else { return [] }
        
        // 3. Fetch profiles for all users
        let profilesResponse = try await supabase
            .from("profiles")
            .select("*")
            .in("id", values: userIds)
            .execute()
        
        let profiles = try decoder.decode([Profile].self, from: profilesResponse.data)
        
        // 4. Create dictionary for quick profile lookup
        var profileDict: [String: Profile] = [:]
        for profile in profiles {
            profileDict[profile.id.uuidString] = profile
        }
        
        // 5. Check friend status for each RSVPed user and create player objects
        var players: [PlayerWithProfile] = []
        
        for rsvp in rsvps {
            let userId = rsvp.user_id.uuidString
            let profile = profileDict[userId]
            
            // Check if there's an accepted friendship between current user and this user
            let isFriend = await checkFriendshipBetweenUsers(userId1: currentUserId, userId2: userId)
            
            players.append(PlayerWithProfile(
                userId: rsvp.user_id,
                name: profile?.name ?? "Unknown Player",
                profile: profile,
                isFriend: isFriend
            ))
        }
        
        return players
    }
    
    // Check friendship between two users (bidirectional check)
    private func checkFriendshipBetweenUsers(userId1: String, userId2: String) async -> Bool {
        do {
            // Check for accepted friendship in either direction
            let response = try await supabase
                .from("friends")
                .select("*")
                .or("and(user_id.eq.\(userId1),friend_id.eq.\(userId2),status.eq.accepted),and(user_id.eq.\(userId2),friend_id.eq.\(userId1),status.eq.accepted)")
                .execute()

            let friendships = try JSONDecoder().decode([[String: AnyCodable]].self, from: response.data)
            let isFriend = !friendships.isEmpty
            return isFriend
            
        } catch {
            print("❌ ERROR checking friendship between users: \(error)")
            return false
        }
    }
    
    // Check friendship with host
    func checkFriendshipWithHost(match: DBMatch, currentUserId: String) async -> Bool {
        let hostUserId = match.postedByUserId.uuidString
        return await checkFriendshipBetweenUsers(userId1: currentUserId, userId2: hostUserId)
    }
    
    // Check if current user is friends with another user
    func checkFriendship(currentUserId: String, otherUserId: String) async -> Bool {
        return await checkFriendshipBetweenUsers(userId1: currentUserId, userId2: otherUserId)
    }
    
    // Join a match
    func joinMatch(matchId: String, userId: String) async throws {
        // First, check if user already has an RSVP for this match
        let existingRSVP = try await supabase
            .from("match_rsvps")
            .select("*")
            .eq("match_id", value: matchId)
            .eq("user_id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        let existingEntries = try decoder.decode([MatchRSVP].self, from: existingRSVP.data)
        
        // Define Encodable structs for insert/update payloads
        struct RSVPInsert: Encodable {
            let match_id: String
            let user_id: String
            let rsvp_status: String
            let rsvp_at: String
        }
        
        struct RSVPUpdate: Encodable {
            let rsvp_status: String
            let rsvp_at: String
        }
        
        if existingEntries.isEmpty {
            // No existing RSVP, insert new one
            let rsvp = RSVPInsert(
                match_id: matchId,
                user_id: userId,
                rsvp_status: "going",
                rsvp_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("match_rsvps")
                .insert(rsvp)
                .execute()
            
            print("✅ Successfully joined match: \(matchId)")
        } else {
            // Update existing RSVP to "going"
            let updateData = RSVPUpdate(
                rsvp_status: "going",
                rsvp_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("match_rsvps")
                .update(updateData)
                .eq("match_id", value: matchId)
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ Successfully updated RSVP to join match: \(matchId)")
        }
    }

    // Leave a match
    func leaveMatch(matchId: String, userId: String) async throws {
        // Check if the RSVP exists
        let existingRSVP = try await supabase
            .from("match_rsvps")
            .select("*")
            .eq("match_id", value: matchId)
            .eq("user_id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        let existingEntries = try decoder.decode([MatchRSVP].self, from: existingRSVP.data)
        
        if !existingEntries.isEmpty {
            // Option 1: Delete the RSVP entirely
            let response = try await supabase
                .from("match_rsvps")
                .delete()
                .eq("match_id", value: matchId)
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ Successfully left match: \(matchId)")
            
            // Option 2: Alternatively, you could update status to "not_going" instead of deleting
            // let updateData = ["rsvp_status": "not_going"]
            // let response = try await supabase
            //     .from("match_rsvps")
            //     .update(updateData)
            //     .eq("match_id", value: matchId)
            //     .eq("user_id", value: userId)
            //     .execute()
        } else {
            print("⚠️ No RSVP found for match: \(matchId) and user: \(userId)")
            throw NSError(domain: "MatchInformationDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No RSVP found for this match"])
        }
    }

    // Fetch RSVP count with better error handling
    func fetchPlayersRSVPCount(matchId: String) async throws -> Int {
        do {
            let response = try await supabase
                .from("match_rsvps")
                .select("*", count: .exact)
                .eq("match_id", value: matchId)
                .eq("rsvp_status", value: "going")
                .execute()
            
            return response.count ?? 0
        } catch {
            print("❌ Error fetching RSVP count: \(error)")
            throw error
        }
    }
    
    // Send friend request
    func sendFriendRequest(fromUserId: String, toUserId: String) async throws {
        let friendRequest = [
            "user_id": fromUserId,
            "friend_id": toUserId,
            "status": "pending"
        ]
        
        _ = try await supabase
            .from("friends")
            .insert(friendRequest)
            .execute()
    }
}

// Helper struct to decode any JSON value
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode AnyCodable")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Cannot encode AnyCodable"))
        }
    }
}
