//
//  AuthManager.swift
//  Teamly
//
//  Created by user@37 on 22/01/26.
//

import Foundation
import Supabase

class AuthManager {
    static let shared = AuthManager()
    
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    // Simple validation - now 6 characters minimum
    private func isFormValid(email: String, password: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email) && password.count >= 6
    }
    
    func registerNewUserWithEmail(email: String, password: String) async throws -> AuthResponse {
        if isFormValid(email: email, password: password) {
            return try await supabase.auth.signUp(
                email: email,
                password: password
            )
        } else {
            // More specific error messages
            var errorMessage = ""
            if !email.isValidEmail() && password.count < 6 {
                errorMessage = "Invalid email format and password must be at least 6 characters"
            } else if !email.isValidEmail() {
                errorMessage = "Invalid email format"
            } else if password.count < 6 {
                errorMessage = "Password must be at least 6 characters"
            } else {
                errorMessage = "Invalid email or password"
            }
            
            throw NSError(
                domain: "ValidationError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws -> Session {
        if isFormValid(email: email, password: password) {
            return try await supabase.auth.signIn(
                email: email,
                password: password
            )
        } else {
            throw NSError(
                domain: "ValidationError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid email or password"]
            )
        }
    }
}

// Email validation extension (add this if not already in your AuthManager)
extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

// Add this struct for profile response
struct ProfileResponse: Codable {
    let name: String?
    let age: Int?
    let gender: String?
    let college_id: Int?
}

// Add this extension to AuthManager.swift
extension AuthManager {
    
    func isOnboardingComplete(userId: UUID) async throws -> Bool {
        do {
            // Try to fetch profile
            let profile: ProfileResponse = try await supabase
                .from("profiles")
                .select("name, age, gender, college_id")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            // Check if all required fields are filled
            return profile.name != nil &&
                   profile.age != nil &&
                   profile.gender != nil &&
                   profile.college_id != nil
        } catch {
            // If error contains PGRST116, it means no profile exists yet
            if let postgrestError = error as? PostgrestError,
               postgrestError.code == "PGRST116" {
                print("No profile exists for user \(userId) - onboarding incomplete")
                return false
            } else {
                print("Error checking onboarding: \(error)")
                return false
            }
        }
    }
}

