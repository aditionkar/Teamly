//
//  TeamChatViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 28/01/26.
//

import UIKit
import Supabase
import Combine

// MARK: - Backend Data Mo dels
struct BackendTeam: Codable, Identifiable {
    let id: UUID
    let name: String
    let sport_id: Int
    let captain_id: UUID
    let college_id: Int?
    let created_at: String
    
    var sportId: Int {
        return sport_id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case sport_id = "sport_id"
        case captain_id = "captain_id"
        case college_id = "college_id"
        case created_at = "created_at"
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let team_id: UUID
    let user_id: UUID
    let message: String
    let created_at: Date
    var sender_name: String?
    var sender_profile_pic: String?
    
    enum CodingKeys: String, CodingKey {
        case id, team_id, user_id, message, created_at
    }
}

struct ChatMessageUI {
    let id: String
    let text: String
    let isFromCurrentUser: Bool
    let timestamp: Date
    let senderName: String?
    let senderProfilePic: String?
}

class TeamChatViewController: UIViewController {
    
    // MARK: - Properties
    var team: BackendTeam?
    var teamMembers: [TeamMember] = []
    private var messages: [ChatMessageUI] = []
    private var currentUserId: UUID?
    private var senderCache: [UUID: (name: String, profilePic: String?)] = [:]
    private var refreshTimer: Timer?
    private var lastPollTime: Date = Date()
    
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
    
    private let titleButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        button.contentHorizontalAlignment = .left
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let messageInputContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Message here"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.layer.cornerRadius = 20
        textField.clipsToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "paperplane.fill", withConfiguration: config), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let challangeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        button.setImage(UIImage(systemName: "flag.2.crossed.fill", withConfiguration: config), for: .normal)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let requestsButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "envelope.fill", withConfiguration: config), for: .normal)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let matchesButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "sportscourt.fill", withConfiguration: config), for: .normal)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // Computed property to check if current user is captain
    private var isCurrentUserCaptain: Bool {
        guard let team = team, let currentUserId = currentUserId else { return false }
        return team.captain_id == currentUserId
    }
    
    // Constraints that need to be toggled
    private var sendButtonTrailingConstraint: NSLayoutConstraint!
    private var sendButtonLeadingToTextFieldConstraint: NSLayoutConstraint!
    private var messageTextFieldTrailingToSendConstraint: NSLayoutConstraint!
    private var messageTextFieldTrailingToContainerConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupTableView()
        updateColors()
        
        // Fetch current user ID and team data
        Task {
            await fetchCurrentUserId()
            await fetchTeamMembers()
            await fetchExistingMessages()
            updateUIWithTeamData()
            updateCaptainButtonsVisibility()
            startPollingForNewMessages()
        }
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                // Check for user interface style changes (dark/light mode)
                if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                    self.updateColors()
                    self.updateGradientColors()
                    self.tableView.reloadData()
                }
            }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop polling when view disappears
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = topGreenTint.bounds
        updateGradientColors()
    }
    
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        
//        // Check for user interface style changes (dark/light mode)
//        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
//            updateColors()
//            updateGradientColors()
//            tableView.reloadData()
//        }
//    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
        
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(backButton)
        view.addSubview(titleButton)
        view.addSubview(tableView)
        view.addSubview(messageInputContainer)
        view.addSubview(activityIndicator)
        
        messageInputContainer.addSubview(messageTextField)
        messageInputContainer.addSubview(sendButton)
        messageInputContainer.addSubview(challangeButton)
        messageInputContainer.addSubview(requestsButton)
        messageInputContainer.addSubview(matchesButton)
        
        // Setup all constraints first
        NSLayoutConstraint.activate([
            // Top Green Tint
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Title Button
            titleButton.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 15),
            titleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: titleButton.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputContainer.topAnchor),
            
            // Message Input Container
            messageInputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            messageInputContainer.heightAnchor.constraint(equalToConstant: 70),
            
            // Matches Button (always visible, leftmost)
            matchesButton.leadingAnchor.constraint(equalTo: messageInputContainer.leadingAnchor, constant: 16),
            matchesButton.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
            matchesButton.widthAnchor.constraint(equalToConstant: 50),
            matchesButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Message Text Field (common constraints)
            messageTextField.leadingAnchor.constraint(equalTo: matchesButton.trailingAnchor, constant: 12),
            messageTextField.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
            messageTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Send Button (common constraints)
            sendButton.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 30),
            sendButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Challenge Button (captain only)
            challangeButton.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
            challangeButton.widthAnchor.constraint(equalToConstant: 50),
            challangeButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Requests Button (captain only)
            requestsButton.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
            requestsButton.widthAnchor.constraint(equalToConstant: 50),
            requestsButton.heightAnchor.constraint(equalToConstant: 50),
            requestsButton.trailingAnchor.constraint(equalTo: messageInputContainer.trailingAnchor, constant: -16)
        ])
        
        // Create dynamic constraints
        sendButtonTrailingConstraint = sendButton.trailingAnchor.constraint(equalTo: messageInputContainer.trailingAnchor, constant: -16)
        sendButtonLeadingToTextFieldConstraint = sendButton.leadingAnchor.constraint(equalTo: messageTextField.trailingAnchor, constant: 12)
        messageTextFieldTrailingToSendConstraint = messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12)
        messageTextFieldTrailingToContainerConstraint = messageTextField.trailingAnchor.constraint(equalTo: messageInputContainer.trailingAnchor, constant: -16)
        
        // Set initial layout
        updateLayoutForCaptainStatus()
    }
    
    private func updateLayoutForCaptainStatus() {
        // Deactivate all dynamic constraints first
        sendButtonTrailingConstraint.isActive = false
        sendButtonLeadingToTextFieldConstraint.isActive = false
        messageTextFieldTrailingToSendConstraint.isActive = false
        messageTextFieldTrailingToContainerConstraint.isActive = false
        
        if isCurrentUserCaptain {
            // Captain layout: TextField -> Send -> Challenge -> Requests
            sendButtonLeadingToTextFieldConstraint.isActive = true
            messageTextFieldTrailingToSendConstraint.isActive = true
            
            // Position challenge button after send button
            challangeButton.leadingAnchor.constraint(equalTo: sendButton.trailingAnchor, constant: 12).isActive = true
            requestsButton.leadingAnchor.constraint(equalTo: challangeButton.trailingAnchor, constant: 12).isActive = true
        } else {
            // Member layout: TextField (full width) -> Send (right side)
            sendButtonTrailingConstraint.isActive = true
            messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12).isActive = true
        }
        
        // Update visibility
        challangeButton.isHidden = !isCurrentUserCaptain
        requestsButton.isHidden = !isCurrentUserCaptain
        
        // Force layout update
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateCaptainButtonsVisibility() {
        DispatchQueue.main.async {
            self.challangeButton.isHidden = !self.isCurrentUserCaptain
            self.requestsButton.isHidden = !self.isCurrentUserCaptain
            self.updateLayoutForCaptainStatus()
        }
    }
    
    private func setupTableView() {
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView.dataSource = self
        tableView.delegate = self
        // REMOVED: tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        // Important: Ensure automatic dimension works properly
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 80 // Give a reasonable estimate
            
            // Remove any default cell spacing
            tableView.sectionHeaderHeight = 0
            tableView.sectionFooterHeight = 0
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        challangeButton.addTarget(self, action: #selector(challangeButtonTapped), for: .touchUpInside)
        requestsButton.addTarget(self, action: #selector(envelopeButtonTapped), for: .touchUpInside)
        matchesButton.addTarget(self, action: #selector(matchesButtonTapped), for: .touchUpInside)
        titleButton.addTarget(self, action: #selector(titleButtonTapped), for: .touchUpInside)
        messageTextField.delegate = self
    }
    
    // MARK: - Data Fetching
    private func fetchCurrentUserId() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            currentUserId = session.user.id
            print("Current user ID: \(session.user.id)")
        } catch {
            print("Error fetching current user: \(error)")
        }
    }
    
    private func fetchTeamMembers() async {
        guard let teamId = team?.id else { return }
        
        do {
            let members: [TeamMember] = try await SupabaseManager.shared.client
                .from("team_members")
                .select()
                .eq("team_id", value: teamId)
                .execute()
                .value
            
            await MainActor.run {
                self.teamMembers = members
            }
        } catch {
            print("Error fetching team members: \(error)")
            await MainActor.run {
                self.teamMembers = []
            }
        }
    }
    
    private func fetchExistingMessages() async {
        guard let teamId = team?.id else { return }
        
        await MainActor.run {
            activityIndicator.startAnimating()
        }
        
        do {
            // Fetch messages for this team - ASCENDING order for top-to-bottom display
            let messages: [ChatMessage] = try await SupabaseManager.shared.client
                .from("chats")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: true) // Changed to ascending
                .limit(50)
                .execute()
                .value
            
            // Fetch sender profiles for all unique user IDs
            let uniqueUserIds = Set(messages.map { $0.user_id })
            await fetchSenderProfiles(for: Array(uniqueUserIds))
            
            // Convert to UI models
            let uiMessages = await convertToUIMessages(messages)
            
            await MainActor.run {
                self.messages = uiMessages // No need to reverse now
                self.lastPollTime = Date() // Update last poll time
                self.tableView.reloadData()
                self.scrollToBottom()
                self.activityIndicator.stopAnimating()
            }
            
        } catch {
            print("Error fetching messages: \(error)")
            await MainActor.run {
                self.activityIndicator.stopAnimating()
                self.showAlert(title: "Error", message: "Failed to load messages. Please try again.")
            }
        }
    }
    
    private func fetchSenderProfiles(for userIds: [UUID]) async {
        guard !userIds.isEmpty else { return }
        
        do {
            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .in("id", values: userIds)
                .execute()
                .value
            
            for profile in profiles {
                senderCache[profile.id] = (name: profile.name ?? "Unknown", profilePic: profile.profile_pic)
            }
        } catch {
            print("Error fetching sender profiles: \(error)")
        }
    }
    
    private func convertToUIMessages(_ messages: [ChatMessage]) async -> [ChatMessageUI] {
        var uiMessages: [ChatMessageUI] = []
        
        for message in messages {
            let isFromCurrentUser = message.user_id == currentUserId
            let senderInfo = senderCache[message.user_id]
            
            let uiMessage = ChatMessageUI(
                id: message.id.uuidString,
                text: message.message,
                isFromCurrentUser: isFromCurrentUser,
                timestamp: message.created_at,
                senderName: senderInfo?.name,
                senderProfilePic: senderInfo?.profilePic
            )
            uiMessages.append(uiMessage)
        }
        
        return uiMessages
    }
    
    // MARK: - Polling for New Messages
    private func startPollingForNewMessages() {
        // Start polling every 3 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task {
                await self?.pollForNewMessages()
            }
        }
    }
    
    private func pollForNewMessages() async {
        guard let teamId = team?.id else { return }
        
        do {
            // Format the date for Supabase query
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let lastPollTimeString = formatter.string(from: lastPollTime)
            
            let newMessages: [ChatMessage] = try await SupabaseManager.shared.client
                .from("chats")
                .select()
                .eq("team_id", value: teamId)
                .gt("created_at", value: lastPollTimeString)
                .order("created_at", ascending: true) // Changed to ascending
                .execute()
                .value
            
            if !newMessages.isEmpty {

                // Fetch sender profiles for new messages
                let uniqueUserIds = Set(newMessages.map { $0.user_id })
                let newUserIds = uniqueUserIds.filter { senderCache[$0] == nil }
                if !newUserIds.isEmpty {
                    await fetchSenderProfiles(for: Array(newUserIds))
                }
                
                // Process new messages in order
                for message in newMessages {
                    await processNewMessage(message)
                }
                
                // Update last poll time
                await MainActor.run {
                    self.lastPollTime = Date()
                }
            }
            
        } catch {
            print("Error polling for messages: \(error)")
        }
    }
    
    private func processNewMessage(_ message: ChatMessage) async {
        let isFromCurrentUser = message.user_id == currentUserId
        let senderInfo = senderCache[message.user_id]
        
        let uiMessage = ChatMessageUI(
            id: message.id.uuidString,
            text: message.message,
            isFromCurrentUser: isFromCurrentUser,
            timestamp: message.created_at,
            senderName: senderInfo?.name,
            senderProfilePic: senderInfo?.profilePic
        )
        
        await MainActor.run {
            // Add to end of array
            self.messages.append(uiMessage)
            
            // Check if we're at the bottom before inserting
            let shouldScrollToBottom = self.isAtBottomOfTableView()
            
            // Animate the new message
            self.tableView.performBatchUpdates({
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }, completion: { _ in
                // Auto-scroll to bottom if we were already at bottom
                if shouldScrollToBottom {
                    self.scrollToBottom()
                }
            })
        }
    }
    
    private func isAtBottomOfTableView() -> Bool {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return true }
        
        let lastVisibleIndexPath = tableView.indexPathsForVisibleRows?.last
        let lastRowIndex = messages.count - 1
        return lastVisibleIndexPath?.row == lastRowIndex
    }
    
    // MARK: - Send Message
    private func sendMessage() {
        guard let messageText = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !messageText.isEmpty,
              let teamId = team?.id,
              let currentUserId = currentUserId else { return }
        
        let messageData = [
            "team_id": teamId.uuidString,
            "user_id": currentUserId.uuidString,
            "message": messageText
        ]
        
        Task {
            do {
                let response: ChatMessage = try await SupabaseManager.shared.client
                    .from("chats")
                    .insert(messageData)
                    .select()
                    .single()
                    .execute()
                    .value

                await MainActor.run {
                    self.messageTextField.text = ""
                }
                
            } catch {
                print("Error sending message: \(error)")
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to send message. Please try again.")
                }
            }
        }
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        titleButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        titleButton.tintColor = isDarkMode ? .white : .black
        
        backButton.backgroundColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.1) :
            UIColor(white: 0, alpha: 0.05)
        backButton.layer.borderColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.2).cgColor :
            UIColor(white: 0, alpha: 0.1).cgColor
        backButton.tintColor = isDarkMode ? .systemGreenDark : .systemGreen
        
        messageTextField.backgroundColor = isDarkMode ? .secondaryDark : .tertiaryLight
        messageTextField.textColor = isDarkMode ? .white : .black
        messageTextField.attributedPlaceholder = NSAttributedString(
            string: "Message here",
            attributes: [NSAttributedString.Key.foregroundColor: isDarkMode ? UIColor.lightGray : UIColor.darkGray]
        )
        
        sendButton.tintColor = isDarkMode ? .systemGreenDark : .systemGreen
        
        let buttonBgColor = isDarkMode ? UIColor.secondaryDark : UIColor.tertiaryLight
        let buttonTintColor = isDarkMode ? UIColor.white : UIColor.black
        
        challangeButton.backgroundColor = buttonBgColor
        challangeButton.tintColor = buttonTintColor
        
        requestsButton.backgroundColor = buttonBgColor
        requestsButton.tintColor = buttonTintColor
        
        matchesButton.backgroundColor = buttonBgColor
        matchesButton.tintColor = buttonTintColor
        
        activityIndicator.color = isDarkMode ? .white : .darkGray
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
    
    private func updateUIWithTeamData() {
        guard let team = team else { return }
        titleButton.setTitle(team.name, for: .normal)
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func sendButtonTapped() {
        sendMessage()
    }
    
    @objc private func challangeButtonTapped() {
        guard let team = team else {
            print("❌ Team not available")
            return
        }
        
        let challengeVC = ChallengeTeamMatchViewController()
        challengeVC.currentTeam = team
        challengeVC.modalPresentationStyle = .overFullScreen
        challengeVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        present(challengeVC, animated: true)
    }
    
    @objc private func envelopeButtonTapped() {
        guard let currentTeam = self.team else {
            // Show an alert or handle the case where team is not available
            print("No team selected")
            return
        }
        
        let requestsVC = MatchRequestViewController()
        requestsVC.team = currentTeam
        requestsVC.modalPresentationStyle = .overFullScreen
        requestsVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        present(requestsVC, animated: true)
    }
    
    @objc private func matchesButtonTapped() {
        let teamMatchesVC = TeamMatchesViewController()
        teamMatchesVC.team = team
        teamMatchesVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        navigationController?.pushViewController(teamMatchesVC, animated: true)
    }
    
    @objc private func titleButtonTapped() {
        let teamInfoVC = TeamInformationViewController()
        teamInfoVC.team = team
        teamInfoVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        navigationController?.pushViewController(teamInfoVC, animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate
extension TeamChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as? ChatMessageCell else {
            return UITableViewCell()
        }
        
        let message = messages[indexPath.row]
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        cell.configure(with: message, isDarkMode: isDarkMode)
        // REMOVED: cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UITextField Delegate
extension TeamChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}

// MARK: - Chat Message Cell
class ChatMessageCell: UITableViewCell {
    
    private let messageBubble: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let senderNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        
        contentView.addSubview(messageBubble)
        messageBubble.addSubview(senderNameLabel)
        messageBubble.addSubview(timestampLabel)
        messageBubble.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            // Message bubble with spacing
            messageBubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            messageBubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
            messageBubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            messageBubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            // Sender name at top left
            senderNameLabel.topAnchor.constraint(equalTo: messageBubble.topAnchor, constant: 12),
            senderNameLabel.leadingAnchor.constraint(equalTo: messageBubble.leadingAnchor, constant: 12),
            senderNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timestampLabel.leadingAnchor, constant: -8),
            
            // Timestamp at top right
            timestampLabel.topAnchor.constraint(equalTo: messageBubble.topAnchor, constant: 12),
            timestampLabel.trailingAnchor.constraint(equalTo: messageBubble.trailingAnchor, constant: -12),
            timestampLabel.leadingAnchor.constraint(greaterThanOrEqualTo: senderNameLabel.trailingAnchor, constant: 8),
            
            // Message below both name and timestamp
            messageLabel.topAnchor.constraint(equalTo: senderNameLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: messageBubble.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: messageBubble.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: messageBubble.bottomAnchor, constant: -12)
        ])
        
        // Set compression resistance and hugging priorities
        senderNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        timestampLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        timestampLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    func configure(with message: ChatMessageUI, isDarkMode: Bool) {
        messageLabel.text = message.text
        senderNameLabel.text = message.senderName ?? "Unknown"
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        timestampLabel.text = formatter.string(from: message.timestamp)
        
        if message.isFromCurrentUser {
            if isDarkMode {
                messageBubble.backgroundColor = .systemGreenDark
                messageLabel.textColor = .white
                senderNameLabel.textColor = UIColor.white.withAlphaComponent(0.8)
                timestampLabel.textColor = UIColor.white.withAlphaComponent(0.7)
            } else {
                messageBubble.backgroundColor = .systemGreen
                messageLabel.textColor = .white
                senderNameLabel.textColor = UIColor.white.withAlphaComponent(0.9)
                timestampLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            }
            
            // Align to right for current user
            NSLayoutConstraint.deactivate([
                messageBubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
                messageBubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
            ])
            
            NSLayoutConstraint.activate([
                messageBubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                messageBubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60)
            ])
        } else {
            if isDarkMode {
                messageBubble.backgroundColor = .tertiaryDark
                messageLabel.textColor = .white
                senderNameLabel.textColor = UIColor.white.withAlphaComponent(0.8)
                timestampLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            } else {
                messageBubble.backgroundColor = .tertiaryLight
                messageLabel.textColor = .black
                senderNameLabel.textColor = UIColor.black.withAlphaComponent(0.7)
                timestampLabel.textColor = UIColor.black.withAlphaComponent(0.5)
            }
            
            // Align to left for other users
            NSLayoutConstraint.deactivate([
                messageBubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16),
                messageBubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
            ])
            
            NSLayoutConstraint.activate([
                messageBubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                messageBubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60)
            ])
        }
        
        // Force layout update
        self.layoutIfNeeded()
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct TeamChatViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TeamChatViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            TeamChatViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct TeamChatViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TeamChatViewController {
        let viewController = TeamChatViewController()
        // Create sample backend team for preview
        
        viewController.team = BackendTeam(
            id: UUID(),
            name: "All Stars FC",
            sport_id: 1,
            captain_id: UUID(),
            college_id: 1,
            created_at: "2024-01-28T12:00:00Z"
        )
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: TeamChatViewController, context: Context) {
        // No update needed
    }
}
#endif
