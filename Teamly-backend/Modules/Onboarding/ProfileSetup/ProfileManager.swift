//
//  ProfileManager.swift
//  Teamly-backend
//
//  Created by user@37 on 24/01/26.
//

import Foundation
import Supabase
import UIKit

class ProfileManager {
    static let shared = ProfileManager()
    
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Save Name and Gender
    func saveNameAndGender(userId: UUID, name: String, gender: String) async throws {
        do {
           
            let userIdString = userId.uuidString
            let capitalizedGender = gender.capitalized

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

            try await supabase
                .from("user_preferred_sports")
                .delete()
                .eq("user_id", value: userIdString)
                .execute()

            guard !sportIds.isEmpty else {
                print("No sports selected to save")
                return
            }

            struct PreferredSport: Encodable {
                let user_id: String
                let sport_id: Int
                let created_at: String
            }

            let sportsData = sportIds.map { sportId in
                PreferredSport(
                    user_id: userIdString,
                    sport_id: sportId,
                    created_at: Date().ISO8601Format()
                )
            }

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
    
    // MARK: - Upload Profile Picture
    func uploadProfilePicture(userId: UUID, image: UIImage) async throws -> String {
        let userIdString = userId.uuidString.lowercased()

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ProfileManager", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "profile_\(timestamp).jpg"
        let filePath = "profile_pictures/\(userIdString)/\(fileName)"

        print("📤 Uploading image to storage...")

        try await supabase.storage
            .from("avatars")
            .upload(
                path: filePath,
                file: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg"
                )
            )

        let publicURL = try await supabase.storage
            .from("avatars")
            .getPublicURL(path: filePath)

        print("✅ Image uploaded: \(publicURL)")

        // Encodable structs instead of [String: Any]
        struct ProfileUpdate: Encodable {
            let profile_pic: String
            let updated_at: String
        }

        struct ProfileInsert: Encodable {
            let id: String
            let profile_pic: String
            let created_at: String
            let updated_at: String
        }

        // Check if profile exists
        let profileResponse = try await supabase
            .from("profiles")
            .select("id")
            .eq("id", value: userIdString)
            .execute()

        let jsonObject = try JSONSerialization.jsonObject(with: profileResponse.data) as? [[String: Any]]
        let profileExists = jsonObject?.isEmpty == false

        if profileExists {
            print("📝 Updating existing profile...")
            let updateData = ProfileUpdate(
                profile_pic: publicURL.absoluteString,
                updated_at: Date().ISO8601Format()
            )
            try await supabase
                .from("profiles")
                .update(updateData)
                .eq("id", value: userIdString)
                .execute()
            print("✅ Profile picture URL updated")
        } else {
            print("📝 Creating new profile...")
            let insertData = ProfileInsert(
                id: userIdString,
                profile_pic: publicURL.absoluteString,
                created_at: Date().ISO8601Format(),
                updated_at: Date().ISO8601Format()
            )
            try await supabase
                .from("profiles")
                .insert(insertData)
                .execute()
            print("✅ New profile created with picture URL")
        }

        return publicURL.absoluteString
    }
        
    private func updateProfilePictureURL(userId: UUID, url: String) async throws {
        do {
            let userIdString = userId.uuidString.lowercased()
            
            // First try to update
            do {
                try await supabase
                    .from("profiles")
                    .update([
                        "profile_pic": url,
                        "updated_at": Date().ISO8601Format()
                    ])
                    .eq("id", value: userIdString)
                    .execute()
                
                print("✅ Profile picture URL updated in database")
                return
            } catch {
                print("⚠️ Update failed, trying insert...")
                
                // If update fails, try insert
                try await supabase
                    .from("profiles")
                    .insert([
                        "id": userIdString,
                        "profile_pic": url,
                        "created_at": Date().ISO8601Format(),
                        "updated_at": Date().ISO8601Format()
                    ])
                    .execute()
                
                print("✅ New profile created with picture URL")
            }
            
        } catch {
            print("❌ Error updating profile picture URL: \(error)")
            throw error
        }
    }
}
