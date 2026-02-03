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
        
        // Register for trait changes (iOS 17+)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.updateTabBarColors()
            }
        }
    }

    // Remove the traitCollectionDidChange method entirely

    // MARK: - Setup
    private func setupTabs() {
        let homeVC = createNavController(
            title: "Home",
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
        
        // Tab Bar Background
        tabBar.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Tab Bar Item Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Add a subtle shadow/separator in light mode
        if !isDarkMode {
            appearance.shadowColor = UIColor(white: 0.9, alpha: 1.0)
            appearance.shadowImage = UIImage()
        }
        
        // Normal state (unselected) - Update colors for both modes
        appearance.stackedLayoutAppearance.normal.iconColor = isDarkMode ? .primaryWhite : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: isDarkMode ? UIColor.primaryWhite : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        // Selected state - Keep systemGreenDark for dark mode, use systemGreen for light mode
        let selectedColor = isDarkMode ? UIColor.systemGreenDark : UIColor.systemGreen
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        // Apply the appearance
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    private func createNavController(title: String, image: UIImage?, selectedImage: UIImage?, viewController: UIViewController) -> UINavigationController {
        let navController = UINavigationController(rootViewController: viewController)
        
        // Configure tab bar item
        navController.tabBarItem = UITabBarItem(
            title: title,
            image: image?.withRenderingMode(.alwaysTemplate),
            selectedImage: selectedImage?.withRenderingMode(.alwaysTemplate)
        )
        
        // Navigation bar appearance - Support both dark and light modes
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        navAppearance.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Set title color based on mode
        let titleColor = isDarkMode ? UIColor.primaryWhite : UIColor.primaryBlack
        navAppearance.titleTextAttributes = [
            .foregroundColor: titleColor,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // Set tint color for bar button items
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


// Placeholders


//import UIKit
//
//class HomeViewController: UIViewController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        title = "Home"
//        
//        let label = UILabel()
//        label.text = "Home Screen"
//        label.textAlignment = .center
//        label.font = .systemFont(ofSize: 20, weight: .medium)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(label)
//        NSLayoutConstraint.activate([
//            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//}

//import UIKit
//
//class MatchViewController: UIViewController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        title = "Match"
//        
//        let label = UILabel()
//        label.text = "Match Screen"
//        label.textAlignment = .center
//        label.font = .systemFont(ofSize: 20, weight: .medium)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(label)
//        NSLayoutConstraint.activate([
//            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//}
//
//import UIKit
//
//class TeamViewController: UIViewController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        title = "Team"
//        
//        let label = UILabel()
//        label.text = "Team Screen"
//        label.textAlignment = .center
//        label.font = .systemFont(ofSize: 20, weight: .medium)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(label)
//        NSLayoutConstraint.activate([
//            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//}

//import UIKit
//
//class ProfileViewController: UIViewController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        title = "Profile"
//        
//        let label = UILabel()
//        label.text = "Profile Screen"
//        label.textAlignment = .center
//        label.font = .systemFont(ofSize: 20, weight: .medium)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(label)
//        NSLayoutConstraint.activate([
//            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//}
//

