//
//  CreateTeamViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 28/01/26.
//

import UIKit
import Supabase

// MARK: - Friend Model
struct FriendUser: Codable, Identifiable {
    let id: UUID
    let email: String?
    let name: String?  // From profiles table
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
    }
    
    var displayName: String {
        return name ?? email ?? "Unknown User"
    }
}

// MARK: - CreateTeamViewController (Bottom Sheet Modal)
class CreateTeamViewController: UIViewController {
    
    // MARK: - Properties
    private var friends: [FriendUser] = []
    private var selectedFriends: Set<UUID> = [] // Track selected friend IDs
    private var pendingInvitations: Set<UUID> = [] // Track friends who were sent invitations
    
    // Updated: Use Supabase sports instead of hardcoded enum
    private var sports: [Sport] = []
    private var selectedSport: Sport?
    
    private var isPlayersExpanded = false
    private var isSportsExpanded = false
    private var containerHeightConstraint: NSLayoutConstraint!
    
    // NEW: Completion handler for when team is created
    var onTeamCreated: ((String) -> Void)?
    
    private var supabase: SupabaseClient {
        return SupabaseManager.shared.client
    }
    
    // MARK: - UI Components
    private let dimmedView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 35
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let grabberView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Unified Sport Section
    private let sportSectionContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let selectSportButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select Sport", for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 50)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let sportChevronImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        imageView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let sportsScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let sportsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let teamNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Team name"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.layer.cornerRadius = 25
        textField.clipsToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        return textField
    }()
    
    // Unified Players Section
    private let playersSectionContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let selectPlayersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select friends", for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 50)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let playersChevronImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        imageView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let playersScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let playersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var containerBottomConstraint: NSLayoutConstraint!
    private var sportSectionHeightConstraint: NSLayoutConstraint!
    private var playersSectionHeightConstraint: NSLayoutConstraint!
    private var panGesture: UIPanGestureRecognizer!
    private let baseContainerHeight: CGFloat = 450
    private let maxPlayersSectionHeight: CGFloat = 300
    private let maxSportsSectionHeight: CGFloat = 200
    private let buttonHeight: CGFloat = 50

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadSportsFromSupabase()
        loadFriendsFromSupabase()
        setupActions()
        setupPanGesture()
        updateColors()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        
        containerView.addSubview(grabberView)
        
        // Sport Section Setup
        containerView.addSubview(sportSectionContainer)
        sportSectionContainer.addSubview(selectSportButton)
        selectSportButton.addSubview(sportChevronImageView)
        sportSectionContainer.addSubview(sportsScrollView)
        sportsScrollView.addSubview(sportsStackView)
        
        containerView.addSubview(teamNameTextField)
        
        // Players Section Setup
        containerView.addSubview(playersSectionContainer)
        playersSectionContainer.addSubview(selectPlayersButton)
        selectPlayersButton.addSubview(playersChevronImageView)
        playersSectionContainer.addSubview(playersScrollView)
        playersScrollView.addSubview(playersStackView)
        
        containerView.addSubview(createButton)
        
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: baseContainerHeight)
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: baseContainerHeight)
        sportSectionHeightConstraint = sportSectionContainer.heightAnchor.constraint(equalToConstant: buttonHeight)
        playersSectionHeightConstraint = playersSectionContainer.heightAnchor.constraint(equalToConstant: buttonHeight)
        
        NSLayoutConstraint.activate([
            // Dimmed View
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container View
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerHeightConstraint,
            containerBottomConstraint,
            
            // Grabber
            grabberView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            grabberView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: 40),
            grabberView.heightAnchor.constraint(equalToConstant: 5),
            
            // Sport Section Container
            sportSectionContainer.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: 40),
            sportSectionContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 45),
            sportSectionContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -45),
            sportSectionHeightConstraint,
            
            // Select Sport Button
            selectSportButton.topAnchor.constraint(equalTo: sportSectionContainer.topAnchor),
            selectSportButton.leadingAnchor.constraint(equalTo: sportSectionContainer.leadingAnchor),
            selectSportButton.trailingAnchor.constraint(equalTo: sportSectionContainer.trailingAnchor),
            selectSportButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            // Sport Chevron
            sportChevronImageView.trailingAnchor.constraint(equalTo: selectSportButton.trailingAnchor, constant: -20),
            sportChevronImageView.centerYAnchor.constraint(equalTo: selectSportButton.centerYAnchor),
            sportChevronImageView.widthAnchor.constraint(equalToConstant: 14),
            sportChevronImageView.heightAnchor.constraint(equalToConstant: 14),
            
            // Sports Scroll View
            sportsScrollView.topAnchor.constraint(equalTo: selectSportButton.bottomAnchor),
            sportsScrollView.leadingAnchor.constraint(equalTo: sportSectionContainer.leadingAnchor),
            sportsScrollView.trailingAnchor.constraint(equalTo: sportSectionContainer.trailingAnchor),
            sportsScrollView.bottomAnchor.constraint(equalTo: sportSectionContainer.bottomAnchor),
            
            // Sports Stack View
            sportsStackView.topAnchor.constraint(equalTo: sportsScrollView.topAnchor, constant: 5),
            sportsStackView.leadingAnchor.constraint(equalTo: sportsScrollView.leadingAnchor, constant: 15),
            sportsStackView.trailingAnchor.constraint(equalTo: sportsScrollView.trailingAnchor, constant: -15),
            sportsStackView.bottomAnchor.constraint(equalTo: sportsScrollView.bottomAnchor, constant: -15),
            sportsStackView.widthAnchor.constraint(equalTo: sportsScrollView.widthAnchor, constant: -30),
            
            // Team Name Text Field
            teamNameTextField.topAnchor.constraint(equalTo: sportSectionContainer.bottomAnchor, constant: 20),
            teamNameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 45),
            teamNameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -45),
            teamNameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Players Section Container
            playersSectionContainer.topAnchor.constraint(equalTo: teamNameTextField.bottomAnchor, constant: 20),
            playersSectionContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 45),
            playersSectionContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -45),
            playersSectionHeightConstraint,
            
            // Select Players Button
            selectPlayersButton.topAnchor.constraint(equalTo: playersSectionContainer.topAnchor),
            selectPlayersButton.leadingAnchor.constraint(equalTo: playersSectionContainer.leadingAnchor),
            selectPlayersButton.trailingAnchor.constraint(equalTo: playersSectionContainer.trailingAnchor),
            selectPlayersButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            // Players Chevron
            playersChevronImageView.trailingAnchor.constraint(equalTo: selectPlayersButton.trailingAnchor, constant: -20),
            playersChevronImageView.centerYAnchor.constraint(equalTo: selectPlayersButton.centerYAnchor),
            playersChevronImageView.widthAnchor.constraint(equalToConstant: 14),
            playersChevronImageView.heightAnchor.constraint(equalToConstant: 14),
            
            // Players Scroll View
            playersScrollView.topAnchor.constraint(equalTo: selectPlayersButton.bottomAnchor),
            playersScrollView.leadingAnchor.constraint(equalTo: playersSectionContainer.leadingAnchor),
            playersScrollView.trailingAnchor.constraint(equalTo: playersSectionContainer.trailingAnchor),
            playersScrollView.bottomAnchor.constraint(equalTo: playersSectionContainer.bottomAnchor),
            
            // Players Stack View
            playersStackView.topAnchor.constraint(equalTo: playersScrollView.topAnchor, constant: 5),
            playersStackView.leadingAnchor.constraint(equalTo: playersScrollView.leadingAnchor, constant: 15),
            playersStackView.trailingAnchor.constraint(equalTo: playersScrollView.trailingAnchor, constant: -15),
            playersStackView.bottomAnchor.constraint(equalTo: playersScrollView.bottomAnchor, constant: -15),
            playersStackView.widthAnchor.constraint(equalTo: playersScrollView.widthAnchor, constant: -30),
            
            // Create Button
            createButton.topAnchor.constraint(equalTo: playersSectionContainer.bottomAnchor, constant: 30),
            createButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            createButton.widthAnchor.constraint(equalToConstant: 120),
            createButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        dimmedView.alpha = 0
        sportsScrollView.alpha = 0
        playersScrollView.alpha = 0
    }
    
    private func loadSportsFromSupabase() {
        Task {
            do {
                let sportsFromDB: [Sport] = try await supabase
                    .from("sports")
                    .select()
                    .order("name")
                    .execute()
                    .value
                
                await MainActor.run {
                    self.sports = sportsFromDB
                    self.setupSportRows()
                }
            } catch {
                print("Error loading sports: \(error)")
                await MainActor.run {
                    // Fallback to default sports if Supabase fails
                    self.sports = [
                        Sport(id: 1, name: "Football", emoji: "⚽️", created_at: ""),
                        Sport(id: 2, name: "Cricket", emoji: "🏏", created_at: ""),
                        Sport(id: 3, name: "Basketball", emoji: "🏀", created_at: ""),
                        Sport(id: 4, name: "Table Tennis", emoji: "🏓", created_at: ""),
                        Sport(id: 5, name: "Badminton", emoji: "🏸", created_at: ""),
                        Sport(id: 6, name: "Tennis", emoji: "🎾", created_at: "")
                    ]
                    self.setupSportRows()
                }
            }
        }
    }
    
    private func loadFriendsFromSupabase() {
        Task {
            do {
                let session = try await supabase.auth.session
                let userId = session.user.id
                
                // Use the PostgreSQL function
                let friendsData: [[String: AnyJSON]] = try await supabase
                    .rpc("get_user_friends_with_profiles", params: ["user_uuid": userId])
                    .execute()
                    .value
                
                // Parse the response into FriendUser objects
                let friendUsers = friendsData.compactMap { data -> FriendUser? in
                    guard
                        let idString = data["id"]?.stringValue,
                        let id = UUID(uuidString: idString)
                    else { return nil }
                    
                    let email = data["email"]?.stringValue
                    let name = data["name"]?.stringValue
                    
                    return FriendUser(
                        id: id,
                        email: email,
                        name: name
                    )
                }
                
                await MainActor.run {
                    self.friends = friendUsers
                    self.setupFriendRows()
                    let title = friendUsers.isEmpty ?
                        "No friends found" :
                        "Select friends (\(friendUsers.count))"
                    self.selectPlayersButton.setTitle(title, for: .normal)
                    self.selectPlayersButton.isEnabled = !friendUsers.isEmpty
                    self.playersChevronImageView.isHidden = friendUsers.isEmpty
                }
                
            } catch {
                print("Error loading friends: \(error)")
                await MainActor.run {
                    self.selectPlayersButton.setTitle("Failed to load friends", for: .normal)
                    self.selectPlayersButton.isEnabled = false
                    self.playersChevronImageView.isHidden = true
                }
            }
        }
    }
    
    private func setupSportRows() {
        sportsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, sport) in sports.enumerated() {
            let sportRow = createSportRow(sport: sport, index: index)
            sportsStackView.addArrangedSubview(sportRow)
        }
    }
    
    private func createSportRow(sport: Sport, index: Int) -> UIView {
        let rowView = UIView()
        rowView.backgroundColor = .clear
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        let emojiLabel = UILabel()
        emojiLabel.text = sport.emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 24)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = sport.name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add tap gesture to the entire row
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sportRowTapped(_:)))
        rowView.addGestureRecognizer(tapGesture)
        rowView.isUserInteractionEnabled = true
        rowView.tag = index
        
        rowView.addSubview(emojiLabel)
        rowView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            rowView.heightAnchor.constraint(equalToConstant: 60),
            
            emojiLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 40),
            emojiLabel.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 17),
            nameLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -20)
        ])
        
        return rowView
    }
    
    private func setupFriendRows() {
        playersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for friend in friends {
            let friendRow = createFriendRow(friend: friend)
            playersStackView.addArrangedSubview(friendRow)
        }
    }
    
    private func createFriendRow(friend: FriendUser) -> UIView {
        let rowView = UIView()
        rowView.backgroundColor = .clear
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarView = UIView()
        avatarView.layer.cornerRadius = 20
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarIcon = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        avatarIcon.image = UIImage(systemName: "person.fill", withConfiguration: config)
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = friend.displayName
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let inviteButton = UIButton(type: .system)
        inviteButton.setTitle("Invite", for: .normal)
        inviteButton.setTitleColor(.white, for: .normal)
        inviteButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        inviteButton.backgroundColor = .systemGreen
        inviteButton.layer.cornerRadius = 12
        inviteButton.addTarget(self, action: #selector(inviteFriendTapped(_:)), for: .touchUpInside)
        inviteButton.translatesAutoresizingMaskIntoConstraints = false
        inviteButton.tag = friends.firstIndex(where: { $0.id == friend.id }) ?? 0
        
        // Check if invitation was already sent
        if pendingInvitations.contains(friend.id) {
            inviteButton.setTitle("Sent", for: .normal)
            inviteButton.backgroundColor = .systemGray
        }
        
        avatarView.addSubview(avatarIcon)
        rowView.addSubview(avatarView)
        rowView.addSubview(nameLabel)
        rowView.addSubview(inviteButton)
        
        NSLayoutConstraint.activate([
            rowView.heightAnchor.constraint(equalToConstant: 60),
            
            avatarView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
            avatarView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),
            
            avatarIcon.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 17),
            nameLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: inviteButton.leadingAnchor, constant: -10),
            
            inviteButton.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
            inviteButton.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            inviteButton.widthAnchor.constraint(equalToConstant: 70),
            inviteButton.heightAnchor.constraint(equalToConstant: 25)
        ])
        
        return rowView
    }
    
    @objc private func sportRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let rowView = gesture.view else { return }
        let index = rowView.tag
        selectedSport = sports[index]
        
        // Update the select sport button title with emoji and name
        if let selectedSport = selectedSport {
            selectSportButton.setTitle("\(selectedSport.emoji) \(selectedSport.name)", for: .normal)
        }
        
        // Collapse the sports dropdown
        toggleSportsDropdown()
    }
    
    private func setupActions() {
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        selectSportButton.addTarget(self, action: #selector(selectSportButtonTapped), for: .touchUpInside)
        selectPlayersButton.addTarget(self, action: #selector(selectPlayersTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmedViewTap))
        dimmedView.addGestureRecognizer(tapGesture)
    }
    
    private func setupPanGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update dimmed view
        dimmedView.backgroundColor = isDarkMode ?
            UIColor.black.withAlphaComponent(0.5) :
            UIColor.black.withAlphaComponent(0.3)
        
        // Update container view
        containerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        // Update grabber
        grabberView.backgroundColor = isDarkMode ?
            UIColor.white.withAlphaComponent(0.3) :
            UIColor.black.withAlphaComponent(0.2)
        
        // Update sport section
        sportSectionContainer.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        selectSportButton.setTitleColor(isDarkMode ? .white : .black, for: .normal)
        sportChevronImageView.tintColor = isDarkMode ? .white : .black
        
        // Update sport row labels
        for case let rowView as UIView in sportsStackView.arrangedSubviews {
            for case let label as UILabel in rowView.subviews {
                if label.text?.count == 1 { // emoji label
                    continue
                }
                label.textColor = isDarkMode ? .white : .black
            }
        }
        
        // Update team name text field
        teamNameTextField.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        teamNameTextField.textColor = isDarkMode ? .white : .black
        teamNameTextField.attributedPlaceholder = NSAttributedString(
            string: "Team name",
            attributes: [NSAttributedString.Key.foregroundColor: isDarkMode ? UIColor.lightGray : UIColor.darkGray]
        )
        
        // Update players section
        playersSectionContainer.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        selectPlayersButton.setTitleColor(isDarkMode ? .white : .black, for: .normal)
        playersChevronImageView.tintColor = isDarkMode ? .white : .black
        
        // Update player rows
        for case let rowView as UIView in playersStackView.arrangedSubviews {
            for case let label as UILabel in rowView.subviews {
                label.textColor = isDarkMode ? .white : .black
            }
            
            // Update avatar view and icon
            for case let avatarView as UIView in rowView.subviews {
                if avatarView.layer.cornerRadius == 20 { // Avatar view
                    avatarView.backgroundColor = isDarkMode ? .quaternaryDark : .quaternaryLight
                    
                    for case let avatarIcon as UIImageView in avatarView.subviews {
                        avatarIcon.tintColor = isDarkMode ? .white : .black
                    }
                }
            }
        }
        
        // Update create button
        createButton.backgroundColor = isDarkMode ? .systemGreen : .systemGreen
    }
    
    // MARK: - Animations
    private func animateIn() {
        containerBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.dimmedView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    private func animateOut(completion: (() -> Void)? = nil) {
        let currentHeight = containerHeightConstraint.constant
        containerBottomConstraint.constant = currentHeight
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.dimmedView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    private func toggleSportsDropdown() {
        isSportsExpanded.toggle()
        
        let chevronRotation: CGFloat = isSportsExpanded ? .pi : 0
        let totalContentHeight = CGFloat(sports.count) * 60 + 30 // rows + padding
        let newSportsSectionHeight: CGFloat = isSportsExpanded ? min(totalContentHeight + buttonHeight, maxSportsSectionHeight) : buttonHeight
        
        // Calculate new container height
        let sportsHeightAddition = isSportsExpanded ? (newSportsSectionHeight - buttonHeight) : 0
        let playersHeightAddition = isPlayersExpanded ? (playersSectionHeightConstraint.constant - buttonHeight) : 0
        let newContainerHeight: CGFloat = baseContainerHeight + sportsHeightAddition + playersHeightAddition
        
        sportSectionHeightConstraint.constant = newSportsSectionHeight
        containerHeightConstraint.constant = newContainerHeight
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.sportChevronImageView.transform = CGAffineTransform(rotationAngle: chevronRotation)
            self.sportsScrollView.alpha = self.isSportsExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    private func togglePlayersDropdown() {
        isPlayersExpanded.toggle()
        
        let chevronRotation: CGFloat = isPlayersExpanded ? .pi : 0
        let totalContentHeight = CGFloat(friends.count) * 60 + 30 // rows + padding
        let newPlayersSectionHeight: CGFloat = isPlayersExpanded ? min(totalContentHeight + buttonHeight, maxPlayersSectionHeight) : buttonHeight
        
        // Calculate new container height
        let sportsHeightAddition = isSportsExpanded ? (sportSectionHeightConstraint.constant - buttonHeight) : 0
        let playersHeightAddition = isPlayersExpanded ? (newPlayersSectionHeight - buttonHeight) : 0
        let newContainerHeight: CGFloat = baseContainerHeight + sportsHeightAddition + playersHeightAddition
        
        playersSectionHeightConstraint.constant = newPlayersSectionHeight
        containerHeightConstraint.constant = newContainerHeight
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.playersChevronImageView.transform = CGAffineTransform(rotationAngle: chevronRotation)
            self.playersScrollView.alpha = self.isPlayersExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerBottomConstraint.constant = translation.y
            }
        case .ended:
            if translation.y > 100 || velocity.y > 500 {
                animateOut()
            } else {
                containerBottomConstraint.constant = 0
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                    self.view.layoutIfNeeded()
                }
            }
        default:
            break
        }
    }
    
    @objc private func handleDimmedViewTap() {
        animateOut()
    }
    
    @objc private func createButtonTapped() {
        guard let teamName = teamNameTextField.text, !teamName.isEmpty else {
            // Show error for missing team name
            showError(message: "Please enter a team name")
            return
        }
        
        guard selectedSport != nil else {
            // Show error for missing sport selection
            showError(message: "Please select a sport")
            return
        }

        createTeamInSupabase(teamName: teamName)
    }
    
    private func createTeamInSupabase(teamName: String) {
        Task {
            do {
                // Get current user session
                let session = try await supabase.auth.session
                let userId = session.user.id
                
                // Step 1: Fetch current user's name and college_id from profiles table
                struct ProfileInfo: Codable {
                    let name: String?
                    let college_id: Int?
                }
                
                let userProfile: ProfileInfo = try await supabase
                    .from("profiles")
                    .select("name, college_id")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                let senderName = userProfile.name ?? "Someone"
                
                // Step 2: Create the team with college_id using a proper struct
                struct NewTeam: Codable {
                    let name: String
                    let sport_id: Int
                    let captain_id: String
                    let college_id: Int?
                }
                
                let newTeam = NewTeam(
                    name: teamName,
                    sport_id: selectedSport!.id,
                    captain_id: userId.uuidString,
                    college_id: userProfile.college_id
                )
                
                print("📝 Creating team with data: \(newTeam)")
                
                // Insert the team
                try await supabase
                    .from("teams")
                    .insert(newTeam)
                    .execute()
                
                print("✅ Team insert executed")
                
                // Step 3: Fetch the newly created team
                let createdTeams: [TeamResponse] = try await supabase
                    .from("teams")
                    .select()
                    .eq("name", value: teamName)
                    .eq("captain_id", value: userId.uuidString)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value
                
                guard let createdTeam = createdTeams.first else {
                    throw NSError(domain: "CreateTeam", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find created team"])
                }
                
                let createdTeamId = createdTeam.id
                print("✅ Team found with ID: \(createdTeamId)")
                
                // Step 4: Add current user as captain to team_members
                struct NewTeamMember: Codable {
                    let team_id: String
                    let user_id: String
                    let role: String
                }
                
                let captainMember = NewTeamMember(
                    team_id: createdTeamId.uuidString,
                    user_id: userId.uuidString,
                    role: "captain"
                )
                
                try await supabase
                    .from("team_members")
                    .insert(captainMember)
                    .execute()
                
                print("✅ Captain added to team_members")
                
                // Step 5: Send notifications to invited friends
                for friendId in pendingInvitations {
                    try await sendTeamInvitationNotification(
                        senderId: userId,
                        senderName: senderName,
                        receiverId: friendId,
                        teamName: teamName,
                        sportName: selectedSport!.name
                    )
                }
                
                print("✅ Notifications sent to \(pendingInvitations.count) friends")

                await MainActor.run {
                    // Call completion handler and dismiss
                    self.onTeamCreated?(teamName)
                    self.animateOut()
                }
                
            } catch {
                print("❌ Error creating team: \(error)")
                await MainActor.run {
                    self.showError(message: "Failed to create team. Please try again.")
                }
            }
        }
    }

    // MARK: - Notification Methods
    private func sendTeamInvitationNotification(senderId: UUID, senderName: String, receiverId: UUID, teamName: String, sportName: String) async throws {
        
        let message = "\(senderName) has requested you to join their \(sportName) team \(teamName)"
        
        // Create notification using a proper struct
        struct NewNotification: Codable {
            let sender_id: String
            let receiver_id: String
            let type: String
            let message: String
        }
        
        let notification = NewNotification(
            sender_id: senderId.uuidString,
            receiver_id: receiverId.uuidString,
            type: "team_invitation",
            message: message
        )
        
        // Insert notification
        try await supabase
            .from("notifications")
            .insert(notification)
            .execute()
        
        print("✅ Team invitation notification sent to \(receiverId)")
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Missing Information", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func selectSportButtonTapped() {
        toggleSportsDropdown()
    }
    
    @objc private func selectPlayersTapped() {
        if friends.isEmpty { return }
        togglePlayersDropdown()
    }
    
    @objc private func inviteFriendTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < friends.count else { return }
        
        let friendId = friends[index].id
        
        if pendingInvitations.contains(friendId) {
            // If already invited, do nothing (or you could allow un-inviting)
            return
        } else {
            // Add to pending invitations
            pendingInvitations.insert(friendId)
            
            // Update button appearance
            sender.setTitle("Sent", for: .normal)
            sender.backgroundColor = .systemGray
            
            // Show subtle feedback
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    sender.transform = .identity
                }
            }
            
            print("📨 Invitation will be sent to \(friends[index].displayName) when team is created")
        }
    }
}

// MARK: - Data Models for Creation
struct TeamCreation: Codable {
    let name: String
    let sport_id: Int
    let captain_id: UUID
    let college_id: Int?
    
    init(name: String, sport_id: Int, captain_id: UUID, college_id: Int? = nil) {
            self.name = name
            self.sport_id = sport_id
            self.captain_id = captain_id
            self.college_id = college_id
        }
    
    enum CodingKeys: String, CodingKey {
        case name
        case sport_id = "sport_id"
        case captain_id = "captain_id"
        case college_id = "college_id"
    }
}

struct TeamResponse: Codable {
    let id: UUID
    let name: String
    let sport_id: Int
    let captain_id: UUID
    let college_id: Int?
    let created_at: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sport_id
        case captain_id
        case college_id
        case created_at
    }
}

struct TeamMemberCreation: Codable {
    let team_id: UUID
    let user_id: UUID
    let role: String
    
    enum CodingKeys: String, CodingKey {
        case team_id = "team_id"
        case user_id = "user_id"
        case role
    }
}

struct Friend: Codable {
    let id: Int
    let user_id: UUID
    let friend_id: UUID
    let status: String
    let created_at: String
    let updated_at: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case user_id = "user_id"
        case friend_id = "friend_id"
        case status
        case created_at = "created_at"
        case updated_at = "updated_at"
    }
}

// MARK: - Notification Model
struct NotificationCreation: Codable {
    let sender_id: String
    let receiver_id: String
    let type: String
    let message: String
    let created_at: String
    let updated_at: String
    
    enum CodingKeys: String, CodingKey {
        case sender_id = "sender_id"
        case receiver_id = "receiver_id"
        case type
        case message
        case created_at = "created_at"
        case updated_at = "updated_at"
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct CreateTeamViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateTeamViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .previewDisplayName("Dark Mode")
            
            CreateTeamViewControllerRepresentable()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .previewDisplayName("Light Mode")
        }
    }
}

struct CreateTeamViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CreateTeamViewController {
        return CreateTeamViewController()
    }
    
    func updateUIViewController(_ uiViewController: CreateTeamViewController, context: Context) {
        // No update needed
    }
}
#endif
