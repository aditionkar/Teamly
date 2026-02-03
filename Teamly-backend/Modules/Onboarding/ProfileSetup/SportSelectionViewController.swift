//
//  SportSelectionViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 24/01/26.
//

import UIKit
import Supabase

class SportSelectionViewController: UIViewController {
    
    // MARK: - UI Elements
    private let topGreenTint: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        return gradient
    }()
    
    private let progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progress = 0.6
        progressView.progressTintColor = .systemGreen
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Your preferred sport"
        label.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sportsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        
        var title = AttributedString("Next")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        config.attributedTitle = title
        
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .primaryWhite
        config.background.cornerRadius = 25
        
        button.configuration = config
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    private var selectedSports: [Sport] = []
    private var sports: [Sport] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupCollectionView()
        updateColors()
        fetchSportsFromSupabase()
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
            sportsCollectionView.reloadData()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
            
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(sportsCollectionView)
        view.addSubview(nextButton)
        view.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Top Green Tint
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -30),
            
            // Progress View
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            progressView.heightAnchor.constraint(equalToConstant: 7),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Sports Collection View
            sportsCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 80),
            sportsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            sportsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            sportsCollectionView.heightAnchor.constraint(equalToConstant: 220),
            
            // Next Button
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: sportsCollectionView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: sportsCollectionView.centerYAnchor)
        ])
    }
    
    private func setupCollectionView() {
        sportsCollectionView.delegate = self
        sportsCollectionView.dataSource = self
        sportsCollectionView.register(SportCollectionViewCell.self, forCellWithReuseIdentifier: "SportCollectionViewCell")
    }
    
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Fetch Sports from Supabase
    private func fetchSportsFromSupabase() {
        loadingIndicator.startAnimating()
        
        Task {
            do {
                let response: [Sport] = try await SupabaseManager.shared.client
                    .from("sports")
                    .select("id, name, emoji")
                    .order("id", ascending: true)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.sports = response
                    self.sportsCollectionView.reloadData()
                    self.loadingIndicator.stopAnimating()
                }
                
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    print("Error fetching sports: \(error)")
                    
                    // Show error message
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to load sports. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        progressView.trackTintColor = isDarkMode ?
            UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) :
            UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        loadingIndicator.color = isDarkMode ? .white : .black
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
    
    private func updateNextButtonState() {
        nextButton.isEnabled = !selectedSports.isEmpty
    }
        
    // MARK: - Actions
    @objc private func nextButtonTapped() {
        guard !selectedSports.isEmpty else { return }
        
        // Show loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        nextButton.isEnabled = false
        
        Task {
            do {
                // Get current user ID from Supabase auth
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id
                
                // Extract sport IDs from selected sports
                let sportIds = selectedSports.map { $0.id }
                
                // Save preferred sports using ProfileManager
                try await ProfileManager.shared.savePreferredSports(
                    userId: userId,
                    sportIds: sportIds
                )
                
                // Success - navigate to next screen
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    nextButton.isEnabled = true
                    
                    let skillLevelVC = SkillLevelViewController(selectedSports: selectedSports)
                    skillLevelVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
                    
                    // If we're already in a navigation controller, push
                    if let navController = navigationController {
                        navController.pushViewController(skillLevelVC, animated: true)
                        navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
                    } else {
                        // If not, create a new navigation controller and present modally
                        let navController = UINavigationController(rootViewController: skillLevelVC)
                        navController.modalPresentationStyle = .fullScreen
                        navController.setNavigationBarHidden(true, animated: false)
                        navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
                        present(navController, animated: true)
                    }
                }
                
            } catch {
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    nextButton.isEnabled = true
                    
                    print("Error saving preferred sports: \(error.localizedDescription)")
                    
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to save sports selection. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension SportSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sports.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SportCollectionViewCell", for: indexPath) as! SportCollectionViewCell
        let sport = sports[indexPath.item]
        let isSelected = selectedSports.contains(where: { $0.id == sport.id })
        cell.configure(with: sport, isSelected: isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedSport = sports[indexPath.item]
        
        if let index = selectedSports.firstIndex(where: { $0.id == selectedSport.id }) {
            selectedSports.remove(at: index)
        } else {
            selectedSports.append(selectedSport)
        }
        
        collectionView.reloadData()
        updateNextButtonState()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 90, height: 90)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let totalWidth = collectionView.frame.width
        let totalCellWidth: CGFloat = 90 * 3
        let totalSpacing: CGFloat = 20 * 2
        let leftInset = (totalWidth - totalCellWidth - totalSpacing) / 2
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: leftInset)
    }
}

// MARK: - Sport Model (should match Supabase table structure)
struct Sport: Codable {
    let id: Int
    let name: String
    let emoji: String
    
    // Add if you have other columns
    let created_at: String?
}


// MARK: - Update SportCollectionViewCell

class SportCollectionViewCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 35
        view.layer.borderWidth = 1.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let selectionIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 4
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        updateColors()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(emojiLabel)
        containerView.addSubview(selectionIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container View - 90x90
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 90),
            containerView.heightAnchor.constraint(equalToConstant: 90),
            
            // Emoji Label - Centered
            emojiLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // Selection Indicator - Top right corner
            selectionIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            selectionIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 8),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        containerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
    }
    
    func configure(with sport: Sport, isSelected: Bool) {
        emojiLabel.text = sport.emoji
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update selection appearance
        if isSelected {
            containerView.layer.borderColor = UIColor.systemGreen.cgColor
            containerView.layer.borderWidth = 1.0
            selectionIndicator.isHidden = true
        } else {
            // Use appropriate border color based on mode
            if isDarkMode {
                containerView.layer.borderColor = UIColor.tertiaryDark.cgColor
            } else {
                containerView.layer.borderColor = UIColor.tertiaryLight.withAlphaComponent(0.5).cgColor
            }
            containerView.layer.borderWidth = 1.0
            selectionIndicator.isHidden = true
        }
        
        // Update background color
        updateColors()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        emojiLabel.text = nil
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        containerView.layer.borderColor = isDarkMode ? UIColor.tertiaryDark.cgColor : UIColor.tertiaryLight.withAlphaComponent(0.5).cgColor
        containerView.layer.borderWidth = 1.0
        selectionIndicator.isHidden = true
        updateColors()
    }
}

// MARK: - SwiftUI Preview
import SwiftUI

struct SportSelectionViewController_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            SportSelectionViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            SportSelectionViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct SportSelectionViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SportSelectionViewController {
        let vc = SportSelectionViewController()
        // Set up navigation controller for preview
        let navController = UINavigationController(rootViewController: vc)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: SportSelectionViewController, context: Context) {
        // Update the view controller if needed
    }
}
