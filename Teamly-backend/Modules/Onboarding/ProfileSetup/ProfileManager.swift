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
            do {
                let userIdString = userId.uuidString

                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    throw NSError(domain: "ProfileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])
                }

                let timestamp = Int(Date().timeIntervalSince1970)
                let fileName = "profile_\(timestamp).jpg"
                let filePath = "profile_pictures/\(userIdString)/\(fileName)"

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
                
                print("✅ Profile picture uploaded successfully: \(publicURL)")

                try await updateProfilePictureURL(userId: userId, url: publicURL.absoluteString)
                
                return publicURL.absoluteString
                
            } catch {
                print("❌ Error uploading profile picture: \(error)")
                throw error
            }
        }
        
        private func updateProfilePictureURL(userId: UUID, url: String) async throws {
            do {
                let userIdString = userId.uuidString
                
                struct ProfilePicUpdate: Encodable {
                    let profile_pic: String
                    let updated_at: String
                }
                
                let updateData = ProfilePicUpdate(
                    profile_pic: url,
                    updated_at: Date().ISO8601Format()
                )
                
                try await supabase
                    .from("profiles")
                    .update(updateData)
                    .eq("id", value: userIdString)
                    .execute()
                
                print("✅ Profile picture URL updated in database")
                
            } catch {
                print("❌ Error updating profile picture URL: \(error)")
                throw error
            }
        }
}
