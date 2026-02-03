//
//  PostDataService.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import Foundation
import Supabase

// Rename to SportItem to avoid conflict
struct SportItem: Identifiable, Codable {
    let id: Int
    let name: String
    let emoji: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case emoji
        case createdAt = "created_at"
    }
}

struct SportCommunity: Codable {
    let id: String
    let collegeId: Int
    let sportId: Int
    let name: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case collegeId = "college_id"
        case sportId = "sport_id"
        case name
        case createdAt = "created_at"
    }
}

struct MatchPostData: Codable {
    let matchType: String
    var communityId: String?
    let venue: String
    let matchDate: String  // Format: "YYYY-MM-DD"
    let matchTime: String  // Format: "HH:mm:ss"
    let sportId: Int
    let skillLevel: String?
    let playersNeeded: Int
    var postedByUserId: UUID
    
    enum CodingKeys: String, CodingKey {
        case matchType = "match_type"
        case communityId = "community_id"
        case venue
        case matchDate = "match_date"
        case matchTime = "match_time"
        case sportId = "sport_id"
        case skillLevel = "skill_level"
        case playersNeeded = "players_needed"
        case postedByUserId = "posted_by_user_id"
    }
}

class PostDataService {
    static let shared = PostDataService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    /// Fetch all sports from Supabase
    /// - Returns: Array of SportItem objects
    func fetchSports() async throws -> [SportItem] {
        do {
            let sports: [SportItem] = try await client
                .from("sports")
                .select()
                .order("name")
                .execute()
                .value
            
            print("✅ Successfully fetched \(sports.count) sports from Supabase")
            return sports
        } catch {
            print("❌ Error fetching sports from Supabase: \(error)")
            throw error
        }
    }
    
    /// Fetch sports with a completion handler for use in non-async contexts
    /// - Parameter completion: Completion handler returning Result<[SportItem], Error>
    func fetchSports(completion: @escaping (Result<[SportItem], Error>) -> Void) {
        Task {
            do {
                let sports = try await fetchSports()
                DispatchQueue.main.async {
                    completion(.success(sports))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Fetch sport community ID for a given sport and college
    /// - Parameters:
    ///   - sportId: The ID of the sport
    ///   - collegeId: The ID of the college (default to 1 as per your INSERT statements)
    /// - Returns: SportCommunity object
    func fetchSportCommunity(sportId: Int, collegeId: Int = 1) async throws -> SportCommunity? {
        do {
            let communities: [SportCommunity] = try await client
                .from("sport_communities")
                .select()
                .eq("sport_id", value: sportId)
                .eq("college_id", value: collegeId)
                .execute()
                .value
            
            if let community = communities.first {
                print("✅ Found sport community: \(community.name) with ID: \(community.id)")
                return community
            } else {
                print("⚠️ No sport community found for sportId: \(sportId), collegeId: \(collegeId)")
                return nil
            }
        } catch {
            print("❌ Error fetching sport community: \(error)")
            throw error
        }
    }
    
    /// Get current user's ID
    /// - Returns: Current user's UUID
    func getCurrentUserId() async throws -> UUID? {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            print("❌ Error getting current user ID: \(error)")
            throw error
        }
    }
    
    /// Calculate community ID based on sport ID (alternative method)
    /// - Parameter sportId: The sport ID
    /// - Returns: Community ID string (e.g., "1.1" for sportId 1)
    private func calculateCommunityId(for sportId: Int) -> String {
        return "1.\(sportId)"
    }
    
    /// Save a match to the database
    /// - Parameter matchData: Match data to save
    func saveMatch(matchData: MatchPostData) async throws {
        do {
            // First, check if we have a valid user session
            guard let userId = try await getCurrentUserId() else {
                throw NSError(domain: "PostDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Calculate community ID directly from sport ID
            let communityId = "1.\(matchData.sportId)"
            
            // Create match data with community ID and user ID
            var matchDataWithIds = matchData
            matchDataWithIds.communityId = communityId
            matchDataWithIds.postedByUserId = userId
            
            // Log the data before saving
            print("📊 Saving match with details:")
            print("  - Community ID: \(communityId)")
            print("  - Sport ID: \(matchData.sportId)")
            print("  - Date: \(matchData.matchDate)")
            print("  - Time: \(matchData.matchTime)")
            print("  - Venue: \(matchData.venue)")
            print("  - Skill Level: \(matchData.skillLevel ?? "Not specified")")
            print("  - Players Needed: \(matchData.playersNeeded)")
            print("  - Posted by User ID: \(userId)")
            
            // Save to database
            let response = try await client
                .from("matches")
                .insert(matchDataWithIds)
                .execute()
            
            print("✅ Match saved successfully with community ID: \(communityId)")
        } catch {
            print("❌ Error saving match: \(error)")
            throw error
        }
    }
    
    /// Save match with completion handler for use in non-async contexts
    func saveMatch(matchData: MatchPostData, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await saveMatch(matchData: matchData)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
