//
//  UpdateSkillViewController.swift
//  Teamly-backend
//
//  Created by admin20 on 19/02/26.
//

//
//  UpdateSkillViewController.swift
//  Teamly-backend
//

import UIKit
import Supabase

class UpdateSkillViewController: UIViewController {

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

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray
        button.backgroundColor = UIColor.systemGray.withAlphaComponent(0.15)
        button.layer.cornerRadius = 17
        button.clipsToBounds = true
        return button
    }()

    private let titleStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Update skill level"
        label.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let infoButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        button.setImage(UIImage(systemName: "info.circle", withConfiguration: configuration), for: .normal)
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

    private let sportNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let sliderContentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let verticalSlider = VerticalSlider()

    private let skillLevelMarkersStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.distribution = .equalSpacing
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let actionButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        var title = AttributedString("Next")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        config.attributedTitle = title
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .white
        config.background.cornerRadius = 25
        button.configuration = config
        button.isEnabled = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Properties
    var onSkillUpdated: (() -> Void)?

    /// Pass in the user's current sports with skill levels
    private var sports: [SportWithSkill]
    private var currentIndex: Int = 0
    private var updatedSkillLevels: [Int: String] = [:] // sportId: newSkillLevel

    private let skillLevels = ["Beginner", "Intermediate", "Experienced", "Advanced"]
    private let skillLevelColors: [UIColor] = [.systemBlue, .systemYellow, .systemOrange, .systemRed]
    private var markerLabels: [UILabel] = []
    private var selectedSkillLevel: String?

    // MARK: - Init
    init(sports: [SportWithSkill]) {
        self.sports = sports
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

        view.addSubview(cancelButton)

        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(infoButton)
        view.addSubview(titleStackView)
        view.addSubview(sportEmojiLabel)
        view.addSubview(sportNameLabel)
        view.addSubview(sliderContentContainer)
        sliderContentContainer.addSubview(verticalSlider)
        sliderContentContainer.addSubview(skillLevelMarkersStackView)
        view.addSubview(actionButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -30),

            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 34),
            cancelButton.heightAnchor.constraint(equalToConstant: 34),

            titleStackView.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 24),
            titleStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            infoButton.widthAnchor.constraint(equalToConstant: 20),
            infoButton.heightAnchor.constraint(equalToConstant: 20),

            sportEmojiLabel.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: 10),
            sportEmojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            sportNameLabel.topAnchor.constraint(equalTo: sportEmojiLabel.bottomAnchor, constant: 4),
            sportNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            sliderContentContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sliderContentContainer.topAnchor.constraint(equalTo: sportNameLabel.bottomAnchor, constant: 20),
            sliderContentContainer.widthAnchor.constraint(equalToConstant: 250),
            sliderContentContainer.heightAnchor.constraint(equalToConstant: 420),

            verticalSlider.trailingAnchor.constraint(equalTo: sliderContentContainer.trailingAnchor),
            verticalSlider.centerYAnchor.constraint(equalTo: sliderContentContainer.centerYAnchor),
            verticalSlider.widthAnchor.constraint(equalToConstant: 8),
            verticalSlider.heightAnchor.constraint(equalToConstant: 380),

            skillLevelMarkersStackView.leadingAnchor.constraint(equalTo: sliderContentContainer.leadingAnchor),
            skillLevelMarkersStackView.trailingAnchor.constraint(equalTo: verticalSlider.leadingAnchor, constant: -70),
            skillLevelMarkersStackView.topAnchor.constraint(equalTo: verticalSlider.topAnchor),
            skillLevelMarkersStackView.bottomAnchor.constraint(equalTo: verticalSlider.bottomAnchor),

            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 120),
            actionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupActions() {
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
    }

    // MARK: - Slider Setup
    private func setupVerticalSlider() {
        verticalSlider.translatesAutoresizingMaskIntoConstraints = false
        verticalSlider.minimumValue = 0
        verticalSlider.maximumValue = 3
        verticalSlider.value = 0
        verticalSlider.isContinuous = true
        verticalSlider.valueChanged = { [weak self] _ in
            self?.updateSliderAppearance()
        }
        setupSkillLevelMarkers()
        updateSliderAppearance()
    }

    private func setupSkillLevelMarkers() {
        markerLabels.removeAll()
        skillLevelMarkersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for level in skillLevels.reversed() {
            let label = UILabel()
            label.text = level
            label.font = UIFont.systemFont(ofSize: 26, weight: .medium)
            label.textAlignment = .right
            label.numberOfLines = 1
            label.translatesAutoresizingMaskIntoConstraints = false
            skillLevelMarkersStackView.addArrangedSubview(label)
            markerLabels.append(label)
        }

        for label in markerLabels {
            label.heightAnchor.constraint(equalToConstant: 70).isActive = true
        }

        updateMarkerColors()
    }

    // MARK: - UI Update
    private func updateUIForCurrentSport() {
        guard currentIndex < sports.count else { return }
        let sport = sports[currentIndex]

        sportEmojiLabel.text = sport.emoji ?? "🏃"
        sportNameLabel.text = sport.name

        // Pre-select current skill level
        if let index = skillLevels.firstIndex(of: sport.skill_level) {
            verticalSlider.value = Float(index)
        } else {
            verticalSlider.value = 0
        }

        updateSliderAppearance()

        // Last sport → Save, otherwise → Next
        let isLast = currentIndex == sports.count - 1
        var title = AttributedString(isLast ? "Save" : "Next")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        actionButton.configuration?.attributedTitle = title
    }

    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        sportNameLabel.textColor = isDarkMode ? UIColor.primaryWhite.withAlphaComponent(0.6) : UIColor.primaryBlack.withAlphaComponent(0.6)
        infoButton.tintColor = isDarkMode ? .primaryWhite : .primaryBlack
        updateMarkerColors()
    }

    private func updateGradientColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        if isDarkMode {
            gradientLayer.colors = [UIColor(red: 0.0, green: 0.15, blue: 0.0, alpha: 1.0).cgColor, UIColor.clear.cgColor]
        } else {
            gradientLayer.colors = [UIColor(red: 53/255, green: 199/255, blue: 89/255, alpha: 0.3).cgColor, UIColor.clear.cgColor]
        }
        gradientLayer.locations = [0.0, 0.25]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }

    private func updateMarkerColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        for label in markerLabels {
            if label.textColor != .systemBlue && label.textColor != .systemYellow &&
               label.textColor != .systemOrange && label.textColor != .systemRed {
                label.textColor = isDarkMode ? .tertiaryDark : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
            }
        }
    }

    private func updateSliderAppearance() {
        let currentValue = verticalSlider.value
        let discreteValue = round(currentValue)
        let isAtSkillLevel = abs(currentValue - discreteValue) < 0.1

        if isAtSkillLevel {
            let skillIndex = Int(discreteValue)
            verticalSlider.trackColor = skillLevelColors[skillIndex]
            updateMarkersAppearance(selectedIndex: 3 - skillIndex)
            selectedSkillLevel = skillLevels[skillIndex]
        } else {
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            if isDarkMode { verticalSlider.trackColor = .secondaryDark }
            updateMarkerColors()
            selectedSkillLevel = nil
        }
    }

    private func updateMarkersAppearance(selectedIndex: Int) {
        for (index, label) in markerLabels.enumerated() {
            if index == selectedIndex {
                label.textColor = skillLevelColors[3 - index]
                label.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
            } else {
                let isDarkMode = traitCollection.userInterfaceStyle == .dark
                label.textColor = isDarkMode ? .tertiaryDark : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
                label.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
            }
        }
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        if let nav = navigationController {
            if nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                nav.dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
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

    @objc private func actionButtonTapped() {
        // Save current sport's selected skill
        let sport = sports[currentIndex]
        let skillLevel = selectedSkillLevel ?? sport.skill_level
        updatedSkillLevels[sport.id] = skillLevel

        // If more sports, move to next
        if currentIndex < sports.count - 1 {
            currentIndex += 1
            updateUIForCurrentSport()
            return
        }

        // All done — save to Supabase
        let loader = UIActivityIndicatorView(style: .medium)
        loader.center = view.center
        loader.startAnimating()
        view.addSubview(loader)
        actionButton.isEnabled = false

        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id

                for (sportId, skillLevel) in updatedSkillLevels {
                    try await SupabaseManager.shared.client
                        .from("user_preferred_sports")
                        .update(["skill_level": skillLevel])
                        .eq("user_id", value: userId.uuidString)
                        .eq("sport_id", value: "\(sportId)")
                        .execute()
                }

                await MainActor.run {
                    loader.removeFromSuperview()
                    actionButton.isEnabled = true
                    onSkillUpdated?()
                    navigationController?.dismiss(animated: true)
                }

            } catch {
                await MainActor.run {
                    loader.removeFromSuperview()
                    actionButton.isEnabled = true
                    print("🔴 Error: \(error)")
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}