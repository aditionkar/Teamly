//
//  NotificationsViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 04/02/26.
//

import UIKit
import Supabase

class NotificationsViewController: UIViewController {
    
    // MARK: - Models
    enum NotificationType: String {
        case friendRequest = "friend_request"
        case friendRequestAccepted = "friend_request_accepted"
        case friendRequestDeclined = "friend_request_declined"
        case teamInvitation = "team_invitation"
        case teamInvitationAccepted = "team_invitation_accepted"
        case teamInvitationDeclined = "team_invitation_declined"
        
        var isExpandable: Bool {
            return self == .friendRequest || self == .teamInvitation
        }
    }
    
    struct Notification {
        let id: Int
        let senderId: UUID
        let receiverId: UUID
        let userName: String
        let message: String
        let type: NotificationType
        let createdAt: Date
        var isExpanded: Bool = false
    }
    
    struct NotificationInsert: Encodable {
        let sender_id: UUID
        let receiver_id: UUID
        let type: String
        let message: String
        let created_at: String
        let updated_at: String
    }
    
    
    // MARK: - Properties
    private var notifications: [Notification] = []
    private let supabase = SupabaseManager.shared.client
    private var currentUserId: UUID? = nil
    
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
        label.text = "Notifications"
        label.font = UIFont.systemFont(ofSize: 37, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
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
        setupTableView()
        fetchCurrentUserId()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if currentUserId != nil {
            fetchNotifications()
        }
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
            tableView.reloadData()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        updateColors()
        
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(glassBackButton)
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        glassBackButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            glassBackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            glassBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            glassBackButton.widthAnchor.constraint(equalToConstant: 40),
            glassBackButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: glassBackButton.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "NotificationCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
    }
    
    // MARK: - Data Fetching
    private func fetchCurrentUserId() {
        Task {
            do {
                let session = try await supabase.auth.session
                currentUserId = session.user.id
                await MainActor.run {
                    fetchNotifications()
                }
            } catch {
                print("Error fetching user session: \(error)")
                await MainActor.run {
                    showError("Failed to load user session")
                }
            }
        }
    }
    
    private func fetchNotifications() {
        guard let userId = currentUserId else {
            showError("User not logged in")
            return
        }
        
        loadingIndicator.startAnimating()
        
        Task {
            do {
                let fetchedNotifications: [SupabaseNotification] = try await supabase
                    .from("notifications")
                    .select()
                    .eq("receiver_id", value: userId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                var transformedNotifications: [Notification] = []
                
                for fetchedNotif in fetchedNotifications {
                    guard let type = NotificationType(rawValue: fetchedNotif.type) else {
                        continue
                    }
                    
                    switch type {
                    case .friendRequestAccepted, .teamInvitationAccepted:
                        guard fetchedNotif.message.lowercased().contains("accepted") else { continue }
                    case .friendRequestDeclined, .teamInvitationDeclined:
                        guard fetchedNotif.message.lowercased().contains("declined") else { continue }
                    default:
                        break
                    }
                    
                    let (userName, message) = parseNotificationMessage(fetchedNotif.message)
                    let senderName = try await fetchUserName(userId: fetchedNotif.senderId)
                    let finalName = senderName ?? userName
                    
                    let notification = Notification(
                        id: fetchedNotif.id,
                        senderId: fetchedNotif.senderId,
                        receiverId: fetchedNotif.receiverId,
                        userName: finalName,
                        message: message,
                        type: type,
                        createdAt: fetchedNotif.createdAt
                    )
                    
                    transformedNotifications.append(notification)
                }
                
                await MainActor.run {
                    self.notifications = transformedNotifications
                    self.loadingIndicator.stopAnimating()
                    self.tableView.reloadData()
                    
                    if transformedNotifications.isEmpty {
                        self.showEmptyState()
                    }
                }
                
            } catch {
                print("Error fetching notifications: \(error)")
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.showError("Failed to load notifications")
                }
            }
        }
    }
    
    private func fetchUserName(userId: UUID) async throws -> String? {
        do {
            let profile: Profile? = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            return profile?.name
        } catch {
            print("Error fetching user name: \(error)")
            return nil
        }
    }
    
    private func parseNotificationMessage(_ fullMessage: String) -> (name: String, message: String) {
        let components = fullMessage.components(separatedBy: " ")
        guard components.count > 1 else { return ("", fullMessage) }
        let name = components[0]
        let message = components[1...].joined(separator: " ")
        return (name, message)
    }
    
    // MARK: - Friend Request Handling
    private func handleFriendRequestAction(notificationId: Int, action: String, cell: NotificationCell) {
        guard let notification = notifications.first(where: { $0.id == notificationId }) else { return }
        
        Task {
            do {
                let updateType: String = action == "accept" ? "friend_request_accepted" : "friend_request_declined"
                
                struct NotificationUpdate: Encodable {
                    let type: String
                    let updated_at: String
                }
                
                let updateData = NotificationUpdate(
                    type: updateType,
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )

                try await supabase
                    .from("notifications")
                    .update(updateData)
                    .eq("id", value: notificationId)
                    .execute()
                
                let receiverName = try await fetchUserName(userId: notification.receiverId)
                
                let newNotificationMessage: String
                if action == "accept" {
                    newNotificationMessage = "\(receiverName ?? "User") accepted your friend request"
                } else {
                    newNotificationMessage = "\(receiverName ?? "User") declined your friend request"
                }
                
                let newNotification = NotificationInsert(
                    sender_id: notification.receiverId,
                    receiver_id: notification.senderId,
                    type: updateType,
                    message: newNotificationMessage,
                    created_at: ISO8601DateFormatter().string(from: Date()),
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                
                try await supabase
                    .from("notifications")
                    .insert(newNotification)
                    .execute()
                
                if action == "accept" {
                    try await createAcceptedFriendship(senderId: notification.senderId, receiverId: notification.receiverId)
                } else {
                    try await deletePendingFriendship(senderId: notification.senderId, receiverId: notification.receiverId)
                }
                
                await MainActor.run {
                    notifications.removeAll { $0.id == notificationId }
                    tableView.reloadData()
                    
                    if action == "accept" {
                        showAlert(title: "Friend Request Accepted", message: "You and \(notification.userName) are now friends!")
                    } else {
                        showAlert(title: "Friend Request Declined", message: "You declined \(notification.userName)'s friend request.")
                    }
                }
                
            } catch {
                print("Error handling friend request: \(error)")
                await MainActor.run { showError("Failed to process friend request") }
            }
        }
    }
    
    // MARK: - Team Invitation Handling
    private func handleTeamInvitationAction(notificationId: Int, action: String) {
        guard let notification = notifications.first(where: { $0.id == notificationId }) else { return }
        
        Task {
            do {
                let updateType: String = action == "accept" ? "team_invitation_accepted" : "team_invitation_declined"
                let receiverName = try await fetchUserName(userId: notification.receiverId) ?? "User"
                let teamName = extractTeamName(from: notification.message)
                
                struct NotificationUpdate: Encodable {
                    let type: String
                    let updated_at: String
                }
                
                let updateData = NotificationUpdate(
                    type: updateType,
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                
                try await supabase
                    .from("notifications")
                    .update(updateData)
                    .eq("id", value: notificationId)
                    .execute()
                
                let responseMessage: String
                if action == "accept" {
                    responseMessage = "\(receiverName) accepted your invite to join team \(teamName)"
                } else {
                    responseMessage = "\(receiverName) declined your invite to join team \(teamName)"
                }
                
                let responseNotification = NotificationInsert(
                    sender_id: notification.receiverId,
                    receiver_id: notification.senderId,
                    type: updateType,
                    message: responseMessage,
                    created_at: ISO8601DateFormatter().string(from: Date()),
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                
                try await supabase
                    .from("notifications")
                    .insert(responseNotification)
                    .execute()
                
                if action == "accept" {
                    try await addUserAsTeamMember(
                        userId: notification.receiverId,
                        senderId: notification.senderId,
                        teamName: teamName
                    )
                }
                
                await MainActor.run {
                    notifications.removeAll { $0.id == notificationId }
                    tableView.reloadData()
                    if notifications.isEmpty { showEmptyState() }
                    
                    if action == "accept" {
                        showAlert(title: "Team Joined!", message: "You have joined the team \(teamName).")
                    } else {
                        showAlert(title: "Invitation Declined", message: "You declined the invitation to join \(teamName).")
                    }
                }
                
            } catch {
                print("Error handling team invitation: \(error)")
                await MainActor.run { showError("Failed to process team invitation") }
            }
        }
    }
    
    private func extractTeamName(from message: String) -> String {
        let anchor = "to join their "
        if let anchorRange = message.range(of: anchor) {
            let afterAnchor = String(message[anchorRange.upperBound...])
            if let teamRange = afterAnchor.range(of: " team ") {
                let teamName = String(afterAnchor[teamRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !teamName.isEmpty { return teamName }
            }
        }
        if let range = message.range(of: " team ", options: .backwards) {
            let teamName = String(message[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !teamName.isEmpty { return teamName }
        }
        return "Unknown Team"
    }
    
    private func addUserAsTeamMember(userId: UUID, senderId: UUID, teamName: String) async throws {
        print("🔍 Looking for team named '\(teamName)' with captain \(senderId)")
        
        var teams: [TeamResponse] = try await supabase
            .from("teams")
            .select()
            .eq("name", value: teamName)
            .eq("captain_id", value: senderId)
            .limit(1)
            .execute()
            .value
        
        if teams.isEmpty {
            print("⚠️ No team found with captain filter, trying name-only lookup")
            teams = try await supabase
                .from("teams")
                .select()
                .eq("name", value: teamName)
                .limit(1)
                .execute()
                .value
        }
        
        guard let team = teams.first else {
            throw NSError(domain: "TeamInvitation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find team '\(teamName)'"])
        }
        
        print("✅ Found team: \(team.name) (id: \(team.id))")
        
        struct NewTeamMember: Codable {
            let team_id: String
            let user_id: String
            let role: String
        }
        
        let member = NewTeamMember(
            team_id: team.id.uuidString,
            user_id: userId.uuidString,
            role: "member"
        )
        
        try await supabase
            .from("team_members")
            .insert(member)
            .execute()
        
        print("✅ User \(userId) added as member to team \(teamName)")
    }
    
    // MARK: - Friendship Helpers
    private func createAcceptedFriendship(senderId: UUID, receiverId: UUID) async throws {
        struct FriendshipUpdate: Encodable {
            let user_id: UUID
            let friend_id: UUID
            let status: String
            let created_at: String
            let updated_at: String
        }
        
        let friendship1 = FriendshipUpdate(
            user_id: senderId, friend_id: receiverId, status: "accepted",
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        let friendship2 = FriendshipUpdate(
            user_id: receiverId, friend_id: senderId, status: "accepted",
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            let existingFriendship1: Friendship? = try await supabase
                .from("friends").select()
                .eq("user_id", value: senderId).eq("friend_id", value: receiverId)
                .single().execute().value
            
            if let existing = existingFriendship1 {
                let updated = FriendshipUpdate(user_id: existing.user_id, friend_id: existing.friend_id,
                    status: "accepted", created_at: existing.created_at,
                    updated_at: ISO8601DateFormatter().string(from: Date()))
                try await supabase.from("friends").update(updated).eq("id", value: existing.id).execute()
            } else {
                try await supabase.from("friends").insert(friendship1).execute()
            }
            
            let existingFriendship2: Friendship? = try await supabase
                .from("friends").select()
                .eq("user_id", value: receiverId).eq("friend_id", value: senderId)
                .single().execute().value
            
            if let existing = existingFriendship2 {
                let updated = FriendshipUpdate(user_id: existing.user_id, friend_id: existing.friend_id,
                    status: "accepted", created_at: existing.created_at,
                    updated_at: ISO8601DateFormatter().string(from: Date()))
                try await supabase.from("friends").update(updated).eq("id", value: existing.id).execute()
            } else {
                try await supabase.from("friends").insert(friendship2).execute()
            }
            
        } catch {
            if let supabaseError = error as? PostgrestError, supabaseError.code == "PGRST116" {
                try await supabase.from("friends").insert([friendship1, friendship2]).execute()
            } else {
                throw error
            }
        }
    }

    private func deletePendingFriendship(senderId: UUID, receiverId: UUID) async throws {
        try await supabase
            .from("friends").delete()
            .eq("user_id", value: senderId).eq("friend_id", value: receiverId)
            .eq("status", value: "pending").execute()
    }
    
    private func createFriendship(senderId: UUID, receiverId: UUID) async throws {
        try await createAcceptedFriendship(senderId: senderId, receiverId: receiverId)
    }
    
    // MARK: - Helper Methods
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "No notifications yet"
        emptyLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundView = emptyLabel
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        updateGlassButtonAppearance(isDarkMode: isDarkMode)
        tableView.backgroundColor = .clear
        loadingIndicator.color = isDarkMode ? .primaryWhite : .primaryBlack
    }
    
    private func updateGradientColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        if isDarkMode {
            let darkGreen = UIColor(red: 0.0, green: 0.15, blue: 0.0, alpha: 1.0)
            gradientLayer.colors = [darkGreen.cgColor, UIColor.clear.cgColor]
        } else {
            let lightGreen = UIColor(red: 53/255, green: 199/255, blue: 89/255, alpha: 0.3)
            gradientLayer.colors = [lightGreen.cgColor, UIColor.clear.cgColor]
        }
        gradientLayer.locations = [0.0, 0.25]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }
    
    private func updateGlassButtonAppearance(isDarkMode: Bool) {
        glassBackButton.backgroundColor = isDarkMode ? UIColor(white: 1, alpha: 0.1) : UIColor(white: 0, alpha: 0.05)
        glassBackButton.layer.borderColor = (isDarkMode ? UIColor(white: 1, alpha: 0.2) : UIColor(white: 0, alpha: 0.1)).cgColor
        glassBackButton.tintColor = isDarkMode ? .systemGreenDark : .systemGreen
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension NotificationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as? NotificationCell else {
            return UITableViewCell()
        }
        let notification = notifications[indexPath.row]
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        cell.configure(with: notification, isDarkMode: isDarkMode)
        cell.delegate = self
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = notifications[indexPath.row]
        if notification.type.isExpandable {
            notifications[indexPath.row].isExpanded.toggle()
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let notification = self.notifications[indexPath.row]
            Task {
                do {
                    try await self.supabase
                        .from("notifications").delete()
                        .eq("id", value: notification.id).execute()
                    await MainActor.run {
                        self.notifications.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        if self.notifications.isEmpty { self.showEmptyState() }
                    }
                    completionHandler(true)
                } catch {
                    print("Error deleting notification: \(error)")
                    await MainActor.run {
                        self.showError("Failed to delete notification")
                        completionHandler(false)
                    }
                }
            }
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - NotificationCellDelegate
extension NotificationsViewController: NotificationCellDelegate {
    func notificationCell(_ cell: NotificationCell, didTapAccept notification: Notification) {
        switch notification.type {
        case .friendRequest:
            handleFriendRequestAction(notificationId: notification.id, action: "accept", cell: cell)
        case .teamInvitation:
            handleTeamInvitationAction(notificationId: notification.id, action: "accept")
        default:
            break
        }
    }
    
    func notificationCell(_ cell: NotificationCell, didTapDecline notification: Notification) {
        switch notification.type {
        case .friendRequest:
            handleFriendRequestAction(notificationId: notification.id, action: "decline", cell: cell)
        case .teamInvitation:
            handleTeamInvitationAction(notificationId: notification.id, action: "decline")
        default:
            break
        }
    }
    
    func notificationCellDidTapName(_ cell: NotificationCell, notification: Notification) {
        navigateToUserProfile(userId: notification.senderId, userName: notification.userName)
    }
}

extension NotificationsViewController {
    private func navigateToUserProfile(userId: UUID, userName: String) {
        let profileVC = UserProfileViewController()
        profileVC.userId = userId
        profileVC.modalPresentationStyle = .fullScreen
        if let navigationController = navigationController {
            navigationController.pushViewController(profileVC, animated: true)
        } else {
            let navController = UINavigationController(rootViewController: profileVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
}

// MARK: - Supabase Models
struct SupabaseNotification: Codable {
    let id: Int
    let senderId: UUID
    let receiverId: UUID
    let type: String
    let message: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case type
        case message
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - NotificationCell Protocol
protocol NotificationCellDelegate: AnyObject {
    func notificationCell(_ cell: NotificationCell, didTapAccept notification: NotificationsViewController.Notification)
    func notificationCell(_ cell: NotificationCell, didTapDecline notification: NotificationsViewController.Notification)
    func notificationCellDidTapName(_ cell: NotificationCell, notification: NotificationsViewController.Notification)
}

// MARK: - NotificationCell
class NotificationCell: UITableViewCell {
    weak var delegate: NotificationCellDelegate?
    private var notification: NotificationsViewController.Notification?
    private let nameTapGesture = UITapGestureRecognizer()
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        imageView.image = UIImage(systemName: "person.fill", withConfiguration: config)
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Collapsed: single-line truncated message (no buttons visible)
    private let messageCollapsedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Expanded: multi-line message (buttons visible to the right)
    private let messageExpandedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Circular Action Buttons (right side, shown only when expanded)
    
    /// Green circle with ✓
    private let acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        button.setImage(UIImage(systemName: "checkmark", withConfiguration: config), for: .normal)
        button.tintColor = .systemGreen
        //button.backgroundColor = UIColor(red: 0.18, green: 0.75, blue: 0.35, alpha: 1.0)
        return button
    }()
    
    /// Dark circle with ✕
    private let declineButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .systemRed
        return button
    }()
    
    private lazy var actionButtonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [acceptButton, declineButton])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.isHidden = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Collapsed-mode trailing constraint alternatives
    private var collapsedTrailingFull: NSLayoutConstraint!    // to container edge (buttons hidden)
    private var collapsedTrailingShort: NSLayoutConstraint!   // stops before buttons (not used in collapsed; kept for safety)
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(avatarView)
        avatarView.addSubview(avatarIcon)
        containerView.addSubview(nameLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(messageCollapsedLabel)
        containerView.addSubview(messageExpandedLabel)
        containerView.addSubview(actionButtonStack)
        
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        declineButton.addTarget(self, action: #selector(declineTapped), for: .touchUpInside)
        nameLabel.isUserInteractionEnabled = true
        nameTapGesture.addTarget(self, action: #selector(nameLabelTapped))
        nameLabel.addGestureRecognizer(nameTapGesture)
        
        // These two constraints are mutually exclusive based on expand state
        collapsedTrailingFull = messageCollapsedLabel.trailingAnchor.constraint(
            equalTo: containerView.trailingAnchor, constant: -16)
        collapsedTrailingShort = messageCollapsedLabel.trailingAnchor.constraint(
            equalTo: actionButtonStack.leadingAnchor, constant: -12)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Avatar — centred vertically in the container
            avatarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            avatarView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 36),
            avatarView.heightAnchor.constraint(equalToConstant: 36),
            avatarIcon.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            // Name row
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),
            
            timeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // COLLAPSED message — single line, trailing to container edge (default)
            messageCollapsedLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            messageCollapsedLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            //messageCollapsedLabel.leadingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            messageCollapsedLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            // EXPANDED message — multi-line, trailing stops before buttons
            messageExpandedLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            messageExpandedLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            messageExpandedLabel.trailingAnchor.constraint(equalTo: actionButtonStack.leadingAnchor, constant: -12),
            messageExpandedLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            // Circular buttons — centred vertically, pinned to trailing edge
            actionButtonStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 10),
            actionButtonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            
            acceptButton.widthAnchor.constraint(equalToConstant: 40),
            acceptButton.heightAnchor.constraint(equalToConstant: 40),
            declineButton.widthAnchor.constraint(equalToConstant: 40),
            declineButton.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        // Start in collapsed state
        collapsedTrailingFull.isActive = true
    }
    
    // MARK: - Configure
    func configure(with notification: NotificationsViewController.Notification, isDarkMode: Bool) {
        self.notification = notification
        
        updateColors(isDarkMode: isDarkMode)
        updateAvatarIcon(for: notification.type)
        
        nameLabel.text = notification.userName
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        timeLabel.text = formatter.localizedString(for: notification.createdAt, relativeTo: Date())
        
        let showExpanded = notification.isExpanded && notification.type.isExpandable
        
        if showExpanded {
            // Expanded state: full message + circular buttons on the right
            messageCollapsedLabel.isHidden = true
            collapsedTrailingFull.isActive = false
            collapsedTrailingShort.isActive = false
            
            messageExpandedLabel.isHidden = false
            messageExpandedLabel.text = notification.message
            
            actionButtonStack.isHidden = false
            acceptButton.isHidden = false
            declineButton.isHidden = false
        } else {
            // Collapsed state: single-line truncated, no buttons
            messageExpandedLabel.isHidden = true
            actionButtonStack.isHidden = true
            acceptButton.isHidden = true
            declineButton.isHidden = true
            
            messageCollapsedLabel.isHidden = false
            messageCollapsedLabel.text = notification.message
            
            collapsedTrailingShort.isActive = false
            collapsedTrailingFull.isActive = true
        }
    }
    
    // MARK: - Helpers
    private func updateAvatarIcon(for type: NotificationsViewController.NotificationType) {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        switch type {
        case .teamInvitation, .teamInvitationAccepted, .teamInvitationDeclined:
            avatarIcon.image = UIImage(systemName: "person.fill", withConfiguration: config)
        default:
            avatarIcon.image = UIImage(systemName: "person.fill", withConfiguration: config)
        }
    }
    
    private func updateColors(isDarkMode: Bool) {
        containerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        avatarView.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        avatarIcon.tintColor = isDarkMode ? UIColor.quaternaryLight : .quaternaryDark
        
        nameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        let msgColor: UIColor = isDarkMode
            ? UIColor(white: 0.70, alpha: 1.0)
            : UIColor(white: 0.35, alpha: 1.0)
        messageCollapsedLabel.textColor = msgColor
        messageExpandedLabel.textColor = msgColor
        
        timeLabel.textColor = UIColor(white: 0.5, alpha: 1.0)
        
        // Accept — always green circle, white checkmark
        //acceptButton.backgroundColor = UIColor(red: 0.18, green: 0.75, blue: 0.35, alpha: 1.0)
        
        
        acceptButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        declineButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        
        acceptButton.tintColor = .systemGreen
        declineButton.tintColor = .systemRed
        
//        // Decline — dark circle, red X
//        declineButton.backgroundColor = isDarkMode
//            ? UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1.0)
//            : UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
//        declineButton.tintColor = isDarkMode
//            ? UIColor(red: 1.0, green: 0.27, blue: 0.27, alpha: 1.0)
//            : UIColor(red: 0.85, green: 0.12, blue: 0.12, alpha: 1.0)
    }
    
    // MARK: - Actions
    @objc private func acceptTapped() {
        guard let notification = notification else { return }
        delegate?.notificationCell(self, didTapAccept: notification)
    }
    
    @objc private func declineTapped() {
        guard let notification = notification else { return }
        delegate?.notificationCell(self, didTapDecline: notification)
    }
    
    @objc private func nameLabelTapped() {
        UIView.animate(withDuration: 0.1, animations: { self.nameLabel.alpha = 0.5 }) { _ in
            UIView.animate(withDuration: 0.1) { self.nameLabel.alpha = 1.0 }
        }
        guard let notification = notification else { return }
        delegate?.notificationCellDidTapName(self, notification: notification)
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct NotificationsViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NotificationsViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            NotificationsViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct NotificationsViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NotificationsViewController {
        return NotificationsViewController()
    }
    func updateUIViewController(_ uiViewController: NotificationsViewController, context: Context) {}
}
#endif
