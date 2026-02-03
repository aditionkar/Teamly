//
//  Colors.swift
//  Teamly-backend
//
//  Created by user@37 on 22/01/26.
//


//
//  Colors.swift
//  Practice - teamly
//
//  Created by user@37 on 23/10/25.
//

import UIKit

// MARK: - Color Palette
extension UIColor {
    // MARK: - Grayscale (Light Mode)
    static let baseWhite = UIColor(hex: "#FFFFFF")
    static let secondaryLight = UIColor(hex: "#F2F2F7") //F2F2F7 //F6F6FA //ECECF1
    static let tertiaryLight = UIColor(hex: "#E5E5EA") //E5E5EA
    static let quaternaryLight = UIColor(hex: "#D1D1D6")
    
    // MARK: - Grayscale (Dark Mode)
    static let baseBlack = UIColor(hex: "#000000")
    static let secondaryDark = UIColor(hex: "#151515") //1C1C1E
    static let tertiaryDark = UIColor(hex: "#282828") //2C2C2E
    static let quaternaryDark = UIColor(hex: "#3A3A3C")
    
    // MARK: - System Colors
    static let systemGreenLight = UIColor(hex: "#34C759")
    static let systemGreenDark = UIColor(hex: "#02b701") //30DB5B
    static let systemGreendarkOG = UIColor(hex: "#30DB5B")
    
    // MARK: - Core Colors
    static let primaryBlack = UIColor(hex: "#000000")
    static let primaryWhite = UIColor(hex: "#FFFFFF")
    
//    // MARK: - Dynamic Colors (Auto-adjusts for light/dark mode)
    static let backgroundPrimary = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? baseBlack : baseWhite
    }
//    
    static let backgroundSecondary = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? secondaryDark : secondaryLight
    }
    
    static let backgroundTertiary = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? tertiaryDark : tertiaryLight
    }
    
    static let backgroundQuaternary = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? quaternaryDark : quaternaryLight
    }
    
    static let systemGreen = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? systemGreenDark : systemGreenLight
    }
}

// MARK: - Hex Color Initializer
extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        let alpha = CGFloat(1.0)
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - SwiftUI Color Support (if using SwiftUI components)
import SwiftUI

extension Color {
    static let backgroundPrimary = Color(UIColor.backgroundPrimary)
    static let backgroundSecondary = Color(UIColor.backgroundSecondary)
    static let backgroundTertiary = Color(UIColor.backgroundTertiary)
    static let backgroundQuaternary = Color(UIColor.backgroundQuaternary)
    static let systemGreen = Color(UIColor.systemGreen)
    static let primaryBlack = Color(UIColor.primaryBlack)
    static let primaryWhite = Color(UIColor.primaryWhite)
}
