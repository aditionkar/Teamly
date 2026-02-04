//
//  MatchRequestViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 01/02/26.
//

import UIKit
import Supabase

// MARK: - Models
struct MatchRequest: Codable {
    let id: Int
    let challenging_team_id: UUID
    let challenged_team_id: UUID
    let proposed_venue: String
    let proposed_date: String // This will be in "yyyy-MM-dd" format
    let proposed_time: String // This will be in "HH:mm:ss" format
    let status: String
    let created_at: String
    let responded_at: String? // Make optional
    let match_id: UUID? // Make optional
    let proposed_skill_level: String? // Added this field
    
    // Helper computed properties for UI display
    var displayDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yy"
        
        if let date = inputFormatter.date(from: proposed_date) {
            return outputFormatter.string(from: date)
        }
        return proposed_date
    }
    
    var displayTime: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm:ss"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        
        if let time = inputFormatter.date(from: proposed_time) {
            return outputFormatter.string(from: time)
        }
        return proposed_time
    }
    
    var timeRange: String {
        // Get the start time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        // Parse the displayed time
        guard let startTime = timeFormatter.date(from: displayTime) else {
            return displayTime
        }
        
        // Add one hour for end time
        let calendar = Calendar.current
        guard let endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) else {
            return displayTime
        }
        
        let startTimeString = timeFormatter.string(from: startTime)
        let endTimeString = timeFormatter.string(from: endTime)
        
        return "\(startTimeString) - \(endTimeString)"
    }
    
    // Helper to check if date is today/tomorrow
    var relativeDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: proposed_date) else {
            return displayDate
        }
        
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            return displayDate
        }
    }
    
    // Helper to get day number for calendar icon
    var calendarIconDay: Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: proposed_date) else {
            return nil
        }
        
        return Calendar.current.component(.day, from: date)
    }
    
    // Helper to check if time is AM or PM
    var isPM: Bool {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        guard let time = timeFormatter.date(from: proposed_time) else {
            return false
        }
        
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "a"
        
        return hourFormatter.string(from: time) == "PM"
    }
}

struct TeamInfo: Codable {
    let id: UUID
    let name: String
}

struct TeamInfoWithSport: Codable {
    let id: UUID
    let name: String
    let sport_id: Int?
}

// MARK: - Create/Update Models
struct CreateMatchRequest: Codable {
    let match_type: String
    let venue: String
    let match_date: String
    let match_time: String
    let sport_id: Int
    let team_id: UUID
    let opponent_team_id: UUID
    let posted_by_user_id: UUID
    // Note: No 'status' field as it doesn't exist in matches table
}

struct Match: Codable, Identifiable {
    let id: UUID
    let match_type: String
    let venue: String
    let match_date: String
    let match_time: String
    let sport_id: Int
    let team_id: UUID?
    let opponent_team_id: UUID?
    let posted_by_user_id: UUID
    let created_at: String
    // Note: No 'status' field as it doesn't exist in matches table
}

struct MatchRequestUpdate: Codable {
    let match_id: String?
    let status: String
    let responded_at: String
}

struct MatchRequestStatusUpdate: Codable {
    let status: String
    let responded_at: String
}

// MARK: - Data Service
class MatchRequestDataService {
    static let shared = MatchRequestDataService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    func fetchMatchRequests(for teamId: UUID) async throws -> [(MatchRequest, TeamInfo)] {
        do {
            let matchRequests: [MatchRequest] = try await client
                .from("match_requests")
                .select()
                .eq("challenged_team_id", value: teamId)
                .eq("status", value: "pending")
                .order("created_at", ascending: false)
                .execute()
                .value

            var results: [(MatchRequest, TeamInfo)] = []
            
            // For each match request, fetch the challenging team info
            for request in matchRequests {
                let challengingTeams: [TeamInfo] = try await client
                    .from("teams")
                    .select("id, name")
                    .eq("id", value: request.challenging_team_id)
                    .execute()
                    .value
                
                if let challengingTeam = challengingTeams.first {
                    results.append((request, challengingTeam))
                }
            }
            
            return results
        } catch {
            print("❌ Error fetching match requests: \(error)")
            throw error
        }
    }
    
    func respondToMatchRequest(requestId: Int, status: String) async throws {
        do {

            let updateData = MatchRequestStatusUpdate(
                status: status,
                responded_at: Date().ISO8601Format()
            )
            
            try await client
                .from("match_requests")
                .update(updateData)
                .eq("id", value: requestId)
                .execute()

        } catch {
            print("❌ Error responding to match request: \(error)")
            throw error
        }
    }
    
    func createMatchFromRequest(request: MatchRequest, challengingTeam: TeamInfo) async throws {
        do {

            // Get the challenging team's sport_id
            let teamQuery: [TeamInfoWithSport] = try await client
                .from("teams")
                .select("id, name, sport_id")
                .eq("id", value: challengingTeam.id)
                .execute()
                .value
            
            guard let teamWithSport = teamQuery.first else {
                throw NSError(domain: "MatchRequestDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Challenging team not found"])
            }
            
            guard let sport_id = teamWithSport.sport_id else {
                throw NSError(domain: "MatchRequestDataService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Team doesn't have a sport assigned"])
            }
            
            // Get current user ID (captain of challenging team)
            let session = try await client.auth.session
            let postedByUserId = session.user.id
            
            // Create match data using proper struct - removed 'status' field
            let matchData = CreateMatchRequest(
                match_type: "team_challenge",
                venue: request.proposed_venue,
                match_date: request.proposed_date,
                match_time: request.proposed_time,
                sport_id: sport_id,
                team_id: challengingTeam.id,
                opponent_team_id: request.challenged_team_id,
                posted_by_user_id: postedByUserId
            )

            // Insert the match - now it's Encodable
            let matchResponse = try await client
                .from("matches")
                .insert(matchData)
                .select()
                .single()
                .execute()
            
            // Parse the created match to get its ID - now using proper Decodable struct
            let match: Match = try JSONDecoder().decode(Match.self, from: matchResponse.data)
            let matchId = match.id
            
            // Update the match request with the match ID - use proper Encodable struct
            let updateData = MatchRequestUpdate(
                match_id: matchId.uuidString,
                status: "accepted",
                responded_at: Date().ISO8601Format()
            )
            
            try await client
                .from("match_requests")
                .update(updateData)
                .eq("id", value: request.id)
                .execute()

        } catch {
            print("❌ Error creating match from request: \(error)")
            throw error
        }
    }
}

// MARK: - View Controller
final class MatchRequestViewController: UIViewController {
    
    // MARK: - Properties
    var team: BackendTeam?
    private var expandedRequestId: Int?
    private var matchRequests: [(MatchRequest, TeamInfo)] = []
    private var isLoading = false
    
    // MARK: - UI Components
    private let dimmedView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 1
        return view
    }()
    
    private let bottomSheet: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()
    
    private let handleView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 2.5
        return v
    }()
    
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 15
        return s
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No pending match requests"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        updateColors()
        setupGestures()
        
        // Set initial position for bottom sheet (off screen)
        bottomSheet.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        
        // Load data if team is available
        if let team = team {
            loadMatchRequests(for: team)
        } else {
            showError("Team information is missing")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.bottomSheet.transform = .identity
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
            reload()
        }
    }
    
    // MARK: - Data Loading
    private func loadMatchRequests(for team: BackendTeam) {
        guard !isLoading else { return }
        
        isLoading = true
        loadingIndicator.startAnimating()
        emptyStateLabel.isHidden = true
        
        Task {
            do {
                let requests = try await MatchRequestDataService.shared.fetchMatchRequests(for: team.id)
                await MainActor.run {
                    self.matchRequests = requests
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.reload()
                    
                    if requests.isEmpty {
                        self.emptyStateLabel.isHidden = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.showError("Failed to load match requests: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .clear
    }
    
    private func setupGestures() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmedViewTap))
        dimmedView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleSwipeDown() {
        animateDismiss()
    }
    
    @objc private func handleDimmedViewTap() {
        animateDismiss()
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(dimmedView)
        view.addSubview(bottomSheet)
        bottomSheet.addSubview(loadingIndicator)
        bottomSheet.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: bottomSheet.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: bottomSheet.centerYAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: bottomSheet.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: bottomSheet.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: bottomSheet.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: bottomSheet.trailingAnchor, constant: -20)
        ])
        
        bottomSheet.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        bottomSheet.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: bottomSheet.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: bottomSheet.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: bottomSheet.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomSheet.bottomAnchor)
        ])
        
        let handleContainer = UIView()
        handleContainer.addSubview(handleView)
        handleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            handleView.centerXAnchor.constraint(equalTo: handleContainer.centerXAnchor),
            handleView.topAnchor.constraint(equalTo: handleContainer.topAnchor, constant: 12),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 5),
            handleView.bottomAnchor.constraint(equalTo: handleContainer.bottomAnchor, constant: -10)
        ])
        
        contentStack.addArrangedSubview(handleContainer)
        
        let listContainer = UIView()
        listContainer.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: listContainer.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: listContainer.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: listContainer.trailingAnchor, constant: -30),
            stackView.bottomAnchor.constraint(equalTo: listContainer.bottomAnchor, constant: -36)
        ])
        
        contentStack.addArrangedSubview(listContainer)
    }
    
    // MARK: - Dismiss Animation
    private func animateDismiss() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.dimmedView.alpha = 0
            self.bottomSheet.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        bottomSheet.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        handleView.backgroundColor = .systemGray
        emptyStateLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
    }
    
    // MARK: - Data Display
    private func reload() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (request, teamInfo) in matchRequests {
            let displayRequest = MatchRequestDisplay(
                team: teamInfo.name,
                venue: request.proposed_venue,
                date: request.relativeDateString,
                originalDate: request.displayDate, // Keep original format for icon
                time: request.timeRange,
                requestId: request.id,
                challengingTeamId: teamInfo.id,
                calendarDay: request.calendarIconDay,
                isPM: request.isPM
            )
            
            if expandedRequestId == request.id {
                stackView.addArrangedSubview(
                    ExpandedCard(
                        displayRequest,
                        onAction: { [weak self] action in
                            self?.handleRequestAction(action: action, request: request, challengingTeam: teamInfo)
                        },
                        onCollapse: { [weak self] in
                            self?.expandedRequestId = nil
                            self?.reload()
                        }
                    )
                )
            } else {
                stackView.addArrangedSubview(
                    CollapsedRow(
                        displayRequest,
                        onAction: { [weak self] action in
                            self?.handleRequestAction(action: action, request: request, challengingTeam: teamInfo)
                        },
                        onTap: { [weak self] in
                            self?.expandedRequestId = request.id
                            self?.reload()
                        }
                    )
                )
            }
        }
    }
    
    private func handleRequestAction(action: String, request: MatchRequest, challengingTeam: TeamInfo) {
        showConfirmationPopup(action: action, request: request, challengingTeam: challengingTeam)
    }
    
    // MARK: - Popup Handling
    private func showConfirmationPopup(action: String, request: MatchRequest, challengingTeam: TeamInfo) {
        let alert = UIAlertController(
            title: action,
            message: "Are you sure you want to \(action.lowercased()) this match request from \(challengingTeam.name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: action, style: .destructive) { [weak self] _ in
            self?.handleRequestResponse(action: action, request: request, challengingTeam: challengingTeam)
        })
        
        present(alert, animated: true)
    }
    
    private func handleRequestResponse(action: String, request: MatchRequest, challengingTeam: TeamInfo) {
        Task {
            do {
                if action == "Accept" {
                    // Create a match from the request
                    try await MatchRequestDataService.shared.createMatchFromRequest(
                        request: request,
                        challengingTeam: challengingTeam
                    )
                } else {
                    // Just update the status to rejected
                    try await MatchRequestDataService.shared.respondToMatchRequest(
                        requestId: request.id,
                        status: "rejected"
                    )
                }
                
                await MainActor.run {
                    // Remove the request from the list
                    self.matchRequests.removeAll { $0.0.id == request.id }
                    self.expandedRequestId = nil
                    self.reload()
                    
                    if self.matchRequests.isEmpty {
                        self.emptyStateLabel.isHidden = false
                    }
                    
                    self.showSuccess("Request \(action.lowercased()) successfully!")
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to \(action.lowercased()) request: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Display Model
struct MatchRequestDisplay {
    let team: String
    let venue: String
    let date: String // This will be "Today", "Tomorrow", or "dd/MM/yy"
    let originalDate: String // Original "dd/MM/yy" format for icon
    let time: String
    let requestId: Int
    let challengingTeamId: UUID
    let calendarDay: Int?
    let isPM: Bool
    
    // Helper to create formatted date text with SF Symbol
    func formattedDateText(isDarkMode: Bool) -> NSAttributedString {
        let icon = NSTextAttachment()
        
        // Try to get the day number from original date format "dd/MM/yy"
        let dayComponents = originalDate.split(separator: "/")
        if let dayString = dayComponents.first, let day = Int(dayString) {
            // iOS 17+ supports numbered calendar icons
            if #available(iOS 17.0, *) {
                icon.image = UIImage(systemName: "\(day).calendar")?.withTintColor(isDarkMode ? .white : .black)
            } else {
                // Fallback for older iOS versions
                icon.image = UIImage(systemName: "calendar")?.withTintColor(isDarkMode ? .white : .black)
            }
        } else {
            icon.image = UIImage(systemName: "calendar")?.withTintColor(isDarkMode ? .white : .black)
        }
        
        icon.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)
        
        let text = NSMutableAttributedString(attachment: icon)
        text.append(NSAttributedString(string: "  \(date)", attributes: [
            .foregroundColor: isDarkMode ? UIColor.white : UIColor.black,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ]))
        return text
    }
    
    // Helper to create formatted time text with SF Symbol
    func formattedTimeText(isDarkMode: Bool) -> NSAttributedString {
        let icon = NSTextAttachment()
        
        if isPM {
            icon.image = UIImage(systemName: "moon.fill")?.withTintColor(.systemBlue)
            icon.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)
        } else {
            icon.image = UIImage(systemName: "sun.horizon")?.withTintColor(.systemYellow)
            icon.bounds = CGRect(x: 0, y: -3, width: 30, height: 20)
        }
        
        let text = NSMutableAttributedString(attachment: icon)
        text.append(NSAttributedString(string: "  \(time)", attributes: [
            .foregroundColor: isDarkMode ? UIColor.white : UIColor.black,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ]))
        return text
    }
}

// MARK: - Collapsed Row
final class CollapsedRow: UIView {
    
    private let onTap: () -> Void
    private let onAction: (String) -> Void
    private let request: MatchRequestDisplay
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    private var declineButton: UIButton?
    private var acceptButton: UIButton?
    
    init(_ request: MatchRequestDisplay, onAction: @escaping (String) -> Void, onTap: @escaping () -> Void) {
        self.request = request
        self.onTap = onTap
        self.onAction = onAction
        super.init(frame: .zero)
        
        backgroundColor = .backgroundTertiary
        layer.cornerRadius = 30
        titleLabel.text = request.team
        
        declineButton = createPill("Decline", .systemRed)
        acceptButton = createPill("Accept", .systemGreen)
        
        declineButton?.addAction(UIAction { _ in self.onAction("Decline") }, for: .touchUpInside)
        acceptButton?.addAction(UIAction { _ in self.onAction("Accept") }, for: .touchUpInside)
        
        let buttons = UIStackView(arrangedSubviews: [declineButton!, acceptButton!])
        buttons.spacing = 12
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        let mainStack = UIStackView(arrangedSubviews: [textStack, UIView(), buttons])
        mainStack.alignment = .center
        
        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        updateColors()
    }
    
    @objc private func tapped() { onTap() }
    
    private func createPill(_ title: String, _ color: UIColor) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(color, for: .normal)
        b.backgroundColor = .backgroundQuaternary
        b.layer.cornerRadius = 15
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        b.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return b
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        declineButton?.backgroundColor = isDarkMode ? .quaternaryDark : .quaternaryLight
        acceptButton?.backgroundColor = isDarkMode ? .quaternaryDark : .quaternaryLight
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Expanded Card
final class ExpandedCard: UIView {
    
    private let request: MatchRequestDisplay
    private let onAction: (String) -> Void
    private let onCollapse: () -> Void
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        return label
    }()
    
    private let venueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.numberOfLines = 0
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .medium)
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .medium)
        return label
    }()
    
    private var declineButton: UIButton?
    private var acceptButton: UIButton?
    
    init(_ request: MatchRequestDisplay, onAction: @escaping (String) -> Void, onCollapse: @escaping () -> Void) {
        self.request = request
        self.onAction = onAction
        self.onCollapse = onCollapse
        super.init(frame: .zero)
        
        backgroundColor = .backgroundTertiary
        layer.cornerRadius = 30
        
        setupViews()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(collapse)))
        updateColors()
    }
    
    @objc private func collapse() { onCollapse() }
    
    private func setupViews() {
        titleLabel.text = request.team
        venueLabel.text = request.venue
        
        let venue = info("📍", venueLabel)
        
        declineButton = createActionButton("Decline", .systemRed)
        acceptButton = createActionButton("Accept", .systemGreen)
        
        declineButton?.addAction(UIAction { _ in self.onAction("Decline") }, for: .touchUpInside)
        acceptButton?.addAction(UIAction { _ in self.onAction("Accept") }, for: .touchUpInside)
        
        let buttons = UIStackView(arrangedSubviews: [declineButton!, acceptButton!])
        buttons.spacing = 8
        buttons.distribution = .fillEqually
        
        // Create a horizontal stack for date and time
        let dateTimeStack = UIStackView()
        dateTimeStack.axis = .horizontal
        dateTimeStack.spacing = 20
        dateTimeStack.alignment = .center
        
        // Add date and time labels to the horizontal stack
        dateTimeStack.addArrangedSubview(dateLabel)
        dateTimeStack.addArrangedSubview(timeLabel)
        
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            venue,
            dateTimeStack,  // Use the horizontal stack instead of separate labels
            buttons
        ])
        
        stack.axis = .vertical
        stack.spacing = 18
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    private func info(_ emoji: String, _ label: UILabel) -> UIStackView {
        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 16)
        emojiLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        let stack = UIStackView(arrangedSubviews: [emojiLabel, label])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .top
        
        return stack
    }
    
    private func createActionButton(_ title: String, _ color: UIColor) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(color, for: .normal)
        b.backgroundColor = .backgroundQuaternary
        b.layer.cornerRadius = 15
        b.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return b
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        backgroundColor = isDarkMode ? .backgroundTertiary : .backgroundSecondary
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        venueLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update date and time labels with formatted text
        dateLabel.attributedText = request.formattedDateText(isDarkMode: isDarkMode)
        timeLabel.attributedText = request.formattedTimeText(isDarkMode: isDarkMode)
        
        declineButton?.backgroundColor = isDarkMode ? .backgroundQuaternary : .backgroundTertiary
        acceptButton?.backgroundColor = isDarkMode ? .backgroundQuaternary : .backgroundTertiary
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct MatchRequestViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MatchRequestViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            MatchRequestViewControllerRepresentable()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
        .ignoresSafeArea()
    }
}

struct MatchRequestViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = MatchRequestViewController()
        let navController = UINavigationController(rootViewController: viewController)
        navController.setNavigationBarHidden(true, animated: false)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No update needed
    }
}
#endif
