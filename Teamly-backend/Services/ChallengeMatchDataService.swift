//
//  ChallengeMatchDataService.swift
//  Teamly-backend
//
//  Created by user@37 on 28/01/26.
//

import Foundation
import Supabase

struct TeamChallenge: Codable, Identifiable {
    let id: UUID
    let name: String
    let sportId: Int
    let captainId: UUID
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sportId = "sport_id"
        case captainId = "captain_id"
    }
}

struct InternalMatchData: Codable {
    let matchType: String
    let venue: String
    let matchDate: String
    let matchTime: String
    let sportId: Int
    let teamId: UUID
    let postedByUserId: UUID
    
    enum CodingKeys: String, CodingKey {
        case matchType = "match_type"
        case venue
        case matchDate = "match_date"
        case matchTime = "match_time"
        case sportId = "sport_id"
        case teamId = "team_id"
        case postedByUserId = "posted_by_user_id"
    }
}

struct MatchRequestData: Codable {
    let challengingTeamId: UUID
    let challengedTeamId: UUID
    let proposedVenue: String
    let proposedDate: String
    let proposedTime: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case challengingTeamId = "challenging_team_id"
        case challengedTeamId = "challenged_team_id"
        case proposedVenue = "proposed_venue"
        case proposedDate = "proposed_date"
        case proposedTime = "proposed_time"
        case status
    }
}

struct TeamCaptainCheck: Codable {
    let captain_id: UUID
}

struct TeamSportId: Codable {
    let sport_id: Int
}

class ChallengeMatchDataService {
    static let shared = ChallengeMatchDataService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    func getCurrentUserId() async throws -> UUID? {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            print("❌ Error getting current user ID: \(error)")
            throw error
        }
    }
    
    func fetchTeamsWithSameSport(currentTeamId: UUID) async throws -> [TeamChallenge] {
        do {
            let currentTeam: [BackendTeam] = try await client
                .from("teams")
                .select()
                .eq("id", value: currentTeamId)
                .execute()
                .value
            
            guard let team = currentTeam.first else {
                throw NSError(domain: "ChallengeMatchDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Current team not found"])
            }
            
            let sportId = team.sport_id
            
            let teams: [TeamChallenge] = try await client
                .from("teams")
                .select()
                .eq("sport_id", value: sportId)
                .neq("id", value: currentTeamId)
                .order("name")
                .execute()
                .value

            return teams
        } catch {
            print("❌ Error fetching teams: \(error)")
            throw error
        }
    }
    
    func getTeamSportId(teamId: UUID) async throws -> Int {
        do {
            let team: [TeamSportId] = try await client
                .from("teams")
                .select("sport_id")
                .eq("id", value: teamId)
                .execute()
                .value
            
            guard let teamData = team.first else {
                throw NSError(domain: "ChallengeMatchDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Team not found"])
            }
            
            return teamData.sport_id
        } catch {
            print("❌ Error getting team sport ID: \(error)")
            throw error
        }
    }
    
    func createInternalMatch(
        venue: String,
        date: Date,
        time: Date,
        teamId: UUID,
        sportId: Int,
        postedByUserId: UUID
    ) async throws {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let formattedDate = dateFormatter.string(from: date)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            let formattedTime = timeFormatter.string(from: time)
            
            let matchData = InternalMatchData(
                matchType: "team_internal",
                venue: venue,
                matchDate: formattedDate,
                matchTime: formattedTime,
                sportId: sportId,
                teamId: teamId,
                postedByUserId: postedByUserId
            )
            let response = try await client
                .from("matches")
                .insert(matchData)
                .execute()

        } catch {
            print("❌ Error creating internal match: \(error)")
            throw error
        }
    }
    
    func createMatchRequest(
        challengingTeamId: UUID,
        challengedTeamId: UUID,
        venue: String,
        date: Date,
        time: Date
    ) async throws {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let formattedDate = dateFormatter.string(from: date)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            let formattedTime = timeFormatter.string(from: time)
            
            let requestData = MatchRequestData(
                challengingTeamId: challengingTeamId,
                challengedTeamId: challengedTeamId,
                proposedVenue: venue,
                proposedDate: formattedDate,
                proposedTime: formattedTime,
                status: "pending"
            )

            let response = try await client
                .from("match_requests")
                .insert(requestData)
                .execute()

        } catch {
            print("❌ Error creating match request: \(error)")
            throw error
        }
    }
    
    func isUserCaptain(userId: UUID, teamId: UUID) async throws -> Bool {
        do {
            let teams: [TeamCaptainCheck] = try await client
                .from("teams")
                .select("captain_id")
                .eq("id", value: teamId)
                .execute()
                .value
            
            if let team = teams.first {
                return team.captain_id == userId
            }
            return false
        } catch {
            print("❌ Error checking captain status: \(error)")
            throw error
        }
    }
}
