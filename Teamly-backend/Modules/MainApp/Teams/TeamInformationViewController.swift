//
//  TeamInformationViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 28/01/26.
//

import UIKit
import Supabase


struct Profile: Codable {
    let id: UUID
    let name: String?
    let email: String?
    let gender: String?
    let age: Int?
    let college_id: Int?
    let profile_pic: String?
    let created_at: String?
    let updated_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, gender, age
        case college_id = "college_id"
        case profile_pic = "profile_pic"
        case created_at = "created_at"
        case updated_at = "updated_at"
    }
}

// Combined team member with profile info
struct TeamMemberWithProfile {
    let teamMember: TeamMember
    let profile: Profile
    let isCurrentUser: Bool
    let isCaptain: Bool
}

class TeamInformationViewController: UIViewController {
    
    // MARK: - Properties
    var team: BackendTeam?
    private var teamMembers: [TeamMemberWithProfile] = []
    var currentUserId: UUID?
    private var supabase: SupabaseClient {
        return SupabaseManager.shared.client
    }
    
    private var isCurrentUserCaptain: Bool {
        guard let team = team, let currentUserId = currentUserId else { return false }
        return team.captain_id == currentUserId
    }
    
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Team Info"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let teamIconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 60
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let teamIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "person.3")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let teamInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let teamInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dotSeparator: UILabel = {
        let label = UILabel()
        label.text = "•"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playerCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let actionsContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 35
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let actionsSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let captainSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Captain"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let captainContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 32
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let captainSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let playersSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Players"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playersContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 35
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let playersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let glassBackButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let editTeamInfoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Fetch data
        Task {
            await fetchCurrentUserId()
            await loadTeamData()
            updateColors()
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
        view.addSubview(glassBackButton)
        view.addSubview(editTeamInfoButton)
        view.addSubview(titleLabel)
        
        scrollView.addSubview(contentView)
        
        contentView.addSubview(teamIconContainerView)
        teamIconContainerView.addSubview(teamIconImageView)
        contentView.addSubview(teamNameLabel)
        contentView.addSubview(teamInfoStackView)
        contentView.addSubview(actionsContainerView)
        contentView.addSubview(actionsSeparator)
        contentView.addSubview(captainSectionLabel)
        contentView.addSubview(captainContainerView)
        contentView.addSubview(captainSeparator)
        contentView.addSubview(playersSectionLabel)
        contentView.addSubview(playersContainerView)
        playersContainerView.addSubview(playersStackView)
        
        teamInfoStackView.addArrangedSubview(teamInfoLabel)
        teamInfoStackView.addArrangedSubview(dotSeparator)
        teamInfoStackView.addArrangedSubview(playerCountLabel)
        
        setupConstraints()
        setupActionButtons()
        
        glassBackButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        editTeamInfoButton.addTarget(self, action: #selector(editTeamInfoTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            glassBackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            glassBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            glassBackButton.widthAnchor.constraint(equalToConstant: 40),
            glassBackButton.heightAnchor.constraint(equalToConstant: 40),
            
            editTeamInfoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            editTeamInfoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            editTeamInfoButton.heightAnchor.constraint(equalToConstant: 40),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            teamIconContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            teamIconContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            teamIconContainerView.widthAnchor.constraint(equalToConstant: 120),
            teamIconContainerView.heightAnchor.constraint(equalToConstant: 120),
            
            teamIconImageView.centerXAnchor.constraint(equalTo: teamIconContainerView.centerXAnchor),
            teamIconImageView.centerYAnchor.constraint(equalTo: teamIconContainerView.centerYAnchor),
            teamIconImageView.widthAnchor.constraint(equalToConstant: 75),
            teamIconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            teamNameLabel.topAnchor.constraint(equalTo: teamIconContainerView.bottomAnchor, constant: 15),
            teamNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            teamNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            teamInfoStackView.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 8),
            teamInfoStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            actionsContainerView.topAnchor.constraint(equalTo: teamInfoStackView.bottomAnchor, constant: 30),
            actionsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            actionsContainerView.heightAnchor.constraint(equalToConstant: 140),
            
            actionsSeparator.topAnchor.constraint(equalTo: actionsContainerView.bottomAnchor, constant: 24),
            actionsSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            actionsSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            actionsSeparator.heightAnchor.constraint(equalToConstant: 0.7),
            
            captainSectionLabel.topAnchor.constraint(equalTo: actionsSeparator.bottomAnchor, constant: 24),
            captainSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            captainSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            captainContainerView.topAnchor.constraint(equalTo: captainSectionLabel.bottomAnchor, constant: 12),
            captainContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            captainContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            captainContainerView.heightAnchor.constraint(equalToConstant: 64),
            
            captainSeparator.topAnchor.constraint(equalTo: captainContainerView.bottomAnchor, constant: 24),
            captainSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            captainSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            captainSeparator.heightAnchor.constraint(equalToConstant: 0.7),
            
            playersSectionLabel.topAnchor.constraint(equalTo: captainSeparator.bottomAnchor, constant: 24),
            playersSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            playersSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            playersContainerView.topAnchor.constraint(equalTo: playersSectionLabel.bottomAnchor, constant: 12),
            playersContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            playersContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            playersContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            
            playersStackView.topAnchor.constraint(equalTo: playersContainerView.topAnchor),
            playersStackView.leadingAnchor.constraint(equalTo: playersContainerView.leadingAnchor),
            playersStackView.trailingAnchor.constraint(equalTo: playersContainerView.trailingAnchor),
            playersStackView.bottomAnchor.constraint(equalTo: playersContainerView.bottomAnchor)
        ])
        
        editTeamInfoButton.setContentHuggingPriority(.required, for: .horizontal)
        editTeamInfoButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        editTeamInfoButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
    }
    
    // UPDATED METHOD: Sort members with current user at the top
        private func sortMembersWithCurrentUserAtTop(_ members: [TeamMemberWithProfile]) -> [TeamMemberWithProfile] {
            // Split into current user and others
            let currentUserMembers = members.filter { $0.isCurrentUser }
            let otherMembers = members.filter { !$0.isCurrentUser }
            
            // Sort other members alphabetically by name (optional)
            let sortedOtherMembers = otherMembers.sorted {
                ($0.profile.name ?? "") < ($1.profile.name ?? "")
            }
            
            // Combine: current user(s) first, then sorted others
            return currentUserMembers + sortedOtherMembers
        }
    
    // MARK: - Data Fetching
    private func fetchCurrentUserId() async {
        do {
            let session = try await supabase.auth.session
            currentUserId = session.user.id
        } catch {
            print("Error fetching current user: \(error)")
        }
    }
    
    private func loadTeamData() async {
        guard let team = team else { return }
        
        do {
            // Fetch team members
            let teamMembers: [TeamMember] = try await supabase
                .from("team_members")
                .select()
                .eq("team_id", value: team.id)
                .execute()
                .value
            
            if teamMembers.isEmpty {
                await MainActor.run {
                    self.playerCountLabel.text = "0 players"
                }
                return
            }
            
            // Get user IDs from team members
            let userIds = teamMembers.map { $0.user_id }
            
            // Fetch profiles for team members
            let profiles: [Profile] = try await supabase
                .from("profiles")
                .select()
                .in("id", values: userIds)
                .execute()
                .value
            
            // Combine team members with profiles
            var combinedMembers: [TeamMemberWithProfile] = []
            
            for teamMember in teamMembers {
                if let profile = profiles.first(where: { $0.id == teamMember.user_id }) {
                    let isCurrentUser = teamMember.user_id == currentUserId
                    let isCaptain = teamMember.role == "captain"
                    
                    combinedMembers.append(TeamMemberWithProfile(
                        teamMember: teamMember,
                        profile: profile,
                        isCurrentUser: isCurrentUser,
                        isCaptain: isCaptain
                    ))
                }
            }
            
            await MainActor.run {
                self.teamMembers = combinedMembers
                self.updateUIWithTeamData()
                self.setupActionButtons()
            }
            
        } catch {
            print("Error loading team data: \(error)")
            await MainActor.run {
                self.playerCountLabel.text = "Error loading players"
            }
        }
    }
    
    // MARK: - UI Updates
    private func updateUIWithTeamData() {
            guard let team = team else { return }
            
            teamNameLabel.text = team.name
            teamInfoLabel.text = "Team"
            playerCountLabel.text = "\(teamMembers.count) players"
            
            editTeamInfoButton.isHidden = !isCurrentUserCaptain
            
            // Update actions container height
            if let heightConstraint = actionsContainerView.constraints.first(where: { $0.firstAttribute == .height }) {
                actionsContainerView.removeConstraint(heightConstraint)
            }
            
            let newHeight: CGFloat = isCurrentUserCaptain ? 108 : 60
            actionsContainerView.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
            
            // Setup sections
            if isCurrentUserCaptain {
                // Captain view: Show "You" in Captain section
                setupCaptainSectionForCurrentUser()
                
                // Show other members in Players section (current user is already in captain section)
                let otherMembers = teamMembers.filter { !$0.isCurrentUser }
                // Sort other members alphabetically
                let sortedOtherMembers = otherMembers.sorted {
                    ($0.profile.name ?? "") < ($1.profile.name ?? "")
                }
                setupPlayersSection(members: sortedOtherMembers, showDeleteButton: true)
            } else {
                // Member view: Show captain in Captain section
                if let captain = teamMembers.first(where: { $0.isCaptain }) {
                    setupCaptainSection(member: captain)
                }
                
                // Show current user at the top, then other members in Players section
                setupPlayersSectionForRegularMember()
            }
            
            updateColors()
        }
    
    private func setupCaptainSectionForCurrentUser() {
            captainContainerView.subviews.forEach { $0.removeFromSuperview() }
            
            if let currentUserMember = teamMembers.first(where: { $0.isCurrentUser }) {
                let playerView = createPlayerView(member: currentUserMember, showLeaveButton: false, showDeleteButton: false)
                captainContainerView.addSubview(playerView)
                
                NSLayoutConstraint.activate([
                    playerView.topAnchor.constraint(equalTo: captainContainerView.topAnchor),
                    playerView.leadingAnchor.constraint(equalTo: captainContainerView.leadingAnchor),
                    playerView.trailingAnchor.constraint(equalTo: captainContainerView.trailingAnchor),
                    playerView.bottomAnchor.constraint(equalTo: captainContainerView.bottomAnchor)
                ])
            }
        }
    
    private func setupCaptainSection(member: TeamMemberWithProfile) {
            captainContainerView.subviews.forEach { $0.removeFromSuperview() }
            
            let playerView = createPlayerView(member: member, showLeaveButton: false, showDeleteButton: false)
            captainContainerView.addSubview(playerView)
            
            NSLayoutConstraint.activate([
                playerView.topAnchor.constraint(equalTo: captainContainerView.topAnchor),
                playerView.leadingAnchor.constraint(equalTo: captainContainerView.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: captainContainerView.trailingAnchor),
                playerView.bottomAnchor.constraint(equalTo: captainContainerView.bottomAnchor)
            ])
        }
        
        private func setupPlayersSection(members: [TeamMemberWithProfile], showDeleteButton: Bool) {
            playersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            for member in members {
                let playerView = createPlayerView(member: member, showLeaveButton: false, showDeleteButton: showDeleteButton)
                playersStackView.addArrangedSubview(playerView)
                
                NSLayoutConstraint.activate([
                    playerView.heightAnchor.constraint(equalToConstant: 70)
                ])
            }
        }
    
    
    private func setupPlayersSectionForRegularMember() {
            playersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            // Filter out captain
            let nonCaptainMembers = teamMembers.filter { !$0.isCaptain }
            
            // Split into current user and others
            let currentUserMember = nonCaptainMembers.first(where: { $0.isCurrentUser })
            let otherMembers = nonCaptainMembers.filter { !$0.isCurrentUser }
            
            // Sort other members alphabetically
            let sortedOtherMembers = otherMembers.sorted {
                ($0.profile.name ?? "") < ($1.profile.name ?? "")
            }
            
            // Add current user first if exists
            if let currentUser = currentUserMember {
                let playerView = createPlayerView(member: currentUser, showLeaveButton: true, showDeleteButton: false)
                playersStackView.addArrangedSubview(playerView)
                
                NSLayoutConstraint.activate([
                    playerView.heightAnchor.constraint(equalToConstant: 70)
                ])
            }
            
            // Add other members
            for member in sortedOtherMembers {
                let playerView = createPlayerView(member: member, showLeaveButton: false, showDeleteButton: false)
                playersStackView.addArrangedSubview(playerView)
                
                NSLayoutConstraint.activate([
                    playerView.heightAnchor.constraint(equalToConstant: 70)
                ])
            }
        }
    
    private func createPlayerView(member: TeamMemberWithProfile, showLeaveButton: Bool, showDeleteButton: Bool) -> UIView {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarView = UIView()
        avatarView.layer.cornerRadius = 22
        avatarView.backgroundColor = isDarkMode ? .tertiaryLight : .tertiaryDark
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarIcon = UIImageView()
        avatarIcon.image = UIImage(systemName: "person.fill")
        avatarIcon.tintColor = isDarkMode ? UIColor.quaternaryDark : .quaternaryLight
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        
        avatarView.addSubview(avatarIcon)
        
        let nameLabel = UILabel()
        nameLabel.text = member.isCurrentUser ? "You" : (member.profile.name ?? "Unknown")
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(avatarView)
        containerView.addSubview(nameLabel)
        
        // Add leave button for current user (non-captain)
        if showLeaveButton {
            let bgView = UIView()
            bgView.layer.cornerRadius = 18
            bgView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(bgView)
            
            let leaveButton = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            let leaveImage = UIImage(systemName: "rectangle.portrait.and.arrow.right", withConfiguration: config)
            leaveButton.setImage(leaveImage, for: .normal)
            leaveButton.tintColor = .systemRed
            leaveButton.translatesAutoresizingMaskIntoConstraints = false
            leaveButton.addTarget(self, action: #selector(leaveTeamTapped(_:)), for: .touchUpInside)
            bgView.addSubview(leaveButton)
            
            NSLayoutConstraint.activate([
                bgView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                bgView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                bgView.widthAnchor.constraint(equalToConstant: 35),
                bgView.heightAnchor.constraint(equalToConstant: 35),

                leaveButton.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
                leaveButton.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
                leaveButton.widthAnchor.constraint(equalToConstant: 16),
                leaveButton.heightAnchor.constraint(equalToConstant: 18)
            ])
        }
        
        // Add delete button for captain view
        if showDeleteButton {
            let bgView = UIView()
            bgView.layer.cornerRadius = 18
            bgView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(bgView)
            
            let deleteButton = UIButton(type: .system)
            deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
            deleteButton.tintColor = .systemRed
            deleteButton.translatesAutoresizingMaskIntoConstraints = false
            deleteButton.tag = teamMembers.firstIndex(where: { $0.teamMember.id == member.teamMember.id }) ?? 0
            deleteButton.addTarget(self, action: #selector(deletePlayerTapped(_:)), for: .touchUpInside)
            bgView.addSubview(deleteButton)
            
            NSLayoutConstraint.activate([
                bgView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                bgView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                bgView.widthAnchor.constraint(equalToConstant: 35),
                bgView.heightAnchor.constraint(equalToConstant: 35),
                
                deleteButton.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
                deleteButton.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
                deleteButton.widthAnchor.constraint(equalToConstant: 16),
                deleteButton.heightAnchor.constraint(equalToConstant: 18)
            ])
        }
        
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 45),
            avatarView.heightAnchor.constraint(equalToConstant: 45),
            
            avatarIcon.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 30),
            avatarIcon.heightAnchor.constraint(equalToConstant: 25),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 20),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }
    
    private func setupActionButtons() {
        // Clear existing buttons
        actionsContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        if isCurrentUserCaptain {
            let actions = [
                ("person.badge.plus", "Add players", #selector(addPlayersTapped)),
                ("sportscourt", "Matches", #selector(matchesTapped))
            ]
            
            var previousButton: UIView?
            
            for (index, (icon, title, selector)) in actions.enumerated() {
                let button = createActionButton(icon: icon, title: title, action: selector)
                actionsContainerView.addSubview(button)
                
                NSLayoutConstraint.activate([
                    button.leadingAnchor.constraint(equalTo: actionsContainerView.leadingAnchor, constant: 16),
                    button.trailingAnchor.constraint(equalTo: actionsContainerView.trailingAnchor, constant: -16),
                    button.heightAnchor.constraint(equalToConstant: 40)
                ])
                
                if let previous = previousButton {
                    button.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 6).isActive = true
                } else {
                    button.topAnchor.constraint(equalTo: actionsContainerView.topAnchor, constant: 8).isActive = true
                }
                
                previousButton = button
                
                if index < actions.count - 1 {
                    let separator = UIView()
                    separator.translatesAutoresizingMaskIntoConstraints = false
                    actionsContainerView.addSubview(separator)
                    
                    NSLayoutConstraint.activate([
                        separator.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 8),
                        separator.leadingAnchor.constraint(equalTo: actionsContainerView.leadingAnchor, constant: 16),
                        separator.trailingAnchor.constraint(equalTo: actionsContainerView.trailingAnchor, constant: -16),
                        separator.heightAnchor.constraint(equalToConstant: 1)
                    ])
                    
                    previousButton = separator
                }
            }
        } else {
            let button = createActionButton(icon: "sportscourt", title: "Matches", action: #selector(matchesTapped))
            actionsContainerView.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.centerYAnchor.constraint(equalTo: actionsContainerView.centerYAnchor),
                button.leadingAnchor.constraint(equalTo: actionsContainerView.leadingAnchor, constant: 16),
                button.trailingAnchor.constraint(equalTo: actionsContainerView.trailingAnchor, constant: -16),
                button.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
    }
    
    private func createActionButton(icon: String, title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let chevronImageView = UIImageView()
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        
        button.addSubview(iconImageView)
        button.addSubview(titleLabel)
        button.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 8),
            iconImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -8),
            chevronImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 20),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return button
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        glassBackButton.backgroundColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.1) :
            UIColor(white: 0, alpha: 0.05)
        glassBackButton.layer.borderColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.2).cgColor :
            UIColor(white: 0, alpha: 0.1).cgColor
        glassBackButton.tintColor = isDarkMode ? .systemGreenDark : .systemGreen
        
        editTeamInfoButton.backgroundColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.1) :
            UIColor(white: 0, alpha: 0.05)
        editTeamInfoButton.layer.borderColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.2).cgColor :
            UIColor(white: 0, alpha: 0.1).cgColor
        editTeamInfoButton.setTitleColor(isDarkMode ? .systemGreenDark : .systemGreen, for: .normal)
        
        teamIconContainerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        teamIconImageView.tintColor = isDarkMode ? .white : .black
        
        teamNameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        teamInfoLabel.textColor = isDarkMode ? .white : .black
        dotSeparator.textColor = isDarkMode ? .systemGreenDark : .systemGreen
        playerCountLabel.textColor = isDarkMode ? .systemGreenDark : .systemGreen
        
        actionsContainerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        captainContainerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        playersContainerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        actionsSeparator.backgroundColor = isDarkMode ?
            UIColor.white.withAlphaComponent(0.3) :
            UIColor.black.withAlphaComponent(0.2)
        captainSeparator.backgroundColor = isDarkMode ?
            UIColor.white.withAlphaComponent(0.3) :
            UIColor.black.withAlphaComponent(0.2)
        
        captainSectionLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        playersSectionLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        updateActionButtonColors(isDarkMode: isDarkMode)
        updatePlayerViewColors(isDarkMode: isDarkMode)
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
    
    private func updateActionButtonColors(isDarkMode: Bool) {
        for subview in actionsContainerView.subviews {
            if let button = subview as? UIButton {
                for buttonSubview in button.subviews {
                    if let iconImageView = buttonSubview as? UIImageView {
                        iconImageView.tintColor = isDarkMode ? .white : .black
                    }
                    if let titleLabel = buttonSubview as? UILabel {
                        titleLabel.textColor = isDarkMode ? .white : .black
                    }
                }
            } else if subview.constraints.contains(where: { $0.firstAttribute == .height && $0.constant == 1 }) {
                subview.backgroundColor = isDarkMode ?
                    UIColor.white.withAlphaComponent(0.3) :
                    UIColor.black.withAlphaComponent(0.2)
            }
        }
    }
    
    private func updatePlayerViewColors(isDarkMode: Bool) {
        updateSinglePlayerViewColors(in: captainContainerView, isDarkMode: isDarkMode)
        
        for case let playerView as UIView in playersStackView.arrangedSubviews {
            updateSinglePlayerViewColors(in: playerView, isDarkMode: isDarkMode)
        }
    }
    
    private func updateSinglePlayerViewColors(in containerView: UIView, isDarkMode: Bool) {
        for subview in containerView.subviews {
            if let avatarView = subview as? UIView, avatarView.layer.cornerRadius == 22 {
                avatarView.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
                
                for avatarSubview in avatarView.subviews {
                    if let icon = avatarSubview as? UIImageView {
                        icon.tintColor = isDarkMode ? UIColor.quaternaryLight : .quaternaryDark
                    }
                }
            }
            
            if let nameLabel = subview as? UILabel, nameLabel.font.pointSize == 18 {
                nameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
            }
            
            if let bgView = subview as? UIView, bgView.layer.cornerRadius == 18 {
                bgView.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
                
                for bgSubview in bgView.subviews {
                    if let button = bgSubview as? UIButton {
                        button.tintColor = .systemRed
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func editTeamInfoTapped() {
        guard let team = team else { return }
        
        EditTeamInformationViewController.present(
            from: self,
            team: team,
            onSave: { [weak self] updatedTeam in
                // Update local team with new name
                self?.team = updatedTeam
                // Update UI
                self?.updateUIWithTeamData()
            }
        )
    }
    
    @objc private func addPlayersTapped() {
        let addPlayersVC = AddPlayersViewController()
        addPlayersVC.team = team 
        addPlayersVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        navigationController?.pushViewController(addPlayersVC, animated: true)
    }
    
    @objc private func matchesTapped() {
        let teamMatchesVC = TeamMatchesViewController()
        teamMatchesVC.team = team
        teamMatchesVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        navigationController?.pushViewController(teamMatchesVC, animated: true)
    }
    
    @objc private func deletePlayerTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < teamMembers.count else { return }
        
        let member = teamMembers[index]
        let userName = member.profile.name ?? "Unknown"
        
        let alertController = createAlert(
            title: "Remove Player",
            message: "Do you want to remove \(userName) from the team?",
            isDestructive: true
        )
        
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            self?.removePlayer(member: member)
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func leaveTeamTapped(_ sender: UIButton) {
        let alertController = createAlert(
            title: "Leave Team",
            message: "Do you want to leave this team?",
            isDestructive: true
        )
        
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            self?.leaveTeam()
        }
        
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func createAlert(title: String, message: String, isDestructive: Bool) -> UIAlertController {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if isDestructive {
            alert.view.tintColor = .systemRed
        } else {
            alert.view.tintColor = isDarkMode ? .systemGreenDark : .systemGreen
        }
        
        return alert
    }
    
    private func removePlayer(member: TeamMemberWithProfile) {
        Task {
            do {
                // Delete from team_members table
                try await supabase
                    .from("team_members")
                    .delete()
                    .eq("id", value: member.teamMember.id)
                    .execute()
                
                print("Removed player: \(member.profile.name ?? "Unknown") from team")
                
                // Refresh data
                await loadTeamData()
                
            } catch {
                print("Error removing player: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to remove player. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
    
    private func leaveTeam() {
        Task {
            do {
                guard let team = team, let currentUserId = currentUserId else { return }
                
                // Find current user's team member record
                let currentUserMembers: [TeamMember] = try await supabase
                    .from("team_members")
                    .select()
                    .eq("team_id", value: team.id)
                    .eq("user_id", value: currentUserId)
                    .execute()
                    .value
                
                guard let currentUserMember = currentUserMembers.first else { return }
                
                // Delete from team_members table
                try await supabase
                    .from("team_members")
                    .delete()
                    .eq("id", value: currentUserMember.id)
                    .execute()
                
                print("User left the team")
                
                // Navigate back
                await MainActor.run {
                    navigationController?.popViewController(animated: true)
                }
                
            } catch {
                print("Error leaving team: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to leave team. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct TeamInformationViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TeamInformationViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            TeamInformationViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct TeamInformationViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = TeamInformationViewController()
        
        // Create sample team for preview
        viewController.team = BackendTeam(
            id: UUID(),
            name: "All Stars FC",
            sport_id: 1,
            captain_id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
            college_id: 1,
            created_at: "2024-01-28T12:00:00Z"
        )
        
        // Set current user for preview
        viewController.currentUserId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")
        
        let navController = UINavigationController(rootViewController: viewController)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No update needed
    }
}
#endif
