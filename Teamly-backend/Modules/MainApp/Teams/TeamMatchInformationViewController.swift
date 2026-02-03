//
//  TeamMatchInformationViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 02/02/26.
//

import UIKit
import Supabase

class TeamMatchInformationViewController: UIViewController {
    
    // MARK: - Properties
    var match: TeamMatch?
    var currentTeam: BackendTeam?
    private var hostProfile: Profile?
    private var rsvpPlayers: [PlayerWithProfile] = []
    private var allPlayers: [PlayerWithProfile] = [] // Combined host + RSVP players
    private var currentUserId: String = ""
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Match Info"
        label.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Glass Back Button
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
    
    private let venueContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let venueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pinIcon: UILabel = {
        let label = UILabel()
        label.text = "📍"
        label.font = UIFont.systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let matchDetailsContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 35
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Updated: Floating action button at bottom
    private let floatingActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let firstSeparatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let playersLabel: UILabel = {
        let label = UILabel()
        label.text = "Players"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playersContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 35
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Data Models
    struct Profile: Codable {
        let id: UUID
        let name: String?
        let email: String?
        let gender: String?
        let age: Int?
        let college_id: Int?
        let profile_pic: String?
        let created_at: String
        let updated_at: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case email
            case gender
            case age
            case college_id = "college_id"
            case profile_pic = "profile_pic"
            case created_at = "created_at"
            case updated_at = "updated_at"
        }
    }
    
    struct PlayerWithProfile {
        let userId: UUID
        let name: String
        let profile: Profile?
        let isFriend: Bool
        let isHost: Bool // Added this to track if player is host
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBackButton()
        setupFloatingActionButton()
        updateColors()
        
        // Setup loading indicator
        setupLoadingIndicator()
        
        // Fetch current user ID and load match details
        fetchCurrentUserAndLoadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
            updateUIWithCurrentData()
        }
    }
    
    // MARK: - Setup
    private func setupLoadingIndicator() {
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBackButton() {
        glassBackButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    private func setupFloatingActionButton() {
        floatingActionButton.addTarget(self, action: #selector(floatingActionButtonTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        updateColors()
        
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add floating action button to main view (not scrollable)
        view.addSubview(floatingActionButton)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(venueContainerView)
        contentView.addSubview(matchDetailsContainerView)
        contentView.addSubview(firstSeparatorLine)
        contentView.addSubview(playersLabel)
        contentView.addSubview(playersContainerView)
        
        view.addSubview(glassBackButton)
        
        venueContainerView.addSubview(pinIcon)
        venueContainerView.addSubview(venueLabel)
        
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Glass Back Button
            glassBackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            glassBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            glassBackButton.widthAnchor.constraint(equalToConstant: 40),
            glassBackButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Floating Action Button at bottom
            floatingActionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            floatingActionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            floatingActionButton.widthAnchor.constraint(equalToConstant: 110),
            floatingActionButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Scroll View - Ends above floating button
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: floatingActionButton.topAnchor, constant: -10),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Venue Container
            venueContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            venueContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            venueContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            // Pin Icon
            pinIcon.centerYAnchor.constraint(equalTo: venueContainerView.centerYAnchor),
            pinIcon.leadingAnchor.constraint(equalTo: venueContainerView.leadingAnchor, constant: 16),
            
            // Venue Label
            venueLabel.centerYAnchor.constraint(equalTo: venueContainerView.centerYAnchor),
            venueLabel.leadingAnchor.constraint(equalTo: pinIcon.trailingAnchor, constant: 10),
            venueLabel.trailingAnchor.constraint(equalTo: venueContainerView.trailingAnchor, constant: -16),
            
            // Match Details Container - Dynamic height will be set later
            matchDetailsContainerView.topAnchor.constraint(equalTo: venueContainerView.bottomAnchor, constant: 20),
            matchDetailsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            matchDetailsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            matchDetailsContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150), // Minimum height
            
            // First Separator Line
            firstSeparatorLine.topAnchor.constraint(equalTo: matchDetailsContainerView.bottomAnchor, constant: 30),
            firstSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            firstSeparatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            firstSeparatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Players Label
            playersLabel.topAnchor.constraint(equalTo: firstSeparatorLine.bottomAnchor, constant: 20),
            playersLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            playersLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            // Players Container
            playersContainerView.topAnchor.constraint(equalTo: playersLabel.bottomAnchor, constant: 12),
            playersContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            playersContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            playersContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            playersContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }
    
    // MARK: - Data Fetching
    private func fetchCurrentUserAndLoadData() {
        loadingIndicator.startAnimating()
        
        Task {
            do {
                // 1. Get current user ID
                let session = try await SupabaseManager.shared.client.auth.session
                currentUserId = session.user.id.uuidString
                print("Current user ID: \(currentUserId)")
                
                // 2. Load match details and players (including host)
                await loadAllData()
                
            } catch {
                print("❌ ERROR fetching current user: \(error)")
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.showError("Failed to load match information")
                }
            }
        }
    }

    private func loadAllData() async {
        guard let match = match else {
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.showError("Match data not available")
            }
            return
        }
        
        do {
            // 1. Fetch host profile (posted by user)
            let hostUserId = match.postedByUserId.uuidString
            let response = try await SupabaseManager.shared.client
                .from("profiles")
                .select("*")
                .eq("id", value: hostUserId)
                .execute()

            let hostProfileData: [[String: Any]] = try JSONSerialization.jsonObject(
                with: response.data, options: []
            ) as? [[String: Any]] ?? []
            
            if let profileData = hostProfileData.first {
                // Convert to Profile struct
                if let idString = profileData["id"] as? String,
                   let id = UUID(uuidString: idString),
                   let createdAt = profileData["created_at"] as? String,
                   let updatedAt = profileData["updated_at"] as? String {
                    
                    hostProfile = Profile(
                        id: id,
                        name: profileData["name"] as? String,
                        email: profileData["email"] as? String,
                        gender: profileData["gender"] as? String,
                        age: profileData["age"] as? Int,
                        college_id: profileData["college_id"] as? Int,
                        profile_pic: profileData["profile_pic"] as? String,
                        created_at: createdAt,
                        updated_at: updatedAt
                    )
                }
            }
            
            // 2. Fetch RSVP players with their profiles
            rsvpPlayers = try await fetchRSVPPlayers(for: match)
            
            // 3. Create host player object
            var hostPlayer: PlayerWithProfile?
            if let hostProfile = hostProfile {
                // Check if host is friend of current user
                let isHostFriend = await checkFriendshipBetweenUsers(userId1: currentUserId, userId2: hostProfile.id.uuidString)
                
                hostPlayer = PlayerWithProfile(
                    userId: hostProfile.id,
                    name: hostProfile.name ?? "Match Host",
                    profile: hostProfile,
                    isFriend: isHostFriend,
                    isHost: true
                )
            }
            
            // 4. Combine host + RSVP players (host at the top)
            if let hostPlayer = hostPlayer {
                // Check if host has also RSVPed
                let hostHasRSVPed = rsvpPlayers.contains { $0.userId.uuidString == hostPlayer.userId.uuidString }
                
                if !hostHasRSVPed {
                    // Add host to the beginning if they haven't RSVPed
                    allPlayers = [hostPlayer] + rsvpPlayers
                } else {
                    // Host already in RSVP list, just use that
                    allPlayers = rsvpPlayers
                    // Mark the host player in the list
                    if let index = allPlayers.firstIndex(where: { $0.userId.uuidString == hostPlayer.userId.uuidString }) {
                        // Create a new player with isHost flag
                        var updatedPlayer = allPlayers[index]
                        allPlayers[index] = PlayerWithProfile(
                            userId: updatedPlayer.userId,
                            name: updatedPlayer.name,
                            profile: updatedPlayer.profile,
                            isFriend: updatedPlayer.isFriend,
                            isHost: true
                        )
                    }
                }
            } else {
                allPlayers = rsvpPlayers
            }
            
            // 5. Update UI with all fetched data
            await MainActor.run {
                self.displayMatchInfo()
                self.loadingIndicator.stopAnimating()
            }
            
        } catch {
            print("❌ ERROR loading match data: \(error)")
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.showError("Failed to load match details")
            }
        }
    }
    
    private func fetchRSVPPlayers(for match: TeamMatch) async throws -> [PlayerWithProfile] {
        // 1. Fetch all RSVPs for this match
        let response = try await SupabaseManager.shared.client
            .from("match_rsvps")
            .select("*")
            .eq("match_id", value: match.id.uuidString)
            .eq("rsvp_status", value: "going")
            .execute()

        let rsvpResponse: [[String: Any]] = try JSONSerialization.jsonObject(
            with: response.data, options: []
        ) as? [[String: Any]] ?? []
        
        guard !rsvpResponse.isEmpty else { return [] }
        
        // 2. Get all user IDs from RSVPs (excluding current host if they RSVPed)
        var userIds: [String] = []
        for rsvp in rsvpResponse {
            if let userId = rsvp["user_id"] as? String {
                userIds.append(userId)
            }
        }
        
        // 3. Fetch profiles for all users
        let response2 = try await SupabaseManager.shared.client
            .from("profiles")
            .select("*")
            .in("id", values: userIds)
            .execute()

        let profilesResponse: [[String: Any]] = try JSONSerialization.jsonObject(
            with: response2.data, options: []
        ) as? [[String: Any]] ?? []
        
        // 4. Create dictionary for quick profile lookup
        var profileDict: [String: Profile] = [:]
        for profileData in profilesResponse {
            if let idString = profileData["id"] as? String,
               let id = UUID(uuidString: idString),
               let createdAt = profileData["created_at"] as? String,
               let updatedAt = profileData["updated_at"] as? String {
                
                let profile = Profile(
                    id: id,
                    name: profileData["name"] as? String,
                    email: profileData["email"] as? String,
                    gender: profileData["gender"] as? String,
                    age: profileData["age"] as? Int,
                    college_id: profileData["college_id"] as? Int,
                    profile_pic: profileData["profile_pic"] as? String,
                    created_at: createdAt,
                    updated_at: updatedAt
                )
                profileDict[idString] = profile
            }
        }
        
        // 5. Check friend status for each RSVPed user and create player objects
        var players: [PlayerWithProfile] = []
        
        for rsvp in rsvpResponse {
            guard let userIdString = rsvp["user_id"] as? String,
                  let userId = UUID(uuidString: userIdString) else { continue }
            
            let profile = profileDict[userIdString]
            
            // Check if there's an accepted friendship between current user and this user
            let isFriend = await checkFriendshipBetweenUsers(userId1: currentUserId, userId2: userIdString)
            
            players.append(PlayerWithProfile(
                userId: userId,
                name: profile?.name ?? "Unknown Player",
                profile: profile,
                isFriend: isFriend,
                isHost: false // RSVP players are not hosts
            ))
        }
        
        return players
    }
    
    // Check friendship between two users (bidirectional check)
    private func checkFriendshipBetweenUsers(userId1: String, userId2: String) async -> Bool {
        guard userId1 != userId2 else { return false } // User can't be friend with themselves
        
        do {
            // Check for accepted friendship in either direction
            let response = try await SupabaseManager.shared.client
                .from("friends")
                .select("*")
                .or("and(user_id.eq.\(userId1),friend_id.eq.\(userId2),status.eq.accepted),and(user_id.eq.\(userId2),friend_id.eq.\(userId1),status.eq.accepted)")
                .execute()
            
            let friendships = try JSONDecoder().decode([[String: AnyCodable]].self, from: response.data)
            let isFriend = !friendships.isEmpty
            print("Is friend: \(isFriend)")
            
            return isFriend
            
        } catch {
            print("❌ ERROR checking friendship between users: \(error)")
            return false
        }
    }
    
    // MARK: - UI Updates
    private func updateUIWithCurrentData() {
        if let match = match {
            displayMatchInfo()
        }
    }
    
    private func displayMatchInfo() {
        guard let match = match else { return }
        
        // Set venue
        venueLabel.text = match.venue
        
        // Setup match details container
        setupMatchDetailsContainer(match: match)
        
        // Setup players section (using allPlayers which includes host)
        setupPlayersSection()
        
        // Configure floating action button based on RSVP status
        configureFloatingActionButton(for: match)
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        venueLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        playersLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        matchDetailsContainerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        playersContainerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        firstSeparatorLine.backgroundColor = isDarkMode ?
            UIColor.white.withAlphaComponent(0.3) :
            UIColor.black.withAlphaComponent(0.2)
        
        updateGlassButtonAppearance(isDarkMode: isDarkMode)
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
    
    private func updateGlassButtonAppearance(isDarkMode: Bool) {
        glassBackButton.backgroundColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.1) :
            UIColor(white: 0, alpha: 0.05)
        glassBackButton.layer.borderColor = (isDarkMode ?
            UIColor(white: 1, alpha: 0.2) :
            UIColor(white: 0, alpha: 0.1)).cgColor
        glassBackButton.tintColor = .systemGreen
    }
    
    private func configureFloatingActionButton(for match: TeamMatch) {
        // Check if current user has RSVPed to this match
        let hasRSVPed = rsvpPlayers.contains { $0.userId.uuidString == currentUserId }
        let isHost = match.postedByUserId.uuidString == currentUserId
        
        // Check if match date is upcoming or past
        let matchDateTime = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: match.matchTime),
                                                  minute: Calendar.current.component(.minute, from: match.matchTime),
                                                  second: 0,
                                                  of: match.matchDate) ?? match.matchDate

        let isMatchUpcoming = matchDateTime > Date()
        
        if isHost {
            // Host cannot join/leave their own match - hide button
            floatingActionButton.isHidden = true
            return
        }
        
        if !isMatchUpcoming {
            // Match is already past - hide the button entirely
            floatingActionButton.isHidden = true
            return
        }
        
        // Only show buttons for upcoming matches for non-hosts
        if hasRSVPed {
            // User has RSVPed and match is upcoming - show Leave button
            floatingActionButton.setTitle("Leave", for: .normal)
            floatingActionButton.setTitleColor(.white, for: .normal)
            floatingActionButton.backgroundColor = .systemRed
            floatingActionButton.isHidden = false
        } else {
            // User hasn't RSVPed and match is upcoming - show Join button
            floatingActionButton.setTitle("Join", for: .normal)
            floatingActionButton.setTitleColor(.white, for: .normal)
            floatingActionButton.backgroundColor = .systemGreen
            floatingActionButton.isHidden = false
        }
    }
    
    // MARK: - UI Setup Methods
    private func setupMatchDetailsContainer(match: TeamMatch) {
        matchDetailsContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Sport icon and label
        let sportIcon = UIImageView(image: UIImage(systemName: "soccerball"))
        sportIcon.tintColor = .systemGray
        sportIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sportIcon.heightAnchor.constraint(equalToConstant: 18),
            sportIcon.widthAnchor.constraint(equalToConstant: 18)
        ])

        let sportLabel = UILabel()
        sportLabel.text = match.sportName ?? "Sport"
        sportLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        sportLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        sportLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Date label
        let dateLabel = UILabel()
        dateLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        dateLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.attributedText = formattedDateText(for: match.matchDate, isDarkMode: isDarkMode)

        // Time icon and label
        let timeIcon = UIImageView(image: UIImage(systemName: "clock"))
        timeIcon.tintColor = .systemGray
        timeIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeIcon.heightAnchor.constraint(equalToConstant: 18),
            timeIcon.widthAnchor.constraint(equalToConstant: 18)
        ])

        let timeLabel = UILabel()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeLabel.text = "\(timeFormatter.string(from: match.matchTime))"
        timeLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        timeLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Check if it's a team_challenge match to show opponent section
        let isTeamChallenge = match.matchType == "team_challenge"
        
        // Players icon and label (REMOVED progress bar)
        let playersIcon = UIImageView(image: UIImage(systemName: "person.3.fill"))
        playersIcon.tintColor = .systemGray
        playersIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playersIcon.heightAnchor.constraint(equalToConstant: 18),
            playersIcon.widthAnchor.constraint(equalToConstant: 23)
        ])
        
        // Only show "X going" label
        let playersGoingLabel = UILabel()
        playersGoingLabel.text = "\(match.playersRSVPed) going"
        playersGoingLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        playersGoingLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        playersGoingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all to container
        matchDetailsContainerView.addSubview(sportIcon)
        matchDetailsContainerView.addSubview(sportLabel)
        matchDetailsContainerView.addSubview(dateLabel)
        matchDetailsContainerView.addSubview(timeIcon)
        matchDetailsContainerView.addSubview(timeLabel)
        matchDetailsContainerView.addSubview(playersIcon)
        matchDetailsContainerView.addSubview(playersGoingLabel)
        
        // Create constraints array
        var constraints: [NSLayoutConstraint] = []
        
        // Sport constraints
        constraints.append(contentsOf: [
            sportIcon.topAnchor.constraint(equalTo: matchDetailsContainerView.topAnchor, constant: 20),
            sportIcon.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
            
            sportLabel.centerYAnchor.constraint(equalTo: sportIcon.centerYAnchor),
            sportLabel.leadingAnchor.constraint(equalTo: sportIcon.trailingAnchor, constant: 12),
            sportLabel.trailingAnchor.constraint(lessThanOrEqualTo: matchDetailsContainerView.trailingAnchor, constant: -20),
        ])
        
        // Date constraints
        constraints.append(contentsOf: [
            dateLabel.topAnchor.constraint(equalTo: sportIcon.bottomAnchor, constant: 16),
            dateLabel.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
        ])
        
        // Time constraints
        constraints.append(contentsOf: [
            timeIcon.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            timeIcon.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
            timeLabel.centerYAnchor.constraint(equalTo: timeIcon.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: timeIcon.trailingAnchor, constant: 12),
        ])
        
        // Check if opponent section should be shown
        if isTeamChallenge {
            // Opponent team icon and label (NO BACKGROUND COLOR)
            let opponentIcon = UIImageView(image: UIImage(systemName: "flag.2.crossed.fill"))
            opponentIcon.tintColor = .systemGray
            opponentIcon.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                opponentIcon.heightAnchor.constraint(equalToConstant: 18),
                opponentIcon.widthAnchor.constraint(equalToConstant: 18)
            ])

            let opponentLabel = UILabel()
            
            // Get correct opponent name for display
            let opponentName = match.opponentNameForDisplay(currentTeamName: currentTeam?.name)
            opponentLabel.text = opponentName ?? "Opponent Team"
            opponentLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            opponentLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
            opponentLabel.translatesAutoresizingMaskIntoConstraints = false
            
            matchDetailsContainerView.addSubview(opponentIcon)
            matchDetailsContainerView.addSubview(opponentLabel)
            
            // Opponent constraints
            constraints.append(contentsOf: [
                opponentIcon.topAnchor.constraint(equalTo: timeIcon.bottomAnchor, constant: 16),
                opponentIcon.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
                opponentLabel.centerYAnchor.constraint(equalTo: opponentIcon.centerYAnchor),
                opponentLabel.leadingAnchor.constraint(equalTo: opponentIcon.trailingAnchor, constant: 12),
            ])
            
            // Players constraints (after opponent)
            constraints.append(contentsOf: [
                playersIcon.topAnchor.constraint(equalTo: opponentIcon.bottomAnchor, constant: 16),
                playersIcon.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
                playersGoingLabel.centerYAnchor.constraint(equalTo: playersIcon.centerYAnchor),
                playersGoingLabel.leadingAnchor.constraint(equalTo: playersIcon.trailingAnchor, constant: 12),
            ])
        } else {
            // For internal matches, players go directly after time
            constraints.append(contentsOf: [
                playersIcon.topAnchor.constraint(equalTo: timeIcon.bottomAnchor, constant: 16),
                playersIcon.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
                playersGoingLabel.centerYAnchor.constraint(equalTo: playersIcon.centerYAnchor),
                playersGoingLabel.leadingAnchor.constraint(equalTo: playersIcon.trailingAnchor, constant: 12),
            ])
        }
        
        // Bottom constraint to set container height
        if isTeamChallenge {
            constraints.append(playersIcon.bottomAnchor.constraint(equalTo: matchDetailsContainerView.bottomAnchor, constant: -20))
        } else {
            constraints.append(playersIcon.bottomAnchor.constraint(equalTo: matchDetailsContainerView.bottomAnchor, constant: -20))
        }
        
        NSLayoutConstraint.activate(constraints)
        
        // Adjust container height based on content
        let estimatedHeight = isTeamChallenge ? 200 : 170 // Adjusted heights
        matchDetailsContainerView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height && constraint.relation == .greaterThanOrEqual {
                constraint.constant = CGFloat(estimatedHeight)
            }
        }
    }
    
    private func setupPlayersSection() {
        playersContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Use allPlayers which includes host
        if allPlayers.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No players have joined yet"
            emptyLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .lightGray : .darkGray
            emptyLabel.textAlignment = .center
            emptyLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            playersContainerView.addSubview(emptyLabel)
            
            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: playersContainerView.centerXAnchor),
                emptyLabel.centerYAnchor.constraint(equalTo: playersContainerView.centerYAnchor)
            ])
            return
        }
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        var previousView: UIView? = nil
        
        for player in allPlayers {
            let playerRow = createPlayerRow(player: player, isDarkMode: isDarkMode)
            playersContainerView.addSubview(playerRow)
            
            if let previous = previousView {
                NSLayoutConstraint.activate([
                    playerRow.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 12),
                    playerRow.leadingAnchor.constraint(equalTo: playersContainerView.leadingAnchor, constant: 20),
                    playerRow.trailingAnchor.constraint(equalTo: playersContainerView.trailingAnchor, constant: -20),
                    playerRow.heightAnchor.constraint(equalToConstant: 60),
                ])
            } else {
                NSLayoutConstraint.activate([
                    playerRow.topAnchor.constraint(equalTo: playersContainerView.topAnchor, constant: 16),
                    playerRow.leadingAnchor.constraint(equalTo: playersContainerView.leadingAnchor, constant: 20),
                    playerRow.trailingAnchor.constraint(equalTo: playersContainerView.trailingAnchor, constant: -20),
                    playerRow.heightAnchor.constraint(equalToConstant: 60),
                ])
            }
            
            previousView = playerRow
        }
        
        if let lastView = previousView {
            NSLayoutConstraint.activate([
                lastView.bottomAnchor.constraint(equalTo: playersContainerView.bottomAnchor, constant: -16),
            ])
        }
    }
    
    private func createPlayerRow(player: PlayerWithProfile, isDarkMode: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Check if this player is the current user
        let isCurrentUser = player.userId.uuidString == currentUserId
        
        // Avatar container view
        let avatarView = UIView()
        avatarView.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        avatarView.layer.cornerRadius = 25
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.clipsToBounds = true

        // SF Symbol icon inside the avatar
        let avatarIcon = UIImageView(image: UIImage(systemName: "person.fill"))
        avatarIcon.tintColor = isDarkMode ? UIColor.quaternaryLight : .quaternaryDark
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false

        avatarView.addSubview(avatarIcon)
        
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),
            
            avatarIcon.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 25),
            avatarIcon.heightAnchor.constraint(equalToConstant: 25)
        ])
        
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Set name with "(Host)" indicator if needed
        if isCurrentUser {
            nameLabel.text = "You"
        } else if player.isHost {
            nameLabel.text = "\(player.name)"
        } else {
            nameLabel.text = player.name
        }
        
        let actionButton = UIButton(type: .system)
        let buttonTintColor = isDarkMode ? UIColor.systemGreen : .systemGreen
        
        // Show nothing for current user
        if isCurrentUser {
            actionButton.isHidden = true
        } else if player.isFriend {
            // Show "Friend" label if player is friend AND not the current user
            actionButton.setTitle("Friend", for: .normal)
            actionButton.setTitleColor(buttonTintColor, for: .normal)
            actionButton.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
            actionButton.isUserInteractionEnabled = false // Make it a label (non-interactive)
            actionButton.isHidden = false
        } else {
            // Not a friend and not current user - show nothing
            actionButton.isHidden = true
        }
        
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        actionButton.layer.cornerRadius = 12
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(avatarView)
        container.addSubview(nameLabel)
        container.addSubview(actionButton)
        
        NSLayoutConstraint.activate([
            avatarView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            avatarView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 50),
            avatarView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            
            actionButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            actionButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 100),
            actionButton.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        return container
    }
    
    // MARK: - Helper Methods
    private func formattedDateText(for date: Date, isDarkMode: Bool) -> NSAttributedString {
        let calendarIcon = NSTextAttachment()
        
        let dayComponent = Calendar.current.component(.day, from: date)
        let tintColor = UIColor.systemGray
        let calendarImage = UIImage(systemName: "\(dayComponent).calendar")?.withTintColor(tintColor) ?? UIImage(systemName: "calendar")!.withTintColor(tintColor)
        calendarIcon.image = calendarImage
        
        calendarIcon.bounds = CGRect(x: 0, y: -2, width: 20, height: 20)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        let dateString = dateFormatter.string(from: date)
        
        let dateText: String
        if Calendar.current.isDateInToday(date) {
            dateText = "  Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            dateText = "  Tomorrow"
        } else {
            dateText = "  \(dateString)"
        }
        
        let fullString = NSMutableAttributedString()
        fullString.append(NSAttributedString(attachment: calendarIcon))
        fullString.append(NSAttributedString(string: dateText))
        
        return fullString
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func floatingActionButtonTapped() {
        guard let match = match else { return }
        
        let hasRSVPed = rsvpPlayers.contains { $0.userId.uuidString == currentUserId }
        let isHost = match.postedByUserId.uuidString == currentUserId
        
        // Check if match date is upcoming
        let matchDateTime = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: match.matchTime),
                                                  minute: Calendar.current.component(.minute, from: match.matchTime),
                                                  second: 0,
                                                  of: match.matchDate) ?? match.matchDate

        let isMatchUpcoming = matchDateTime > Date()
        
        if isHost || !isMatchUpcoming {
            return
        }
        
        if hasRSVPed {
            // Leave match
            Task {
                await leaveMatch(matchId: match.id.uuidString)
            }
        } else {
            // Join match
            Task {
                await joinMatch(matchId: match.id.uuidString)
            }
        }
    }
    
    private func joinMatch(matchId: String) async {
        do {
            let rsvp = [
                "match_id": matchId,
                "user_id": currentUserId,
                "rsvp_status": "going"
            ]
            
            _ = try await SupabaseManager.shared.client
                .from("match_rsvps")
                .insert(rsvp)
                .execute()
            
            print("Successfully joined match")
            
            // Reload data to update UI
            await MainActor.run {
                self.loadingIndicator.startAnimating()
            }
            
            await loadAllData()
            
        } catch {
            print("❌ ERROR joining match: \(error)")
            await MainActor.run {
                self.showError("Failed to join match")
            }
        }
    }
    
    private func leaveMatch(matchId: String) async {
        do {
            _ = try await SupabaseManager.shared.client
                .from("match_rsvps")
                .delete()
                .eq("match_id", value: matchId)
                .eq("user_id", value: currentUserId)
                .execute()
            
            print("Successfully left match")
            
            // Reload data to update UI
            await MainActor.run {
                self.loadingIndicator.startAnimating()
            }
            
            await loadAllData()
            
        } catch {
            print("❌ ERROR leaving match: \(error)")
            await MainActor.run {
                self.showError("Failed to leave match")
            }
        }
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
