//
//  UserProfileViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 03/02/26.
//

import UIKit
import Supabase

// MARK: - User Profile View Controller
class UserProfileViewController: UIViewController {
    
    // MARK: - Properties
    var userId: UUID?
    private let supabase = SupabaseManager.shared.client
    
    private var userProfile: Profile?
    private var userTeams: [BackendTeam] = []
    private var userSports: [SportWithSkill] = []
    
    // MARK: - UI Components
    private let topGreenTint: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        return gradient
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Profile"
        label.font = .systemFont(ofSize: 35, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    
    private lazy var avatarView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 45)
        imageView.image = UIImage(systemName: "person.fill", withConfiguration: config)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 45),
            imageView.heightAnchor.constraint(equalToConstant: 45)
        ])
        
        view.layer.cornerRadius = 43
        view.clipsToBounds = true
        view.layer.borderWidth = 1.0
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Loading..."
        label.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        return label
    }()
    
    private let ageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Age : Loading..."
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let genderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Loading..."
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    // NEW: Send Request Button
    private let sendRequestButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Send Request", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        return button
    }()
    
    private let teamsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Teams"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private let teamsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()
    
    private let sportsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Preferred sports"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private let sportsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateColors()
        setupBackButton()
        setupSendRequestButton() // NEW: Setup button action
        
        // Start loading data
        Task {
            await fetchUserProfileData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
        
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        view.addSubview(loadingIndicator)
        
        contentView.addSubview(backButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(ageLabel)
        contentView.addSubview(genderLabel)
        contentView.addSubview(sendRequestButton) // NEW: Add button to view hierarchy
        contentView.addSubview(teamsLabel)
        contentView.addSubview(teamsStackView)
        contentView.addSubview(sportsLabel)
        contentView.addSubview(sportsStackView)
        
        setupConstraints()
    }
    
    private func setupBackButton() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    // NEW: Setup send request button action
    private func setupSendRequestButton() {
        sendRequestButton.addTarget(self, action: #selector(sendRequestButtonTapped), for: .touchUpInside)
    }
    
    @objc private func backButtonTapped() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    // NEW: Send request button action handler
    @objc private func sendRequestButtonTapped() {
        print("Send Request button tapped")
        // TODO: Implement request sending logic
        showRequestSentAlert()
    }
    
    private func showRequestSentAlert() {
        let alert = UIAlertController(
            title: "Request Sent",
            message: "Your connection request has been sent successfully.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        present(alert, animated: true)
    }
    
    // MARK: - Data Fetching
    private func fetchUserProfileData() async {
        guard let userId = userId else {
                await MainActor.run {
                    showError(message: "User ID not found")
                }
                return
            }
        
        await MainActor.run {
            loadingIndicator.startAnimating()
        }
        
        do {
            // 1. Fetch user profile
            userProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            // 2. Fetch user's teams
            let teamMembers: [TeamMember] = try await supabase
                .from("team_members")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            var teams: [BackendTeam] = []
            for teamMember in teamMembers {
                let team: BackendTeam = try await supabase
                    .from("teams")
                    .select()
                    .eq("id", value: teamMember.team_id)
                    .single()
                    .execute()
                    .value
                teams.append(team)
            }
            userTeams = teams
            
            // 3. Fetch user's preferred sports with skill levels
            let preferredSports: [UserPreferredSport] = try await supabase
                .from("user_preferred_sports")
                .select("sport_id, skill_level")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            var sportsWithSkills: [SportWithSkill] = []
            for prefSport in preferredSports {
                let sportData: SportData = try await supabase
                    .from("sports")
                    .select()
                    .eq("id", value: prefSport.sport_id)
                    .single()
                    .execute()
                    .value
                
                let sportWithSkill = SportWithSkill(
                    id: sportData.id,
                    name: sportData.name,
                    emoji: sportData.emoji,
                    skill_level: prefSport.skill_level
                )
                sportsWithSkills.append(sportWithSkill)
            }
            userSports = sportsWithSkills
            
            // 4. Update UI with fetched data
            await MainActor.run {
                updateUIWithFetchedData()
                loadingIndicator.stopAnimating()
            }
            
        } catch {
            print("Error fetching user profile data: \(error)")
            await MainActor.run {
                loadingIndicator.stopAnimating()
                showError(message: "Failed to load profile data. Please try again.")
            }
        }
    }
    
    private func updateUIWithFetchedData() {
        // Update profile information
        if let profile = userProfile {
            nameLabel.text = profile.name ?? "No name"
            
            if let age = profile.age {
                ageLabel.text = "Age : \(age)"
            } else {
                ageLabel.text = "Age : Not specified"
            }
            
            if let gender = profile.gender {
                genderLabel.text = gender
                genderLabel.textColor = gender == "Male" ? .systemBlue : .systemPink
            } else {
                genderLabel.text = "Not specified"
                genderLabel.textColor = .systemGray
            }
        }
        
        // Clear existing team cards
        teamsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add team cards
        if userTeams.isEmpty {
            let noTeamsLabel = UILabel()
            noTeamsLabel.text = "Not a member of any teams"
            noTeamsLabel.font = .systemFont(ofSize: 16)
            noTeamsLabel.textColor = .systemGray
            noTeamsLabel.textAlignment = .center
            teamsStackView.addArrangedSubview(noTeamsLabel)
        } else {
            for team in userTeams {
                let teamCard = createTeamCard(teamName: team.name)
                teamsStackView.addArrangedSubview(teamCard)
            }
        }
        
        // Clear existing sport rows
        sportsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add sport rows
        if userSports.isEmpty {
            let noSportsLabel = UILabel()
            noSportsLabel.text = "No preferred sports selected"
            noSportsLabel.font = .systemFont(ofSize: 16)
            noSportsLabel.textColor = .systemGray
            noSportsLabel.textAlignment = .center
            sportsStackView.addArrangedSubview(noSportsLabel)
        } else {
            for sport in userSports {
                let levelColor = getSkillLevelColor(sport.skill_level)
                let sportRow = createSportRow(
                    emoji: sport.emoji ?? "🏃‍♂️",
                    sportName: sport.name,
                    level: sport.skill_level,
                    levelColor: levelColor
                )
                sportsStackView.addArrangedSubview(sportRow)
            }
        }
        
        // Update colors
        updateColors()
    }
    
    private func getSkillLevelColor(_ level: String) -> UIColor {
        switch level {
        case "Beginner":
            return UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0) // Blue
        case "Intermediate":
            return UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1.0) // Green
        case "Experienced":
            return UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: 1.0) // Yellow
        case "Advanced":
            return UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0) // Red
        default:
            return UIColor.systemGray
        }
    }
    
    private func createTeamCard(teamName: String) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 33
        view.layer.borderWidth = 0.6
        view.clipsToBounds = true
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        view.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        
        let iconView = UIView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 20
        iconView.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        view.addSubview(iconView)
        
        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = UIImage(systemName: "person.3")
        icon.tintColor = isDarkMode ? .quaternaryLight : .quaternaryDark
        iconView.addSubview(icon)
        
        let teamLabel = UILabel()
        teamLabel.translatesAutoresizingMaskIntoConstraints = false
        teamLabel.text = teamName
        teamLabel.font = .systemFont(ofSize: 19, weight: .regular)
        teamLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        view.addSubview(teamLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            icon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 23),
            icon.heightAnchor.constraint(equalToConstant: 15),
            
            teamLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            teamLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            teamLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -12),
            
            view.heightAnchor.constraint(equalToConstant: 65)
        ])
        
        return view
    }
    
    private func createSportRow(emoji: String, sportName: String, level: String, levelColor: UIColor) -> UIView {
        let rowView = UIView()
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        let emojiContainer = UIView()
        emojiContainer.translatesAutoresizingMaskIntoConstraints = false
        emojiContainer.layer.cornerRadius = 25
        emojiContainer.layer.borderWidth = 0.6
        emojiContainer.clipsToBounds = true
        rowView.addSubview(emojiContainer)
        
        let emojiLabel = UILabel()
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 28)
        emojiLabel.textAlignment = .center
        emojiContainer.addSubview(emojiLabel)
        
//        let sportNameLabel = UILabel()
//        sportNameLabel.translatesAutoresizingMaskIntoConstraints = false
//        sportNameLabel.text = sportName
//        sportNameLabel.font = .systemFont(ofSize: 16, weight: .medium)
//        sportNameLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack
//        rowView.addSubview(sportNameLabel)
        
        let levelBadge = UIView()
        levelBadge.translatesAutoresizingMaskIntoConstraints = false
        levelBadge.backgroundColor = levelColor
        levelBadge.layer.cornerRadius = 15
        levelBadge.clipsToBounds = true
        rowView.addSubview(levelBadge)
        
        let levelLabel = UILabel()
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        levelLabel.text = level
        levelLabel.font = .systemFont(ofSize: 15, weight: .medium)
        levelLabel.textColor = .white
        levelLabel.textAlignment = .center
        levelBadge.addSubview(levelLabel)
        
        NSLayoutConstraint.activate([
            // Emoji container
            emojiContainer.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
            emojiContainer.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            emojiContainer.widthAnchor.constraint(equalToConstant: 65),
            emojiContainer.heightAnchor.constraint(equalToConstant: 65),
            
            // Emoji label
            emojiLabel.centerXAnchor.constraint(equalTo: emojiContainer.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContainer.centerYAnchor),
            
            // Level badge
            levelBadge.leadingAnchor.constraint(equalTo: emojiContainer.trailingAnchor, constant: 24),
            levelBadge.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            levelBadge.heightAnchor.constraint(equalToConstant: 30),

            
            // Level label
            levelLabel.topAnchor.constraint(equalTo: levelBadge.topAnchor, constant: 8),
            levelLabel.bottomAnchor.constraint(equalTo: levelBadge.bottomAnchor, constant: -8),
            levelLabel.leadingAnchor.constraint(equalTo: levelBadge.leadingAnchor, constant: 20),
            levelLabel.trailingAnchor.constraint(equalTo: levelBadge.trailingAnchor, constant: -20),
            
            // Row height
            rowView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        return rowView
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update back button
        updateGlassButton(backButton, isDarkMode: isDarkMode)
        
        // Update avatar view
        avatarView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        avatarView.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark.withAlphaComponent(0.5) : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        if let imageView = avatarView.subviews.first as? UIImageView {
            imageView.tintColor = isDarkMode ? .quaternaryLight : .quaternaryDark
        }
        
        // Update labels
        nameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        ageLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        teamsLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        sportsLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        loadingIndicator.color = isDarkMode ? .white : .gray
        
        updateTeamCardsColors()
        updateSportRowsColors()
    }
    
    private func updateGlassButton(_ button: UIButton, isDarkMode: Bool) {
        button.backgroundColor = isDarkMode ? UIColor(white: 1, alpha: 0.1) : UIColor(white: 0, alpha: 0.05)
        button.layer.borderColor = (isDarkMode ? UIColor(white: 1, alpha: 0.2) : UIColor(white: 0, alpha: 0.1)).cgColor
        button.tintColor = isDarkMode ? .systemGreenDark : .systemGreen
    }
    
    private func updateTeamCardsColors() {
        for view in teamsStackView.arrangedSubviews {
            if view is UILabel { continue }
            
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
            view.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
            
            for subview in view.subviews {
                if subview.layer.cornerRadius == 20 {
                    subview.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
                    
                    for innerSubview in subview.subviews {
                        if let icon = innerSubview as? UIImageView {
                            icon.tintColor = isDarkMode ? .quaternaryLight : .quaternaryDark
                        }
                    }
                }
                
                if let label = subview as? UILabel, subview.layer.cornerRadius != 20 {
                    label.textColor = isDarkMode ? .primaryWhite : .primaryBlack
                }
            }
        }
    }
    
    private func updateSportRowsColors() {
        for view in sportsStackView.arrangedSubviews {
            if let sportRow = view as? UIView {
                let isDarkMode = traitCollection.userInterfaceStyle == .dark
                
                if let emojiContainer = sportRow.subviews.first(where: { $0.layer.cornerRadius == 25 }) {
                    emojiContainer.backgroundColor = isDarkMode ? .black : .white
                    emojiContainer.layer.borderColor = isDarkMode ? UIColor.black.cgColor : UIColor.white.cgColor
                }
                
                if let sportNameLabel = sportRow.subviews.compactMap({ $0 as? UILabel })
                    .first(where: { !($0.superview is UIView && $0.superview?.layer.cornerRadius == 18) }) {
                    sportNameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
                }
            }
        }
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
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            backButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            avatarView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.widthAnchor.constraint(equalToConstant: 85),
            avatarView.heightAnchor.constraint(equalToConstant: 85),
            
            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            ageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            ageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            ageLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            genderLabel.topAnchor.constraint(equalTo: ageLabel.bottomAnchor, constant: 4),
            genderLabel.leadingAnchor.constraint(equalTo: ageLabel.leadingAnchor),
            genderLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // NEW: Send Request Button constraints
            sendRequestButton.topAnchor.constraint(equalTo: genderLabel.bottomAnchor, constant: 16),
            sendRequestButton.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            sendRequestButton.widthAnchor.constraint(equalToConstant: 150),
            sendRequestButton.heightAnchor.constraint(equalToConstant: 25),
            
            teamsLabel.topAnchor.constraint(equalTo: sendRequestButton.bottomAnchor, constant: 32), // Updated from avatarView to sendRequestButton
            teamsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            teamsLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            teamsStackView.topAnchor.constraint(equalTo: teamsLabel.bottomAnchor, constant: 16),
            teamsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            teamsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            sportsLabel.topAnchor.constraint(equalTo: teamsStackView.bottomAnchor, constant: 28),
            sportsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sportsLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            sportsStackView.topAnchor.constraint(equalTo: sportsLabel.bottomAnchor, constant: 16),
            sportsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sportsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sportsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func showError(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
