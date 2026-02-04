//
//  MatchesViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import UIKit
import Supabase
import Foundation

// MARK: - Delegate Protocol
protocol FiltersModalDelegate: AnyObject {
    func didSelectFilters(skillLevels: Set<String>, timeFilters: Set<String>, isFillingFast: Bool)
}

// MARK: - Main View Controller
class MatchesViewController: UIViewController {
    
    // MARK: - Properties
    var sportName: String = "Football" // Default value, will be set from HomeViewController
    private var selectedDateIndex = 0 // Start with today selected
    private var dates: [(day: String, label: String, fullDate: String, dbDate: String)] = []
    private var filteredMatches: [DBMatch] = []
    private var isFillingFastFilterEnabled = false
    private var currentUserId: String = ""
    private var userCollegeId: Int = 0
    private let dataService = MatchesDataService()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Filter properties
    private var selectedSkillLevels: Set<String> = []
    private var selectedTimeFilters: Set<String> = [] // "day" or "night"
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let dateStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let matchesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 375, height: 185)
        layout.minimumLineSpacing = 5
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let noMatchesLabel: UILabel = {
        let label = UILabel()
        label.text = "No matches available on this day"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Glass Back Button - Updated Style
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
    
    // Plus Button for creating new post
    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        button.setImage(image, for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Funnel Button for filters
    private let funnelButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let image = UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: config)
        button.setImage(image, for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDates()
        setupDateChips()
        setupMatchesCollectionView()
        setupBackButton()
        setupPlusButton()
        setupFunnelButton()
        
        // Hide collection view initially
        matchesCollectionView.isHidden = true
        loadingIndicator.startAnimating()
        
        // Set the title label based on sportName
        titleLabel.text = "\(sportName) games"
        
        // Update colors based on current mode
        updateColors()
        
        // First, get user data, then load matches
        fetchUserDataAndLoadMatches()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
            updateDateChipsForModeChange()
            matchesCollectionView.reloadData()
        }
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
        
        // Setup loading indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add loading indicator
        view.addSubview(loadingIndicator)
        
        // Add all components to content view
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateScrollView)
        dateScrollView.addSubview(dateStackView)
        contentView.addSubview(matchesCollectionView)
        contentView.addSubview(noMatchesLabel)
        
        // Add buttons to main view (not content view so they stay fixed)
        view.addSubview(glassBackButton)
        view.addSubview(funnelButton)
        view.addSubview(plusButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Glass Back Button
            glassBackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            glassBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            glassBackButton.widthAnchor.constraint(equalToConstant: 40),
            glassBackButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Plus Button
            plusButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            plusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            plusButton.widthAnchor.constraint(equalToConstant: 40),
            plusButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Funnel Button (between back and plus)
            funnelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            funnelButton.trailingAnchor.constraint(equalTo: plusButton.leadingAnchor, constant: -10),
            funnelButton.widthAnchor.constraint(equalToConstant: 40),
            funnelButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: glassBackButton.bottomAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Date Scroll View
            dateScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            dateScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dateScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dateScrollView.heightAnchor.constraint(equalToConstant: 60),
            
            // Date Stack View
            dateStackView.topAnchor.constraint(equalTo: dateScrollView.topAnchor),
            dateStackView.leadingAnchor.constraint(equalTo: dateScrollView.leadingAnchor, constant: 16),
            dateStackView.trailingAnchor.constraint(equalTo: dateScrollView.trailingAnchor, constant: -16),
            dateStackView.bottomAnchor.constraint(equalTo: dateScrollView.bottomAnchor),
            dateStackView.heightAnchor.constraint(equalTo: dateScrollView.heightAnchor),
            
            // Matches Collection View
            matchesCollectionView.topAnchor.constraint(equalTo: dateScrollView.bottomAnchor, constant: 20),
            matchesCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            matchesCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            matchesCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            matchesCollectionView.heightAnchor.constraint(equalToConstant: 500),
            
            // No Matches Label
            noMatchesLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            noMatchesLabel.centerYAnchor.constraint(equalTo: matchesCollectionView.centerYAnchor),
            noMatchesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            noMatchesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupDates() {
        let calendar = Calendar.current
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd/MM/yy"
        
        let dbFormatter = DateFormatter()
        dbFormatter.dateFormat = "yyyy-MM-dd"
        
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "EEE"
        
        let today = Date()
        
        for dayOffset in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let displayDate = displayFormatter.string(from: date)
                let dbDate = dbFormatter.string(from: date)
                let dayNumber = calendar.component(.day, from: date)
                let dayLabel: String
                
                if dayOffset == 0 {
                    dayLabel = "Tod"
                } else if dayOffset == 1 {
                    dayLabel = "Tom"
                } else {
                    dayLabel = labelFormatter.string(from: date).prefix(3).capitalized
                }
                
                dates.append((day: "\(dayNumber)", label: dayLabel, fullDate: displayDate, dbDate: dbDate))
            }
        }
    }
    
    private func updateFunnelButtonAppearance() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update funnel button based on active filters
        let hasActiveFilters = !selectedSkillLevels.isEmpty || !selectedTimeFilters.isEmpty || isFillingFastFilterEnabled
        
        if hasActiveFilters {
            // Active filters: show filled icon with tint
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
            let image = UIImage(systemName: "line.3.horizontal.decrease.circle.fill", withConfiguration: config)
            funnelButton.setImage(image, for: .normal)
            funnelButton.tintColor = .systemGreen
        } else {
            // No active filters: show outline icon
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
            let image = UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: config)
            funnelButton.setImage(image, for: .normal)
            funnelButton.tintColor = .systemGreen
        }
    }
    
    private func fetchUserDataAndLoadMatches() {
        Task {
            do {
                print("=== FETCHING USER DATA FOR MATCHES SCREEN ===")
                
                // 1. Get current user ID from auth
                let session = try await SupabaseManager.shared.client.auth.session
                currentUserId = session.user.id.uuidString
                print("Current user ID: \(currentUserId)")
                
                // 2. Fetch user profile to get college ID
                let homeDataService = HomeDataService()
                guard let userProfile = try await homeDataService.fetchUserProfile(userId: currentUserId) else {
                    print("Failed to fetch user profile")
                    await showError("Failed to load user data")
                    return
                }
                
                userCollegeId = userProfile.college_id
                print("User college ID: \(userCollegeId)")
                
                // 3. Load matches for the initially selected date
                await loadMatchesForSelectedDate()
                
            } catch {
                print("❌ ERROR fetching user data: \(error)")
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.showError("Failed to load data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadMatchesForSelectedDate() async {
        guard selectedDateIndex < dates.count else {
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.noMatchesLabel.isHidden = false
                self.matchesCollectionView.isHidden = true
            }
            return
        }
        
        let selectedDate = dates[selectedDateIndex]
        print("Loading matches for date: \(selectedDate.dbDate)")
        print("Applied filters - Skill Levels: \(selectedSkillLevels), Time: \(selectedTimeFilters), Filling Fast: \(isFillingFastFilterEnabled)")
        
        do {
            // Fetch matches from Supabase
            let dbMatches = try await dataService.fetchMatchesForSportAndDate(
                sportName: sportName,
                date: selectedDate.dbDate,
                collegeId: userCollegeId,
                currentUserId: currentUserId
            )
            
            // Apply all filters
            var filteredDBMatches = dbMatches
            
            // 1. Apply filling fast filter if enabled
            if isFillingFastFilterEnabled {
                filteredDBMatches = filteredDBMatches.filter { match in
                    let fillRatio = Double(match.playersRSVPed) / Double(match.playersNeeded)
                    return fillRatio >= 0.66 // Show ONLY matches that are 66%+ filled (red slots)
                }
                print("After filling fast filter: \(filteredDBMatches.count) matches")
            }
            
            // 2. Apply skill level filters if any are selected
            if !selectedSkillLevels.isEmpty {
                filteredDBMatches = filteredDBMatches.filter { match in
                    guard let skillLevel = match.skillLevel?.lowercased() else { return false }
                    return selectedSkillLevels.contains(skillLevel)
                }
                print("After skill level filter: \(filteredDBMatches.count) matches")
            }
            
            // 3. Apply time filters if any are selected
            if !selectedTimeFilters.isEmpty {
                filteredDBMatches = filteredDBMatches.filter { match in
                    if selectedTimeFilters.contains("day") && selectedTimeFilters.contains("night") {
                        // Show both day and night matches
                        return true
                    } else if selectedTimeFilters.contains("day") {
                        // Show only day matches (6 AM to 5:59 PM)
                        return !match.isNightTime
                    } else if selectedTimeFilters.contains("night") {
                        // Show only night matches (6 PM to 5:59 AM)
                        return match.isNightTime
                    }
                    return false
                }
                print("After time filter: \(filteredDBMatches.count) matches")
            }
            
            await MainActor.run {
                self.filteredMatches = filteredDBMatches
                self.matchesCollectionView.reloadData()
                self.loadingIndicator.stopAnimating()
                
                // Show/hide no matches message
                if self.filteredMatches.isEmpty {
                    self.noMatchesLabel.isHidden = false
                    self.matchesCollectionView.isHidden = true
                    print("No matches found for \(self.sportName) on \(selectedDate.fullDate) with applied filters")
                } else {
                    self.noMatchesLabel.isHidden = true
                    self.matchesCollectionView.isHidden = false
                    print("Displaying \(self.filteredMatches.count) matches for \(self.sportName)")
                }
            }
            
        } catch {
            print("❌ ERROR loading matches: \(error)")
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.showError("Failed to load matches: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupDateChips() {
        // Clear existing chips
        dateStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        for (index, date) in dates.enumerated() {
            let chip = DateChipView(day: date.day, label: date.label, isSelected: index == selectedDateIndex, isDarkMode: isDarkMode)
            chip.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                chip.widthAnchor.constraint(equalToConstant: 60),
                chip.heightAnchor.constraint(equalToConstant: 60)
            ])
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dateChipTapped(_:)))
            chip.addGestureRecognizer(tapGesture)
            chip.tag = index
            
            dateStackView.addArrangedSubview(chip)
        }
    }
    
    private func setupMatchesCollectionView() {
        matchesCollectionView.delegate = self
        matchesCollectionView.dataSource = self
        matchesCollectionView.register(MatchCellCard.self, forCellWithReuseIdentifier: "MatchCellCard")
    }
    
    private func setupBackButton() {
        glassBackButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    private func setupPlusButton() {
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
    }
    
    private func setupFunnelButton() {
        funnelButton.addTarget(self, action: #selector(funnelButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - New method to update date chips for mode change
    private func updateDateChipsForModeChange() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        for (index, chipView) in dateStackView.arrangedSubviews.enumerated() {
            if let chip = chipView as? DateChipView {
                chip.updateDarkMode(isDarkMode)
                chip.isSelected = (index == selectedDateIndex)
            }
        }
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        contentView.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        noMatchesLabel.textColor = isDarkMode ? .lightGray : .darkGray
        matchesCollectionView.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        updateGlassButton(glassBackButton, isDarkMode: isDarkMode)
        updateGlassButton(plusButton, isDarkMode: isDarkMode)
        updateGlassButton(funnelButton, isDarkMode: isDarkMode)
        updateFunnelButtonAppearance()
    }
    
    private func updateGlassButton(_ button: UIButton, isDarkMode: Bool) {
        button.backgroundColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.1) :
            UIColor(white: 0, alpha: 0.05)
        button.layer.borderColor = (isDarkMode ?
            UIColor(white: 1, alpha: 0.2) :
            UIColor(white: 0, alpha: 0.1)).cgColor
        
        // Don't override tintColor for funnel button if it has active filters
        if button == funnelButton && (!selectedSkillLevels.isEmpty || !selectedTimeFilters.isEmpty || isFillingFastFilterEnabled) {
            // Keep the blue tint for active filters
            return
        }
        
        button.tintColor = isDarkMode ? .systemGreenDark : .systemGreen
    }
    
    // MARK: - Actions
    @objc private func dateChipTapped(_ gesture: UITapGestureRecognizer) {
        guard let chip = gesture.view as? DateChipView else { return }
        
        // Deselect previous
        if let previousChip = dateStackView.arrangedSubviews[selectedDateIndex] as? DateChipView {
            previousChip.isSelected = false
        }
        
        // Select new
        selectedDateIndex = chip.tag
        chip.isSelected = true
        
        // Show loading indicator
        loadingIndicator.startAnimating()
        matchesCollectionView.isHidden = true
        noMatchesLabel.isHidden = true
        
        // Load matches for the selected date
        Task {
            await loadMatchesForSelectedDate()
        }
    }
    
    @objc private func funnelButtonTapped() {
        let modalViewController = FiltersModalViewController()
        modalViewController.modalPresentationStyle = .overCurrentContext
        modalViewController.modalTransitionStyle = .crossDissolve
        
        // Pass current selections to modal
        modalViewController.selectedSkillLevels = selectedSkillLevels
        modalViewController.selectedTimeFilters = selectedTimeFilters
        modalViewController.isFillingFastEnabled = isFillingFastFilterEnabled
        
        // Set delegate
        modalViewController.delegate = self
        
        modalViewController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        present(modalViewController, animated: true, completion: nil)
    }
    
    @objc private func backButtonTapped() {
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func plusButtonTapped() {
        let sportsPostVC = SportsPostViewController()
        sportsPostVC.modalPresentationStyle = .pageSheet
        sportsPostVC.preSelectedSportName = sportName
        
        if let sheet = sportsPostVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 20
        }
        
        sportsPostVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        present(sportsPostVC, animated: true)
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension MatchesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredMatches.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MatchCellCard", for: indexPath) as! MatchCellCard
        let match = filteredMatches[indexPath.item]
        
        cell.configure(with: match, onTap: nil)
        cell.updateColors(isDarkMode: traitCollection.userInterfaceStyle == .dark)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let match = filteredMatches[indexPath.item]
        print("Selected match: \(match.venue)")
        
        // Navigate to MatchInformationViewController
        let matchInfoVC = MatchInformationViewController()
        matchInfoVC.match = match
        
        if let navController = navigationController {
            navController.pushViewController(matchInfoVC, animated: true)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        } else {
            let navController = UINavigationController(rootViewController: matchInfoVC)
            navController.modalPresentationStyle = .fullScreen
            navController.setNavigationBarHidden(true, animated: false)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
            present(navController, animated: true)
        }
    }
}

// MARK: - FiltersModalDelegate
extension MatchesViewController: FiltersModalDelegate {
    func didSelectFilters(skillLevels: Set<String>, timeFilters: Set<String>, isFillingFast: Bool) {
        // Update the filter selections
        selectedSkillLevels = skillLevels
        selectedTimeFilters = timeFilters
        isFillingFastFilterEnabled = isFillingFast
        
        print("Selected skill levels: \(skillLevels)")
        print("Selected time filters: \(timeFilters)")
        print("Filling fast enabled: \(isFillingFast)")
        
        // Update the funnel button appearance
        updateFunnelButtonAppearance()
        
        // Show loading indicator
        loadingIndicator.startAnimating()
        matchesCollectionView.isHidden = true
        noMatchesLabel.isHidden = true
        
        // Reload matches with the new filters immediately
        Task {
            await loadMatchesForSelectedDate()
        }
    }
}

// MARK: - Filters Modal View Controller
class FiltersModalViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: FiltersModalDelegate?
    var selectedSkillLevels: Set<String> = []
    var selectedTimeFilters: Set<String> = []
    var isFillingFastEnabled: Bool = false
    
    // Skill Level buttons - using FilterButtonView
    private var beginnerButton: FilterButtonView!
    private var intermediateButton: FilterButtonView!
    private var experiencedButton: FilterButtonView!
    private var advancedButton: FilterButtonView!
    
    // Time buttons - using NewStyleButtonView
    private var dayButton: NewStyleButtonView!
    private var nightButton: NewStyleButtonView!
    
    // Filling Fast button
    private var fillingFastButton: FilterButtonView!
    
    // Container for the modal content (for animation)
    private let contentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateColors()
        applyCurrentSelections()
        
        // Start with container completely off-screen
        contentContainer.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate container sliding up in one smooth animation
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.contentContainer.transform = .identity
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    private func setupUI() {
        // Set up the view hierarchy
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Add tap gesture to dismiss when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        // Add pan gesture to dismiss by sliding down
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        contentContainer.addGestureRecognizer(panGesture)
        
        view.addSubview(contentContainer)
        
        // Background for the content (will be set in updateColors())
        let contentBackground = UIView()
        contentBackground.layer.cornerRadius = 20
        contentBackground.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentBackground.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(contentBackground)
        
        // Handle bar at top
        let handleBar = UIView()
        handleBar.layer.cornerRadius = 2.5
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(handleBar)
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "Filters"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(titleLabel)
        
        // Skill Level section
        let skillLevelLabel = UILabel()
        skillLevelLabel.text = "Skill Level"
        skillLevelLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        skillLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(skillLevelLabel)
        
        // Skill Level buttons - using FilterButtonView
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        // Initialize with isSelected based on current selections
        beginnerButton = FilterButtonView(
            title: "Beginner",
            icon: "",
            isSelected: selectedSkillLevels.contains("beginner"),
            isDarkMode: isDarkMode
        )
        beginnerButton.setColor(.systemTeal.withAlphaComponent(0.7))

        intermediateButton = FilterButtonView(
            title: "Intermediate",
            icon: "",
            isSelected: selectedSkillLevels.contains("intermediate"),
            isDarkMode: isDarkMode
        )
        intermediateButton.setColor(.systemYellow.withAlphaComponent(0.7))

        experiencedButton = FilterButtonView(
            title: "Experienced",
            icon: "",
            isSelected: selectedSkillLevels.contains("experienced"),
            isDarkMode: isDarkMode
        )
        experiencedButton.setColor(.systemOrange.withAlphaComponent(0.7))

        advancedButton = FilterButtonView(
            title: "Advanced",
            icon: "",
            isSelected: selectedSkillLevels.contains("advanced"),
            isDarkMode: isDarkMode
        )
        advancedButton.setColor(.systemRed.withAlphaComponent(0.7))
        
        let skillStackView = UIStackView(arrangedSubviews: [beginnerButton, intermediateButton])
        skillStackView.axis = .horizontal
        skillStackView.spacing = 12
        skillStackView.distribution = .fillEqually
        skillStackView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(skillStackView)
        
        let skillStackView2 = UIStackView(arrangedSubviews: [experiencedButton, advancedButton])
        skillStackView2.axis = .horizontal
        skillStackView2.spacing = 12
        skillStackView2.distribution = .fillEqually
        skillStackView2.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(skillStackView2)
        
        // First separator
        let separator1 = createSeparator()
        contentContainer.addSubview(separator1)
        
        // Time section
        let timeLabel = UILabel()
        timeLabel.text = "Time"
        timeLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(timeLabel)
        
        // Time buttons - using NewStyleButtonView
        dayButton = NewStyleButtonView(
            title: "Day",
            icon: "sun.horizon",
            isSelected: selectedTimeFilters.contains("day"),
            isDarkMode: isDarkMode
        )
        dayButton.setIconColor(.systemYellow)
        nightButton = NewStyleButtonView(
            title: "Night",
            icon: "moon.fill",
            isSelected: selectedTimeFilters.contains("night"),
            isDarkMode: isDarkMode
        )
        nightButton.setIconColor(.systemBlue)
        
        let timeStackView = UIStackView(arrangedSubviews: [dayButton, nightButton])
        timeStackView.axis = .horizontal
        timeStackView.spacing = 12
        timeStackView.distribution = .fillEqually
        timeStackView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(timeStackView)
        
        // Second separator
        let separator2 = createSeparator()
        contentContainer.addSubview(separator2)
        
        // Availability section
        let availabilityLabel = UILabel()
        availabilityLabel.text = "Availability"
        availabilityLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        availabilityLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(availabilityLabel)
        
        // Filling Fast button
        fillingFastButton = FilterButtonView(
            title: "Filling fast",
            icon: "chart.line.uptrend.xyaxis",
            isSelected: isFillingFastEnabled,
            isDarkMode: isDarkMode,
            isFillingFastButton: true
        )
        fillingFastButton.setColor(.systemGreen.withAlphaComponent(0.7))
        
        let fillingFastStackView = UIStackView(arrangedSubviews: [fillingFastButton])
        fillingFastStackView.axis = .horizontal
        fillingFastStackView.distribution = .fillEqually
        fillingFastStackView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(fillingFastStackView)
        
        // Clear All Button
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear All", for: .normal)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        contentContainer.addSubview(clearButton)
        
        // Add tap gestures
        addTapGesture(to: beginnerButton)
        addTapGesture(to: intermediateButton)
        addTapGesture(to: experiencedButton)
        addTapGesture(to: advancedButton)
        addTapGesture(to: dayButton)
        addTapGesture(to: nightButton)
        addTapGesture(to: fillingFastButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Content container (full width, height based on content)
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content background (covers entire container)
            contentBackground.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            contentBackground.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            contentBackground.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            contentBackground.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            
            handleBar.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 12),
            handleBar.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 40),
            handleBar.heightAnchor.constraint(equalToConstant: 5),
            
            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            
            skillLevelLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            skillLevelLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            
            skillStackView.topAnchor.constraint(equalTo: skillLevelLabel.bottomAnchor, constant: 16),
            skillStackView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            skillStackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            
            skillStackView2.topAnchor.constraint(equalTo: skillStackView.bottomAnchor, constant: 12),
            skillStackView2.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            skillStackView2.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            
            // First separator
            separator1.topAnchor.constraint(equalTo: skillStackView2.bottomAnchor, constant: 30),
            separator1.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            separator1.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            separator1.heightAnchor.constraint(equalToConstant: 1),
            
            // Time section
            timeLabel.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: 30),
            timeLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            
            timeStackView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            timeStackView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            timeStackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            
            // Second separator
            separator2.topAnchor.constraint(equalTo: timeStackView.bottomAnchor, constant: 30),
            separator2.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            separator2.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            separator2.heightAnchor.constraint(equalToConstant: 1),
            
            // Availability section
            availabilityLabel.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: 30),
            availabilityLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            
            fillingFastStackView.topAnchor.constraint(equalTo: availabilityLabel.bottomAnchor, constant: 16),
            fillingFastStackView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            fillingFastStackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),
            
            clearButton.topAnchor.constraint(equalTo: fillingFastStackView.bottomAnchor, constant: 40),
            clearButton.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            clearButton.heightAnchor.constraint(equalToConstant: 40),
            clearButton.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -34)
        ])
        
        // Update handle bar color
        updateColors()
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }
    
    private func applyCurrentSelections() {
        // Apply skill level selections
        beginnerButton.isSelected = selectedSkillLevels.contains("beginner")
        intermediateButton.isSelected = selectedSkillLevels.contains("intermediate")
        experiencedButton.isSelected = selectedSkillLevels.contains("experienced")
        advancedButton.isSelected = selectedSkillLevels.contains("advanced")
        
        // Apply time selections
        dayButton.isSelected = selectedTimeFilters.contains("day")
        nightButton.isSelected = selectedTimeFilters.contains("night")
        
        // Apply filling fast selection
        fillingFastButton.isSelected = isFillingFastEnabled
    }
    
    private func sendSelectedFilters() {
        // Collect selected skill levels
        var selectedSkills: Set<String> = []
        if beginnerButton.isSelected { selectedSkills.insert("beginner") }
        if intermediateButton.isSelected { selectedSkills.insert("intermediate") }
        if experiencedButton.isSelected { selectedSkills.insert("experienced") }
        if advancedButton.isSelected { selectedSkills.insert("advanced") }
        
        // Collect selected time filters
        var selectedTimes: Set<String> = []
        if dayButton.isSelected { selectedTimes.insert("day") }
        if nightButton.isSelected { selectedTimes.insert("night") }
        
        delegate?.didSelectFilters(
            skillLevels: selectedSkills,
            timeFilters: selectedTimes,
            isFillingFast: fillingFastButton.isSelected
        )
    }
    
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update content background
        if let contentBackground = contentContainer.subviews.first {
            contentBackground.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        }
        
        // Update labels
        for subview in contentContainer.subviews {
            if let label = subview as? UILabel {
                label.textColor = isDarkMode ? .primaryWhite : .primaryBlack
            }
        }
        
        // Update skill level buttons unselected state
        let skillButtons = [beginnerButton, intermediateButton, experiencedButton, advancedButton]
        skillButtons.forEach { button in
            if let button = button, !button.isSelected {
                button.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
            }
        }
        
        // Update filling fast button unselected state
        if !fillingFastButton.isSelected {
            fillingFastButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        }
        
        // Update handle bar
        if let handleBar = contentContainer.subviews.first(where: { $0.constraints.contains(where: { $0.firstAttribute == .height && $0.constant == 5 }) }) {
            handleBar.backgroundColor = isDarkMode ?
                UIColor.white.withAlphaComponent(0.3) :
                UIColor.black.withAlphaComponent(0.2)
        }
        
        // Update separators
        for subview in contentContainer.subviews {
            if subview.constraints.contains(where: { $0.firstAttribute == .height && $0.constant == 1 }) {
                subview.backgroundColor = isDarkMode ?
                    UIColor.white.withAlphaComponent(0.2) :
                    UIColor.black.withAlphaComponent(0.2)
            }
        }
        
        // Update clear button text color
        if let clearButton = contentContainer.subviews.first(where: { $0 is UIButton && ($0 as! UIButton).title(for: .normal) == "Clear All" }) as? UIButton {
            clearButton.setTitleColor(isDarkMode ? .systemBlue : .systemBlue, for: .normal)
        }
    }
    
    // MARK: - Button Actions
    @objc private func buttonTapped(_ gesture: UITapGestureRecognizer) {
        guard let button = gesture.view else { return }
        
        // Toggle the selection state
        if let filterButton = button as? FilterButtonView {
            filterButton.isSelected.toggle()
        } else if let newStyleButton = button as? NewStyleButtonView {
            newStyleButton.isSelected.toggle()
        }
        
        // DO NOT dismiss modal here - only update the button state
        // Modal will dismiss when user slides down or taps outside
    }
    
    @objc private func clearButtonTapped() {
        // Clear all selections
        beginnerButton.isSelected = false
        intermediateButton.isSelected = false
        experiencedButton.isSelected = false
        advancedButton.isSelected = false
        dayButton.isSelected = false
        nightButton.isSelected = false
        fillingFastButton.isSelected = false
        
        // DO NOT send filters or dismiss here
        // Wait for user to slide down or tap outside
    }
    
    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !contentContainer.frame.contains(location) {
            // Send current selections and dismiss
            sendSelectedFilters()
            dismissModal()
        }
    }
    
    // MARK: - Pan Gesture Handler
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            // Only allow downward dragging
            if translation.y > 0 {
                contentContainer.transform = CGAffineTransform(translationX: 0, y: translation.y)
                // Fade background as we drag down
                let progress = min(translation.y / 200, 1.0)
                view.backgroundColor = UIColor.black.withAlphaComponent(0.5 * (1 - progress))
            }
            
        case .ended:
            // If dragged down more than 150 points or fast downward swipe
            if translation.y > 150 || velocity.y > 800 {
                dismissModal()
            } else {
                // Snap back to original position with spring animation
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                    self.contentContainer.transform = .identity
                    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                }
            }
            
        default:
            break
        }
    }
    
    private func dismissModal() {
        // Always send current selections when dismissing
        sendSelectedFilters()
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseIn) {
            self.contentContainer.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
        } completion: { _ in
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    // MARK: - Private Methods
    private func addTapGesture(to button: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonTapped(_:)))
        button.addGestureRecognizer(tapGesture)
        button.isUserInteractionEnabled = true
    }
}

// MARK: - UIGestureRecognizerDelegate
extension FiltersModalViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: view)
        return !contentContainer.frame.contains(location)
    }
}

// MARK: - Date Chip View
class DateChipView: UIView {
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let labelLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private var isDarkMode: Bool
    
    var isSelected: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    init(day: String, label: String, isSelected: Bool, isDarkMode: Bool) {
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        self.dayLabel.text = day
        self.labelLabel.text = label
        self.isSelected = isSelected
        setupUI()
        updateAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Make it fully rounded (perfect circle)
        layer.cornerRadius = 30
        layer.masksToBounds = true
        
        let stackView = UIStackView(arrangedSubviews: [dayLabel, labelLabel])
        stackView.axis = .vertical
        stackView.spacing = 3
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func updateAppearance() {
        if isSelected {
            // Selected state: In dark mode = white bg with black text, in light mode = black bg with white text
            backgroundColor = isDarkMode ? .white : .black
            dayLabel.textColor = isDarkMode ? .black : .white
            labelLabel.textColor = isDarkMode ? .black : .white
        } else {
            // Unselected state
            backgroundColor = isDarkMode ? .secondaryDark : .tertiaryLight
            dayLabel.textColor = isDarkMode ? .white : .black
            labelLabel.textColor = isDarkMode ? .gray : .darkGray
        }
        
        // Ensure perfect circle
        layer.cornerRadius = 30
        layer.masksToBounds = true
    }
    
    func updateDarkMode(_ isDarkMode: Bool) {
        self.isDarkMode = isDarkMode
        updateAppearance()
    }
}

// MARK: - Filter Button View
class FilterButtonView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var isDarkMode: Bool
    private var isFillingFastButton: Bool = false
    
    var isSelected: Bool = false {
        didSet {
            updateAppearance(isSelected: isSelected)
        }
    }
    
    private var selectedColor: UIColor = .white
    
    init(title: String, icon: String, isSelected: Bool, isDarkMode: Bool, isFillingFastButton: Bool = false) {
        self.isDarkMode = isDarkMode
        self.isFillingFastButton = isFillingFastButton
        super.init(frame: .zero)
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: icon)
        self.isSelected = isSelected
        setupUI()
        updateAppearance(isSelected: isSelected)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        layer.cornerRadius = 20
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, iconImageView])
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            heightAnchor.constraint(equalToConstant: 40),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }
    
    private func updateAppearance(isSelected: Bool) {
        if isSelected {
            if isFillingFastButton {
                // Special handling for filling fast button in light mode
                if isDarkMode {
                    // Dark mode selected: white bg, black text
                    titleLabel.textColor = .black
                    iconImageView.tintColor = .black
                    backgroundColor = .white
                } else {
                    // Light mode selected: black bg, white text
                    titleLabel.textColor = .white
                    iconImageView.tintColor = .white
                    backgroundColor = .black
                }
            } else {
                // Regular button selected state
                titleLabel.textColor = .black
                iconImageView.tintColor = .black
                backgroundColor = selectedColor
            }
        } else {
            // Unselected state for all buttons
            titleLabel.textColor = isDarkMode ? .white : .black
            iconImageView.tintColor = isDarkMode ? .white : .black
            backgroundColor = isDarkMode ? .secondaryDark : .tertiaryLight
        }
    }
    
    // MARK: - Public Methods
    func setColor(_ color: UIColor) {
        selectedColor = color
        updateAppearance(isSelected: isSelected)
    }
}

// MARK: - New Style Button View (for Filters, Filling Fast, Day/Night buttons)
class NewStyleButtonView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var isDarkMode: Bool
    
    var isSelected: Bool = false {
        didSet {
            updateAppearance(isSelected: isSelected)
        }
    }
    
    init(title: String, icon: String? = nil, isSelected: Bool = false, isDarkMode: Bool = true) {
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        titleLabel.text = title
        if let icon = icon {
            iconImageView.image = UIImage(systemName: icon)
        }
        self.isSelected = isSelected
        setupUI()
        updateAppearance(isSelected: isSelected)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        layer.cornerRadius = 20

        let stackView = UIStackView(arrangedSubviews: [iconImageView, titleLabel])
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            heightAnchor.constraint(equalToConstant: 40),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }
    
    private func updateAppearance(isSelected: Bool) {
        titleLabel.textColor = isSelected ? .black : (isDarkMode ? .white : .black)
        iconImageView.tintColor = isSelected ? .black : (isDarkMode ? .white : .black)
        backgroundColor = isSelected ? (isDarkMode ? .white.withAlphaComponent(0.7) : .white) : (isDarkMode ? .tertiaryDark : .tertiaryLight)
    }

    func setIconColor(_ color: UIColor) {
        iconImageView.tintColor = color
    }
}// MARK: - SwiftUI Preview for UIKit
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct FootballGamesViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FootballGamesViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            FootballGamesViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct FootballGamesViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MatchesViewController {
        return MatchesViewController()
    }
    
    func updateUIViewController(_ uiViewController: MatchesViewController, context: Context) {
        // No update needed
    }
}
#endif
