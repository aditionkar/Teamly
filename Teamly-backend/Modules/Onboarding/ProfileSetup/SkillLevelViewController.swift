//
//  SkillLevelViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 24/01/26.
//

import UIKit
import Auth
import Supabase

class SkillLevelViewController: UIViewController {
    
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
        progressView.progress = 0.8
        progressView.progressTintColor = .systemGreen
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    private let titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select your skill level"
        label.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let infoButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        let infoImage = UIImage(systemName: "info.circle", withConfiguration: configuration)
        button.setImage(infoImage, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Main container for slider and labels
    private let sliderContentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let verticalSlider = VerticalSlider()
    
    private let skillLevelMarkersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
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
    
    private let sportEmojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    private let selectedSports: [Sport]
    private var currentSportIndex: Int = 0
    private var skillLevelsForSports: [String: String] = [:] // Store skill levels for each sport
    private var selectedSkillLevel: String?
    private let skillLevels = ["Beginner", "Intermediate", "Experienced", "Advanced"]
    private let skillLevelColors: [UIColor] = [
        .systemBlue,
        .systemYellow,
        .systemOrange,
        .systemRed
    ]
    
    private var markerLabels: [UILabel] = []
    
    // MARK: - Initializer
    init(selectedSports: [Sport]) {
        self.selectedSports = selectedSports
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupVerticalSlider()
        updateColors()
        updateUIForCurrentSport()
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
            updateMarkerColors()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Set initial background color
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
        
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(progressView)
        
        // Setup title stack view with info button
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(infoButton)
        view.addSubview(titleStackView)
        view.addSubview(sportEmojiLabel)
        view.addSubview(sliderContentContainer)
        sliderContentContainer.addSubview(verticalSlider)
        sliderContentContainer.addSubview(skillLevelMarkersStackView)
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

            
            // Title Stack View
            titleStackView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 60),
            titleStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Info Button size
            infoButton.widthAnchor.constraint(equalToConstant: 20),
            infoButton.heightAnchor.constraint(equalToConstant: 20),
            
            // Sport Emoji Label
            sportEmojiLabel.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: 10),
            sportEmojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        
            // Slider Content Container - Adjusted position
            sliderContentContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sliderContentContainer.topAnchor.constraint(equalTo: sportEmojiLabel.bottomAnchor, constant: 20),
            sliderContentContainer.widthAnchor.constraint(equalToConstant: 250),
            sliderContentContainer.heightAnchor.constraint(equalToConstant: 420),
            
            // Vertical Slider - Increased width to accommodate vertical oval
            verticalSlider.trailingAnchor.constraint(equalTo: sliderContentContainer.trailingAnchor, constant: -0),
            verticalSlider.centerYAnchor.constraint(equalTo: sliderContentContainer.centerYAnchor),
            verticalSlider.widthAnchor.constraint(equalToConstant: 8),
            verticalSlider.heightAnchor.constraint(equalToConstant: 380),
            
            // Skill Level Markers - on the LEFT side
            skillLevelMarkersStackView.leadingAnchor.constraint(equalTo: sliderContentContainer.leadingAnchor),
            skillLevelMarkersStackView.trailingAnchor.constraint(equalTo: verticalSlider.leadingAnchor, constant: -70),
            skillLevelMarkersStackView.topAnchor.constraint(equalTo: verticalSlider.topAnchor),
            skillLevelMarkersStackView.bottomAnchor.constraint(equalTo: verticalSlider.bottomAnchor),
            
            // Next Button
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
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
        
        // Update info button color
        infoButton.tintColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update sport emoji label
        sportEmojiLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update marker labels
        updateMarkerColors()
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
    
    private func updateUIForCurrentSport() {
        guard currentSportIndex < selectedSports.count else { return }
        
        let currentSport = selectedSports[currentSportIndex]
        
        // Update the emoji
        sportEmojiLabel.text = currentSport.emoji
        
        // Calculate progress within the 80% range
        // Base is 80% for this screen (4th out of 5 screens)
        let baseProgress: Float = 0.8
            
        // Calculate progress within current sports (0 to 1)
        let sportProgress = Float(currentSportIndex) / Float(selectedSports.count)
            
        // Final progress = 80% base + (20% * sportProgress)
        let progress = 0.8 + (0.2 * sportProgress)
            
        progressView.setProgress(progress, animated: true)

        
        // If we have a saved skill level for this sport, set the slider
        if let savedSkillLevel = skillLevelsForSports[currentSport.name],
           let savedIndex = skillLevels.firstIndex(of: savedSkillLevel) {
            verticalSlider.value = Float(savedIndex)
            updateSliderAppearance()
        } else {
            // Reset slider to default (beginner)
            verticalSlider.value = 0
            updateSliderAppearance()
        }
    }
    
    private func setupVerticalSlider() {
        verticalSlider.translatesAutoresizingMaskIntoConstraints = false
        verticalSlider.minimumValue = 0
        verticalSlider.maximumValue = 3
        verticalSlider.value = 0
        verticalSlider.isContinuous = true
        verticalSlider.valueChanged = { [weak self] value in
            self?.handleSliderValueChanged(value)
        }
        
        // Create markers for each skill level
        setupSkillLevelMarkers()
        
        // Update initial appearance
        updateSliderAppearance()
    }

    private func setupSkillLevelMarkers() {
        // Clear existing labels
        markerLabels.removeAll()
        skillLevelMarkersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Create labels for each skill level (top to bottom: Advanced -> Beginner)
        for level in skillLevels.reversed() {
            let markerLabel = UILabel()
            markerLabel.text = level
            markerLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
            markerLabel.textAlignment = .right
            markerLabel.adjustsFontSizeToFitWidth = false
            markerLabel.numberOfLines = 1
            markerLabel.translatesAutoresizingMaskIntoConstraints = false
            skillLevelMarkersStackView.addArrangedSubview(markerLabel)
            markerLabels.append(markerLabel)
        }
        
        // Decreased height for tighter spacing
        for label in markerLabels {
            label.heightAnchor.constraint(equalToConstant: 70).isActive = true
        }
        
        // Set initial colors
        updateMarkerColors()
    }
    
    private func updateMarkerColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update unselected markers
        for label in markerLabels {
            // If the label is not currently selected (from updateMarkersAppearance), set to appropriate color
            if label.textColor != .systemBlue && label.textColor != .systemYellow &&
               label.textColor != .systemOrange && label.textColor != .systemRed {
                label.textColor = isDarkMode ? .tertiaryDark : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
            }
        }
    }
    
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
    }
    
    private func updateSliderAppearance() {
        let currentValue = verticalSlider.value
        
        // Check if slider is exactly at a skill level
        let discreteValue = round(currentValue)
        let isAtSkillLevel = abs(currentValue - discreteValue) < 0.1
        
        if isAtSkillLevel {
            let skillIndex = Int(discreteValue)
            let color = skillLevelColors[skillIndex]
            
            // Update slider color
            verticalSlider.trackColor = color
            
            // Update markers appearance (reverse index for vertical display)
            updateMarkersAppearance(selectedIndex: 3 - skillIndex)
            
            selectedSkillLevel = skillLevels[skillIndex]
        } else {
            // Slider is between skill levels
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            if isDarkMode {
                verticalSlider.trackColor = .secondaryDark
            }
            
            // Reset all markers to gray
            updateMarkerColors()
            
            selectedSkillLevel = nil
        }
        
        // Next button is always enabled
        nextButton.isEnabled = true
        nextButton.configuration?.baseBackgroundColor = .systemGreen
    }
    
    private func updateMarkersAppearance(selectedIndex: Int) {
        for (index, label) in markerLabels.enumerated() {
            if index == selectedIndex {
                // Reverse index to match skill levels array
                let skillIndex = 3 - index
                label.textColor = skillLevelColors[skillIndex]
                label.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
            } else {
                let isDarkMode = traitCollection.userInterfaceStyle == .dark
                label.textColor = isDarkMode ? .tertiaryDark : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
                label.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
            }
        }
    }
    
    // MARK: - Actions
    private func handleSliderValueChanged(_ value: Float) {
        updateSliderAppearance()
    }
    
    // MARK: - Actions
    @objc private func nextButtonTapped() {
        // Save current skill level
        if let selectedSkillLevel = selectedSkillLevel {
            let currentSport = selectedSports[currentSportIndex]
            skillLevelsForSports[currentSport.name] = selectedSkillLevel
        }
        
        // Check if there are more sports
        if currentSportIndex < selectedSports.count - 1 {
            // Move to next sport
            currentSportIndex += 1
            updateUIForCurrentSport()
            
            // If it's the last sport, change button text to "Finish"
            if currentSportIndex == selectedSports.count - 1 {
                nextButton.configuration?.title = "Finish"
            }
        } else {
            // All sports processed, save skill levels and navigate to next screen
            saveSkillLevelsAndNavigate()
        }
    }

    private func saveSkillLevelsAndNavigate() {
        // Show loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        nextButton.isEnabled = false
        
        Task {
            do {
                // Get current user ID
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id
                
                // Convert skillLevelsForSports to [sportId: skillLevel] format
                var sportSkillLevels: [Int: String] = [:]
                for sport in selectedSports {
                    if let skillLevel = skillLevelsForSports[sport.name] {
                        sportSkillLevels[sport.id] = skillLevel
                    }
                }
                
                // Save skill levels using ProfileManager
                try await ProfileManager.shared.saveSkillLevels(
                    userId: userId,
                    sportSkillLevels: sportSkillLevels
                )
                
                // Success - navigate to next screen
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    nextButton.isEnabled = true
                    
                    self.navigateToAvatarSelection()
                }
                
            } catch {
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    nextButton.isEnabled = true
                    
                    print("Error saving skill levels: \(error.localizedDescription)")
                    
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to save skill levels. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func navigateToAvatarSelection() {
        print("Selected skill levels: \(skillLevelsForSports)")
        
        let avatarSelectionVC = AvatarSelectionViewController()
        
        if let navController = self.navigationController {
            navController.pushViewController(avatarSelectionVC, animated: true)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        } else {
            let navController = UINavigationController(rootViewController: avatarSelectionVC)
            navController.modalPresentationStyle = .fullScreen
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
            self.present(navController, animated: true)
        }
    }
    
    @objc private func infoButtonTapped() {
        let infoVC = SkillLevelInfoViewController()
        
        if let sheet = infoVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        
        present(infoVC, animated: true)
    }
}

// MARK: - Custom Vertical Slider
class VerticalSlider: UIView {
    
    var minimumValue: Float = 0
    var maximumValue: Float = 1
    var value: Float = 0 {
        didSet {
            updateThumbPosition()
        }
    }
    var trackColor: UIColor = .tertiaryDark {
        didSet {
            updateTrackColor()
        }
    }
    var isContinuous: Bool = true
    
    var valueChanged: ((Float) -> Void)?
    
    private let trackBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 4 // Increased for wider track
        view.clipsToBounds = true
        return view
    }()
    
    private let blurEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10 // Increased for wider track
        view.clipsToBounds = true
        return view
    }()
    
    private let coloredTrackView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let thumbView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        // Vertical oval shape: taller and narrower
        view.layer.cornerRadius = 12 // Corner radius for vertical oval
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        //view.layer.borderWidth = 2
        return view
    }()
    
    private var thumbCenterYConstraint: NSLayoutConstraint?
    private var coloredTrackHeightConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateColors()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        updateColors()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    private func setupView() {
        // Add glass effect background
        addSubview(trackBackgroundView)
        trackBackgroundView.addSubview(blurEffectView)
        trackBackgroundView.addSubview(coloredTrackView)
        addSubview(thumbView)
        
        NSLayoutConstraint.activate([
            // Track background
            trackBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            trackBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Blur effect
            blurEffectView.leadingAnchor.constraint(equalTo: trackBackgroundView.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trackBackgroundView.trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: trackBackgroundView.topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: trackBackgroundView.bottomAnchor),
            
            // Colored track (starts from bottom)
            coloredTrackView.leadingAnchor.constraint(equalTo: trackBackgroundView.leadingAnchor),
            coloredTrackView.trailingAnchor.constraint(equalTo: trackBackgroundView.trailingAnchor),
            coloredTrackView.bottomAnchor.constraint(equalTo: trackBackgroundView.bottomAnchor),
            
            // Thumb - Vertical oval shape: narrower (16) and taller (60)
            thumbView.centerXAnchor.constraint(equalTo: centerXAnchor),
            thumbView.widthAnchor.constraint(equalToConstant: 24), // Narrower for vertical oval
            thumbView.heightAnchor.constraint(equalToConstant: 42) // Taller for vertical oval
        ])
        
        thumbCenterYConstraint = thumbView.centerYAnchor.constraint(equalTo: bottomAnchor)
        thumbCenterYConstraint?.isActive = true
        
        coloredTrackHeightConstraint = coloredTrackView.heightAnchor.constraint(equalToConstant: 0)
        coloredTrackHeightConstraint?.isActive = true
        
        // Add gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        updateTrackColor()
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update thumb border color
        thumbView.layer.borderColor = isDarkMode ? UIColor.primaryWhite.cgColor : UIColor.primaryBlack.cgColor
        
        // Update track background for unselected state
        if trackColor == .tertiaryDark || trackColor == UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.3) {
            trackBackgroundView.backgroundColor = isDarkMode ? .tertiaryDark : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.3)
        }
        
        // Update blur effect style
        let blurStyle: UIBlurEffect.Style = isDarkMode ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        blurEffectView.effect = UIBlurEffect(style: blurStyle)
    }
    
    private func updateThumbPosition() {
        let normalizedValue = (value - minimumValue) / (maximumValue - minimumValue)
        
        let bottomOffset: CGFloat = 40 // Space at bottom for beginner level
        let availableHeight = bounds.height - bottomOffset
        let yOffset = (availableHeight * CGFloat(normalizedValue)) + bottomOffset
        
        thumbCenterYConstraint?.constant = -yOffset
        coloredTrackHeightConstraint?.constant = yOffset
        
        layoutIfNeeded()
    }
    
    private func updateTrackColor() {
        coloredTrackView.backgroundColor = trackColor
    }
    
    private func snapToNearestLevel() {
        let currentValue = value
        let lowerLevel = floor(currentValue)
        let upperLevel = ceil(currentValue)
        let progress = currentValue - lowerLevel
        
        // Snap up if >= 50%, snap down if < 50%
        let snappedValue = progress >= 0.5 ? upperLevel : lowerLevel
        
        // Animate the snap
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.value = snappedValue
            self.layoutIfNeeded()
        }
        
        valueChanged?(snappedValue)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        updateValueForLocation(location)
        
        if gesture.state == .ended {
            // Snap to nearest level when user releases
            snapToNearestLevel()
        } else {
            valueChanged?(value)
        }
    }

    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        updateValueForLocation(location)
        
        // Snap to nearest level after tap
        snapToNearestLevel()
    }
    
    private func updateValueForLocation(_ location: CGPoint) {
        // Invert Y coordinate (bottom = 0, top = max)
        let normalizedY = 1.0 - (location.y / bounds.height)
        let clampedY = max(0, min(1, normalizedY))
        
        let newValue = minimumValue + Float(clampedY) * (maximumValue - minimumValue)
        
        if isContinuous {
            value = newValue
            valueChanged?(value)
        } else {
            value = newValue
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateThumbPosition()
    }
}

// MARK: - Skill Level Info View Controller (Modal)
class SkillLevelInfoViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 28
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])
        
        // Add skill level descriptions
        let skillLevels = [
            ("Beginner", "You're new to the sport or have limited experience. Focused on learning basic rules, techniques, and fundamentals."),
            ("Intermediate", "You have a good understanding of the game and basic skills. Can participate comfortably in recreational play."),
            ("Experienced", "Regular player with solid technical skills and game understanding. Comfortable with advanced techniques and strategies."),
            ("Advanced", "Highly skilled player with extensive experience. Competes at high levels with advanced tactical understanding and consistent performance.")
        ]
        
        for (title, description) in skillLevels {
            let levelView = createSkillLevelView(title: title, description: description)
            contentStackView.addArrangedSubview(levelView)
        }
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
    }
    
    private func createSkillLevelView(title: String, description: String) -> UIView {
        let containerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .systemGreen
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = description
        descriptionLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Set description label color based on current mode
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        descriptionLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SkillLevelViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SkillLevelViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .previewDisplayName("Dark Mode")
            
            SkillLevelViewControllerRepresentable()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .previewDisplayName("Light Mode")
        }
    }
}

struct SkillLevelViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SkillLevelViewController {
        // Create a sample array of sports for the preview
        let sampleSports = [
            Sport(id: 1,name: "Football", emoji: "⚽️", created_at: "2026-01-24 17:26:40"),
            Sport(id: 3,name: "Basketball", emoji: "🏀", created_at: "2026-01-24 17:26:40")
        ]
        return SkillLevelViewController(selectedSports: sampleSports)
    }
    
    func updateUIViewController(_ uiViewController: SkillLevelViewController, context: Context) {
        // No update needed
    }
}
#endif
