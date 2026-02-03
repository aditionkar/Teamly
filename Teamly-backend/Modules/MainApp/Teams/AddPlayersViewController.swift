//
//  AddPlayersViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 28/01/26.
//

import UIKit
import Supabase

struct FriendWithProfile {
    let id: UUID
    let email: String?
    let name: String?
    
    var displayName: String {
        return name ?? email ?? "Unknown"
    }
}

// MARK: - Fix 1: Add Codable structs for database records
struct FriendRecord: Codable {
    let friend_id: UUID
}

struct TeamMemberRecord: Codable {
    let user_id: UUID
}

struct NewTeamMember: Codable {
    let team_id: UUID
    let user_id: UUID
    let role: String
    
    init(team_id: UUID, user_id: UUID, role: String = "member") {
        self.team_id = team_id
        self.user_id = user_id
        self.role = role
    }
}


class AddPlayersViewController: UIViewController {
    
    var team: BackendTeam?
    private var currentUserId: UUID?
    private var supabase: SupabaseClient {
        return SupabaseManager.shared.client
    }
    
    private var allFriends: [FriendWithProfile] = []
    private var filteredFriends: [FriendWithProfile] = []
    private var teamMemberIds: Set<UUID> = []
    private var selectedUserIds: Set<UUID> = []
    
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
        label.text = "Add Players"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search players"
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let playersTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No friends available to add"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        
        var title = AttributedString("Add")
        title.font = .systemFont(ofSize: 17, weight: .semibold)
        config.attributedTitle = title
        
        config.background.cornerRadius = 27
        
        button.configuration = config
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupSearchBar()
        updateColors()
        
        Task {
            await fetchCurrentUserId()
            await loadData()
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
    
    private func setupUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
        
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(glassBackButton)
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(playersTableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(addButton)
        
        setupConstraints()
        
        glassBackButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            glassBackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            glassBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            glassBackButton.widthAnchor.constraint(equalToConstant: 40),
            glassBackButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: glassBackButton.bottomAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            searchBar.heightAnchor.constraint(equalToConstant: 50),
            
            playersTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 30),
            playersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playersTableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -20),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 90),
            addButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    private func setupTableView() {
        playersTableView.register(PlayerCell.self, forCellReuseIdentifier: "PlayerCell")
        playersTableView.dataSource = self
        playersTableView.delegate = self
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        updateSearchBarColors()
    }
    
    // MARK: - Data Fetching
    private func fetchCurrentUserId() async {
        do {
            let session = try await supabase.auth.session
            currentUserId = session.user.id
            print("Current user ID: \(currentUserId?.uuidString ?? "nil")")
        } catch {
            print("Error fetching current user: \(error)")
        }
    }
    
    private func loadData() async {
        guard let currentUserId = currentUserId,
              let team = team else {
            print("Missing currentUserId or team")
            return
        }
        
        print("Loading data for user: \(currentUserId), team: \(team.id)")
        
        do {
            // First try using the RPC function
            let friends: [FriendResponse] = try await supabase
                .rpc("get_friends_not_in_team", params: [
                    "user_uuid": currentUserId,
                    "team_uuid": team.id
                ])
                .execute()
                .value
            
            print("RPC returned \(friends.count) friends")
            
            let mappedFriends = friends.map { friend in
                FriendWithProfile(
                    id: friend.id,
                    email: friend.email,
                    name: friend.name
                )
            }
            
            allFriends = mappedFriends
            filteredFriends = mappedFriends
            
            await MainActor.run {
                playersTableView.reloadData()
                updateEmptyState()
                updateAddButtonAppearance()
                
                if mappedFriends.isEmpty {
                    emptyStateLabel.text = "No friends available to add"
                }
            }
            
        } catch {
            print("RPC error: \(error)")
            print("Falling back to manual approach...")
            
            // Fallback to manual approach
            await loadDataManually()
        }
    }
    
    private func loadDataManually() async {
            guard let currentUserId = currentUserId,
                  let team = team else {
                return
            }
            
            do {
                // Step 1: Get all accepted friends
                let friends: [FriendRecord] = try await supabase
                    .from("friends")
                    .select("friend_id")
                    .eq("user_id", value: currentUserId)
                    .eq("status", value: "accepted")
                    .execute()
                    .value  // This automatically decodes to [FriendRecord]
                
                if friends.isEmpty {
                    print("No accepted friends found")
                    await MainActor.run {
                        allFriends = []
                        filteredFriends = []
                        playersTableView.reloadData()
                        updateEmptyState()
                    }
                    return
                }
                
                print("Found \(friends.count) accepted friends")
                
                // Step 2: Get current team members
                let teamMembers: [TeamMemberRecord] = try await supabase
                    .from("team_members")
                    .select("user_id")
                    .eq("team_id", value: team.id)
                    .execute()
                    .value  // This automatically decodes to [TeamMemberRecord]
                
                let teamMemberIds = Set(teamMembers.map { $0.user_id })
                
                print("Team has \(teamMemberIds.count) members")
                
                // Step 3: Get profiles for friends who are not team members
                var friendsToAdd: [FriendWithProfile] = []
                
                for friend in friends {
                    // Skip if friend is already in team
                    if teamMemberIds.contains(friend.friend_id) {
                        continue
                    }
                    
                    // Get profile for this friend
                    do {
                        let profile: Profile = try await supabase
                            .from("profiles")
                            .select()
                            .eq("id", value: friend.friend_id)
                            .single()
                            .execute()
                            .value
                        
                        // Get email from auth.users
                        let userEmail = try? await getEmailForUserId(friend.friend_id)
                        
                        friendsToAdd.append(FriendWithProfile(
                            id: friend.friend_id,
                            email: userEmail,
                            name: profile.name
                        ))
                    } catch {
                        print("Error fetching profile for friend \(friend.friend_id): \(error)")
                    }
                }
                
                print("Manual approach found \(friendsToAdd.count) friends to add")
                
                allFriends = friendsToAdd
                filteredFriends = friendsToAdd
                
                await MainActor.run {
                    playersTableView.reloadData()
                    updateEmptyState()
                    updateAddButtonAppearance()
                    
                    if friendsToAdd.isEmpty {
                        emptyStateLabel.text = "No friends available to add"
                    }
                }
                
            } catch {
                print("Manual approach error: \(error)")
                
                await MainActor.run {
                    showError(message: "Could not load friends list. Please try again later.")
                }
            }
        }
        
    
    private func getEmailForUserId(_ userId: UUID) async throws -> String? {
        do {
            // We need to use admin API or get email from profiles if stored
            // For now, return nil as email might not be accessible
            return nil
        } catch {
            return nil
        }
    }
    
    // MARK: - Helper Structs
    struct FriendResponse: Codable {
            let id: UUID
            let name: String?
            let email: String?
    }
    
    struct FriendRecord: Codable {
        let friend_id: UUID
    }
    
    struct TeamMemberRecord: Codable {
        let user_id: UUID
    }
    
    // MARK: - UI Updates
    private func updateEmptyState() {
        let isEmpty = filteredFriends.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        playersTableView.isHidden = isEmpty
        
        if isEmpty && !(searchBar.text?.isEmpty ?? true) {
            emptyStateLabel.text = "No friends found"
        } else {
            emptyStateLabel.text = "No friends available to add"
        }
    }
    
    private func filterFriends(with searchText: String) {
        if searchText.isEmpty {
            filteredFriends = allFriends
        } else {
            filteredFriends = allFriends.filter { friend in
                friend.displayName.lowercased().contains(searchText.lowercased())
            }
        }
        playersTableView.reloadData()
        updateEmptyState()
    }
    
    private func toggleUserSelection(_ friend: FriendWithProfile) {
        if selectedUserIds.contains(friend.id) {
            selectedUserIds.remove(friend.id)
        } else {
            selectedUserIds.insert(friend.id)
        }
        
        updateAddButtonAppearance()
        playersTableView.reloadData()
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        glassBackButton.backgroundColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.1) :
            UIColor(white: 0, alpha: 0.1)
        glassBackButton.layer.borderColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.2).cgColor :
            UIColor(white: 0, alpha: 0.2).cgColor
        glassBackButton.tintColor = .systemGreen
        
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        emptyStateLabel.textColor = isDarkMode ? .lightGray : .darkGray
        
        updateSearchBarColors()
        updateAddButtonAppearance()
        
        playersTableView.reloadData()
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
    
    private func updateSearchBarColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = isDarkMode ? .secondaryDark : .tertiaryLight
            textField.textColor = isDarkMode ? .white : .black
            
            let placeholderColor = isDarkMode ? UIColor.lightGray : UIColor.gray
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search friends...",
                attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
            )
            
            if let leftView = textField.leftView as? UIImageView {
                leftView.tintColor = isDarkMode ? .lightGray : .gray
            }
            
            if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
                let clearImage = clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
                clearButton.setImage(clearImage, for: .normal)
                clearButton.tintColor = isDarkMode ? .lightGray : .gray
            }
            
            textField.layer.cornerRadius = 12
            textField.clipsToBounds = true
        }
    }
    
    private func updateAddButtonAppearance() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        addButton.isEnabled = !selectedUserIds.isEmpty
        
        if addButton.isEnabled {
            addButton.configuration?.baseBackgroundColor = .systemGreenDark
            addButton.configuration?.baseForegroundColor = .primaryWhite
        } else {
            addButton.configuration?.baseBackgroundColor = isDarkMode ? .systemGray : .lightGray
            addButton.configuration?.baseForegroundColor = isDarkMode ? .darkGray : .white
        }
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func addButtonTapped() {
            guard let team = team else { return }
            
            let selectedFriends = allFriends.filter { selectedUserIds.contains($0.id) }
            
            Task {
                do {
                    // Add each selected friend to team_members
                    for friend in selectedFriends {
                        // Fix 4: Use a proper Codable struct instead of [String: Any]
                        let newMember = NewTeamMember(
                            team_id: team.id,
                            user_id: friend.id
                        )
                        
                        try await supabase
                            .from("team_members")
                            .insert(newMember)
                            .execute()
                        
                        print("Added \(friend.displayName) to team \(team.name)")
                    }
                    
                    // Show success message
                    await MainActor.run {
                        if selectedFriends.count == 1 {
                            showSuccessMessage("\(selectedFriends.first?.displayName ?? "Player") added to team!")
                        } else {
                            showSuccessMessage("\(selectedFriends.count) players added to team!")
                        }
                        
                        // Clear selection and refresh
                        selectedUserIds.removeAll()
                        updateAddButtonAppearance()
                        
                        // Remove added friends from the list
                        let addedFriendIds = Set(selectedFriends.map { $0.id })
                        allFriends = allFriends.filter { !addedFriendIds.contains($0.id) }
                        filteredFriends = allFriends
                        playersTableView.reloadData()
                        updateEmptyState()
                    }
                    
                } catch {
                    print("Error adding players: \(error)")
                    await MainActor.run {
                        showError(message: "Failed to add players. Please try again.")
                    }
                }
            }
        }
    
    
    
    private func showSuccessMessage(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if #available(iOS 13.0, *) {
            alert.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
        
        alert.view.tintColor = .systemGreen
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if #available(iOS 13.0, *) {
            alert.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
        
        alert.view.tintColor = .systemRed
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
}

extension AddPlayersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath) as? PlayerCell else {
            return UITableViewCell()
        }
        
        let friend = filteredFriends[indexPath.row]
        let isSelected = selectedUserIds.contains(friend.id)
        cell.configure(with: friend, isSelected: isSelected)
        
        cell.onSelectButtonTapped = { [weak self] in
            self?.toggleUserSelection(friend)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let friend = filteredFriends[indexPath.row]
        toggleUserSelection(friend)
    }
}

extension AddPlayersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterFriends(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

class PlayerCell: UITableViewCell {
    
    var onSelectButtonTapped: (() -> Void)?
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 30
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let checkmarkIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
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
        
        contentView.addSubview(containerView)
        containerView.addSubview(avatarView)
        avatarView.addSubview(avatarIcon)
        containerView.addSubview(nameLabel)
        containerView.addSubview(selectButton)
        selectButton.addSubview(checkmarkIcon)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            avatarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),
            
            avatarIcon.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 24),
            avatarIcon.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 20),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectButton.leadingAnchor, constant: -8),
            
            selectButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            selectButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            selectButton.widthAnchor.constraint(equalToConstant: 20),
            selectButton.heightAnchor.constraint(equalToConstant: 20),
            
            checkmarkIcon.centerXAnchor.constraint(equalTo: selectButton.centerXAnchor),
            checkmarkIcon.centerYAnchor.constraint(equalTo: selectButton.centerYAnchor),
            checkmarkIcon.widthAnchor.constraint(equalToConstant: 16),
            checkmarkIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        selectButton.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
    }
    
    func configure(with friend: FriendWithProfile, isSelected: Bool) {
        nameLabel.text = friend.displayName
        
        updateColors()
        updateSelectionState(isSelected: isSelected)
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        containerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        avatarView.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        avatarIcon.tintColor = isDarkMode ? UIColor.quaternaryLight : .quaternaryDark
        nameLabel.textColor = isDarkMode ? .white : .black
        checkmarkIcon.tintColor = .black
    }
    
    private func updateSelectionState(isSelected: Bool) {
        if isSelected {
            selectButton.backgroundColor = .systemGreenDark
            checkmarkIcon.isHidden = false
        } else {
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            selectButton.backgroundColor = isDarkMode ? UIColor.quaternaryDark : .quaternaryLight
            checkmarkIcon.isHidden = true
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    @objc private func selectButtonTapped() {
        onSelectButtonTapped?()
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct AddPlayersViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddPlayersViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            AddPlayersViewControllerRepresentable()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
        .ignoresSafeArea()
    }
}

struct AddPlayersViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = AddPlayersViewController()
        
        // Create sample team for preview
        viewController.team = BackendTeam(
            id: UUID(),
            name: "All Stars FC",
            sport_id: 1,
            captain_id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
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
