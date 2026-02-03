//
//  TeamMatchesViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 02/02/26.
//

import UIKit
internal import PostgREST
import Supabase

class TeamMatchesViewController: UIViewController {
    
    // MARK: - Properties
    var team: BackendTeam? // Changed from Team to BackendTeam
    
    private var upcomingMatches: [TeamMatch] = []
    private var pastMatches: [TeamMatch] = []
    private var currentMatches: [TeamMatch] = []
    
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Matches"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["Upcoming", "Past"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.layer.cornerRadius = 18
        segmentedControl.clipsToBounds = true
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 30
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No matches found"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        loadMatchesData()
        updateColors()
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
            collectionView.reloadData()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Set initial background color
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
        
        // Add green tint gradient background
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(glassBackButton)
        view.addSubview(titleLabel)
        view.addSubview(segmentedControl)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        view.addSubview(loadingIndicator)
        
        setupConstraints()
        
        glassBackButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Top Green Tint
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            // Glass Back Button
            glassBackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            glassBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            glassBackButton.widthAnchor.constraint(equalToConstant: 40),
            glassBackButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: glassBackButton.bottomAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 25),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 30),
            
            // Collection View
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 25),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Empty State Label
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.register(TeamMatchCellCard.self, forCellWithReuseIdentifier: "TeamMatchCellCard")
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private func loadMatchesData() {
        guard let team = team else {
            print("Team is nil")
            showEmptyState()
            return
        }
        
        loadingIndicator.startAnimating()
        collectionView.isHidden = true
        emptyStateLabel.isHidden = true
        
        // Fetch matches from Supabase
        Task {
            do {
                let matches = try await fetchTeamMatchesFromDatabase(teamId: team.id)
                await MainActor.run {
                    processFetchedMatches(matches)
                    loadingIndicator.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    print("Error fetching matches: \(error)")
                    loadingIndicator.stopAnimating()
                    showEmptyState()
                }
            }
        }
    }
    
    private func fetchTeamMatchesFromDatabase(teamId: UUID) async throws -> [TeamMatch] {
        let supabase = SupabaseManager.shared.client
        
        do {
            // Query to get team matches with team names
            let query = supabase
                .from("matches")
                .select("""
                    *,
                    team:teams!team_id(name),
                    opponent_team:teams!opponent_team_id(name),
                    sport:sports(name)
                """)
                .or("team_id.eq.\(teamId.uuidString),opponent_team_id.eq.\(teamId.uuidString)")
                .in("match_type", value: ["team_internal", "team_challenge"])
                .order("match_date", ascending: true)
                .order("match_time", ascending: true)
            
            print("Fetching matches for team: \(teamId)")
            
            let response: [MatchResponse] = try await query.execute().value
            
            print("Found \(response.count) matches")
            
            // Transform response into TeamMatch objects
            var teamMatches: [TeamMatch] = []
            
            for matchResponse in response {
                print("Processing match: \(matchResponse.id)")
                
                // Convert MatchResponse to dictionary for TeamMatch.fromDictionary
                var dict: [String: Any] = [
                    "id": matchResponse.id.uuidString,
                    "match_type": matchResponse.match_type,
                    "venue": matchResponse.venue,
                    "match_date": matchResponse.match_date,
                    "match_time": matchResponse.match_time,
                    "sport_id": matchResponse.sport_id,
                    "players_needed": matchResponse.players_needed ?? 0,
                    "posted_by_user_id": matchResponse.posted_by_user_id.uuidString,
                    "created_at": matchResponse.created_at
                ]
                
                // Add optional fields
                if let teamId = matchResponse.team_id {
                    dict["team_id"] = teamId.uuidString
                }
                if let opponentTeamId = matchResponse.opponent_team_id {
                    dict["opponent_team_id"] = opponentTeamId.uuidString
                }
                if let skillLevel = matchResponse.skill_level {
                    dict["skill_level"] = skillLevel
                }
                
                // Add team names from relationships
                if let teamName = matchResponse.team?.name {
                    dict["team_name"] = teamName
                }
                if let opponentTeamName = matchResponse.opponent_team?.name {
                    dict["opponent_team_name"] = opponentTeamName
                }
                if let sportName = matchResponse.sport?.name {
                    dict["sport_name"] = sportName
                }
                
                // Fetch RSVP count separately for each match
                let rsvpCount = try await getRSVPCountForMatch(matchId: matchResponse.id)
                dict["players_rsvped"] = rsvpCount
                
                // Create TeamMatch object
                if let teamMatch = TeamMatch.fromDictionary(dict) {
                    teamMatches.append(teamMatch)
                } else {
                    print("Failed to create TeamMatch from dictionary")
                }
            }
            
            return teamMatches
            
        } catch {
            print("Error fetching matches from Supabase: \(error)")
            throw error
        }
    }
    
    private func getRSVPCountForMatch(matchId: UUID) async throws -> Int {
        let supabase = SupabaseManager.shared.client
        
        do {
            // Get count of RSVPs for this match
            let response = try await supabase
                .from("match_rsvps")
                .select("*", count: .exact)
                .eq("match_id", value: matchId.uuidString)
                .execute()
            
            return response.count ?? 0
        } catch {
            print("Error fetching RSVP count for match \(matchId): \(error)")
            return 0
        }
    }
    
    // MARK: - Helper Structures for Supabase Response
    private struct MatchResponse: Codable {
        let id: UUID
        let match_type: String
        let team_id: UUID?
        let opponent_team_id: UUID?
        let venue: String
        let match_date: String
        let match_time: String
        let sport_id: Int
        let skill_level: String?
        let players_needed: Int?
        let posted_by_user_id: UUID
        let created_at: String
        
        let team: TeamInfo?
        let opponent_team: TeamInfo?
        let sport: SportInfo?
        
        struct TeamInfo: Codable {
            let name: String
        }
        
        struct SportInfo: Codable {
            let name: String
        }
    }
    
    private func processFetchedMatches(_ matches: [TeamMatch]) {
        print("Processing \(matches.count) fetched matches")
        
        let currentDate = Date()
        
        // Filter matches into upcoming and past
        upcomingMatches = matches.filter { match in
            let matchDateTime = combineDateAndTime(date: match.matchDate, time: match.matchTime)
            return matchDateTime >= currentDate
        }.sorted { match1, match2 in
            let dateTime1 = combineDateAndTime(date: match1.matchDate, time: match1.matchTime)
            let dateTime2 = combineDateAndTime(date: match2.matchDate, time: match2.matchTime)
            return dateTime1 < dateTime2
        }
        
        pastMatches = matches.filter { match in
            let matchDateTime = combineDateAndTime(date: match.matchDate, time: match.matchTime)
            return matchDateTime < currentDate
        }.sorted { match1, match2 in
            let dateTime1 = combineDateAndTime(date: match1.matchDate, time: match1.matchTime)
            let dateTime2 = combineDateAndTime(date: match2.matchDate, time: match2.matchTime)
            return dateTime1 > dateTime2 // Show most recent first
        }
        
        print("Upcoming matches: \(upcomingMatches.count)")
        print("Past matches: \(pastMatches.count)")
        
        // Debug print match details
        for (index, match) in upcomingMatches.enumerated() {
            print("Upcoming match \(index + 1): \(match.venue) on \(match.matchDate)")
        }
        
        // Set initial data
        currentMatches = upcomingMatches
        collectionView.reloadData()
        updateEmptyState()
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        return calendar.date(from: combinedComponents) ?? date
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update view background
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Update title label color
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update glass back button colors
        glassBackButton.backgroundColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.1) :
            UIColor(white: 0, alpha: 0.05)
        glassBackButton.layer.borderColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.2).cgColor :
            UIColor(white: 0, alpha: 0.1).cgColor
        glassBackButton.tintColor = isDarkMode ? .systemGreenDark : .systemGreen
        
        // Update segmented control colors
        segmentedControl.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        segmentedControl.selectedSegmentTintColor = isDarkMode ? UIColor.white : UIColor.black
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: isDarkMode ? UIColor.white.withAlphaComponent(0.8) : UIColor.black.withAlphaComponent(0.8),
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]

        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: isDarkMode ? UIColor.black : UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 16)
        ]

        segmentedControl.setTitleTextAttributes(normalAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedAttributes, for: .selected)
        
        // Update empty state label color
        emptyStateLabel.textColor = isDarkMode ? UIColor.lightGray : UIColor.darkGray
        
        // Update loading indicator color
        loadingIndicator.color = isDarkMode ? .white : .gray
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
    
    private func updateEmptyState() {
        let isEmpty = currentMatches.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        
        if segmentedControl.selectedSegmentIndex == 0 {
            emptyStateLabel.text = "No upcoming matches"
        } else {
            emptyStateLabel.text = "No past matches"
        }
        
        print("Empty state: \(isEmpty), message: \(emptyStateLabel.text ?? "")")
    }
    
    private func showEmptyState() {
        emptyStateLabel.isHidden = false
        collectionView.isHidden = true
        print("Showing empty state")
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func segmentedControlChanged() {
        if segmentedControl.selectedSegmentIndex == 0 {
            currentMatches = upcomingMatches
        } else {
            currentMatches = pastMatches
        }
        
        // Animate reload similar to MatchViewController
        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve) {
            self.collectionView.reloadData()
        }
        
        updateEmptyState()
        
        // Scroll to top when switching segments
        if !currentMatches.isEmpty {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension TeamMatchesViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Current matches count: \(currentMatches.count)")
        return currentMatches.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeamMatchCellCard", for: indexPath) as? TeamMatchCellCard else {
            return UICollectionViewCell()
        }
        
        var match = currentMatches[indexPath.item]
        print("Configuring cell for match: \(match.venue)")
        
        // Fix opponent team name if needed
        if let currentTeamName = team?.name {
            if match.matchType == "team_challenge" {
                if let opponentTeamName = match.opponentTeamName,
                   opponentTeamName == currentTeamName {
                    // The opponent name matches current team, show the other team name
                    match.opponentTeamName = match.teamName
                } else if let teamName = match.teamName,
                          teamName == currentTeamName,
                          let opponentTeamName = match.opponentTeamName {
                    // The team name matches current team, opponent name is already correct
                    // No change needed
                }
            }
        }
        
        cell.configure(with: match) { [weak self] in
            // Handle cell tap if needed
            print("Tapped on match at \(match.venue)")
        }
        
        // Update cell colors based on current theme
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        cell.updateColors(isDarkMode: isDarkMode)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 30, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 15, left: 20, bottom: 20, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let match = currentMatches[indexPath.item]
        print("Selected match at \(match.venue)")
        
        // Navigate to TeamMatchInformationViewController
        let matchInfoVC = TeamMatchInformationViewController()
        matchInfoVC.match = match
        matchInfoVC.currentTeam = team
        matchInfoVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        navigationController?.pushViewController(matchInfoVC, animated: true)
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct TeamMatchesViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TeamMatchesViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            TeamMatchesViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct TeamMatchesViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = TeamMatchesViewController()
        
        // Create sample BackendTeam for preview
        viewController.team = BackendTeam(
            id: UUID(),
            name: "Champions FC",
            sport_id: 1,
            captain_id: UUID(),
            college_id: 1,
            created_at: "2024-01-28T12:00:00Z"
        )
        
        let navController = UINavigationController(rootViewController: viewController)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No update needed
    }
}
#endif
