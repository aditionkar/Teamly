//
//  SearchingCommunitiesViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 24/01/26.
//

import UIKit
import Supabase

class SearchingCommunitiesViewController: UIViewController {
    
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
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "Rectangle")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // NEW: Search Alert View (replaces location alert)
    private let searchAlertView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 14
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let searchAlertTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Join College Community"
        label.font = UIFont(name: "SFProDisplay-Semibold", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchAlertDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "To join your college community we need your college city"
        label.font = UIFont(name: "SFProText-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchSeparatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Search", for: .normal)
        button.titleLabel?.font = UIFont(name: "SFProText-Semibold", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let searchingLabel: UILabel = {
        let label = UILabel()
        label.text = "Searching Communities near you ..."
        label.font = UIFont(name: "SFProDisplay-Semibold", size: 16) ?? UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
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
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Set initial background color
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
        
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(backgroundImageView)
        view.addSubview(searchAlertView)
        
        // Add search alert content
        searchAlertView.addSubview(searchAlertTitleLabel)
        searchAlertView.addSubview(searchAlertDescriptionLabel)
        searchAlertView.addSubview(searchSeparatorLine)
        searchAlertView.addSubview(searchButton)
        
        view.addSubview(searchingLabel)
    }
    
    private func setupConstraints() {
        
        // Top Green Tint
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // Background Image View - Much wider with minimal padding
        NSLayoutConstraint.activate([
            backgroundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            backgroundImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 350)
        ])

        // Search Alert View - Centered on top of the image
        NSLayoutConstraint.activate([
            searchAlertView.centerXAnchor.constraint(equalTo: backgroundImageView.centerXAnchor),
            searchAlertView.centerYAnchor.constraint(equalTo: backgroundImageView.centerYAnchor),
            searchAlertView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            searchAlertView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        // Search Alert Title Label
        NSLayoutConstraint.activate([
            searchAlertTitleLabel.topAnchor.constraint(equalTo: searchAlertView.topAnchor, constant: 20),
            searchAlertTitleLabel.leadingAnchor.constraint(equalTo: searchAlertView.leadingAnchor, constant: 16),
            searchAlertTitleLabel.trailingAnchor.constraint(equalTo: searchAlertView.trailingAnchor, constant: -16)
        ])
        
        // Search Alert Description Label
        NSLayoutConstraint.activate([
            searchAlertDescriptionLabel.topAnchor.constraint(equalTo: searchAlertTitleLabel.bottomAnchor, constant: 8),
            searchAlertDescriptionLabel.leadingAnchor.constraint(equalTo: searchAlertView.leadingAnchor, constant: 16),
            searchAlertDescriptionLabel.trailingAnchor.constraint(equalTo: searchAlertView.trailingAnchor, constant: -16)
        ])
        
        // Separator Line
        NSLayoutConstraint.activate([
            searchSeparatorLine.topAnchor.constraint(equalTo: searchAlertDescriptionLabel.bottomAnchor, constant: 20),
            searchSeparatorLine.leadingAnchor.constraint(equalTo: searchAlertView.leadingAnchor),
            searchSeparatorLine.trailingAnchor.constraint(equalTo: searchAlertView.trailingAnchor),
            searchSeparatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        // Search Button
        NSLayoutConstraint.activate([
            searchButton.topAnchor.constraint(equalTo: searchSeparatorLine.bottomAnchor),
            searchButton.leadingAnchor.constraint(equalTo: searchAlertView.leadingAnchor),
            searchButton.trailingAnchor.constraint(equalTo: searchAlertView.trailingAnchor),
            searchButton.heightAnchor.constraint(equalToConstant: 44),
            searchAlertView.bottomAnchor.constraint(equalTo: searchButton.bottomAnchor)
        ])
        
        // Searching Label - Just below the image
        NSLayoutConstraint.activate([
            searchingLabel.topAnchor.constraint(equalTo: backgroundImageView.bottomAnchor, constant: 30),
            searchingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            searchingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update view background
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Update search alert view background
        searchAlertView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        // Update alert label colors
        searchAlertTitleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        searchAlertDescriptionLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update separator line color
        searchSeparatorLine.backgroundColor = isDarkMode ? UIColor.systemGray : UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        
        // Update searching label color
        searchingLabel.textColor = isDarkMode ? .tertiaryLight : .tertiaryDark
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
            // For light mode, use light green with reduced alpha
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
    
    private func setupActions() {
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func searchButtonTapped() {
        // Hide the search alert
        UIView.animate(withDuration: 0.3, animations: {
            self.searchAlertView.alpha = 0
        }) { _ in
            self.searchAlertView.isHidden = true
            
            // Show searching label
            UIView.animate(withDuration: 0.5) {
                self.searchingLabel.alpha = 1
            }

            self.presentNextModal()
        }
    }
    
    private func presentNextModal() {
        let collegeCityModalVC = CollegeCityViewController()
        
        if let sheet = collegeCityModalVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        collegeCityModalVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        present(collegeCityModalVC, animated: true)
    }
}


// MARK: - Updated CollegesModalViewController to accept data
class CollegesModalViewController: UIViewController {
    
    // MARK: - Properties
    var colleges: [College] = []
    var cityName: String = ""
    
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupConstraints()
        updateColors()
        
        titleLabel.text = cityName
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateColors()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
    }
    
    private func updateColors() {
        let presentingViewControllerMode: UIUserInterfaceStyle
        if let presentingVC = self.presentingViewController {
            presentingViewControllerMode = presentingVC.traitCollection.userInterfaceStyle
        } else {
            presentingViewControllerMode = traitCollection.userInterfaceStyle
        }
        
        let isDarkMode = presentingViewControllerMode == .dark
        
        view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        tableView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        tableView.reloadData()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CollegeTableViewCell.self, forCellReuseIdentifier: "CollegeCell")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

// MARK: - College Model
struct College: Codable {
    let id: Int
    let name: String
    let location: String?
    let created_at: String?
}

// MARK: - Table View Delegate & Data Source
extension CollegesModalViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colleges.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CollegeCell", for: indexPath) as? CollegeTableViewCell else {
            return UITableViewCell()
        }
        
        let college = colleges[indexPath.row]
        cell.configure(with: college.name)
        cell.onJoinTapped = { [weak self] in
            self?.handleJoinCollege(college)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func handleJoinCollege(_ college: College) {
        print("Join button tapped for: \(college.name)")
        
        // Then show verification screen
        let verificationVC = CollegeVerificationViewController()
        verificationVC.selectedCollege = college
        verificationVC.modalPresentationStyle = .fullScreen
        verificationVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        present(verificationVC, animated: true)
    }
}

// MARK: - College Table View Cell
class CollegeTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let collegeNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProText-Bold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let joinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Join", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        button.setTitleColor(.primaryWhite, for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 18
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    var onJoinTapped: (() -> Void)?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(collegeNameLabel)
        containerView.addSubview(joinButton)
    }
    
    private func updateColors() {
        // Try to get the parent view controller's mode
        var isDarkMode = false
        
        // Traverse up the view hierarchy to find the modal view controller
        var currentView: UIView? = self
        while let view = currentView {
            if let tableView = view as? UITableView,
               let modalVC = tableView.delegate as? CollegesModalViewController {
                // Get the presenting view controller's trait collection
                if let presentingVC = modalVC.presentingViewController {
                    isDarkMode = presentingVC.traitCollection.userInterfaceStyle == .dark
                } else {
                    isDarkMode = modalVC.traitCollection.userInterfaceStyle == .dark
                }
                break
            }
            currentView = view.superview
        }
        
        // Update container view background
        containerView.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        
        // Update college name label color
        collegeNameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            containerView.heightAnchor.constraint(equalToConstant: 52),
            
            // College Name Label
            collegeNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            collegeNameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            collegeNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: joinButton.leadingAnchor, constant: -12),
            
            // Join Button
            joinButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            joinButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            joinButton.widthAnchor.constraint(equalToConstant: 70),
            joinButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupActions() {
        joinButton.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with collegeName: String) {
        collegeNameLabel.text = collegeName
        updateColors()
    }
    
    // MARK: - Actions
    @objc private func joinButtonTapped() {
        onJoinTapped?()
    }
}


// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchingCommunitiesViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchingCommunitiesViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .previewDisplayName("Dark Mode")
            
            SearchingCommunitiesViewControllerRepresentable()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .previewDisplayName("Light Mode")
        }
    }
}

struct SearchingCommunitiesViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SearchingCommunitiesViewController {
        return SearchingCommunitiesViewController()
    }
    
    func updateUIViewController(_ uiViewController: SearchingCommunitiesViewController, context: Context) {
        // No update needed
    }
}
#endif


