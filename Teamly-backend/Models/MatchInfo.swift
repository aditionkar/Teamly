//
//  MatchInfo.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import Foundation

// Updated to match Supabase schema
struct MatchInfo: Codable, Identifiable {
    let id: UUID
    let matchType: String
    let communityId: String?
    let venue: String
    let matchDate: Date
    let matchTime: String
    let sportId: Int
    let skillLevel: String
    let playersNeeded: Int
    let postedByUserId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case matchType = "match_type"
        case communityId = "community_id"
        case venue
        case matchDate = "match_date"
        case matchTime = "match_time"
        case sportId = "sport_id"
        case skillLevel = "skill_level"
        case playersNeeded = "players_needed"
        case postedByUserId = "posted_by_user_id"
        case createdAt = "created_at"
    }
}

struct ProfileInfo: Codable {
    let id: UUID
    let name: String?
    let gender: String?
    let age: Int?
    let collegeId: Int?
    let profilePic: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case gender
        case age
        case collegeId = "college_id"
        case profilePic = "profile_pic"
    }
}

struct MatchRSVP: Codable {
    let id: Int
    let matchId: UUID
    let userId: UUID
    let rsvpStatus: String
    let rsvpAt: Date
    let attended: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case userId = "user_id"
        case rsvpStatus = "rsvp_status"
        case rsvpAt = "rsvp_at"
        case attended
    }
}

//struct Friend: Codable {
//    let id: Int
//    let userId: UUID
//    let friendId: UUID
//    let status: String
//    let createdAt: Date
//    let updatedAt: Date
//    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case userId = "user_id"
//        case friendId = "friend_id"
//        case status
//        case createdAt = "created_at"
//        case updatedAt = "updated_at"
//    }
//}


