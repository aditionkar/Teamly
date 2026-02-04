//
//  TeamViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 27/01/26.
//

import UIKit
import Supabase

class TeamViewController: UIViewController {
    
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
        label.text = "Teams"
        label.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search teams"
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let centerIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .light)
        imageView.image = UIImage(systemName: "person.badge.shield.exclamationmark.fill", withConfiguration: config)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Not in a team yet\nCreate your own"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    
    private let teamsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    private var teams: [TeamWithSport] = []
    
    // Remove the computed property and handle user ID fetching in loadUserTeams method
    private var supabase: SupabaseClient {
        return SupabaseManager.shared.client
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateColors()
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadUserTeams()
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
        
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(centerIcon)
        view.addSubview(descriptionLabel)
        view.addSubview(createButton)
        view.addSubview(teamsStackView)
        
        NSLayoutConstraint.activate([
            // Top Green Tint
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Search Bar constraints
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            searchBar.heightAnchor.constraint(equalToConstant: 50),
            
            // Center Icon - centered vertically and horizontally
            centerIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            centerIcon.widthAnchor.constraint(equalToConstant: 70),
            centerIcon.heightAnchor.constraint(equalToConstant: 70),
            
            // Description Label - below the icon
            descriptionLabel.topAnchor.constraint(equalTo: centerIcon.bottomAnchor, constant: 20),
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Teams Stack View - below search bar
            teamsStackView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 50),
            teamsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            teamsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Create Button - at the bottom (always visible)
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            createButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createButton.widthAnchor.constraint(equalToConstant: 120),
            createButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update view background
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Update title label color
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update search bar colors
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = isDarkMode ?
                .secondaryDark :
                .secondaryLight
            textField.textColor = isDarkMode ? .lightGray : .darkGray
            
            let placeholderColor = isDarkMode ?
                UIColor.gray.withAlphaComponent(0.5) :
                UIColor.lightGray
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search teams",
                attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
            )
        }
        
        // Update center icon
        centerIcon.tintColor = isDarkMode ? .gray : .lightGray
        
        // Update description label
        descriptionLabel.textColor = isDarkMode ? .gray : .darkGray
        
        // Update create button (always visible)
        createButton.backgroundColor = isDarkMode ? .systemGreenDark : .systemGreen
        
        // Update search bar icon colors
        if let searchIcon = searchBar.searchTextField.leftView as? UIImageView {
            searchIcon.tintColor = isDarkMode ? .gray : .darkGray
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
    
    // MARK: - Data Loading
    private func loadUserTeams() {
        loadingIndicator.startAnimating()
        
        Task {
            do {
                // Get current user ID from Supabase auth session (async)
                let session = try await supabase.auth.session
                let userId = session.user.id
                
                // Step 1: Fetch team memberships for current user
                let teamMemberships: [TeamMember] = try await supabase
                    .from("team_members")
                    .select()
                    .eq("user_id", value: userId.uuidString.lowercased())
                    .execute()
                    .value
                
                if teamMemberships.isEmpty {
                    await MainActor.run {
                        showEmptyState()
                    }
                    return
                }
                
                // Step 2: Get team IDs from memberships
                let teamIds = teamMemberships.map { $0.team_id }
                
                // Step 3: Fetch teams data with sport emoji using a join
                let response: [TeamWithSport] = try await supabase
                    .from("teams")
                    .select("""
                        id,
                        name,
                        sport_id,
                        college_id,
                        captain_id,
                        created_at,
                        sports:sport_id (
                            id,
                            name,
                            emoji
                        )
                    """)
                    .in("id", values: teamIds)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.teams = response
                    self.displayTeams(response)
                }
                
            } catch {
                print("Error loading teams: \(error)")
                await MainActor.run {
                    showErrorState()
                }
            }
            
        }
    }
    
    private func displayTeams(_ teams: [TeamWithSport]) {
        // Clear existing team buttons
        teamsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if teams.isEmpty {
            showEmptyState()
            return
        }
        
        // Show teams UI
        loadingIndicator.stopAnimating()
        centerIcon.isHidden = true
        descriptionLabel.isHidden = true
        teamsStackView.isHidden = false
        searchBar.isHidden = false
        
        // Create button for each team
        for (index, team) in teams.enumerated() {
            let teamButton = createTeamButton(for: team, index: index)
            teamsStackView.addArrangedSubview(teamButton)
            
            // Add height constraint
            teamButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }
    }
    
    private func createTeamButton(for team: TeamWithSport, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        
        // Use sport emoji from database
        let sportEmoji = team.sports?.emoji ?? "🏅"
        button.setTitle("\(sportEmoji)  \(team.name)", for: .normal)
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 19, weight: .regular)
        button.layer.cornerRadius = 30
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        // Set colors based on current theme
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let bgColor = isDarkMode ? UIColor.secondaryDark : UIColor.secondaryLight
        let textColor = isDarkMode ? UIColor.white : UIColor.black
        
        button.backgroundColor = bgColor
        button.setTitleColor(textColor, for: .normal)
        
        // Store team index using tag
        button.tag = index
        
        // Add tap action
        button.addTarget(self, action: #selector(teamButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func showEmptyState() {
        loadingIndicator.stopAnimating()
        centerIcon.isHidden = false
        descriptionLabel.isHidden = false
        teamsStackView.isHidden = true
        searchBar.isHidden = true
        createButton.isHidden = false
    }
    
    private func showErrorState() {
        loadingIndicator.stopAnimating() 
        
        
        let errorLabel = UILabel()
        errorLabel.text = "Unable to load teams\nPlease try again"
        errorLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        errorLabel.textColor = .systemRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 2
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Remove after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            errorLabel.removeFromSuperview()
        }
        
        showEmptyState()
    }
    
    // MARK: - Actions
    @objc private func createButtonTapped() {
        let createTeamVC = CreateTeamViewController()
        
        // Set completion handler for when team is created
        createTeamVC.onTeamCreated = { [weak self] teamName in
            self?.teamCreated(with: teamName)
        }
        
        // Set modal presentation style to avoid white background
        createTeamVC.modalPresentationStyle = .overFullScreen
        createTeamVC.modalTransitionStyle = .coverVertical
    
        createTeamVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        
        present(createTeamVC, animated: true)
    }
        
    @objc private func teamButtonTapped(_ sender: UIButton) {
        let teamIndex = sender.tag
        guard teamIndex < teams.count else { return }
        
        let selectedTeam = teams[teamIndex]
        print("Selected team: \(selectedTeam.name)")
        
        // Fetch team details and members from Supabase
        Task {
            await loadTeamDetails(teamId: selectedTeam.id)
        }
    }

    private func loadTeamDetails(teamId: UUID) async {
        do {
            // Fetch team details
            let team: BackendTeam = try await SupabaseManager.shared.client
                .from("teams")
                .select()
                .eq("id", value: teamId)
                .single()
                .execute()
                .value
            
            // Fetch team members
            let members: [TeamMember] = try await SupabaseManager.shared.client
                .from("team_members")
                .select()
                .eq("team_id", value: teamId)
                .execute()
                .value
            
            await MainActor.run {
                navigateToTeamChat(team: team, members: members)
            }
        } catch {
            print("Error loading team details: \(error)")
            await MainActor.run {
                // Show error or navigate with basic data
                showAlert(title: "Error", message: "Failed to load team details")
            }
        }
    }

    private func navigateToTeamChat(team: BackendTeam, members: [TeamMember]) {
        if let navController = navigationController {
            print("Navigation controller exists")
            let teamChatVC = TeamChatViewController()
            teamChatVC.team = team
            teamChatVC.teamMembers = members
            navController.pushViewController(teamChatVC, animated: true)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        } else {
            print("No navigation controller found - presenting modally")
            let teamChatVC = TeamChatViewController()
            teamChatVC.team = team
            teamChatVC.teamMembers = members
            let navController = UINavigationController(rootViewController: teamChatVC)
            navController.modalPresentationStyle = .fullScreen
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
            present(navController, animated: true)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Team Management
    private func teamCreated(with teamName: String) {
        // Reload teams after creating a new one
        loadUserTeams()
        
        // Show success feedback
        let successLabel = UILabel()
        successLabel.text = "Team created successfully!"
        successLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .systemGreenDark : .systemGreen
        successLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        successLabel.textAlignment = .center
        successLabel.alpha = 0
        successLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(successLabel)
        
        NSLayoutConstraint.activate([
            successLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successLabel.bottomAnchor.constraint(equalTo: createButton.topAnchor, constant: -20)
        ])
        
        // Animate success message
        UIView.animate(withDuration: 0.3) {
            successLabel.alpha = 1
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                UIView.animate(withDuration: 0.3) {
                    successLabel.alpha = 0
                } completion: { _ in
                    successLabel.removeFromSuperview()
                }
            }
        }
    }
}

// MARK: - Data Models
struct TeamWithSport: Codable, Identifiable {
    let id: UUID
    let name: String
    let sport_id: Int
    let college_id: Int?
    let captain_id: UUID
    let created_at: String
    let sports: SportData?
    
    // Nested struct to match Supabase's nested response
    struct SportData: Codable {
        let id: Int
        let name: String
        let emoji: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case sport_id = "sport_id"
        case college_id = "college_id"
        case captain_id = "captain_id"
        case created_at = "created_at"
        case sports
    }
}

struct TeamMember: Codable {
    let id: Int
    let team_id: UUID
    let user_id: UUID
    let role: String
    let joined_at: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case team_id = "team_id"
        case user_id = "user_id"
        case role
        case joined_at = "joined_at"
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct TeamViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TeamViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            TeamViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct TeamViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TeamViewController {
        return TeamViewController()
    }
    
    func updateUIViewController(_ uiViewController: TeamViewController, context: Context) {
        // No update needed
    }
}
#endif
