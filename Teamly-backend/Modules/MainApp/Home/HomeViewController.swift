//
//  HomeViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import UIKit
import Supabase
import Foundation

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    private let dataService = HomeDataService()
    private var currentUserId: String = ""
    private var userCollegeId: Int = 0
    private var sports: [HomeDataService.Sport] = []
    private var preferredSports: [HomeDataService.Sport] = []
    private var preferredSportsMatches: [String: [DBMatch]] = [:] // Dictionary to store matches by sport name
    private var selectedSportIndex: Int = 0 // Track which sport is currently selected
    private var tableViewHeightConstraint: NSLayoutConstraint?
    private var contentViewBottomConstraint: NSLayoutConstraint?
    
    private var reminderBannerTopConstraint: NSLayoutConstraint?
    private var reminderBannerHeightConstraint: NSLayoutConstraint?
    private var isReminderVisible: Bool = false
    
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
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Top Right Container with Icons
    private let topRightContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 22
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let postButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let notificationButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        button.setImage(UIImage(systemName: "bell.fill", withConfiguration: config), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(" Search players", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Sports Selection Collection View
    private let sportsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumLineSpacing = 15
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Preferred Sports Section
    private let preferredSportsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let preferredSportsHeader: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let preferredSportsEmojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let preferredSportsTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let seeMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("See more", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let matchesTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false // Since it's inside a scroll view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 190
        return tableView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let noMatchesLabel: UILabel = {
        let label = UILabel()
        label.text = "No matches available for today or tomorrow"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let reminderBanner: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 28
        view.layer.borderWidth = 1.5
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false
        
//        // Subtle glow shadow
//        view.layer.shadowColor = UIColor.red.cgColor
//        view.layer.shadowOpacity = 0.25
//        view.layer.shadowRadius = 10
//        view.layer.shadowOffset = .zero
        
        return view
    }()


    private let reminderLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()


    private let reminderDismissButton: UIButton = {
        let button = UIButton(type: .system)
        
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupTableView()
        setupActions()
        setupReminderBanner()
        updateColors()
        fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        refreshHomeData()
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
            sportsCollectionView.reloadData()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        updateColors()
        
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(loadingIndicator)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(topRightContainer)
        topRightContainer.addSubview(postButton)
        topRightContainer.addSubview(notificationButton)
        contentView.addSubview(searchButton)
        contentView.addSubview(sportsCollectionView)
        contentView.addSubview(preferredSportsContainer)
        
        // Setup preferred sports container
        preferredSportsContainer.addSubview(preferredSportsHeader)
        preferredSportsContainer.addSubview(matchesTableView)
        preferredSportsContainer.addSubview(noMatchesLabel)
        
        // Setup preferred sports header
        preferredSportsHeader.addSubview(preferredSportsEmojiLabel)
        preferredSportsHeader.addSubview(preferredSportsTitleLabel)
        preferredSportsHeader.addSubview(seeMoreButton)
        
        setupConstraints()
        updateSearchButtonAppearance()
        
        // Hide content initially
        contentView.isHidden = true
        loadingIndicator.startAnimating()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Top Green Tint
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20 + view.safeAreaInsets.top),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: topRightContainer.leadingAnchor, constant: -12),
            
            // Top Right Container
            topRightContainer.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            topRightContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            topRightContainer.widthAnchor.constraint(equalToConstant: 92),
            topRightContainer.heightAnchor.constraint(equalToConstant: 44),
            
            // Post Button
            postButton.leadingAnchor.constraint(equalTo: topRightContainer.leadingAnchor),
            postButton.centerYAnchor.constraint(equalTo: topRightContainer.centerYAnchor),
            postButton.widthAnchor.constraint(equalToConstant: 44),
            postButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Notification Button
            notificationButton.trailingAnchor.constraint(equalTo: topRightContainer.trailingAnchor),
            notificationButton.centerYAnchor.constraint(equalTo: topRightContainer.centerYAnchor),
            notificationButton.widthAnchor.constraint(equalToConstant: 44),
            notificationButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Search Bar
            searchButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            searchButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            searchButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            searchButton.heightAnchor.constraint(equalToConstant: 45),
            
            // Sports Collection View
            sportsCollectionView.topAnchor.constraint(equalTo: searchButton.bottomAnchor, constant: 20),
            sportsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sportsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sportsCollectionView.heightAnchor.constraint(equalToConstant: 100),
            
            // Preferred Sports Container
            preferredSportsContainer.topAnchor.constraint(equalTo: sportsCollectionView.bottomAnchor, constant: 10),
            preferredSportsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            preferredSportsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // Bottom constraint will be set dynamically
            
            // Preferred Sports Header
            preferredSportsHeader.topAnchor.constraint(equalTo: preferredSportsContainer.topAnchor),
            preferredSportsHeader.leadingAnchor.constraint(equalTo: preferredSportsContainer.leadingAnchor, constant: 18),
            preferredSportsHeader.trailingAnchor.constraint(equalTo: preferredSportsContainer.trailingAnchor, constant: -18),
            preferredSportsHeader.heightAnchor.constraint(equalToConstant: 30),
            
            // Preferred Sports Emoji Label
            preferredSportsEmojiLabel.leadingAnchor.constraint(equalTo: preferredSportsHeader.leadingAnchor),
            preferredSportsEmojiLabel.centerYAnchor.constraint(equalTo: preferredSportsHeader.centerYAnchor),
            preferredSportsEmojiLabel.widthAnchor.constraint(equalToConstant: 30),
            
            // Preferred Sports Title Label
            preferredSportsTitleLabel.leadingAnchor.constraint(equalTo: preferredSportsEmojiLabel.trailingAnchor, constant: 8),
            preferredSportsTitleLabel.centerYAnchor.constraint(equalTo: preferredSportsHeader.centerYAnchor),
            
            // See More Button
            seeMoreButton.trailingAnchor.constraint(equalTo: preferredSportsHeader.trailingAnchor),
            seeMoreButton.centerYAnchor.constraint(equalTo: preferredSportsHeader.centerYAnchor),
            seeMoreButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Matches Table View
            matchesTableView.topAnchor.constraint(equalTo: preferredSportsHeader.bottomAnchor, constant: 10),
            matchesTableView.leadingAnchor.constraint(equalTo: preferredSportsContainer.leadingAnchor),
            matchesTableView.trailingAnchor.constraint(equalTo: preferredSportsContainer.trailingAnchor),
            // matchesTableView.bottomAnchor.constraint(equalTo: preferredSportsContainer.bottomAnchor), // Will be set dynamically
            
            // No Matches Label
            noMatchesLabel.centerXAnchor.constraint(equalTo: preferredSportsContainer.centerXAnchor),
            noMatchesLabel.topAnchor.constraint(equalTo: preferredSportsHeader.bottomAnchor, constant: 150),
            noMatchesLabel.leadingAnchor.constraint(equalTo: preferredSportsContainer.leadingAnchor, constant: 20),
            noMatchesLabel.trailingAnchor.constraint(equalTo: preferredSportsContainer.trailingAnchor, constant: -20),
            noMatchesLabel.bottomAnchor.constraint(lessThanOrEqualTo: preferredSportsContainer.bottomAnchor, constant: -20)
        ])
        
        // Create initial tableView height constraint
        tableViewHeightConstraint = matchesTableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint?.isActive = true
    }
    
    private func setupCollectionView() {
        sportsCollectionView.delegate = self
        sportsCollectionView.dataSource = self
        sportsCollectionView.register(SportCardCell.self, forCellWithReuseIdentifier: "SportCardCell")
    }
    
    private func setupTableView() {
        matchesTableView.delegate = self
        matchesTableView.dataSource = self
        matchesTableView.register(MatchTableViewCell.self, forCellReuseIdentifier: "MatchTableViewCell")
    }
    
    private func setupActions() {
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
        postButton.addTarget(self, action: #selector(postButtonTapped), for: .touchUpInside)
        seeMoreButton.addTarget(self, action: #selector(seeMoreGamesTapped), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside) // Add this line
    }
    
    private func setupReminderBanner() {
        contentView.addSubview(reminderBanner)
        reminderBanner.addSubview(reminderLabel)
        reminderBanner.addSubview(reminderDismissButton)

        // Constraints for the banner itself
        reminderBannerTopConstraint = reminderBanner.topAnchor.constraint(
            equalTo: searchButton.bottomAnchor, constant: 20
        )
        reminderBannerTopConstraint?.isActive = true

        NSLayoutConstraint.activate([
            
            reminderBanner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            reminderBanner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            reminderDismissButton.topAnchor.constraint(equalTo: reminderBanner.topAnchor, constant: 12),
            reminderDismissButton.trailingAnchor.constraint(equalTo: reminderBanner.trailingAnchor, constant: -12),
            reminderDismissButton.widthAnchor.constraint(equalToConstant: 40),
            reminderDismissButton.heightAnchor.constraint(equalToConstant: 40),

            reminderLabel.topAnchor.constraint(equalTo: reminderBanner.topAnchor, constant: 20),
            reminderLabel.leadingAnchor.constraint(equalTo: reminderBanner.leadingAnchor, constant: 24),
            reminderLabel.trailingAnchor.constraint(equalTo: reminderDismissButton.leadingAnchor, constant: -14),
            reminderLabel.bottomAnchor.constraint(equalTo: reminderBanner.bottomAnchor, constant: -20),
        ])


        reminderDismissButton.addTarget(self, action: #selector(dismissReminderBanner), for: .touchUpInside)
        updateReminderBannerColors()

        // Hide until showReminderBanner() is called
        reminderBanner.isHidden = true
    }

    
    // MARK: - Data Fetching
    private func fetchData() {
        Task {
            do {
                
                // 1. Get current user ID from auth
                let session = try await SupabaseManager.shared.client.auth.session
                currentUserId = session.user.id.uuidString
                
                // 2. Fetch user profile to get college ID
                guard let userProfile = try await dataService.fetchUserProfile(userId: currentUserId) else {
                    print("Failed to fetch user profile")
                    await showError("Failed to load user data")
                    return
                }
                
                userCollegeId = userProfile.college_id
                
                // 3. Fetch college name for title
                if let college = try await dataService.fetchCollege(collegeId: userCollegeId) {
                    await MainActor.run {
                        self.titleLabel.text = college.name
                    }
                }
                
                // 4. Fetch all sports
                let allSports = try await dataService.fetchAllSports()
                
                // 5. Fetch user's preferred sports
                let preferredSportsData = try await dataService.fetchUserPreferredSports(userId: currentUserId)
                
                // Convert to Sport objects
                var userPreferredSports: [HomeDataService.Sport] = []
                for preferredSport in preferredSportsData {
                    if let sport = allSports.first(where: { $0.id == preferredSport.sport_id }) {
                        userPreferredSports.append(sport)
                    }
                }
                
                preferredSports = userPreferredSports
                
                // 6. Sort sports: preferred sports first, then the rest
                let preferredSportIds = Set(userPreferredSports.map { $0.id })
                var sortedSports = allSports.sorted { sport1, sport2 in
                    let isSport1Preferred = preferredSportIds.contains(sport1.id)
                    let isSport2Preferred = preferredSportIds.contains(sport2.id)
                    
                    if isSport1Preferred && !isSport2Preferred {
                        return true
                    } else if !isSport1Preferred && isSport2Preferred {
                        return false
                    }
                    return sport1.id < sport2.id
                }
                
                // 7. Fetch matches for the first preferred sport or first sport if no preferred sports
                var initialSport: HomeDataService.Sport?
                if let firstPreferredSport = preferredSports.first {
                    initialSport = firstPreferredSport
                } else if let firstSport = sortedSports.first {
                    initialSport = firstSport
                }
                
                if let sport = initialSport {
                    let dbMatches = try await dataService.fetchMatchesForSport(
                        sportId: sport.id,
                        collegeId: userCollegeId,
                        currentUserId: currentUserId
                    )
                    
                    preferredSportsMatches[sport.name] = dbMatches

                    await MainActor.run {
                        self.sports = sortedSports
                        self.sportsCollectionView.reloadData()

                        self.seeMoreButton.tag = sport.id

                        self.updatePreferredSportsSection(for: sport)

                        if let index = self.sports.firstIndex(where: { $0.id == sport.id }) {
                            self.selectedSportIndex = index
                            let indexPath = IndexPath(item: index, section: 0)
                            self.sportsCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                        }
                        
                        self.loadingIndicator.stopAnimating()
                        self.contentView.isHidden = false
                        self.showReminderBanner(message: "Reminder - Game on! Your match starts at 6:00 PM, only 2 hours to go.")
                    }
                }
                
            } catch {
                print("❌ ERROR fetching home data: \(error)")
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.showError("Failed to load data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updatePreferredSportsSection(for sport: HomeDataService.Sport) {
        preferredSportsEmojiLabel.text = sport.emoji
        preferredSportsTitleLabel.text = "\(sport.name)"
        seeMoreButton.tag = sport.id
        
        let matches = preferredSportsMatches[sport.name] ?? []
        
        // IMPORTANT: Make sure matches are updated with current RSVP counts
        Task {
            await updateMatchesWithCurrentRSVPCounts(for: matches, sportName: sport.name)
        }
        
        // Update table view
        matchesTableView.reloadData()
        
        // Show/hide no matches label
        noMatchesLabel.isHidden = !matches.isEmpty
        
        // Update table view height based on number of matches
        let tableViewHeight = CGFloat(matches.count) * 190
        tableViewHeightConstraint?.constant = tableViewHeight
        
        // Update constraints based on matches availability
        updateConstraintsBasedOnMatches(matches)
    }
    
    private func updateMatchesWithCurrentRSVPCounts(for matches: [DBMatch], sportName: String) async {
        var updatedMatches = matches
        
        for i in 0..<updatedMatches.count {
            let match = updatedMatches[i]
            
            do {
                // FIX: Use the correct method name - fetchRSVPCount
                let currentRSVPCount = try await dataService.fetchRSVPCount(for: match.id.uuidString)
                
                // Create a new DBMatch with updated count
                updatedMatches[i] = DBMatch(
                    id: match.id,
                    matchType: match.matchType,
                    communityId: match.communityId,
                    venue: match.venue,
                    matchDate: match.matchDate,
                    matchTime: match.matchTime,
                    sportId: match.sportId,
                    sportName: match.sportName,
                    skillLevel: match.skillLevel,
                    playersNeeded: match.playersNeeded,
                    postedByUserId: match.postedByUserId,
                    createdAt: match.createdAt,
                    playersRSVPed: currentRSVPCount, // Updated count
                    postedByName: match.postedByName,
                    isFriend: match.isFriend
                )
            } catch {
                print("Error fetching RSVP count for match \(match.id): \(error)")
            }
        }
        
        // Update the stored matches with fresh RSVP counts
        await MainActor.run {
            self.preferredSportsMatches[sportName] = updatedMatches
            self.matchesTableView.reloadData()
        }
    }

    private func fetchMatchesForSelectedSport(_ sport: HomeDataService.Sport) {
        Task {
            do {
                let dbMatches = try await dataService.fetchMatchesForSport(
                    sportId: sport.id,
                    collegeId: userCollegeId,
                    currentUserId: currentUserId
                )
                
                // Store matches for this sport
                preferredSportsMatches[sport.name] = dbMatches

                await MainActor.run {
                    self.updatePreferredSportsSection(for: sport)
                }
                
            } catch {
                print("❌ ERROR fetching matches for \(sport.name): \(error)")
                await MainActor.run {
                    self.preferredSportsMatches[sport.name] = []
                    self.updatePreferredSportsSection(for: sport)
                    self.showError("Failed to load matches: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateConstraintsBasedOnMatches(_ matches: [DBMatch]) {
        // Remove any existing bottom constraint from preferredSportsContainer
        preferredSportsContainer.constraints.forEach { constraint in
            if constraint.firstAttribute == .bottom && constraint.secondAttribute == .bottom {
                preferredSportsContainer.removeConstraint(constraint)
            }
        }
        
        // Remove any existing bottom constraint from matchesTableView
        matchesTableView.constraints.forEach { constraint in
            if constraint.firstAttribute == .bottom && constraint.secondAttribute == .bottom {
                matchesTableView.removeConstraint(constraint)
            }
        }
        
        // Add the correct constraints based on whether there are matches
        if matches.isEmpty {
            // When no matches, connect noMatchesLabel.bottom to preferredSportsContainer.bottom
            preferredSportsContainer.addConstraint(
                NSLayoutConstraint(
                    item: noMatchesLabel,
                    attribute: .bottom,
                    relatedBy: .equal,
                    toItem: preferredSportsContainer,
                    attribute: .bottom,
                    multiplier: 1,
                    constant: -20
                )
            )
        } else {
            // When there are matches, connect matchesTableView.bottom to preferredSportsContainer.bottom
            preferredSportsContainer.addConstraint(
                NSLayoutConstraint(
                    item: matchesTableView,
                    attribute: .bottom,
                    relatedBy: .equal,
                    toItem: preferredSportsContainer,
                    attribute: .bottom,
                    multiplier: 1,
                    constant: 0
                )
            )
        }
        
        // Connect preferredSportsContainer.bottom to contentView.bottom
        contentViewBottomConstraint?.isActive = false
        contentViewBottomConstraint = preferredSportsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        contentViewBottomConstraint?.isActive = true
        
        // Force layout update
        view.layoutIfNeeded()
    }
    
    // MARK: - Refresh Methods
    private func refreshHomeData() {
        guard !sports.isEmpty else { return }
        
        Task {
            await refreshMatchesForCurrentSport()
        }
    }

    private func refreshMatchesForCurrentSport() async {
        let currentSportId = seeMoreButton.tag
        guard let currentSport = sports.first(where: { $0.id == currentSportId }) else { return }
        
        do {
            let freshMatches = try await dataService.fetchMatchesForSport(
                sportId: currentSport.id,
                collegeId: userCollegeId,
                currentUserId: currentUserId
            )

            preferredSportsMatches[currentSport.name] = freshMatches

            await MainActor.run {
                self.updatePreferredSportsSection(for: currentSport)
            }
            
        } catch {
            print("❌ ERROR refreshing matches: \(error)")
            await MainActor.run {
                self.showError("Failed to refresh matches")
            }
        }
    }
    
    // MARK: - Button Actions
    @objc private func notificationButtonTapped() {
        let notificationsVC = NotificationsViewController()
        
        if let navController = navigationController {
            navController.pushViewController(notificationsVC, animated: true)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        } else {
            let navController = UINavigationController(rootViewController: notificationsVC)
            navController.modalPresentationStyle = .fullScreen
            navController.setNavigationBarHidden(true, animated: false)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
            present(navController, animated: true)
        }
    }
    
    @objc private func postButtonTapped() {
        let postVC = PostViewController()
        postVC.modalPresentationStyle = .pageSheet
        
        if let sheet = postVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 20
        }
        postVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        
        present(postVC, animated: true)
    }
    
    @objc private func seeMoreGamesTapped() {
        let sportId = seeMoreButton.tag
        if let sport = sports.first(where: { $0.id == sportId }) {
            navigateToMatchesViewController(with: sport.name)
        }
    }
    
    @objc private func searchButtonTapped() {
        let searchVC = SearchViewController()
        
        if let navController = navigationController {
            navController.pushViewController(searchVC, animated: true)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        } else {
            let navController = UINavigationController(rootViewController: searchVC)
            navController.modalPresentationStyle = .fullScreen
            navController.setNavigationBarHidden(true, animated: false)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
            present(navController, animated: true)
        }
    }
    
    func showReminderBanner(message: String) {
        reminderLabel.text = message
        reminderBanner.isHidden = false
        isReminderVisible = true
        updateSportsCollectionViewTopConstraint()

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func dismissReminderBanner() {
        isReminderVisible = false
        UIView.animate(withDuration: 0.25, animations: {
            self.reminderBanner.alpha = 0
            self.view.layoutIfNeeded()
        }) { _ in
            self.reminderBanner.isHidden = true
            self.reminderBanner.alpha = 1
            self.updateSportsCollectionViewTopConstraint()
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }

    /// Re-anchors the sports collection view depending on banner visibility
    private func updateSportsCollectionViewTopConstraint() {
        // Remove all existing top constraints on sportsCollectionView
        contentView.constraints.forEach { constraint in
            if constraint.firstItem === sportsCollectionView && constraint.firstAttribute == .top {
                constraint.isActive = false
            }
        }

        if isReminderVisible {
            sportsCollectionView.topAnchor.constraint(
                equalTo: reminderBanner.bottomAnchor, constant: 12
            ).isActive = true
        } else {
            sportsCollectionView.topAnchor.constraint(
                equalTo: searchButton.bottomAnchor, constant: 20
            ).isActive = true
        }
    }
    
    // MARK: - Navigation Methods
    private func navigateToMatchesViewController(with sportName: String) {
        let matchesVC = MatchesViewController()
        matchesVC.sportName = sportName
        
        if let navController = navigationController {
            navController.pushViewController(matchesVC, animated: true)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        } else {
            let navController = UINavigationController(rootViewController: matchesVC)
            navController.modalPresentationStyle = .fullScreen
            navController.setNavigationBarHidden(true, animated: false)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
            present(navController, animated: true)
        }
    }
    
    private func navigateToMatchInformationViewController(with match: DBMatch) {
        let matchInfoVC = MatchInformationViewController()
        matchInfoVC.match = match
        matchInfoVC.hidesBottomBarWhenPushed = true 
        
        if let navController = navigationController {
            navController.pushViewController(matchInfoVC, animated: true)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        } else {
            let navController = UINavigationController(rootViewController: matchInfoVC)
            navController.modalPresentationStyle = .fullScreen
            navController.setNavigationBarHidden(true, animated: false)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
            present(navController, animated: true)
        }
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        preferredSportsTitleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        seeMoreButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        topRightContainer.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        postButton.tintColor = isDarkMode ? .primaryWhite : .primaryBlack
        notificationButton.tintColor = isDarkMode ? .primaryWhite : .primaryBlack
        noMatchesLabel.textColor = isDarkMode ? .gray : .darkGray
        
        updateSearchButtonAppearance()
        updateReminderBannerColors()
    }
    
    private func updateReminderBannerColors() {

        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        if isDarkMode {
            
            // Deep wine red background
            reminderBanner.backgroundColor = UIColor(
                red: 0.38,
                green: 0.06,
                blue: 0.10,
                alpha: 1.0
            )
            
            // Neon red border
            reminderBanner.layer.borderColor = UIColor(
                red: 1.0,
                green: 0.15,
                blue: 0.30,
                alpha: 1.0
            ).cgColor
            
            reminderLabel.textColor = UIColor.white.withAlphaComponent(0.95)
            
            reminderDismissButton.tintColor = .white
            reminderDismissButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            reminderDismissButton.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
            
        } else {
            
            reminderBanner.backgroundColor = UIColor(
                red: 1.0,
                green: 0.93,
                blue: 0.95,
                alpha: 1.0
            )
            
            reminderBanner.layer.borderColor = UIColor(
                red: 0.85,
                green: 0.25,
                blue: 0.35,
                alpha: 0.6
            ).cgColor
            
            reminderLabel.textColor = UIColor(
                red: 0.55,
                green: 0.05,
                blue: 0.10,
                alpha: 1.0
            )
            
            reminderDismissButton.tintColor = UIColor(
                red: 0.55,
                green: 0.05,
                blue: 0.10,
                alpha: 1.0
            )
            
            reminderDismissButton.backgroundColor = UIColor.white
            reminderDismissButton.layer.borderColor = UIColor(
                red: 0.55,
                green: 0.05,
                blue: 0.10,
                alpha: 0.3
            ).cgColor
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
    
    private func updateSearchButtonAppearance() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        searchButton.backgroundColor = isDarkMode ? .secondaryDark : .tertiaryLight
        searchButton.setTitleColor(isDarkMode ? .white.withAlphaComponent(0.5) : .darkGray.withAlphaComponent(0.6), for: .normal)
        searchButton.layer.cornerRadius = 22
        searchButton.clipsToBounds = true
        
        // Add a magnifying glass icon
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let searchIcon = UIImage(systemName: "magnifyingglass", withConfiguration: config)
        searchButton.setImage(searchIcon, for: .normal)
        searchButton.tintColor = isDarkMode ? .white.withAlphaComponent(0.5) : .darkGray.withAlphaComponent(0.6)
        searchButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        searchButton.semanticContentAttribute = .forceLeftToRight
        searchButton.imageView?.contentMode = .scaleAspectFit
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

// MARK: - UICollectionView DataSource & Delegate
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sports.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SportCardCell", for: indexPath) as! SportCardCell
        let sport = sports[indexPath.item]
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let isSelected = indexPath.item == selectedSportIndex
        let isPreferred = preferredSports.contains(where: { $0.id == sport.id })
        
        cell.configure(with: sport, isDarkMode: isDarkMode, isSelected: isSelected, isPreferred: isPreferred)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sport = sports[indexPath.item]
        selectedSportIndex = indexPath.item
        
        // Update cell appearance
        collectionView.reloadData()
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        
        // Update the seeMoreButton tag with the current sport ID
        seeMoreButton.tag = sport.id
        
        // Check if we already have matches for this sport
        if let existingMatches = preferredSportsMatches[sport.name], !existingMatches.isEmpty {
            // Update UI with existing matches
            updatePreferredSportsSection(for: sport)
        } else {
            // Fetch matches for this sport
            fetchMatchesForSelectedSport(sport)
        }
    }
}

// MARK: - UITableView DataSource & Delegate
extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let currentSportId = seeMoreButton.tag
        if let sport = sports.first(where: { $0.id == currentSportId }),
           let matches = preferredSportsMatches[sport.name] {
            return matches.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchTableViewCell", for: indexPath) as! MatchTableViewCell
        
        let currentSportId = seeMoreButton.tag
        if let sport = sports.first(where: { $0.id == currentSportId }),
           let matches = preferredSportsMatches[sport.name],
           indexPath.row < matches.count {
            let match = matches[indexPath.row]
            cell.configure(with: match)
            
            // Remove any existing tap gesture recognizers from MatchCellCard
            cell.matchCellCard.gestureRecognizers?.forEach { cell.matchCellCard.removeGestureRecognizer($0) }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let currentSportId = seeMoreButton.tag
        if let sport = sports.first(where: { $0.id == currentSportId }),
           let matches = preferredSportsMatches[sport.name],
           indexPath.row < matches.count {
            let match = matches[indexPath.row]
            
            // Navigate to MatchInformationViewController
            navigateToMatchInformationViewController(with: match)
        }
    }
}

// MARK: - SportCardCell
class SportCardCell: UICollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
//    private let nameLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            emojiLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func configure(with sport: HomeDataService.Sport, isDarkMode: Bool, isSelected: Bool, isPreferred: Bool) {
        emojiLabel.text = sport.emoji
        //nameLabel.text = sport.name
        
        // Set background color based on mode
        containerView.backgroundColor = isDarkMode ? .black : .white
        
        // Set border if selected
        if isSelected {
            containerView.layer.borderWidth = 0.5
            containerView.layer.borderColor = UIColor.systemGreen.cgColor
        } else {
            containerView.layer.borderWidth = 0
            containerView.layer.borderColor = nil
        }
        
        // Set text color
        //nameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Optionally add a small indicator for preferred sports
        if isPreferred {
            // You could add a small star or indicator here
            // For now, just use the border for selection
        }
    }
}

// MARK: - MatchTableViewCell
class MatchTableViewCell: UITableViewCell {
    var matchCellCard: MatchCellCard!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        matchCellCard = MatchCellCard()
        matchCellCard.translatesAutoresizingMaskIntoConstraints = false
        
        // Disable user interaction on the card itself so table view handles taps
        matchCellCard.isUserInteractionEnabled = false
        
        contentView.addSubview(matchCellCard)
        
        NSLayoutConstraint.activate([
            matchCellCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            matchCellCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            matchCellCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            matchCellCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2)
        ])
    }
    
    func configure(with match: DBMatch) {
        matchCellCard.configure(with: match, onTap: nil)
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct HomeViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            HomeViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct HomeViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> HomeViewController {
        return HomeViewController()
    }
    
    func updateUIViewController(_ uiViewController: HomeViewController, context: Context) {
        // No update needed
    }
}
#endif
