//
//  ProfileViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 01/02/26.
//

import UIKit
import Supabase

// MARK: - Profile View Controller
class ProfileViewController: UIViewController {
    
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "My Profile"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    
    private lazy var avatarButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Create and set the SF Symbol image
        let config = UIImage.SymbolConfiguration(pointSize: 45)
        if let image = UIImage(systemName: "person.fill", withConfiguration: config) {
            button.setImage(image, for: .normal)
        }
        
        button.layer.cornerRadius = 43
        button.clipsToBounds = true
        button.isUserInteractionEnabled = false
        button.layer.borderWidth = 1.0
        return button
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
    
    private let teamsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Teams"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    // Dynamic team cards will be created based on fetched data
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
    
    // Dynamic sport rows will be created based on fetched data
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
    
    // MARK: - Properties
    private var currentUserId: UUID?
    private var supabase: SupabaseClient {
        return SupabaseManager.shared.client
    }
    private var userProfile: Profile?
    private var userTeams: [BackendTeam] = []
    private var userSports: [SportWithSkill] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateColors()
        
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
        // Set initial background color
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
        
        // Add green tint gradient background
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add loading indicator
        view.addSubview(loadingIndicator)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(avatarButton)
        contentView.addSubview(nameLabel)
        contentView.addSubview(ageLabel)
        contentView.addSubview(genderLabel)
        contentView.addSubview(teamsLabel)
        contentView.addSubview(teamsStackView)
        contentView.addSubview(sportsLabel)
        contentView.addSubview(sportsStackView)
        
        setupConstraints()
    }
    
    // MARK: - Data Fetching
    private func fetchUserProfileData() async {
        await MainActor.run {
            loadingIndicator.startAnimating()
        }
        
        do {
            // 1. Get current user ID
            let session = try await supabase.auth.session
            currentUserId = session.user.id
            print("Current user ID: \(currentUserId?.uuidString ?? "nil")")
            
            guard let userId = currentUserId else {
                print("No user ID found")
                await showError(message: "User not authenticated")
                return
            }
            
            // 2. Fetch user profile using your existing Profile struct
            userProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            // 3. Fetch user's teams using your existing TeamMember struct
            let teamMembers: [TeamMember] = try await supabase
                .from("team_members")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            // Fetch team details for each team the user is a member of
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
            
            // 4. Fetch user's preferred sports with skill levels
            let preferredSports: [UserPreferredSport] = try await supabase
                .from("user_preferred_sports")
                .select("sport_id, skill_level")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            // Fetch sport details for each preferred sport
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
            
            // 5. Update UI with fetched data
            await MainActor.run {
                updateUIWithFetchedData()
                loadingIndicator.stopAnimating()
            }
            
        } catch {
            print("Error fetching profile data: \(error)")
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
        
        // Apply initial colors based on current trait collection
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        view.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        
        // Team icon view
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
            // Icon view
            iconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Icon
            icon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 23),
            icon.heightAnchor.constraint(equalToConstant: 15),
            
            // Team label
            teamLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            teamLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            teamLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -12),
            
            // Card height
            view.heightAnchor.constraint(equalToConstant: 65)
        ])
        
        return view
    }
    
    private func createSportRow(emoji: String, sportName: String, level: String, levelColor: UIColor) -> UIView {
        let rowView = UIView()
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        // Emoji container
        let emojiContainer = UIView()
        emojiContainer.translatesAutoresizingMaskIntoConstraints = false
        emojiContainer.layer.cornerRadius = 25
        emojiContainer.layer.borderWidth = 0.6
        emojiContainer.clipsToBounds = true
        rowView.addSubview(emojiContainer)
        
        // Emoji label
        let emojiLabel = UILabel()
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 28)
        emojiLabel.textAlignment = .center
        emojiContainer.addSubview(emojiLabel)
        
        // Sport name label
        let sportNameLabel = UILabel()
        sportNameLabel.translatesAutoresizingMaskIntoConstraints = false
        sportNameLabel.text = sportName
        sportNameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        sportNameLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack
        //rowView.addSubview(sportNameLabel)
        
        // Level badge
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
        
        // Update view background
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Update title label color
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update avatar button colors
        avatarButton.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        avatarButton.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark.withAlphaComponent(0.5) : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        if let image = avatarButton.image(for: .normal) {
            let tintColor = isDarkMode ? UIColor.quaternaryLight : .quaternaryDark
            avatarButton.setImage(image.withTintColor(tintColor, renderingMode: .alwaysOriginal), for: .normal)
        }
        
        // Update name, age, gender labels
        nameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        ageLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update section labels
        teamsLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        sportsLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update loading indicator color
        loadingIndicator.color = isDarkMode ? .white : .gray
        
        // Update team cards and sport rows
        updateTeamCardsColors()
        updateSportRowsColors()
    }
    
    private func updateTeamCardsColors() {
        for view in teamsStackView.arrangedSubviews {
            // Skip if it's a UILabel (no teams message)
            if view is UILabel { continue }
            
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            
            // Update main card
            view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
            view.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
            
            // Find all subviews and update them
            for subview in view.subviews {
                // Icon view (has corner radius 20)
                if subview.layer.cornerRadius == 20 {
                    subview.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
                    
                    // Find icon inside
                    for innerSubview in subview.subviews {
                        if let icon = innerSubview as? UIImageView {
                            icon.tintColor = isDarkMode ? .quaternaryLight : .quaternaryDark
                        }
                    }
                }
                
                // Team label (UILabel that's not inside icon view)
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
                
                // Update emoji container
                if let emojiContainer = sportRow.subviews.first(where: { $0.layer.cornerRadius == 25 }) {
                    emojiContainer.backgroundColor = isDarkMode ? .black : .white
                    emojiContainer.layer.borderColor = isDarkMode ? UIColor.black as! CGColor : UIColor.white as! CGColor
                }
                
                // Update sport name label
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
            // Top Green Tint
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Scroll View - starts from top of safe area
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // Avatar
            avatarButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            avatarButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarButton.widthAnchor.constraint(equalToConstant: 85),
            avatarButton.heightAnchor.constraint(equalToConstant: 85),
            
            // Name
            nameLabel.topAnchor.constraint(equalTo: avatarButton.topAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Age
            ageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            ageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            ageLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Gender
            genderLabel.topAnchor.constraint(equalTo: ageLabel.bottomAnchor, constant: 4),
            genderLabel.leadingAnchor.constraint(equalTo: ageLabel.leadingAnchor),
            genderLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Teams Section
            teamsLabel.topAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 32),
            teamsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            teamsLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Teams Stack View
            teamsStackView.topAnchor.constraint(equalTo: teamsLabel.bottomAnchor, constant: 16),
            teamsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            teamsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Sports Section
            sportsLabel.topAnchor.constraint(equalTo: teamsStackView.bottomAnchor, constant: 28),
            sportsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sportsLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Sports Stack View
            sportsStackView.topAnchor.constraint(equalTo: sportsLabel.bottomAnchor, constant: 16),
            sportsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sportsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sportsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Additional Data Structures
// Renamed Sport struct to SportData to avoid naming conflict with existing Sport model

struct UserPreferredSport: Codable {
    let sport_id: Int
    let skill_level: String
}

struct SportData: Codable {
    let id: Int
    let name: String
    let emoji: String?
}

struct SportWithSkill {
    let id: Int
    let name: String
    let emoji: String?
    let skill_level: String
}

// MARK: - SwiftUI Preview
import SwiftUI

struct ProfileViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreviewWrapper {
                ProfileViewController()
            }
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
            
            UIViewControllerPreviewWrapper {
                ProfileViewController()
            }
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        }
    }
}

struct UIViewControllerPreviewWrapper<T: UIViewController>: UIViewControllerRepresentable {
    let viewController: () -> T
    
    func makeUIViewController(context: Context) -> T {
        viewController()
    }
    
    func updateUIViewController(_ uiViewController: T, context: Context) {
        // Update the view controller if needed
    }
}
