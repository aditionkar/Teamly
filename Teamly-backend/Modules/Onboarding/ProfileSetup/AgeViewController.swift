//
//  AgeViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 24/01/26.
//

import UIKit
import Auth
import Supabase

class AgeViewController: UIViewController {
    
    // MARK: - UI Elements
    private let topGreenTint: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        return gradient
    }()
    
    private let progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progress = 0.4
        progressView.progressTintColor = .systemGreen
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "What's your age"
        label.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ageScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.bounces = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let ageStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        
        var title = AttributedString("Next")
        title.font = .systemFont(ofSize: 20, weight: .semibold) 
        config.attributedTitle = title
        
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .primaryWhite
        config.background.cornerRadius = 25
        
        button.configuration = config
        button.isEnabled = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    private let ages = Array(16...100)
    private var ageLabels: [UILabel] = []
    private var selectedAge: Int = 20
    private var itemWidth: CGFloat = 0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupAgeSelector()
        updateColors()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        itemWidth = view.bounds.width / 4
        
        // Update content size
        let contentWidth = CGFloat(ages.count) * itemWidth
        ageStackView.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollToAge(self.selectedAge, animated: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = topGreenTint.bounds
        updateGradientColors()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
            updateGradientColors()
            updateAgeAppearance() // Also update age label colors
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Set initial background color
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
        
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(ageScrollView)
        view.addSubview(nextButton)
        
        ageScrollView.addSubview(ageStackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Top Green Tint
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -30),
            
            // Progress View
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            progressView.heightAnchor.constraint(equalToConstant: 7),

            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Age Scroll View
            ageScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 120),
            ageScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ageScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ageScrollView.heightAnchor.constraint(equalToConstant: 120),
            
            // Age Stack View
            ageStackView.topAnchor.constraint(equalTo: ageScrollView.topAnchor),
            ageStackView.leadingAnchor.constraint(equalTo: ageScrollView.leadingAnchor),
            ageStackView.trailingAnchor.constraint(equalTo: ageScrollView.trailingAnchor),
            ageStackView.bottomAnchor.constraint(equalTo: ageScrollView.bottomAnchor),
            ageStackView.centerYAnchor.constraint(equalTo: ageScrollView.centerYAnchor),
            
            // Next Button
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private func setupAgeSelector() {
        // Create age labels
        for age in ages {
            let label = UILabel()
            label.text = "\(age)"
            label.font = UIFont.systemFont(ofSize: 95, weight: .black)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            
            ageLabels.append(label)
            ageStackView.addArrangedSubview(label)
        }
        
        ageScrollView.delegate = self
        ageScrollView.clipsToBounds = false
        
        // Set initial colors for age labels
        updateAgeAppearance()
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update view background
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Update progress view track color
        progressView.trackTintColor = isDarkMode ?
            UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) :
            UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        
        // Update title label color
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
    }
    
    private func updateGradientColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if isDarkMode {
            let darkGreen = UIColor(red: 0.0, green: 0.15, blue: 0.0, alpha: 1.0)
            gradientLayer.colors = [
                darkGreen.cgColor,
                UIColor.clear.cgColor
            ]
        } else {
            // For light mode, use light green with reduced alpha
            let lightGreen = UIColor(red: 53/255, green: 199/255, blue: 89/255, alpha: 0.3)
            gradientLayer.colors = [
                lightGreen.cgColor,
                UIColor.clear.cgColor
            ]
        }
        
        gradientLayer.locations = [0.0, 0.25]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }
    
    // MARK: - Actions
    @objc private func nextButtonTapped() {
        // Show loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        nextButton.isEnabled = false
        
        Task {
            do {
                // Get current user ID from Supabase auth
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id
                
                // Save age using ProfileManager
                try await ProfileManager.shared.saveAge(userId: userId, age: selectedAge)
                
                // Success - navigate to next screen
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    nextButton.isEnabled = true
                    
                    let sportSelectionVC = SportSelectionViewController()
                    
                    // If we're already in a navigation controller, push
                    if let navController = navigationController {
                        navController.pushViewController(sportSelectionVC, animated: true)
                        navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
                    } else {
                        // If not, create a new navigation controller and present modally
                        let navController = UINavigationController(rootViewController: sportSelectionVC)
                        navController.modalPresentationStyle = .fullScreen
                        navController.setNavigationBarHidden(true, animated: false)
                        navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
                        present(navController, animated: true)
                    }
                }
                
            } catch {
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    nextButton.isEnabled = true
                    
                    print("Error saving age: \(error.localizedDescription)")
                    
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to save age. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func scrollToAge(_ age: Int, animated: Bool) {
        guard let index = ages.firstIndex(of: age), itemWidth > 0 else { return }
        
        // Calculate the x position to center the selected age
        // Add content inset to allow scrolling to edges
        let xPosition = (CGFloat(index) * itemWidth) - (view.bounds.width / 2) + (itemWidth / 2)
        
        ageScrollView.setContentOffset(CGPoint(x: xPosition, y: 0), animated: animated)
        selectedAge = age
        updateAgeAppearance()
    }
    
    private func updateAgeAppearance() {
        guard itemWidth > 0 else { return }
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Calculate center position
        let centerX = ageScrollView.contentOffset.x + view.bounds.width / 2
        
        for (index, label) in ageLabels.enumerated() {
            // Calculate label's center position
            let labelCenterX = (CGFloat(index) * itemWidth) + (itemWidth / 2)
            let distanceFromCenter = abs(labelCenterX - centerX)
            
            // Determine styling based on position
            if distanceFromCenter < itemWidth / 2 {
                // Center label - large, green, bold
                label.font = UIFont.systemFont(ofSize: 95, weight: .black)
                label.textColor = .systemGreen
                label.alpha = 1.0
                selectedAge = ages[index]
            } else if distanceFromCenter < itemWidth * 1.5 {
                // Adjacent labels (left and right) - medium size, semi-transparent
                label.font = UIFont.systemFont(ofSize: 65, weight: .heavy)
                if isDarkMode {
                    label.textColor = .white.withAlphaComponent(0.4)
                } else {
                    label.textColor = .black.withAlphaComponent(0.4)
                }
                label.alpha = 0.6
            } else {
                // Labels outside visible area - hidden
                label.font = UIFont.systemFont(ofSize: 50, weight: .bold)
                if isDarkMode {
                    label.textColor = .white.withAlphaComponent(0.2)
                } else {
                    label.textColor = .black.withAlphaComponent(0.2)
                }
                label.alpha = 0.0
            }
        }
    }
    
    private func snapToNearestAge() {
        guard itemWidth > 0 else { return }
        
        let centerX = ageScrollView.contentOffset.x + view.bounds.width / 2
        
        // Find the closest age
        var closestIndex = 0
        var minDistance: CGFloat = .greatestFiniteMagnitude
        
        for (index, _) in ages.enumerated() {
            let labelCenterX = (CGFloat(index) * itemWidth) + (itemWidth / 2)
            let distance = abs(labelCenterX - centerX)
            
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }
        
        scrollToAge(ages[closestIndex], animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension AgeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateAgeAppearance()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapToNearestAge()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            snapToNearestAge()
        }
    }
}

// MARK: - SwiftUI Preview
import SwiftUI

struct AgeViewController_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            AgeViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            AgeViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct AgeViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AgeViewController {
        return AgeViewController()
    }
    
    func updateUIViewController(_ uiViewController: AgeViewController, context: Context) {
        // Update the view controller if needed
    }
}
