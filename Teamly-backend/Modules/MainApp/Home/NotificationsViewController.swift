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
            tableView.reloadData() // Reload table to update cell colors
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Set initial background color based on current mode
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
                // Fetch notifications where the current user is the receiver
                let fetchedNotifications: [SupabaseNotification] = try await supabase
                    .from("notifications")
                    .select()
                    .eq("receiver_id", value: userId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                // Transform Supabase data to our Notification model
                var transformedNotifications: [Notification] = []
                
                for fetchedNotif in fetchedNotifications {
                    // Parse the message to extract name and actual message
                    let (userName, message) = parseNotificationMessage(fetchedNotif.message)
                    
                    // Fetch sender's name from profiles table using your existing Profile struct
                    let senderName = try await fetchUserName(userId: fetchedNotif.senderId)
                    
                    // Use the sender's actual name instead of parsed name for consistency
                    let finalName = senderName ?? userName
                    
                    guard let type = NotificationType(rawValue: fetchedNotif.type) else {
                        continue
                    }
                    
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
            // Using your existing Profile struct from other file
            let profile: Profile? = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            return profile?.name // Changed from fullName to name to match your Profile struct
        } catch {
            print("Error fetching user name: \(error)")
            return nil
        }
    }
    
    private func parseNotificationMessage(_ fullMessage: String) -> (name: String, message: String) {
        // Split the message by spaces
        let components = fullMessage.components(separatedBy: " ")
        
        guard components.count > 1 else {
            return ("", fullMessage)
        }
        
        // First word is the name
        let name = components[0]
        
        // Rest is the message
        let message = components[1...].joined(separator: " ")
        
        return (name, message)
    }
    
    private func handleFriendRequestAction(notificationId: Int, action: String, cell: NotificationCell) {
        guard let notification = notifications.first(where: { $0.id == notificationId }) else { return }
        
        Task {
            do {
                // 1. Update the existing notification type in database
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
                
                // 2. Create a new notification for the sender (interchanged sender/receiver)
                let senderName = try await fetchUserName(userId: notification.senderId)
                let receiverName = try await fetchUserName(userId: notification.receiverId)
                
                let newNotificationMessage: String
                if action == "accept" {
                    newNotificationMessage = "\(receiverName ?? "User") accepted your friend request"
                } else {
                    newNotificationMessage = "\(receiverName ?? "User") declined your friend request"
                }
                
                let newNotification = NotificationInsert(
                    sender_id: notification.receiverId, // Interchanged: original receiver becomes sender
                    receiver_id: notification.senderId, // Interchanged: original sender becomes receiver
                    type: updateType,
                    message: newNotificationMessage,
                    created_at: ISO8601DateFormatter().string(from: Date()),
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                
                try await supabase
                    .from("notifications")
                    .insert(newNotification)
                    .execute()
                
                // 3. Handle friends table based on action
                if action == "accept" {
                    try await createAcceptedFriendship(senderId: notification.senderId, receiverId: notification.receiverId)
                } else {
                    // For decline, just delete any existing pending friend request
                    try await deletePendingFriendship(senderId: notification.senderId, receiverId: notification.receiverId)
                }
                
                await MainActor.run {
                    // Remove the notification from local array
                    notifications.removeAll { $0.id == notificationId }
                    tableView.reloadData()
                    
                    if action == "accept" {
                        // Show success message
                        showAlert(title: "Friend Request Accepted", message: "You and \(notification.userName) are now friends!")
                    } else {
                        // Show declined message
                        showAlert(title: "Friend Request Declined", message: "You declined \(notification.userName)'s friend request.")
                    }
                }
                
            } catch {
                print("Error handling friend request: \(error)")
                await MainActor.run {
                    showError("Failed to process friend request")
                }
            }
        }
    }
    
    private func createAcceptedFriendship(senderId: UUID, receiverId: UUID) async throws {
        // Create a new struct for friendship updates that excludes the id
        struct FriendshipUpdate: Encodable {
            let user_id: UUID
            let friend_id: UUID
            let status: String
            let created_at: String
            let updated_at: String
        }
        
        // Create two rows in friends table for bidirectional friendship
        
        // First friendship: sender -> receiver
        let friendship1 = FriendshipUpdate(
            user_id: senderId,
            friend_id: receiverId,
            status: "accepted",
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        // Second friendship: receiver -> sender
        let friendship2 = FriendshipUpdate(
            user_id: receiverId,
            friend_id: senderId,
            status: "accepted",
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        // Try to update existing records first, if they exist
        do {
            // Check if sender->receiver friendship exists
            let existingFriendship1: Friendship? = try await supabase
                .from("friends")
                .select()
                .eq("user_id", value: senderId)
                .eq("friend_id", value: receiverId)
                .single()
                .execute()
                .value
            
            if let existing = existingFriendship1 {
                // Update existing record
                let updatedFriendship1 = FriendshipUpdate(
                    user_id: existing.user_id,
                    friend_id: existing.friend_id,
                    status: "accepted",
                    created_at: existing.created_at,
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                
                try await supabase
                    .from("friends")
                    .update(updatedFriendship1)
                    .eq("id", value: existing.id)
                    .execute()
            } else {
                // Insert new record
                try await supabase
                    .from("friends")
                    .insert(friendship1)
                    .execute()
            }
            
            // Check if receiver->sender friendship exists
            let existingFriendship2: Friendship? = try await supabase
                .from("friends")
                .select()
                .eq("user_id", value: receiverId)
                .eq("friend_id", value: senderId)
                .single()
                .execute()
                .value
            
            if let existing = existingFriendship2 {
                // Update existing record
                let updatedFriendship2 = FriendshipUpdate(
                    user_id: existing.user_id,
                    friend_id: existing.friend_id,
                    status: "accepted",
                    created_at: existing.created_at,
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                
                try await supabase
                    .from("friends")
                    .update(updatedFriendship2)
                    .eq("id", value: existing.id)
                    .execute()
            } else {
                // Insert new record
                try await supabase
                    .from("friends")
                    .insert(friendship2)
                    .execute()
            }
            
            print("Created/updated bidirectional friendships: \(senderId) ↔ \(receiverId)")
            
        } catch {
            // If single() fails (no records), insert both new records
            if let supabaseError = error as? PostgrestError,
               supabaseError.code == "PGRST116" { // No rows found
                try await supabase
                    .from("friends")
                    .insert([friendship1, friendship2])
                    .execute()
                
                print("Created new bidirectional friendships: \(senderId) ↔ \(receiverId)")
            } else {
                throw error
            }
        }
    }

    private func deletePendingFriendship(senderId: UUID, receiverId: UUID) async throws {
        // Delete any pending friend requests between these users
        // We only delete if status is 'pending'
        
        try await supabase
            .from("friends")
            .delete()
            .eq("user_id", value: senderId)
            .eq("friend_id", value: receiverId)
            .eq("status", value: "pending")
            .execute()
        
        print("Deleted pending friendship request: \(senderId) → \(receiverId)")
    }
    
    private func createFriendship(senderId: UUID, receiverId: UUID) async throws {
        // This function now redirects to createAcceptedFriendship
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
        
        // Update view background
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Update title label
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update glass button
        updateGlassButtonAppearance(isDarkMode: isDarkMode)
        
        // Update table view background
        tableView.backgroundColor = .clear
        
        // Update loading indicator
        loadingIndicator.color = isDarkMode ? .primaryWhite : .primaryBlack
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
        glassBackButton.tintColor = isDarkMode ? .systemGreenDark : .systemGreen
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        // Check if we're in a navigation controller stack
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            // Pop back to HomeViewController
            navigationController.popViewController(animated: true)
        } else {
            // We were presented modally, so dismiss
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
        var notification = notifications[indexPath.row]
        
        if notification.type == .friendRequest {
            notification.isExpanded.toggle()
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
                    // Delete from database
                    try await self.supabase
                        .from("notifications")
                        .delete()
                        .eq("id", value: notification.id)
                        .execute()
                    
                    await MainActor.run {
                        // Remove from local array
                        self.notifications.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        
                        if self.notifications.isEmpty {
                            self.showEmptyState()
                        }
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
        print("Accepted: \(notification.userName)")
        handleFriendRequestAction(notificationId: notification.id, action: "accept", cell: cell)
    }
    
    func notificationCell(_ cell: NotificationCell, didTapDecline notification: Notification) {
        print("Declined: \(notification.userName)")
        handleFriendRequestAction(notificationId: notification.id, action: "decline", cell: cell)
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

// MARK: - NotificationCell
protocol NotificationCellDelegate: AnyObject {
    func notificationCell(_ cell: NotificationCell, didTapAccept notification: NotificationsViewController.Notification)
    func notificationCell(_ cell: NotificationCell, didTapDecline notification: NotificationsViewController.Notification)
}

class NotificationCell: UITableViewCell {
    weak var delegate: NotificationCellDelegate?
    private var notification: NotificationsViewController.Notification?
    private var isDarkMode: Bool = true
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
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
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        imageView.image = UIImage(systemName: "person.fill", withConfiguration: config)
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let image = UIImage(systemName: "checkmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let declineButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 15
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var expandedConstraints: [NSLayoutConstraint] = []
    private var collapsedConstraints: [NSLayoutConstraint] = []
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(avatarView)
        avatarView.addSubview(avatarIcon)
        containerView.addSubview(nameLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
        
        buttonStack.addArrangedSubview(acceptButton)
        buttonStack.addArrangedSubview(declineButton)
        containerView.addSubview(buttonStack)
        
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        declineButton.addTarget(self, action: #selector(declineTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            avatarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            avatarView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            avatarView.widthAnchor.constraint(equalToConstant: 35),
            avatarView.heightAnchor.constraint(equalToConstant: 35),
            
            avatarIcon.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            messageLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: buttonStack.leadingAnchor, constant: -12),

            buttonStack.centerYAnchor.constraint(equalTo: messageLabel.centerYAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            
            acceptButton.widthAnchor.constraint(equalToConstant: 44),
            acceptButton.heightAnchor.constraint(equalToConstant: 44),
            declineButton.widthAnchor.constraint(equalToConstant: 44),
            declineButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        collapsedConstraints = [
            containerView.heightAnchor.constraint(equalToConstant: 80)
        ]
        
        expandedConstraints = [
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ]
    }
    
    func configure(with notification: NotificationsViewController.Notification, isDarkMode: Bool) {
        self.notification = notification
        self.isDarkMode = isDarkMode
        
        // Update colors based on mode
        updateColors(isDarkMode: isDarkMode)
        
        nameLabel.text = notification.userName
        
        // Format the time
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let relativeTime = formatter.localizedString(for: notification.createdAt, relativeTo: Date())
        timeLabel.text = relativeTime
        
        if notification.isExpanded && notification.type == .friendRequest {
            messageLabel.text = notification.message
            buttonStack.isHidden = false
            NSLayoutConstraint.deactivate(collapsedConstraints)
            NSLayoutConstraint.activate(expandedConstraints)
        } else {
            messageLabel.text = notification.message
            buttonStack.isHidden = true
            NSLayoutConstraint.deactivate(expandedConstraints)
            NSLayoutConstraint.activate(collapsedConstraints)
        }
        
        // Hide buttons for non-friend-request notifications
        if notification.type != .friendRequest {
            buttonStack.isHidden = true
        }
    }
    
    private func updateColors(isDarkMode: Bool) {
        // Update container view
        containerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        // Update avatar view
        avatarView.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        
        // Update avatar icon
        avatarIcon.tintColor = isDarkMode ?
        UIColor.quaternaryLight :
            .quaternaryDark
        
        // Update labels
        nameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        messageLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        timeLabel.textColor = isDarkMode ?
            UIColor(white: 0.5, alpha: 1.0) :
            UIColor(white: 0.4, alpha: 1.0)
        
        // Update button backgrounds and tints
        let buttonBackground = isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight
        acceptButton.backgroundColor = buttonBackground
        declineButton.backgroundColor = buttonBackground
        
        // Button tints use system colors that remain consistent
        acceptButton.tintColor = .systemGreen
        declineButton.tintColor = .systemRed
    }
    
    @objc private func acceptTapped() {
        guard let notification = notification else { return }
        delegate?.notificationCell(self, didTapAccept: notification)
    }
    
    @objc private func declineTapped() {
        guard let notification = notification else { return }
        delegate?.notificationCell(self, didTapDecline: notification)
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
    
    func updateUIViewController(_ uiViewController: NotificationsViewController, context: Context) {
        // No update needed
    }
}
#endif
