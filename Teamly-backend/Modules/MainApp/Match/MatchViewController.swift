//
//  MatchViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 27/01/26.
//

import UIKit

class MatchViewController: UIViewController {
    
    // MARK: - Data
    private var selectedSegment: Int = 0  // 0 = upcoming, 1 = past
    private var upcomingMatches: [DBMatch] = []
    private var pastMatches: [DBMatch] = []
    private var currentMatches: [DBMatch] = []
    
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
        label.text = "Matches"
        label.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var segmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Upcoming", "Past"])

        control.selectedSegmentIndex = 0

        // Glass effect look
        control.layer.cornerRadius = 18
        control.clipsToBounds = true

        control.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            return self.createLayout()
        }

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false

        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false

        cv.register(MatchCellCard.self, forCellWithReuseIdentifier: "MatchCellCard")

        cv.dataSource = self
        cv.delegate = self

        return cv
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No matches found"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        updateColors()
        fetchUserMatches()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        
        view.addSubview(titleLabel)
        view.addSubview(segmentControl)
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            segmentControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            segmentControl.heightAnchor.constraint(equalToConstant: 30),

            collectionView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Fetching
    private func fetchUserMatches() {
        activityIndicator.startAnimating()
        emptyStateLabel.isHidden = true
        collectionView.isHidden = true
        
        MatchDataService.shared.fetchUserMatches { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let matches):
                    print("✅ Received \(matches.count) matches from service")
                    self.processMatches(matches)
                case .failure(let error):
                    print("❌ Error fetching matches: \(error.localizedDescription)")
                    self.showError(message: "Failed to load matches. Please try again.")
                }
            }
        }
    }
    
    private func processMatches(_ matches: [DBMatch]) {
        let now = Date()
        let calendar = Calendar.current
        
        // Clear existing data
        upcomingMatches.removeAll()
        pastMatches.removeAll()
        
        for match in matches {
            let matchDateTime = combineDateAndTime(date: match.matchDate, time: match.matchTime)
            
            // Check if match is today
            if calendar.isDate(match.matchDate, inSameDayAs: now) {
                // For today's matches, compare with current time
                if matchDateTime > now {
                    // Future time today -> upcoming
                    upcomingMatches.append(match)
                } else {
                    // Past time today -> past
                    pastMatches.append(match)
                }
            } else if matchDateTime > now {
                // Future dates (tomorrow or later) -> upcoming
                upcomingMatches.append(match)
            } else {
                // Past dates -> past
                pastMatches.append(match)
            }
        }
        
        print("📊 Results:")
        print("  Upcoming matches: \(upcomingMatches.count)")
        print("  Past matches: \(pastMatches.count)")
        
        // Sort matches
        upcomingMatches.sort { combineDateAndTime(date: $0.matchDate, time: $0.matchTime) <
                               combineDateAndTime(date: $1.matchDate, time: $1.matchTime) }
        
        pastMatches.sort { combineDateAndTime(date: $0.matchDate, time: $0.matchTime) >
                           combineDateAndTime(date: $1.matchDate, time: $1.matchTime) }
        
        // Update current matches based on selected segment
        currentMatches = selectedSegment == 0 ? upcomingMatches : pastMatches
        
        // Update UI
        updateEmptyState()
        collectionView.reloadData()
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Extract time components from the time date
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        // Use the system's calendar which respects local timezone
        return calendar.date(from: combinedComponents) ?? date
    }
    
    private func updateEmptyState() {
        let isEmpty = currentMatches.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        
        if isEmpty {
            emptyStateLabel.text = selectedSegment == 0 ? "No upcoming matches" : "No past matches"
        }
    }
    
    private func showError(message: String) {
        emptyStateLabel.text = message
        emptyStateLabel.isHidden = false
        collectionView.isHidden = true
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        emptyStateLabel.textColor = isDarkMode ? .gray : .darkGray
        
        segmentControl.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        segmentControl.selectedSegmentTintColor = isDarkMode ? UIColor.white : UIColor.black
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: isDarkMode ? UIColor.white.withAlphaComponent(0.8) : UIColor.black.withAlphaComponent(0.8),
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]

        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: isDarkMode ? UIColor.black : UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 16)
        ]

        segmentControl.setTitleTextAttributes(normalAttributes, for: .normal)
        segmentControl.setTitleTextAttributes(selectedAttributes, for: .selected)
        
        activityIndicator.color = isDarkMode ? .white : .gray
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

    // MARK: - Segment Change
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        selectedSegment = sender.selectedSegmentIndex

        currentMatches = selectedSegment == 0 ? upcomingMatches : pastMatches
        updateEmptyState()

        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve) {
            self.collectionView.reloadData()
        }
    }

    // MARK: - Layout
    private func createLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(185))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(185))

        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 5
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 20, trailing: 0)

        return section
    }
    
    // MARK: - Refresh
    @objc private func refreshData() {
        fetchUserMatches()
    }
}

// MARK: - CollectionView DataSource & Delegate
extension MatchViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentMatches.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "MatchCellCard",
            for: indexPath
        ) as! MatchCellCard

        let match = currentMatches[indexPath.item]

        cell.configure(with: match) {
            print("Tapped: Match ID \(match.id)")
        }
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        cell.updateColors(isDarkMode: isDarkMode)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let match = currentMatches[indexPath.item]
        print("Selected match: \(match.venue)")
        
        if let navController = navigationController {
            let matchVC = MatchInformationViewController()
            matchVC.match = match
            navController.pushViewController(matchVC, animated: true)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        } else {
            let matchVC = MatchInformationViewController()
            matchVC.match = match
            let navController = UINavigationController(rootViewController: matchVC)
            navController.modalPresentationStyle = .fullScreen
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
            present(navController, animated: true)
        }
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct MatchViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MatchViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            MatchViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct MatchViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MatchViewController {
        return MatchViewController()
    }
    
    func updateUIViewController(_ uiViewController: MatchViewController, context: Context) {
        // No update needed
    }
}
#endif
