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
        title.font = .systemFont(ofSize: 20, weight: .semibold)
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
    private var skillLevelsForSports: [String: String] = [:]
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
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
        
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(progressView)

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

            
            // Title Stack View
            titleStackView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 60),
            titleStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Info Button size
            infoButton.widthAnchor.constraint(equalToConstant: 20),
            infoButton.heightAnchor.constraint(equalToConstant: 20),
            
            // Sport Emoji Label
            sportEmojiLabel.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: 10),
            sportEmojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        
            // Slider Content Container
            sliderContentContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sliderContentContainer.topAnchor.constraint(equalTo: sportEmojiLabel.bottomAnchor, constant: 20),
            sliderContentContainer.widthAnchor.constraint(equalToConstant: 250),
            sliderContentContainer.heightAnchor.constraint(equalToConstant: 420),
            
            // Vertical Slider
            verticalSlider.trailingAnchor.constraint(equalTo: sliderContentContainer.trailingAnchor, constant: -0),
            verticalSlider.centerYAnchor.constraint(equalTo: sliderContentContainer.centerYAnchor),
            verticalSlider.widthAnchor.constraint(equalToConstant: 8),
            verticalSlider.heightAnchor.constraint(equalToConstant: 380),
            
            // Skill Level Markers — aligned to the slider's top and bottom edges
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

        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite

        progressView.trackTintColor = isDarkMode ?
            UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) :
            UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack

        infoButton.tintColor = isDarkMode ? .primaryWhite : .primaryBlack

        sportEmojiLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack

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

        sportEmojiLabel.text = currentSport.emoji

        let baseProgress: Float = 0.8

        let sportProgress = Float(currentSportIndex) / Float(selectedSports.count)

        let progress = 0.8 + (0.2 * sportProgress)
            
        progressView.setProgress(progress, animated: true)

        if let savedSkillLevel = skillLevelsForSports[currentSport.name],
           let savedIndex = skillLevels.firstIndex(of: savedSkillLevel) {
            verticalSlider.value = Float(savedIndex)
            updateSliderAppearance()
        } else {
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

        setupSkillLevelMarkers()

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
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()
    
    private let blurEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
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
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private var thumbCenterYConstraint: NSLayoutConstraint?
    private var coloredTrackHeightConstraint: NSLayoutConstraint?

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Alignment helpers
    //
    // The markers stack (skillLevelMarkersStackView) uses .equalSpacing
    // distribution with 4 labels × 70 pt height over a 380 pt total height.
    //
    //   spacing between labels = (380 - 4 × 70) / 3 ≈ 33.33 pt
    //
    // Label centre positions measured from the BOTTOM of the 380 pt track:
    //   Level 0 (Beginner)     → 35 pt   from bottom
    //   Level 1 (Intermediate) → 138.33 pt from bottom
    //   Level 2 (Experienced)  → 241.67 pt from bottom
    //   Level 3 (Advanced)     → 345 pt   from bottom
    //
    // The thumb's centerY constraint is anchored to the view's bottomAnchor
    // with a *negative* constant, so a constant of -35 places the thumb
    // 35 pt above the bottom — exactly at the Beginner label centre.
    // ─────────────────────────────────────────────────────────────────────────

    private let levelCount: Int    = 4
    private let labelHeight: CGFloat = 70.0
    private let totalHeight: CGFloat = 380.0

    /// Y distance from the bottom of the track to the centre of the label
    /// for the given integer level index (0 = Beginner, 3 = Advanced).
    private func thumbOffsetFromBottom(forLevel level: Int) -> CGFloat {
        let spacing = (totalHeight - CGFloat(levelCount) * labelHeight) / CGFloat(levelCount - 1)
        return CGFloat(level) * (labelHeight + spacing) + labelHeight / 2.0
    }

    /// Smooth interpolation between level offsets for in-between drag values.
    private func thumbOffsetFromBottom(forValue val: Float) -> CGFloat {
        let clamped = max(minimumValue, min(maximumValue, val))
        let lower   = Int(floor(clamped))
        let upper   = Int(ceil(clamped))

        guard lower != upper else {
            return thumbOffsetFromBottom(forLevel: lower)
        }

        let fraction    = CGFloat(clamped - Float(lower))
        let lowerOffset = thumbOffsetFromBottom(forLevel: lower)
        let upperOffset = thumbOffsetFromBottom(forLevel: upper)
        return lowerOffset + fraction * (upperOffset - lowerOffset)
    }
    
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
        addSubview(trackBackgroundView)
        trackBackgroundView.addSubview(blurEffectView)
        trackBackgroundView.addSubview(coloredTrackView)
        addSubview(thumbView)
        
        NSLayoutConstraint.activate([
            // Track background fills the full slider view
            trackBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            trackBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Blur effect fills the track background
            blurEffectView.leadingAnchor.constraint(equalTo: trackBackgroundView.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trackBackgroundView.trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: trackBackgroundView.topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: trackBackgroundView.bottomAnchor),
            
            // Colored track grows upward from the bottom
            coloredTrackView.leadingAnchor.constraint(equalTo: trackBackgroundView.leadingAnchor),
            coloredTrackView.trailingAnchor.constraint(equalTo: trackBackgroundView.trailingAnchor),
            coloredTrackView.bottomAnchor.constraint(equalTo: trackBackgroundView.bottomAnchor),
            
            // Thumb size — vertical oval
            thumbView.centerXAnchor.constraint(equalTo: centerXAnchor),
            thumbView.widthAnchor.constraint(equalToConstant: 24),
            thumbView.heightAnchor.constraint(equalToConstant: 42)
        ])
        
        // Thumb Y: negative constant = distance above the bottom anchor.
        // Initial value places thumb at the Beginner (level 0) centre.
        thumbCenterYConstraint = thumbView.centerYAnchor.constraint(
            equalTo: bottomAnchor,
            constant: -thumbOffsetFromBottom(forLevel: 0)
        )
        thumbCenterYConstraint?.isActive = true
        
        // Colored track starts at zero height (Beginner)
        coloredTrackHeightConstraint = coloredTrackView.heightAnchor.constraint(
            equalToConstant: thumbOffsetFromBottom(forLevel: 0)
        )
        coloredTrackHeightConstraint?.isActive = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        updateTrackColor()
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        thumbView.layer.borderColor = isDarkMode ? UIColor.primaryWhite.cgColor : UIColor.primaryBlack.cgColor
        
        if trackColor == .tertiaryDark || trackColor == UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.3) {
            trackBackgroundView.backgroundColor = isDarkMode
                ? .tertiaryDark
                : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.3)
        }
        
        let blurStyle: UIBlurEffect.Style = isDarkMode
            ? .systemUltraThinMaterialDark
            : .systemUltraThinMaterialLight
        blurEffectView.effect = UIBlurEffect(style: blurStyle)
    }
    
    // MARK: - Position update
    //
    // Both the thumb centre and the coloured-track height are derived from
    // `thumbOffsetFromBottom(forValue:)`, which maps slider values to the
    // exact centre of the corresponding label in the markers stack.
    private func updateThumbPosition() {
        let offset = thumbOffsetFromBottom(forValue: value)
        thumbCenterYConstraint?.constant  = -offset
        coloredTrackHeightConstraint?.constant = offset
        layoutIfNeeded()
    }
    
    private func updateTrackColor() {
        coloredTrackView.backgroundColor = trackColor
    }
    
    private func snapToNearestLevel() {
        let lowerLevel = floor(value)
        let upperLevel = ceil(value)
        let progress   = value - lowerLevel
        let snappedValue = progress >= 0.5 ? upperLevel : lowerLevel
        
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
            snapToNearestLevel()
        } else {
            valueChanged?(value)
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        updateValueForLocation(location)
        snapToNearestLevel()
    }
    
    private func updateValueForLocation(_ location: CGPoint) {
        // Invert Y: bottom of track = level 0, top = level max
        let normalizedY = 1.0 - (location.y / bounds.height)
        let clampedY    = max(0, min(1, normalizedY))
        let newValue    = minimumValue + Float(clampedY) * (maximumValue - minimumValue)
        
        value = newValue
        if isContinuous { valueChanged?(value) }
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
        let sampleSports = [
            Sport(id: 1, name: "Football",   emoji: "⚽️", created_at: "2026-01-24 17:26:40"),
            Sport(id: 3, name: "Basketball", emoji: "🏀", created_at: "2026-01-24 17:26:40")
        ]
        return SkillLevelViewController(selectedSports: sampleSports)
    }
    
    func updateUIViewController(_ uiViewController: SkillLevelViewController, context: Context) {}
}
#endif
