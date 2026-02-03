//
//  SampleMatch.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import UIKit
import Supabase
import Foundation

class SampleMatchViewController: UIViewController {
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Matches"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Properties
    private var matches: [DBMatch] = []
    private var currentUserId: String = ""
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        fetchMatches()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateColors()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(equalToConstant: 40),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MatchCellCard.self, forCellWithReuseIdentifier: "MatchCellCard")
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDarkMode ? .black : .white
        titleLabel.textColor = isDarkMode ? .white : .black
        collectionView.backgroundColor = isDarkMode ? .black : .white
        refreshControl.tintColor = isDarkMode ? .white : .gray
    }
    
    // MARK: - Data Fetching
    @objc private func refreshData() {
        fetchMatches()
    }
    
    private func fetchMatches() {
        loadingIndicator.startAnimating()
        
        Task {
            do {
                print("=== FETCHING MATCHES ===")
                
                // Get current user ID first
                await getCurrentUserId()
                
                // Fetch matches
                let matchesResponse = try await SupabaseManager.shared.client
                    .from("matches")
                    .select("*")
                    .order("match_date", ascending: true)
                    .order("match_time", ascending: true)
                    .execute()
                
                // Decode matches
                let decoder = JSONDecoder()
                let matchesData = try decoder.decode([MatchRecord].self, from: matchesResponse.data)
                
                print("Successfully decoded \(matchesData.count) matches")
                
                if matchesData.isEmpty {
                    print("No matches found in database")
                    await showError("No matches available")
                    return
                }
                
                // Get all unique user IDs from matches
                let userIds = Set(matchesData.map { $0.posted_by_user_id.uuidString })
                print("Fetching names for \(userIds.count) unique users")
                
                // Fetch user names in batch
                let userNames = await fetchUserNames(for: Array(userIds))
                
                // Process each match
                var processedMatches: [DBMatch] = []
                
                for (index, matchRecord) in matchesData.enumerated() {
                    print("\nProcessing match \(index + 1)/\(matchesData.count)")
                    
                    // Fetch RSVP count for this match
                    let rsvpCount = await fetchRSVPCount(for: matchRecord.id.uuidString)
                    print("RSVP count: \(rsvpCount)")
                    
                    // Get user name
                    let userName = userNames[matchRecord.posted_by_user_id.uuidString] ?? "Unknown User"
                    print("User name: \(userName)")
                    
                    // Check if poster is friend of current user
                    let isFriend = await checkFriendship(friendId: matchRecord.posted_by_user_id.uuidString)
                    print("Is friend: \(isFriend)")
                    
                    // Create DBMatch object
                    if let dbMatch = createDBMatch(
                        from: matchRecord,
                        rsvpCount: rsvpCount,
                        userName: userName,
                        isFriend: isFriend
                    ) {
                        processedMatches.append(dbMatch)
                        print("✅ Created DBMatch for: \(dbMatch.venue)")
                    } else {
                        print("❌ Failed to create DBMatch")
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    self.matches = processedMatches
                    self.collectionView.reloadData()
                    self.loadingIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                    
                    if processedMatches.isEmpty {
                        self.showEmptyState()
                    } else {
                        print("\n✅ SUCCESS: Loaded \(processedMatches.count) matches")
                    }
                }
                
            } catch {
                print("\n❌ ERROR fetching matches: \(error)")
                print("Error details: \(error.localizedDescription)")
                
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                    self.showError("Failed to load matches: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getCurrentUserId() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            currentUserId = session.user.id.uuidString
            print("Current user ID: \(currentUserId)")
        } catch {
            print("Error getting current user: \(error)")
            currentUserId = ""
        }
    }
    
    private func fetchUserNames(for userIds: [String]) async -> [String: String] {
        guard !userIds.isEmpty else { return [:] }
        
        do {
            print("Fetching profiles for user IDs: \(userIds)")
            
            // Fetch user names from profiles table
            let response = try await SupabaseManager.shared.client
                .from("profiles")
                .select("id, name")
                .in("id", values: userIds)
                .execute()
            
            let decoder = JSONDecoder()
            let profiles = try decoder.decode([UserProfile].self, from: response.data)
            
            var userNames: [String: String] = [:]
            for profile in profiles {
                userNames[profile.id.uuidString] = profile.name ?? "Unknown User"
            }
            
            print("Fetched \(profiles.count) user profiles")
            return userNames
            
        } catch {
            print("Error fetching user names: \(error)")
            return [:]
        }
    }
    
    private func fetchRSVPCount(for matchId: String) async -> Int {
        guard !matchId.isEmpty else { return 0 }
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("match_rsvps")
                .select("*", count: .exact)
                .eq("match_id", value: matchId)
                .eq("rsvp_status", value: "going")
                .execute()
            
            return response.count ?? 0
        } catch {
            print("Error fetching RSVP count: \(error)")
            return 0
        }
    }
    
    private func checkFriendship(friendId: String) async -> Bool {
        guard !currentUserId.isEmpty, !friendId.isEmpty else {
            return false
        }
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("friends")
                .select("*")
                .eq("user_id", value: currentUserId)
                .eq("friend_id", value: friendId)
                .eq("status", value: "accepted")
                .execute()
            
            let decoder = JSONDecoder()
            let friendships = try decoder.decode([Friendship].self, from: response.data)
            
            return !friendships.isEmpty
        } catch {
            print("Error checking friendship: \(error)")
            return false
        }
    }
    
    private func createDBMatch(
        from matchRecord: MatchRecord,
        rsvpCount: Int,
        userName: String,
        isFriend: Bool
    ) -> DBMatch? {
        // Parse date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let matchDate = dateFormatter.date(from: matchRecord.match_date) else {
            print("Failed to parse date: \(matchRecord.match_date)")
            return nil
        }
        
        // Parse time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let matchTime = timeFormatter.date(from: matchRecord.match_time) else {
            print("Failed to parse time: \(matchRecord.match_time)")
            return nil
        }
        
        // Parse created_at
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone.current
        let createdAt = isoFormatter.date(from: matchRecord.created_at) ?? Date()
        
        return DBMatch(
            id: matchRecord.id,
            matchType: matchRecord.match_type,
            communityId: matchRecord.community_id,
            venue: matchRecord.venue,
            matchDate: matchDate,
            matchTime: matchTime,
            sportId: matchRecord.sport_id,
            sportName: "Sport", // Placeholder - you can fetch this too if needed
            skillLevel: matchRecord.skill_level,
            playersNeeded: matchRecord.players_needed,
            postedByUserId: matchRecord.posted_by_user_id,
            createdAt: createdAt,
            playersRSVPed: rsvpCount,
            postedByName: userName,
            isFriend: isFriend
        )
    }
    
    // MARK: - Helper Methods
    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "No matches found"
        emptyLabel.textColor = .gray
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.systemFont(ofSize: 18)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.viewWithTag(999)?.removeFromSuperview()
        
        emptyLabel.tag = 999
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            if let presentedVC = self.presentedViewController {
                presentedVC.dismiss(animated: false) {
                    self.presentAlert(message: message)
                }
            } else {
                self.presentAlert(message: message)
            }
        }
    }
    
    private func presentAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}

// MARK: - Data Models
struct MatchRecord: Codable {
    let id: UUID
    let match_type: String
    let community_id: String?
    let venue: String
    let match_date: String
    let match_time: String
    let sport_id: Int
    let skill_level: String?
    let players_needed: Int
    let posted_by_user_id: UUID
    let created_at: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case match_type
        case community_id
        case venue
        case match_date
        case match_time
        case sport_id
        case skill_level
        case players_needed
        case posted_by_user_id
        case created_at
    }
}

struct UserProfile: Codable {
    let id: UUID
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}

struct Friendship: Codable {
    let id: Int
    let user_id: UUID
    let friend_id: UUID
    let status: String
    let created_at: String
    let updated_at: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case friend_id
        case status
        case created_at
        case updated_at
    }
}

// MARK: - UICollectionViewDataSource
extension SampleMatchViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return matches.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MatchCellCard", for: indexPath) as? MatchCellCard else {
            return UICollectionViewCell()
        }
        
        let match = matches[indexPath.item]
        cell.configure(with: match)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension SampleMatchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width - 40
        let height: CGFloat = 280
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let match = matches[indexPath.item]
        handleMatchSelection(match: match)
    }
}

// MARK: - UICollectionViewDelegate
extension SampleMatchViewController: UICollectionViewDelegate {
    private func handleMatchSelection(match: DBMatch) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        let formattedDate = dateFormatter.string(from: match.matchDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let startTime = timeFormatter.string(from: match.matchTime)
        
        let calendar = Calendar.current
        if let endTimeDate = calendar.date(byAdding: .hour, value: 1, to: match.matchTime) {
            let endTime = timeFormatter.string(from: endTimeDate)
            
            let alert = UIAlertController(
                title: "Match Details",
                message: """
                🏟️ \(match.venue)
                📅 \(formattedDate)
                ⏰ \(startTime) - \(endTime)
                👥 \(match.playersRSVPed)/\(match.playersNeeded) going
                🎯 \(match.skillLevel ?? "Not specified")
                👤 Posted by: \(match.postedByName)\(match.isFriend ? " 👫" : "")
                """,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - Preview Support
#if DEBUG
import SwiftUI

struct SampleMatchViewController_Preview: PreviewProvider {
    static var previews: some View {
        UIViewControllerPreview {
            let vc = SampleMatchViewController()
            vc.overrideUserInterfaceStyle = .light
            return vc
        }
        .previewDisplayName("Light Mode")
        
        UIViewControllerPreview {
            let vc = SampleMatchViewController()
            vc.overrideUserInterfaceStyle = .dark
            return vc
        }
        .previewDisplayName("Dark Mode")
        .preferredColorScheme(.dark)
    }
}

struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController
    
    init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Update the view controller if needed
    }
}
#endif
