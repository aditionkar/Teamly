//
//  NotificationsViewController.swift
//  Practice - teamly
//
//  Created by user@37 on 19/12/25.
//

import UIKit

class NotificationsViewController: UIViewController {
    
    // MARK: - Models
    enum NotificationType {
        case info
        case teamRequest
        case friendRequest
    }
    
    struct Notification {
        let id: String
        let userName: String
        let message: String
        let time: String
        let type: NotificationType
        var isExpanded: Bool = false
        let teamName: String?
    }
    
    // MARK: - Properties
    private var notifications: [Notification] = [
        Notification(id: "1", userName: "Daksh", message: "has requested you to...", time: "10:01 AM", type: .teamRequest, teamName: "ALL Stars FC"),
        Notification(id: "2", userName: "Aditi", message: "has sent you a friend...", time: "9:41 AM", type: .friendRequest, teamName: nil),
        Notification(id: "3", userName: "Disha", message: "has posted a cricket...", time: "5:33 PM", type: .info, teamName: nil)
    ]
    
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        updateColors()
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
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "NotificationCell")
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
        let notification = notifications[indexPath.row]
        
        if notification.type == .teamRequest || notification.type == .friendRequest || notification.type == .info {
            notifications[indexPath.row].isExpanded.toggle()
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
}

// MARK: - NotificationCellDelegate
extension NotificationsViewController: NotificationCellDelegate {
    func notificationCell(_ cell: NotificationCell, didTapAccept notification: Notification) {
        print("Accepted: \(notification.userName)")
        // Handle accept action
    }
    
    func notificationCell(_ cell: NotificationCell, didTapDecline notification: Notification) {
        print("Declined: \(notification.userName)")
        // Handle decline action
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
            containerView.heightAnchor.constraint(equalToConstant: 67)
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
        timeLabel.text = notification.time
        
        if notification.isExpanded {
            if notification.type == .teamRequest {
                messageLabel.text = "has requested you to join their football team \(notification.teamName ?? "")"
                buttonStack.isHidden = false
                NSLayoutConstraint.deactivate(collapsedConstraints)
                NSLayoutConstraint.activate(expandedConstraints)
            } else if notification.type == .friendRequest {
                messageLabel.text = "has sent you a friend request."
                buttonStack.isHidden = false
                NSLayoutConstraint.deactivate(collapsedConstraints)
                NSLayoutConstraint.activate(expandedConstraints)
            } else {
                    messageLabel.text = notification.message.replacingOccurrences(of: "...", with: " match.")
                buttonStack.isHidden = true
                NSLayoutConstraint.deactivate(collapsedConstraints)
                NSLayoutConstraint.activate(expandedConstraints)
            }
            
        } else {
            messageLabel.text = notification.message
            buttonStack.isHidden = true
            NSLayoutConstraint.deactivate(expandedConstraints)
            NSLayoutConstraint.activate(collapsedConstraints)
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
