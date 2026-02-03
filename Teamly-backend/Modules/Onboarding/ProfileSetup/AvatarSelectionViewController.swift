//
//  AvatarSelectionViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 24/01/26.
//

import UIKit

class AvatarSelectionViewController: UIViewController {
    
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
        progressView.progress = 1.0
        progressView.progressTintColor = .systemGreen
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add a profile pic"
        label.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let avatarContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 35
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add arrow icon
        let arrowImage = UIImage(systemName: "chevron.down")
        button.setImage(arrowImage, for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        
        return button
    }()
    
    private let skipButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        var title = AttributedString("Skip")
        title.font = .systemFont(ofSize: 20, weight: .semibold) // bigger + bolder
        config.attributedTitle = title
        config.background.cornerRadius = 25
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        
        var title = AttributedString("Next")
        title.font = .systemFont(ofSize: 20, weight: .semibold) // bigger + bolder
        config.attributedTitle = title
        
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .primaryWhite
        config.background.cornerRadius = 25
        
        button.configuration = config
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    private var selectedAvatar: UIImage?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        updateColors()
        
        // Set default SF Symbol
        avatarImageView.image = UIImage(systemName: "person.fill")
        
        // Enable next button by default
        updateNextButtonState()
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
        view.addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(selectButton)
        view.addSubview(skipButton)
        view.addSubview(nextButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Top Green Tint - extends from top to just above the Next button
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
            
            // Avatar Container
            avatarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            avatarContainer.widthAnchor.constraint(equalToConstant: 200),
            avatarContainer.heightAnchor.constraint(equalToConstant: 200),
            
            // Avatar Image View
            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor, constant: 40),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Select Button
            selectButton.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            selectButton.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: -30),
            selectButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Next Button (at bottom)
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Skip Button (above Next button)
            skipButton.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -16),
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.widthAnchor.constraint(equalToConstant: 120),
            skipButton.heightAnchor.constraint(equalToConstant: 50)
        ])
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
        
        // Update avatar container
        avatarContainer.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        // Update avatar image view tint
        avatarImageView.tintColor = isDarkMode ? .quaternaryLight : .quaternaryDark
        
        // Update select button colors
        selectButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        selectButton.tintColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update skip button colors
        skipButton.configuration?.baseBackgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        skipButton.configuration?.baseForegroundColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update next button colors
        nextButton.configuration?.baseBackgroundColor = .systemGreen
        nextButton.configuration?.baseForegroundColor = .primaryWhite
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
    
    private func setupActions() {
        selectButton.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private func updateNextButtonState() {
        // Next button is always enabled now
        nextButton.isEnabled = true
        nextButton.alpha = 1.0
    }
    
    // MARK: - Actions
    @objc private func selectButtonTapped() {
        let optionModalVC = AvatarOptionModalViewController()
        
        // Set callback for when an option is selected
        optionModalVC.onOptionSelected = { [weak self] option in
            self?.handleAvatarOption(option)
        }
        
        if let sheet = optionModalVC.sheetPresentationController {
            sheet.detents = [.custom { context in
                return 240 // Exact height needed
            }]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        present(optionModalVC, animated: true)
    }
    
    @objc private func skipButtonTapped() {
        // Navigate to next screen without selecting avatar
        let searchingCommunitiesVC = SearchingCommunitiesViewController()
        
        if let navController = self.navigationController {
            navController.pushViewController(searchingCommunitiesVC, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: searchingCommunitiesVC)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true)
        }
    }
    
    @objc private func nextButtonTapped() {
        // Navigate to SearchingCommunitiesViewController
        let searchingCommunitiesVC = SearchingCommunitiesViewController()
        
        if let navController = self.navigationController {
            navController.pushViewController(searchingCommunitiesVC, animated: true)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        } else {
            let navController = UINavigationController(rootViewController: searchingCommunitiesVC)
            navController.modalPresentationStyle = .fullScreen
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
            self.present(navController, animated: true)
        }
    }
    
    private func handleAvatarOption(_ option: AvatarOption) {
        switch option {
        case .takePhoto:
            print("Take photo selected")
            selectedAvatar = UIImage(systemName: "person.fill")
            avatarImageView.image = selectedAvatar
            avatarImageView.tintColor = .systemGreen
            updateNextButtonState()
            
        case .choosePhoto:
            print("Choose photo selected")
            selectedAvatar = UIImage(systemName: "person.fill")
            avatarImageView.image = selectedAvatar
            avatarImageView.tintColor = .systemGreen
            updateNextButtonState()
        }
    }
}

// MARK: - Avatar Option Modal View Controller
class AvatarOptionModalViewController: UIViewController {
    
    // MARK: - Properties
    var onOptionSelected: ((AvatarOption) -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add profile picture"
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let optionsContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let takePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Create configuration
        var config = UIButton.Configuration.plain()
        config.title = "Take photo"
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let cameraIcon = UIImage(systemName: "camera", withConfiguration: imageConfig)
        config.image = cameraIcon
        
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        
        button.configuration = config
        button.contentHorizontalAlignment = .fill
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        return button
    }()

    private let choosePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Create configuration
        var config = UIButton.Configuration.plain()
        config.title = "Choose photo"
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let photoIcon = UIImage(systemName: "photo", withConfiguration: imageConfig)
        config.image = photoIcon
        
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        
        button.configuration = config
        button.contentHorizontalAlignment = .fill
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        return button
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        updateColors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update colors when view appears to ensure correct mode
        updateColors()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    private func setupUI() {
        // Add scroll view and content stack
        view.addSubview(titleLabel)
        view.addSubview(optionsContainer)
        optionsContainer.addSubview(takePhotoButton)
        optionsContainer.addSubview(separatorLine)
        optionsContainer.addSubview(choosePhotoButton)
        
        // Set preferred content size to make modal only as tall as needed
        preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 240)
    }
    
    private func updateColors() {
        // Get the presenting view controller's trait collection to determine mode
        let presentingViewControllerMode: UIUserInterfaceStyle
        if let presentingVC = self.presentingViewController {
            presentingViewControllerMode = presentingVC.traitCollection.userInterfaceStyle
        } else {
            // Fallback to current view controller's trait collection
            presentingViewControllerMode = traitCollection.userInterfaceStyle
        }
        
        let isDarkMode = presentingViewControllerMode == .dark
        
        // Update view background
        view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        // Update title label color
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update options container
        optionsContainer.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        
        // Update buttons
        takePhotoButton.configuration?.baseForegroundColor = isDarkMode ? .primaryWhite : .primaryBlack
        choosePhotoButton.configuration?.baseForegroundColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update separator line
        separatorLine.backgroundColor = isDarkMode ?
            UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0) :
            UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Options Container
            optionsContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            optionsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            optionsContainer.heightAnchor.constraint(equalToConstant: 112),
            optionsContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -40),
            
            // Take Photo Button
            takePhotoButton.topAnchor.constraint(equalTo: optionsContainer.topAnchor),
            takePhotoButton.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
            takePhotoButton.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            takePhotoButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Separator Line
            separatorLine.topAnchor.constraint(equalTo: takePhotoButton.bottomAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor, constant: 20),
            separatorLine.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor, constant: -20),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Choose Photo Button
            choosePhotoButton.topAnchor.constraint(equalTo: separatorLine.bottomAnchor),
            choosePhotoButton.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
            choosePhotoButton.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            choosePhotoButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupActions() {
        takePhotoButton.addTarget(self, action: #selector(takePhotoTapped), for: .touchUpInside)
        choosePhotoButton.addTarget(self, action: #selector(choosePhotoTapped), for: .touchUpInside)
    }
    
    @objc private func takePhotoTapped() {
        onOptionSelected?(.takePhoto)
        dismiss(animated: true)
    }
    
    @objc private func choosePhotoTapped() {
        onOptionSelected?(.choosePhoto)
        dismiss(animated: true)
    }
}
// MARK: - Avatar Option Enum
enum AvatarOption {
    case takePhoto
    case choosePhoto
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct AvatarSelectionViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AvatarSelectionViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .previewDisplayName("Dark Mode")
            
            AvatarSelectionViewControllerRepresentable()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .previewDisplayName("Light Mode")
        }
    }
}

struct AvatarSelectionViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AvatarSelectionViewController {
        return AvatarSelectionViewController()
    }
    
    func updateUIViewController(_ uiViewController: AvatarSelectionViewController, context: Context) {
        // No update needed
    }
}
#endif
