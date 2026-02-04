//
//  PostDataService.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import Foundation
import Supabase

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
    let matchDate: String
    let matchTime: String
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

    func fetchSports() async throws -> [SportItem] {
        do {
            let sports: [SportItem] = try await client
                .from("sports")
                .select()
                .order("name")
                .execute()
                .value

            return sports
        } catch {
            print("❌ Error fetching sports from Supabase: \(error)")
            throw error
        }
    }

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
                return community
            } else {
                return nil
            }
        } catch {
            print("❌ Error fetching sport community: \(error)")
            throw error
        }
    }

    func getCurrentUserId() async throws -> UUID? {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            print("❌ Error getting current user ID: \(error)")
            throw error
        }
    }

    private func calculateCommunityId(for sportId: Int) -> String {
        return "1.\(sportId)"
    }

    func saveMatch(matchData: MatchPostData) async throws {
        do {
            // First, check if we have a valid user session
            guard let userId = try await getCurrentUserId() else {
                throw NSError(domain: "PostDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }

            let communityId = "1.\(matchData.sportId)"

            var matchDataWithIds = matchData
            matchDataWithIds.communityId = communityId
            matchDataWithIds.postedByUserId = userId

            let response = try await client
                .from("matches")
                .insert(matchDataWithIds)
                .execute()

        } catch {
            print("❌ Error saving match: \(error)")
            throw error
        }
    }

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
