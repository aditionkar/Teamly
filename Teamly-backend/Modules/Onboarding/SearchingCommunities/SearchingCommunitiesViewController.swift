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
    
    private let locationAlertView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 14
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let alertTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enable Location"
        label.font = UIFont(name: "SFProDisplay-Semibold", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let alertDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "To search existing communities near your location"
        label.font = UIFont(name: "SFProText-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let disableButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Disable", for: .normal)
        button.titleLabel?.font = UIFont(name: "SFProText-Regular", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let enableButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Enable", for: .normal)
        button.titleLabel?.font = UIFont(name: "SFProText-Semibold", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let separatorLine1: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let separatorLine2: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // NEW: Secondary alert view for disable action
    private let secondaryAlertView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 14
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    private let secondaryAlertTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "We Need Your Location"
        label.font = UIFont(name: "SFProDisplay-Semibold", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let secondaryAlertDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "We need your location to search nearby communities"
        label.font = UIFont(name: "SFProText-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let secondarySeparatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let secondaryEnableButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Enable", for: .normal)
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
        view.addSubview(locationAlertView)
        
        // Add alert content
        locationAlertView.addSubview(alertTitleLabel)
        locationAlertView.addSubview(alertDescriptionLabel)
        locationAlertView.addSubview(separatorLine1)
        locationAlertView.addSubview(buttonsStackView)
        locationAlertView.addSubview(separatorLine2)
        
        buttonsStackView.addArrangedSubview(disableButton)
        buttonsStackView.addArrangedSubview(enableButton)
        
        // Setup secondary alert
        view.addSubview(secondaryAlertView)
        secondaryAlertView.addSubview(secondaryAlertTitleLabel)
        secondaryAlertView.addSubview(secondaryAlertDescriptionLabel)
        secondaryAlertView.addSubview(secondarySeparatorLine)
        secondaryAlertView.addSubview(secondaryEnableButton)
        
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
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10), // Reduced from 20 to 10
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10), // Reduced from -20 to -10
            backgroundImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 350) // Increased from 300 to 350
        ])

        // Location Alert View - Centered on top of the image
        NSLayoutConstraint.activate([
            locationAlertView.centerXAnchor.constraint(equalTo: backgroundImageView.centerXAnchor),
            locationAlertView.centerYAnchor.constraint(equalTo: backgroundImageView.centerYAnchor),
            locationAlertView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            locationAlertView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        // Alert Title Label
        NSLayoutConstraint.activate([
            alertTitleLabel.topAnchor.constraint(equalTo: locationAlertView.topAnchor, constant: 20),
            alertTitleLabel.leadingAnchor.constraint(equalTo: locationAlertView.leadingAnchor, constant: 16),
            alertTitleLabel.trailingAnchor.constraint(equalTo: locationAlertView.trailingAnchor, constant: -16)
        ])
        
        // Alert Description Label
        NSLayoutConstraint.activate([
            alertDescriptionLabel.topAnchor.constraint(equalTo: alertTitleLabel.bottomAnchor, constant: 8),
            alertDescriptionLabel.leadingAnchor.constraint(equalTo: locationAlertView.leadingAnchor, constant: 16),
            alertDescriptionLabel.trailingAnchor.constraint(equalTo: locationAlertView.trailingAnchor, constant: -16)
        ])
        
        // First Separator Line (between description and buttons)
        NSLayoutConstraint.activate([
            separatorLine1.topAnchor.constraint(equalTo: alertDescriptionLabel.bottomAnchor, constant: 20),
            separatorLine1.leadingAnchor.constraint(equalTo: locationAlertView.leadingAnchor),
            separatorLine1.trailingAnchor.constraint(equalTo: locationAlertView.trailingAnchor),
            separatorLine1.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        // Buttons Stack View
        NSLayoutConstraint.activate([
            buttonsStackView.topAnchor.constraint(equalTo: separatorLine1.bottomAnchor),
            buttonsStackView.leadingAnchor.constraint(equalTo: locationAlertView.leadingAnchor),
            buttonsStackView.trailingAnchor.constraint(equalTo: locationAlertView.trailingAnchor),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Second Separator Line (between buttons)
        NSLayoutConstraint.activate([
            separatorLine2.centerXAnchor.constraint(equalTo: locationAlertView.centerXAnchor),
            separatorLine2.topAnchor.constraint(equalTo: separatorLine1.bottomAnchor),
            separatorLine2.bottomAnchor.constraint(equalTo: buttonsStackView.bottomAnchor),
            separatorLine2.widthAnchor.constraint(equalToConstant: 0.5)
        ])
        
        // Location Alert View Bottom Constraint (based on buttons)
        NSLayoutConstraint.activate([
            locationAlertView.bottomAnchor.constraint(equalTo: buttonsStackView.bottomAnchor)
        ])
        
        // Secondary Alert View - Same position as first alert
        NSLayoutConstraint.activate([
            secondaryAlertView.centerXAnchor.constraint(equalTo: backgroundImageView.centerXAnchor),
            secondaryAlertView.centerYAnchor.constraint(equalTo: backgroundImageView.centerYAnchor),
            secondaryAlertView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            secondaryAlertView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        // Secondary Alert Title Label
        NSLayoutConstraint.activate([
            secondaryAlertTitleLabel.topAnchor.constraint(equalTo: secondaryAlertView.topAnchor, constant: 20),
            secondaryAlertTitleLabel.leadingAnchor.constraint(equalTo: secondaryAlertView.leadingAnchor, constant: 16),
            secondaryAlertTitleLabel.trailingAnchor.constraint(equalTo: secondaryAlertView.trailingAnchor, constant: -16)
        ])
        
        // Secondary Alert Description Label
        NSLayoutConstraint.activate([
            secondaryAlertDescriptionLabel.topAnchor.constraint(equalTo: secondaryAlertTitleLabel.bottomAnchor, constant: 8),
            secondaryAlertDescriptionLabel.leadingAnchor.constraint(equalTo: secondaryAlertView.leadingAnchor, constant: 16),
            secondaryAlertDescriptionLabel.trailingAnchor.constraint(equalTo: secondaryAlertView.trailingAnchor, constant: -16)
        ])
        
        // Secondary Separator Line (between description and button)
        NSLayoutConstraint.activate([
            secondarySeparatorLine.topAnchor.constraint(equalTo: secondaryAlertDescriptionLabel.bottomAnchor, constant: 20),
            secondarySeparatorLine.leadingAnchor.constraint(equalTo: secondaryAlertView.leadingAnchor),
            secondarySeparatorLine.trailingAnchor.constraint(equalTo: secondaryAlertView.trailingAnchor),
            secondarySeparatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        // Secondary Enable Button
        NSLayoutConstraint.activate([
            secondaryEnableButton.topAnchor.constraint(equalTo: secondarySeparatorLine.bottomAnchor),
            secondaryEnableButton.leadingAnchor.constraint(equalTo: secondaryAlertView.leadingAnchor),
            secondaryEnableButton.trailingAnchor.constraint(equalTo: secondaryAlertView.trailingAnchor),
            secondaryEnableButton.heightAnchor.constraint(equalToConstant: 44),
            secondaryAlertView.bottomAnchor.constraint(equalTo: secondaryEnableButton.bottomAnchor)
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
        
        // Update alert view backgrounds
        locationAlertView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        secondaryAlertView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        // Update alert label colors
        alertTitleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        alertDescriptionLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        secondaryAlertTitleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        secondaryAlertDescriptionLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update separator line colors
        separatorLine1.backgroundColor = isDarkMode ? UIColor.systemGray : UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        separatorLine2.backgroundColor = isDarkMode ? UIColor.systemGray : UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        secondarySeparatorLine.backgroundColor = isDarkMode ? UIColor.systemGray : UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        
        // Update button colors (systemBlue works well in both modes)
        // Buttons already use .systemBlue which adapts automatically
        
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
        disableButton.addTarget(self, action: #selector(disableButtonTapped), for: .touchUpInside)
        enableButton.addTarget(self, action: #selector(enableButtonTapped), for: .touchUpInside)
        secondaryEnableButton.addTarget(self, action: #selector(secondaryEnableButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func disableButtonTapped() {
        // Hide the first alert and show the secondary alert
        UIView.animate(withDuration: 0.3, animations: {
            self.locationAlertView.alpha = 0
        }) { _ in
            self.locationAlertView.isHidden = true
            
            // Show secondary alert
            self.secondaryAlertView.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.secondaryAlertView.alpha = 1
            }
        }
    }
    
    @objc private func enableButtonTapped() {
        handleLocationEnable()
    }
    
    @objc private func secondaryEnableButtonTapped() {
        // Hide secondary alert and proceed with location enable
        UIView.animate(withDuration: 0.3, animations: {
            self.secondaryAlertView.alpha = 0
        }) { _ in
            self.secondaryAlertView.isHidden = true
            self.handleLocationEnable()
        }
    }
    
    private func handleLocationEnable() {
        // Hide any visible alert view
        UIView.animate(withDuration: 0.3, animations: {
            if !self.locationAlertView.isHidden {
                self.locationAlertView.alpha = 0
            }
            if !self.secondaryAlertView.isHidden {
                self.secondaryAlertView.alpha = 0
            }
        }) { _ in
            self.locationAlertView.isHidden = true
            self.secondaryAlertView.isHidden = true
            
            // Show searching label
            UIView.animate(withDuration: 0.5) {
                self.searchingLabel.alpha = 1
            }
            
            // Wait for a few seconds then present modal
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.presentNextModal()
            }
        }
    }
    
    private func presentNextModal() {
        let collegesModalVC = CollegesModalViewController()
        
        if let sheet = collegesModalVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        collegesModalVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        present(collegesModalVC, animated: true)
    }
}

// MARK: - Colleges Modal View Controller
class CollegesModalViewController: UIViewController {
    
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Chennai , Tamil Nadu"
        label.font = UIFont(name: "SFProDisplay-Semibold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold)
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
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    private var colleges: [College] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupConstraints()
        updateColors()
        fetchCollegesFromSupabase()
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
        view.addSubview(loadingIndicator)
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
        loadingIndicator.color = isDarkMode ? .white : .black
        
        tableView.reloadData()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CollegeTableViewCell.self, forCellReuseIdentifier: "CollegeCell")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Fetch Colleges from Supabase
    private func fetchCollegesFromSupabase() {
        loadingIndicator.startAnimating()
        
        Task {
            do {
                let response: [College] = try await SupabaseManager.shared.client
                    .from("colleges")
                    .select("id, name, location")
                    .order("name", ascending: true)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.colleges = response
                    self.tableView.reloadData()
                    self.loadingIndicator.stopAnimating()
                }
                
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    print("Error fetching colleges: \(error)")
                    
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to load colleges. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - College Model (update to match your Supabase table)
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
        
        // Save college ID immediately
        saveCollegeId(college.id)
        
        // Then show verification screen
        let verificationVC = CollegeVerificationViewController()
        verificationVC.selectedCollege = college
        verificationVC.modalPresentationStyle = .fullScreen
        verificationVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        present(verificationVC, animated: true)
    }
    
    private func saveCollegeId(_ collegeId: Int) {
        // Show loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id
                
                // Save college using ProfileManager
                try await ProfileManager.shared.saveCollege(
                    userId: userId,
                    collegeId: collegeId
                )

                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    
                    // Show success message
                    let alert = UIAlertController(
                        title: "Success",
                        message: "College saved successfully!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
                
            } catch {
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    
                    print("Error saving college ID: \(error.localizedDescription)")
                    
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to save college. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
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
            
            // Join Button - Adjusted for better appearance with background
            joinButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            joinButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            joinButton.widthAnchor.constraint(equalToConstant: 70), // Increased width for better appearance
            joinButton.heightAnchor.constraint(equalToConstant: 36) // Fixed height for rounded corners
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
