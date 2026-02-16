//
//  TabBarController.swift
//  Teamly-backend
//
//  Created by user@37 on 25/01/26.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        setupTabs()
        setupTabBarAppearance()

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.updateTabBarColors()
            }
        }
    }

    // MARK: - Setup
    private func setupTabs() {
        let homeVC = createNavController(
            title: "Discover",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill"),
            viewController: HomeViewController()
        )
        
        let matchVC = createNavController(
            title: "Match",
            image: UIImage(systemName: "calendar"),
            selectedImage: UIImage(systemName: "calendar"),
            viewController: MatchViewController()
        )
        
        let teamVC = createNavController(
            title: "Team",
            image: UIImage(systemName: "person.3"),
            selectedImage: UIImage(systemName: "person.3.fill"),
            viewController: TeamViewController()
        )
        
        let profileVC = createNavController(
            title: "Profile",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill"),
            viewController: ProfileViewController()
        )

        viewControllers = [homeVC, matchVC, teamVC, profileVC]
    }

    private func setupTabBarAppearance() {
        tabBar.clipsToBounds = true
        updateTabBarColors()
    }
    
    // MARK: - Public/Internal Methods
    func updateTabBarColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        tabBar.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite

        if !isDarkMode {
            appearance.shadowColor = UIColor(white: 0.9, alpha: 1.0)
            appearance.shadowImage = UIImage()
        }

        appearance.stackedLayoutAppearance.normal.iconColor = isDarkMode ? .primaryWhite : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: isDarkMode ? UIColor.primaryWhite : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]

        let selectedColor = isDarkMode ? UIColor.systemGreenDark : UIColor.systemGreen
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    private func createNavController(title: String, image: UIImage?, selectedImage: UIImage?, viewController: UIViewController) -> UINavigationController {
        let navController = UINavigationController(rootViewController: viewController)

        navController.tabBarItem = UITabBarItem(
            title: title,
            image: image?.withRenderingMode(.alwaysTemplate),
            selectedImage: selectedImage?.withRenderingMode(.alwaysTemplate)
        )

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        navAppearance.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite

        let titleColor = isDarkMode ? UIColor.primaryWhite : UIColor.primaryBlack
        navAppearance.titleTextAttributes = [
            .foregroundColor: titleColor,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        let tintColor = isDarkMode ? UIColor.systemGreenDark : UIColor.systemGreen
        navController.navigationBar.tintColor = tintColor
        
        navController.navigationBar.standardAppearance = navAppearance
        navController.navigationBar.scrollEdgeAppearance = navAppearance
        
        return navController
    }
    
    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct TabBarController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TabBarControllerRepresentable()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .previewDisplayName("Dark Mode")
            
            TabBarControllerRepresentable()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .previewDisplayName("Light Mode")
        }
    }
}

struct TabBarControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TabBarController {
        return TabBarController()
    }
    
    func updateUIViewController(_ uiViewController: TabBarController, context: Context) {
        // Update the tab bar colors when SwiftUI preview changes color scheme
        uiViewController.updateTabBarColors()
    }
}
#endif

