//
//  ProfileManager.swift
//  Teamly-backend
//
//  Created by user@37 on 24/01/26.
//

import Foundation
import Supabase

class ProfileManager {
    static let shared = ProfileManager()
    
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Save Name and Gender
    func saveNameAndGender(userId: UUID, name: String, gender: String) async throws {
        do {
            // Convert UUID to String for Supabase
            let userIdString = userId.uuidString
            let capitalizedGender = gender.capitalized
            
            // Use upsert - will insert if doesn't exist, update if does
            try await supabase
                .from("profiles")
                .upsert([
                    "id": userIdString,
                    "name": name,
                    "gender": capitalizedGender,
                    "updated_at": Date().ISO8601Format()
                ])
                .execute()
            
            print("Name and gender saved successfully for user: \(userId)")
            
        } catch {
            print("Error saving name and gender: \(error)")
            throw error
        }
    }
    
    // MARK: - Save Age
    func saveAge(userId: UUID, age: Int) async throws {
        do {
            let userIdString = userId.uuidString.lowercased()
            
            // Define a struct that conforms to Encodable
            struct AgeUpdate: Encodable {
                let age: Int
                let updated_at: String
            }
            
            let updateData = AgeUpdate(
                age: age,
                updated_at: Date().ISO8601Format()
            )
            
            try await supabase
                .from("profiles")
                .update(updateData)
                .eq("id", value: userIdString)
                .execute()
            
            print("Age saved successfully for user: \(userId)")
            
        } catch {
            print("Error saving age: \(error)")
            throw error
        }
    }

    // MARK: - Save Preferred Sports
    func savePreferredSports(userId: UUID, sportIds: [Int]) async throws {
        do {
            let userIdString = userId.uuidString
            
            // First, clear existing preferred sports for this user
            try await supabase
                .from("user_preferred_sports")
                .delete()
                .eq("user_id", value: userIdString)
                .execute()
            
            // If no sports selected, just return
            guard !sportIds.isEmpty else {
                print("No sports selected to save")
                return
            }
            
            // Define a struct that conforms to Encodable
            struct PreferredSport: Encodable {
                let user_id: String
                let sport_id: Int
                let created_at: String
            }
            
            // Prepare data for bulk insert
            let sportsData = sportIds.map { sportId in
                PreferredSport(
                    user_id: userIdString,
                    sport_id: sportId,
                    created_at: Date().ISO8601Format()
                )
            }
            
            // Insert all selected sports
            try await supabase
                .from("user_preferred_sports")
                .insert(sportsData)
                .execute()
            
            print("\(sportIds.count) preferred sports saved successfully for user: \(userId)")
            
        } catch {
            print("Error saving preferred sports: \(error)")
            throw error
        }
    }
    
    // MARK: - Save Skill Level for Sports
        func saveSkillLevels(userId: UUID, sportSkillLevels: [Int: String]) async throws {
            do {
                let userIdString = userId.uuidString
                
                for (sportId, skillLevel) in sportSkillLevels {
                    // Update skill level for each sport
                    try await supabase
                        .from("user_preferred_sports")
                        .update(["skill_level": skillLevel])
                        .eq("user_id", value: userIdString)
                        .eq("sport_id", value: sportId)
                        .execute()
                    
                    print("Skill level '\(skillLevel)' saved for sport ID: \(sportId)")
                }
                
                print("Skill levels saved successfully for user: \(userId)")
                
            } catch {
                print("Error saving skill levels: \(error)")
                throw error
            }
        }
    
    // MARK: - Save College
    func saveCollege(userId: UUID, collegeId: Int) async throws {
        do {
            let userIdString = userId.uuidString.lowercased()
            
            // Define a struct that conforms to Encodable
            struct CollegeUpdate: Encodable {
                let college_id: Int
                let updated_at: String
            }
            
            let updateData = CollegeUpdate(
                college_id: collegeId,
                updated_at: Date().ISO8601Format()
            )
            
            try await supabase
                .from("profiles")
                .update(updateData)
                .eq("id", value: userIdString)
                .execute()
            
            print("College saved successfully for user: \(userId)")
            
        } catch {
            print("Error saving college: \(error)")
            throw error
        }
    }
}
