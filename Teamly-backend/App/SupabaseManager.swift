//
//  SupabaseManager.swift
//  Teamly
//
//  Created by user@37 on 22/01/26.
//

import Supabase
import Foundation

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: "https://pnfutmtuczawqyemvabe.supabase.co")!
        let supabaseKey = "sb_publishable_DhyHk3-Gt_8jEWBhzUga1Q_RQt8I9-6"
        
        // Create options with auth configuration
        let options = SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                emitLocalSessionAsInitialSession: true
            )
        )
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: options
        )
    }
}
