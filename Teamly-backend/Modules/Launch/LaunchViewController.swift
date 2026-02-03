//
//  LaunchViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 22/01/26.
//

import UIKit

class LaunchViewController: UIViewController {
    
    var onComplete: (() -> Void)?
    
    private let footballImageView = UIImageView()
    private let appNameLabel = UILabel()
    private let loadingBar = UIView()
    private let loadingProgress = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startBounceAnimation()
        startLoadingBarAnimation()
        simulateAppLoading()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    private func setupUI() {
        // Set initial colors based on current mode
        updateColors()
        
        // Configure App Name Label
        appNameLabel.text = "Teamly"
        appNameLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        appNameLabel.textAlignment = .center
        
        // Configure Loading Bar Background
        loadingBar.layer.cornerRadius = 3 // Increased for thicker bar
        
        // Configure Loading Progress
        loadingProgress.backgroundColor = .systemGreen
        loadingProgress.layer.cornerRadius = 3 // Increased for thicker bar
        
        // Create main stack view for football and app name
        let mainStackView = UIStackView(arrangedSubviews: [footballImageView, appNameLabel])
        mainStackView.axis = .vertical
        mainStackView.spacing = 24
        mainStackView.alignment = .center
        
        view.addSubview(mainStackView)
        view.addSubview(loadingBar)
        loadingBar.addSubview(loadingProgress)
        
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        loadingBar.translatesAutoresizingMaskIntoConstraints = false
        loadingProgress.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
//            // Football image
//            footballImageView.widthAnchor.constraint(equalToConstant: 120),
//            footballImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Main stack view - centered
            mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            
            // Loading bar - shorter and positioned below Teamly label
            loadingBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingBar.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 30), // Below Teamly label
            loadingBar.widthAnchor.constraint(equalToConstant: 180), // Shorter width
            loadingBar.heightAnchor.constraint(equalToConstant: 6), // Thicker bar
            
            // Loading progress (initial state - very small)
            loadingProgress.leadingAnchor.constraint(equalTo: loadingBar.leadingAnchor),
            loadingProgress.topAnchor.constraint(equalTo: loadingBar.topAnchor),
            loadingProgress.bottomAnchor.constraint(equalTo: loadingBar.bottomAnchor),
            loadingProgress.widthAnchor.constraint(equalToConstant: 1) // Start very small
        ])
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update view background
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Update app name label color
        appNameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update loading bar background
        loadingBar.backgroundColor = isDarkMode ? .baseWhite : UIColor(white: 0.9, alpha: 1.0)
    }
    
    private func startBounceAnimation() {
       
        footballImageView.transform = CGAffineTransform(translationX: 0, y: 40)
        
        // Create bigger bounce animation
        UIView.animate(
            withDuration: 1.0,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 1.0,
            options: [.curveEaseInOut, .repeat, .autoreverse],
            animations: {
                // Bigger bounce up
                self.footballImageView.transform = CGAffineTransform(translationX: 0, y: -40)
            },
            completion: nil
        )
         
        // Add subtle rotation for more dynamic effect
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = -0.08
        rotateAnimation.toValue = 0.08
        rotateAnimation.duration = 1.8
        rotateAnimation.autoreverses = true
        rotateAnimation.repeatCount = .infinity
        rotateAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        footballImageView.layer.add(rotateAnimation, forKey: "bounceRotate")
    }
    
    private func startLoadingBarAnimation() {
        // Reset loading bar
        self.loadingProgress.constraints.forEach { constraint in
            if constraint.firstAttribute == .width {
                constraint.constant = 1
            }
        }
        self.view.layoutIfNeeded()
        
        // Animate loading bar growing from left to right
        UIView.animate(
            withDuration: 1.5,
            delay: 0.2,
            options: [.curveEaseInOut],
            animations: {
                // Expand the progress bar to full width
                self.loadingProgress.constraints.forEach { constraint in
                    if constraint.firstAttribute == .width {
                        constraint.constant = self.loadingBar.frame.width
                    }
                }
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                // Reset and repeat the animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.startLoadingBarAnimation()
                }
            }
        )
    }

    private func simulateAppLoading() {
        // Simulate loading time (3 seconds to see multiple bounces and loading cycles)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Stop all animations before transitioning
            self.footballImageView.layer.removeAllAnimations()
            self.loadingProgress.layer.removeAllAnimations()
            
            // Transition to LandingViewController
            self.transitionToLandingViewController()
        }
    }
    
    private func transitionToLandingViewController() {
        let landingVC = LandingViewController()
        landingVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        
        // Get the window and transition
        if let window = self.view.window {
            UIView.transition(with: window, duration: 1.0, options: .transitionCrossDissolve, animations: {
                window.rootViewController = landingVC
            }, completion: nil)
        } else {
            // Fallback: present modally
            landingVC.modalPresentationStyle = .fullScreen
            self.present(landingVC, animated: false)
        }
        
        // Call onComplete if it exists (for backward compatibility)
        self.onComplete?()
    }
  
    // Clean up animations when view disappears
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        footballImageView.layer.removeAllAnimations()
        loadingProgress.layer.removeAllAnimations()
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI)
import SwiftUI

struct LaunchViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LaunchViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            LaunchViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct LaunchViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LaunchViewController {
        return LaunchViewController()
    }
    
    func updateUIViewController(_ uiViewController: LaunchViewController, context: Context) {
        // Update the view controller if needed
    }
}
#endif

//Placeholder




//import UIKit
//
//class EditTeamInformationViewController: UIViewController {
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        
//        let titleLabel = UILabel()
//        titleLabel.text = "EditTeamInformationViewController"
//        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
//        titleLabel.textAlignment = .center
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(titleLabel)
//        
//        NSLayoutConstraint.activate([
//            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//}

import UIKit

class NotificationsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "NotificationsViewController"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

//class AddPlayersViewController: UIViewController {
//    var team: BackendTeam?
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        print("AddPlayersViewController")
//    }
//}

//class TeamMatchesViewController: UIViewController {
//    var team: BackendTeam?
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        print("TeamMatchesViewController")
//    }
//}


//// ChallengeTeamMatchViewController.swift
//class ChallengeTeamMatchViewController: UIViewController {
//    var currentTeam: BackendTeam?
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        print("Challenge VC - Team: \(currentTeam?.name ?? "None")")
//    }
//}

// TeamMatchRequestViewController.swift
//class TeamMatchRequestViewController: UIViewController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        print("Match Requests VC loaded")
//    }
//}


// Helper struct if needed
struct Team {
    var name: String?
}
