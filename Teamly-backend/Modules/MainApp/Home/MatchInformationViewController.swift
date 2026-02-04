//
//  MatchInformationViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 03/02/26.
//

import UIKit
import Supabase

class MatchInformationViewController: UIViewController {
    
    // MARK: - Properties
    var match: DBMatch?
    private var hostProfile: MatchInformationDataService.Profile?
    private var rsvpPlayers: [MatchInformationDataService.PlayerWithProfile] = []
    private var currentUserId: String = ""
    private var isHostFriend: Bool = false
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let dataService = MatchInformationDataService()
    
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
    private let matchDetailsContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 35
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Updated: Floating action button at bottom - REDUCED WIDTH
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
    
    private let hostedByLabel: UILabel = {
        let label = UILabel()
        label.text = "Hosted by"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let hostedByContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 35
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let secondSeparatorLine: UIView = {
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
        
        if match != nil {
                Task {
                    await refreshMatchData()
                }
            }
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
        contentView.addSubview(hostedByLabel)
        contentView.addSubview(hostedByContainerView)
        contentView.addSubview(secondSeparatorLine)
        contentView.addSubview(playersLabel)
        contentView.addSubview(playersContainerView)
        
        view.addSubview(glassBackButton)

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

            // Venue Label
            venueLabel.centerYAnchor.constraint(equalTo: venueContainerView.centerYAnchor),
            venueLabel.leadingAnchor.constraint(equalTo: venueContainerView.leadingAnchor, constant: 16),
            venueLabel.trailingAnchor.constraint(equalTo: venueContainerView.trailingAnchor, constant: -16),
            
            // Match Details Container
            matchDetailsContainerView.topAnchor.constraint(equalTo: venueContainerView.bottomAnchor, constant: 20),
            matchDetailsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            matchDetailsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            matchDetailsContainerView.heightAnchor.constraint(equalToConstant: 200),
            
            // First Separator Line
            firstSeparatorLine.topAnchor.constraint(equalTo: matchDetailsContainerView.bottomAnchor, constant: 30),
            firstSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            firstSeparatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            firstSeparatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Hosted By Label
            hostedByLabel.topAnchor.constraint(equalTo: firstSeparatorLine.bottomAnchor, constant: 20),
            hostedByLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            hostedByLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            // Hosted By Container
            hostedByContainerView.topAnchor.constraint(equalTo: hostedByLabel.bottomAnchor, constant: 12),
            hostedByContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hostedByContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            hostedByContainerView.heightAnchor.constraint(equalToConstant: 70),
            
            // Second Separator Line
            secondSeparatorLine.topAnchor.constraint(equalTo: hostedByContainerView.bottomAnchor, constant: 30),
            secondSeparatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            secondSeparatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            secondSeparatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Players Label
            playersLabel.topAnchor.constraint(equalTo: secondSeparatorLine.bottomAnchor, constant: 20),
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
    
    // MARK: - Data Fetching (Simplified)
    private func fetchCurrentUserAndLoadData() {
        loadingIndicator.startAnimating()
        
        Task {
            do {
                // 1. Get current user ID
                currentUserId = try await dataService.fetchCurrentUserId()
                // 2. Load match details, host profile, and RSVP players
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
            // 1. Fetch host profile
            hostProfile = try? await dataService.fetchHostProfile(for: match)
            
            // 2. Fetch RSVP players with their profiles and friend status
            rsvpPlayers = try await dataService.fetchRSVPPlayers(for: match, currentUserId: currentUserId)
            


            // 3. Check if host is friend
            isHostFriend = await dataService.checkFriendshipWithHost(match: match, currentUserId: currentUserId)
            
            // 4. Update UI with all fetched data
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
    
    private func refreshMatchData() async {
        guard let match = match else { return }
        
        do {
            // Fetch updated match data with RSVP count
            let updatedCount = try await dataService.fetchPlayersRSVPCount(matchId: match.id.uuidString)
            
            await MainActor.run {
                // Update the match object with fresh data
                self.match?.playersRSVPed = updatedCount
                
                // Re-fetch RSVP players and host profile
                Task {
                    await self.loadAllData()
                }
            }
        } catch {
            print("Error refreshing match data: \(error)")
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
        
        // Setup hosted by section
        setupHostedBySection(match: match)
        
        // Setup players section
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
        hostedByLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        playersLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        matchDetailsContainerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        hostedByContainerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        playersContainerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        firstSeparatorLine.backgroundColor = isDarkMode ?
            UIColor.white.withAlphaComponent(0.3) :
            UIColor.black.withAlphaComponent(0.2)
        secondSeparatorLine.backgroundColor = isDarkMode ?
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
    
    private func configureFloatingActionButton(for match: DBMatch) {
        // Check if current user has RSVPed to this match
        let hasRSVPed = rsvpPlayers.contains { $0.userId.uuidString == currentUserId }
        let isHost = match.postedByUserId.uuidString == currentUserId
        
        // Check if match date is upcoming or past
        let currentDate = Date()
        let matchDate = match.matchDate
        // To check both date and time, create a combined date-time
        let matchDateTime = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: match.matchTime),
                                                  minute: Calendar.current.component(.minute, from: match.matchTime),
                                                  second: 0,
                                                  of: match.matchDate) ?? match.matchDate

        let isMatchUpcoming = matchDateTime > Date()
        
        if isHost {
            // Host cannot join/leave their own match
            floatingActionButton.isHidden = true
            return
        }
        
        if !isMatchUpcoming {
            // Match is already past - hide the button entirely
            floatingActionButton.isHidden = true
            return
        }
        
        // Only show buttons for upcoming matches
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
    private func setupMatchDetailsContainer(match: DBMatch) {
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
        sportLabel.text = match.sportName
        sportLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        sportLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        sportLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Date label
        let dateLabel = UILabel()
        dateLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        dateLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.attributedText = formattedDateText(for: match.matchDate, isDarkMode: isDarkMode)

        // Time icon and label - UPDATED WITH TIME RANGE
        let timeIcon = UIImageView(image: UIImage(systemName: "clock"))
        timeIcon.tintColor = .systemGray
        timeIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeIcon.heightAnchor.constraint(equalToConstant: 18),
            timeIcon.widthAnchor.constraint(equalToConstant: 18)
        ])

        let timeLabel = UILabel()
        // Calculate end time by adding 1 hour to start time
        let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: match.matchTime) ?? match.matchTime
        timeLabel.text = formatTimeRange(startTime: match.matchTime, endTime: endTime)
        timeLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        timeLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Skill level icon and badge
        let skillIcon = UIImageView(image: UIImage(systemName: "gauge.with.dots.needle.33percent"))
        skillIcon.tintColor = .systemGray
        skillIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            skillIcon.heightAnchor.constraint(equalToConstant: 18),
            skillIcon.widthAnchor.constraint(equalToConstant: 18)
        ])

        let skillBadge = UILabel()
        skillBadge.text = "\(match.skillLevel?.capitalized ?? "Not specified")"
        skillBadge.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        skillBadge.textColor = .white
        skillBadge.textAlignment = .center
        skillBadge.layer.cornerRadius = 12
        skillBadge.layer.masksToBounds = true
        skillBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            skillBadge.heightAnchor.constraint(equalToConstant: 24),
            skillBadge.widthAnchor.constraint(equalToConstant: 120)
        ])
        
        // Skill level colors
        if let skillLevel = match.skillLevel?.lowercased() {
            switch skillLevel {
                case "beginner":
                    skillBadge.backgroundColor = .systemTeal.withAlphaComponent(0.7)
                case "intermediate":
                    skillBadge.backgroundColor = .systemYellow.withAlphaComponent(0.7)
                case "experienced":
                    skillBadge.backgroundColor = .systemOrange.withAlphaComponent(0.7)
                case "advanced":
                    skillBadge.backgroundColor = .systemRed.withAlphaComponent(0.7)
                default:
                    skillBadge.backgroundColor = .gray.withAlphaComponent(0.7)
            }
        } else {
            skillBadge.backgroundColor = .gray.withAlphaComponent(0.7)
        }

        // Players icon and progress
        let playersIcon = UIImageView(image: UIImage(systemName: "person.3.fill"))
        playersIcon.tintColor = .systemGray
        playersIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playersIcon.heightAnchor.constraint(equalToConstant: 18),
            playersIcon.widthAnchor.constraint(equalToConstant: 23)
        ])
        
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = Float(match.playersRSVPed) / Float(match.playersNeeded)
        
        // Dynamic progress bar color based on percentage
        let progressPercentage = Float(match.playersRSVPed) / Float(match.playersNeeded)
        if progressPercentage <= 0.33 {
            progressView.progressTintColor = .systemGreen
        } else if progressPercentage <= 0.66 {
            progressView.progressTintColor = .systemYellow
        } else {
            progressView.progressTintColor = .systemRed
        }
        
        progressView.trackTintColor = isDarkMode ? UIColor(white: 0.3, alpha: 1.0) : UIColor(white: 0.8, alpha: 1.0)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        let playersCountLabel = UILabel()
        playersCountLabel.text = "\(match.playersRSVPed)/\(match.playersNeeded)"
        playersCountLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        playersCountLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        playersCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all to container
        matchDetailsContainerView.addSubview(sportIcon)
        matchDetailsContainerView.addSubview(sportLabel)
        matchDetailsContainerView.addSubview(dateLabel)
        matchDetailsContainerView.addSubview(timeIcon)
        matchDetailsContainerView.addSubview(timeLabel)
        matchDetailsContainerView.addSubview(skillIcon)
        matchDetailsContainerView.addSubview(skillBadge)
        matchDetailsContainerView.addSubview(playersIcon)
        matchDetailsContainerView.addSubview(progressView)
        matchDetailsContainerView.addSubview(playersCountLabel)
        
        NSLayoutConstraint.activate([
            sportIcon.topAnchor.constraint(equalTo: matchDetailsContainerView.topAnchor, constant: 20),
            sportIcon.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
            
            sportLabel.centerYAnchor.constraint(equalTo: sportIcon.centerYAnchor),
            sportLabel.leadingAnchor.constraint(equalTo: sportIcon.trailingAnchor, constant: 12),
            
            // Sport label trailing constraint
            sportLabel.trailingAnchor.constraint(lessThanOrEqualTo: matchDetailsContainerView.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: sportIcon.bottomAnchor, constant: 16),
            dateLabel.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
            
            timeIcon.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            timeIcon.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
            timeLabel.centerYAnchor.constraint(equalTo: timeIcon.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: timeIcon.trailingAnchor, constant: 12),
            
            skillIcon.topAnchor.constraint(equalTo: timeIcon.bottomAnchor, constant: 16),
            skillIcon.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
            skillBadge.centerYAnchor.constraint(equalTo: skillIcon.centerYAnchor),
            skillBadge.leadingAnchor.constraint(equalTo: skillIcon.trailingAnchor, constant: 12),
            skillBadge.heightAnchor.constraint(equalToConstant: 28),
            
            playersIcon.topAnchor.constraint(equalTo: skillIcon.bottomAnchor, constant: 16),
            playersIcon.leadingAnchor.constraint(equalTo: matchDetailsContainerView.leadingAnchor, constant: 20),
            progressView.centerYAnchor.constraint(equalTo: playersIcon.centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: playersIcon.trailingAnchor, constant: 12),
            progressView.widthAnchor.constraint(equalToConstant: 200),
            progressView.heightAnchor.constraint(equalToConstant: 7),
            playersCountLabel.centerYAnchor.constraint(equalTo: playersIcon.centerYAnchor),
            playersCountLabel.leadingAnchor.constraint(equalTo: progressView.trailingAnchor, constant: 12),
        ])
    }
    
    private func setupHostedBySection(match: DBMatch) {
        hostedByContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Check if host is the current user
        let isHost = match.postedByUserId.uuidString == currentUserId
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
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

        // FIRST: Add avatarIcon to avatarView
        avatarView.addSubview(avatarIcon)
        
        // THEN: Activate constraints
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
        
        if isHost {
            nameLabel.text = "You"
        } else {
            nameLabel.text = hostProfile?.name ?? match.postedByName
            
            nameLabel.isUserInteractionEnabled = true
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hostNameTapped))
                    nameLabel.addGestureRecognizer(tapGesture)
        }
        
        let sendButton = UIButton(type: .system)
        let buttonTintColor = isDarkMode ? UIColor.systemGreen : .systemGreen
        
        if isHost {
            // This is the current user's own match - hide the button
            sendButton.isHidden = true
        } else if isHostFriend {
            // Show "Friend" label if host is friend
            sendButton.setTitle("Friend", for: .normal)
            sendButton.setTitleColor(buttonTintColor, for: .normal)
            sendButton.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
            sendButton.isUserInteractionEnabled = false // Make it a label (non-interactive)
            sendButton.isHidden = false
        }
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        sendButton.layer.cornerRadius = 12
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Note: avatarIcon is already added to avatarView above
        hostedByContainerView.addSubview(avatarView)
        hostedByContainerView.addSubview(nameLabel)
        hostedByContainerView.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: hostedByContainerView.topAnchor, constant: 11),
            avatarView.leadingAnchor.constraint(equalTo: hostedByContainerView.leadingAnchor, constant: 20),
            avatarView.widthAnchor.constraint(equalToConstant: 50),
            avatarView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            
            sendButton.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            sendButton.trailingAnchor.constraint(equalTo: hostedByContainerView.trailingAnchor, constant: -20),
            sendButton.widthAnchor.constraint(equalToConstant: 100),
            sendButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
    
    private func setupPlayersSection() {
        playersContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        if rsvpPlayers.isEmpty {
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
        
        for player in rsvpPlayers {
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
    
    private func createPlayerRow(player: MatchInformationDataService.PlayerWithProfile, isDarkMode: Bool) -> UIView {
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

        // FIX: First add avatarIcon to avatarView
        avatarView.addSubview(avatarIcon)
        
        // THEN activate constraints
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
        
        if isCurrentUser {
            nameLabel.text = "You"
        } else {
            nameLabel.text = player.name
        }
        
        if !isCurrentUser {
                nameLabel.isUserInteractionEnabled = true
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playerNameTapped(_:)))
                nameLabel.addGestureRecognizer(tapGesture)
                
                // Store player ID using the tag property (convert UUID hash to Int)
                nameLabel.tag = Int(player.userId.uuidString.hashValue)
            }
        
        let actionButton = UIButton(type: .system)
        let buttonTintColor = isDarkMode ? UIColor.systemGreen : .systemGreen
        
        if isCurrentUser {
            // This is the current user - hide the button
            actionButton.isHidden = true
        } else if player.isFriend {
            // Show "Friend" label if player is friend
            actionButton.setTitle("Friend", for: .normal)
            actionButton.setTitleColor(buttonTintColor, for: .normal)
            actionButton.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
            actionButton.isUserInteractionEnabled = false // Make it a label (non-interactive)
            actionButton.isHidden = false
        }
        
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        actionButton.layer.cornerRadius = 12
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        
        // avatarIcon is already added to avatarView above
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
    
    // MARK: - Friend Request Actions
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Tap Gesture Handlers

    @objc private func playerNameTapped(_ sender: UITapGestureRecognizer) {
        guard let nameLabel = sender.view as? UILabel else { return }
        
        // Find the player by matching the tag (which contains hashed UUID)
        let tagValue = nameLabel.tag
        
        // Search through rsvpPlayers to find the matching player
        guard let player = rsvpPlayers.first(where: { player in
            Int(player.userId.uuidString.hashValue) == tagValue
        }) else { return }
        
        // Don't navigate if player is current user (shouldn't happen, but check anyway)
        if player.userId.uuidString == currentUserId {
            return
        }
        
        // Navigate to UserProfileViewController for player
        navigateToUserProfile(userId: player.userId)
    }

    @objc private func hostNameTapped() {
        guard let match = match else { return }
        
        // Don't navigate if host is current user
        if match.postedByUserId.uuidString == currentUserId {
            return
        }
        
        // Navigate to UserProfileViewController for host
        navigateToUserProfile(userId: match.postedByUserId)
    }

    private func navigateToUserProfile(userId: UUID) {
        let userProfileVC = UserProfileViewController()
        userProfileVC.userId = userId
        
        // If you have a custom initializer, use it:
        // let userProfileVC = UserProfileViewController(userId: userId)
        
        // Push to navigation controller
        if let navigationController = navigationController {
            navigationController.pushViewController(userProfileVC, animated: true)
        } else {
            // If not in a navigation controller, present modally
            let navController = UINavigationController(rootViewController: userProfileVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
    
    // MARK: - Helper Methods
    private func formatTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formatTimeRange(startTime: Date, endTime: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startString = formatter.string(from: startTime)
        let endString = formatter.string(from: endTime)
        return "\(startString) - \(endString)"
    }
    
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
        let currentDate = Date()
        let matchDate = match.matchDate
        let isMatchUpcoming = matchDate > currentDate
        
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
            try await dataService.joinMatch(matchId: matchId, userId: currentUserId)
            
            // Update the count
            await updateMatchPlayersCount()
            
            // Reload all data
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
            try await dataService.leaveMatch(matchId: matchId, userId: currentUserId)
            
            // Update the count
            await updateMatchPlayersCount()
            
            // Reload all data
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
    
    private func updateMatchPlayersCount() async {
        guard let match = match else { return }
        
        do {
            let updatedCount = try await dataService.fetchPlayersRSVPCount(matchId: match.id.uuidString)
            
            await MainActor.run {
                self.match?.playersRSVPed = updatedCount
                self.displayMatchInfo() // Refresh UI with updated count
            }
        } catch {
            print("Error fetching updated players count: \(error)")
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

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct MatchInformationViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MatchInformationViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            MatchInformationViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct MatchInformationViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = MatchInformationViewController()
        
        // Create a sample DBMatch for preview
        let sampleMatch = DBMatch(
            id: UUID(),
            matchType: "sport_community",
            communityId: "1",
            venue: "El Classico Turf, Potheri",
            matchDate: Date(),
            matchTime: Date(),
            sportId: 1,
            sportName: "Football",
            skillLevel: "intermediate",
            playersNeeded: 10,
            postedByUserId: UUID(),
            createdAt: Date(),
            playersRSVPed: 8,
            postedByName: "Aditi",
            isFriend: false
        )
        
        viewController.match = sampleMatch
        
        let navController = UINavigationController(rootViewController: viewController)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
#endif
