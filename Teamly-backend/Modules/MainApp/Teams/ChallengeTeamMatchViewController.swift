//
//  ChallengeTeamMatchViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 28/01/26.
//

import UIKit

class ChallengeTeamMatchViewController: UIViewController {
    
    // MARK: - Properties
    private var selectedTeam: TeamChallenge?
    private var challengeTeams: [TeamChallenge] = []
    private let dataService = ChallengeMatchDataService.shared
    
    var availableTeams: [Team] = []
    var currentTeam: BackendTeam?
    private var isTeamListExpanded = false
    private var isChallengeModeEnabled = false
    
    // MARK: - Picker Properties
    private let timePicker = UIDatePicker()
    private let datePicker = UIDatePicker()
    private var activeTimeField: UIButton? // Track which time field is active
    private var fromTime: Date?
    private var toTime: Date?
    private var selectedDate: Date?
    
    // MARK: - UI Components
    private let dimmedView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let handleBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Challenge Team"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Venue Field
    private let venueField: UITextField = {
        let field = UITextField()
        field.layer.cornerRadius = 25
        
        // Padding view
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        field.leftView = paddingView
        field.leftViewMode = .always

        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    // Time Fields (Updated to UIButton)
    private let timeContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let timeIconLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "Time"
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fromTimeButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set placeholder text
        button.setTitle("From", for: .normal)
        button.contentHorizontalAlignment = .center
        
        return button
    }()
    
    private let toTimeButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set placeholder text
        button.setTitle("To", for: .normal)
        button.contentHorizontalAlignment = .center
        
        return button
    }()
    
    // Date Field (Updated to UIButton)
    private let dateContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let dateIconLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "Date"
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set placeholder text
        button.setTitle("Select date", for: .normal)
        button.contentHorizontalAlignment = .center
        
        return button
    }()
    
    // Challenge Mode Toggle Section
    private let challengeModeContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let challengeIconLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let challengeModeLabel: UILabel = {
        let label = UILabel()
        label.text = "Challenge"
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let challengeModeSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    // Challenge Team Dropdown
    private let challengeTeamButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.setTitle("Challenge team", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.contentHorizontalAlignment = .leading
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let dropdownIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        imageView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Team List Container - This will replace the button when expanded
    private let teamListContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // Challenge Button
    private let challengeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Challenge", for: .normal)
        button.setTitleColor(.primaryWhite, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var containerViewHeightConstraint: NSLayoutConstraint!
    private var teamListHeightConstraint: NSLayoutConstraint!
    private var containerBottomConstraint: NSLayoutConstraint!
    
    var availableTeamNames: [String] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadChallengeTeams()
        setupActions()
        setupPickers()
        updateColors()
        updateChallengeSectionVisibility()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        
        let challengeButtonContainer = UIView()
        challengeButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        challengeButtonContainer.addSubview(challengeButton)
        
        containerView.addSubview(handleBar)
        containerView.addSubview(titleLabel)
        containerView.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        // Add venue field
        contentStackView.addArrangedSubview(venueField)
        
        // Add time container
        setupTimeContainer()
        contentStackView.addArrangedSubview(timeContainer)
        
        // Add date container
        setupDateContainer()
        contentStackView.addArrangedSubview(dateContainer)
        
        // Add challenge mode container
        setupChallengeModeContainer()
        contentStackView.addArrangedSubview(challengeModeContainer)
        
        // Add challenge team dropdown
        let challengeContainer = UIView()
        challengeContainer.translatesAutoresizingMaskIntoConstraints = false
        challengeContainer.addSubview(challengeTeamButton)
        challengeTeamButton.addSubview(dropdownIcon)
        
        contentStackView.addArrangedSubview(challengeContainer)
        
        // Add team list container
        teamListContainer.addSubview(tableView)
        contentStackView.addArrangedSubview(challengeButtonContainer)
        contentStackView.insertArrangedSubview(teamListContainer, at: contentStackView.arrangedSubviews.count - 2)
        
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 600)
        teamListHeightConstraint = teamListContainer.heightAnchor.constraint(equalToConstant: 0)
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 600)
        
        NSLayoutConstraint.activate([
            // Dimmed View
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container View
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerViewHeightConstraint,
            containerBottomConstraint,
            
            handleBar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            handleBar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 40),
            handleBar.heightAnchor.constraint(equalToConstant: 5),
            
            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 40),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -40),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -80),
            
            venueField.heightAnchor.constraint(equalToConstant: 50),
            
            // Time container constraints
            timeContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Date container constraints
            dateContainer.heightAnchor.constraint(equalToConstant: 60),
            
            challengeTeamButton.topAnchor.constraint(equalTo: challengeContainer.topAnchor),
            challengeTeamButton.leadingAnchor.constraint(equalTo: challengeContainer.leadingAnchor),
            challengeTeamButton.trailingAnchor.constraint(equalTo: challengeContainer.trailingAnchor),
            challengeTeamButton.bottomAnchor.constraint(equalTo: challengeContainer.bottomAnchor),
            challengeTeamButton.heightAnchor.constraint(equalToConstant: 50),
            
            dropdownIcon.trailingAnchor.constraint(equalTo: challengeTeamButton.trailingAnchor, constant: -20),
            dropdownIcon.centerYAnchor.constraint(equalTo: challengeTeamButton.centerYAnchor),
     
            tableView.topAnchor.constraint(equalTo: teamListContainer.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: teamListContainer.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: teamListContainer.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: teamListContainer.bottomAnchor, constant: -16),
            teamListHeightConstraint,

            challengeButton.centerXAnchor.constraint(equalTo: challengeButtonContainer.centerXAnchor),
            challengeButton.topAnchor.constraint(equalTo: challengeButtonContainer.topAnchor),
            challengeButton.bottomAnchor.constraint(equalTo: challengeButtonContainer.bottomAnchor),
            challengeButton.heightAnchor.constraint(equalToConstant: 32),
            challengeButton.widthAnchor.constraint(equalToConstant: 120)
        ])
        
        // Add tap gesture to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmedViewTap))
        dimmedView.addGestureRecognizer(tapGesture)
        
        // Add pan gesture for swipe down to dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        containerView.addGestureRecognizer(panGesture)
        
        dimmedView.alpha = 0
    }
    
    private func setupTimeContainer() {
        timeContainer.addSubview(timeIconLabel)
        timeContainer.addSubview(timeLabel)
        timeContainer.addSubview(fromTimeButton)
        timeContainer.addSubview(toTimeButton)
        
        NSLayoutConstraint.activate([
            // Horizontal arrangement
            timeIconLabel.leadingAnchor.constraint(equalTo: timeContainer.leadingAnchor),
            timeIconLabel.topAnchor.constraint(greaterThanOrEqualTo: timeContainer.topAnchor),
            timeIconLabel.bottomAnchor.constraint(lessThanOrEqualTo: timeContainer.bottomAnchor),
            timeIconLabel.centerYAnchor.constraint(equalTo: timeContainer.centerYAnchor),
            
            timeLabel.leadingAnchor.constraint(equalTo: timeIconLabel.trailingAnchor, constant: 12),
            timeLabel.centerYAnchor.constraint(equalTo: timeIconLabel.centerYAnchor),
            
            fromTimeButton.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 29),
            fromTimeButton.centerYAnchor.constraint(equalTo: timeContainer.centerYAnchor),
            fromTimeButton.heightAnchor.constraint(equalToConstant: 50),
            fromTimeButton.widthAnchor.constraint(equalToConstant: 100),
            
            toTimeButton.leadingAnchor.constraint(equalTo: fromTimeButton.trailingAnchor, constant: 12),
            toTimeButton.centerYAnchor.constraint(equalTo: timeContainer.centerYAnchor),
            toTimeButton.trailingAnchor.constraint(equalTo: timeContainer.trailingAnchor),
            toTimeButton.heightAnchor.constraint(equalToConstant: 50),
            toTimeButton.widthAnchor.constraint(equalTo: fromTimeButton.widthAnchor)
        ])
    }
    
    private func setupDateContainer() {
        dateContainer.addSubview(dateIconLabel)
        dateContainer.addSubview(dateLabel)
        dateContainer.addSubview(dateButton)
        
        NSLayoutConstraint.activate([
            dateIconLabel.leadingAnchor.constraint(equalTo: dateContainer.leadingAnchor),
            dateIconLabel.centerYAnchor.constraint(equalTo: dateContainer.centerYAnchor),
            
            dateLabel.leadingAnchor.constraint(equalTo: dateIconLabel.trailingAnchor, constant: 12),
            dateLabel.centerYAnchor.constraint(equalTo: dateContainer.centerYAnchor),
            
            dateButton.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 29),
            dateButton.centerYAnchor.constraint(equalTo: dateContainer.centerYAnchor),
            dateButton.trailingAnchor.constraint(equalTo: dateContainer.trailingAnchor),
            dateButton.widthAnchor.constraint(equalToConstant: 214),
            dateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupChallengeModeContainer() {
        challengeModeContainer.addSubview(challengeIconLabel)
        challengeModeContainer.addSubview(challengeModeLabel)
        challengeModeContainer.addSubview(challengeModeSwitch)
        
        NSLayoutConstraint.activate([
            challengeIconLabel.leadingAnchor.constraint(equalTo: challengeModeContainer.leadingAnchor),
            challengeIconLabel.centerYAnchor.constraint(equalTo: challengeModeContainer.centerYAnchor),
            
            challengeModeLabel.leadingAnchor.constraint(equalTo: challengeIconLabel.trailingAnchor, constant: 12),
            challengeModeLabel.centerYAnchor.constraint(equalTo: challengeModeContainer.centerYAnchor),
            
            challengeModeSwitch.trailingAnchor.constraint(equalTo: challengeModeContainer.trailingAnchor),
            challengeModeSwitch.centerYAnchor.constraint(equalTo: challengeModeContainer.centerYAnchor),
            
            // Set container height
            challengeModeContainer.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Setup Pickers
    private func setupPickers() {
        // Setup Time Picker
        timePicker.datePickerMode = .time
        timePicker.minuteInterval = 30
        
        if #available(iOS 13.4, *) {
            timePicker.preferredDatePickerStyle = .wheels
        }
        timePicker.addTarget(self, action: #selector(timePickerValueChanged(_:)), for: .valueChanged)
        
        // Setup Date Picker
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        
        // Set minimum date to today
        datePicker.minimumDate = Date()
    }
    
    private func setupTableView() {
        tableView.register(ChallengeTeamCell.self, forCellReuseIdentifier: "ChallengeTeamCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func loadChallengeTeams() {
        guard let currentTeam = currentTeam else {
            print("❌ Current team not set")
            return
        }
        
        Task {
            do {
                challengeTeams = try await dataService.fetchTeamsWithSameSport(
                    currentTeamId: currentTeam.id
                )
                
                // Update UI on main thread
                await MainActor.run {
                    availableTeamNames = challengeTeams.map { $0.name }
                    tableView.reloadData()
                }
            } catch {
                print("❌ Failed to load challenge teams: \(error)")
                await MainActor.run {
                    showAlert(title: "Error", message: "Failed to load available teams")
                }
            }
        }
    }
    
    private func setupActions() {
        challengeTeamButton.addTarget(self, action: #selector(toggleTeamList), for: .touchUpInside)
        challengeButton.addTarget(self, action: #selector(challengeButtonTapped), for: .touchUpInside)
        challengeModeSwitch.addTarget(self, action: #selector(challengeModeSwitchChanged), for: .valueChanged)
        
        // Add button targets for pickers
        fromTimeButton.addTarget(self, action: #selector(timeButtonTapped(_:)), for: .touchUpInside)
        toTimeButton.addTarget(self, action: #selector(timeButtonTapped(_:)), for: .touchUpInside)
        dateButton.addTarget(self, action: #selector(dateButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Animations
    private func animateIn() {
        containerBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.dimmedView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    private func animateOut(completion: (() -> Void)? = nil) {
        let currentHeight = containerViewHeightConstraint.constant
        containerBottomConstraint.constant = currentHeight
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.dimmedView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    // MARK: - Color Updates
    func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update dimmed view
        dimmedView.backgroundColor = isDarkMode ?
            UIColor.black.withAlphaComponent(0.5) :
            UIColor.black.withAlphaComponent(0.3)
        
        // Update container view
        containerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        // Update handle bar
        handleBar.backgroundColor = isDarkMode ?
            UIColor.white.withAlphaComponent(0.3) :
            UIColor.black.withAlphaComponent(0.2)
        
        // Update title label
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update venue field
        venueField.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        venueField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        venueField.attributedPlaceholder = NSAttributedString(
            string: "📍 Venue",
            attributes: [.foregroundColor: isDarkMode ? UIColor.gray : UIColor.lightGray]
        )
        
        // Update time section
        updateLabelWithIcon(label: timeIconLabel, iconName: "clock", isDarkMode: isDarkMode)
        timeLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update time buttons
        fromTimeButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        updateTimeButtonColor(button: fromTimeButton, isDarkMode: isDarkMode)
        
        toTimeButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        updateTimeButtonColor(button: toTimeButton, isDarkMode: isDarkMode)
        
        // Update date section
        updateLabelWithIcon(label: dateIconLabel, iconName: "calendar", isDarkMode: isDarkMode)
        dateLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update date button
        dateButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        updateDateButtonColor(isDarkMode: isDarkMode)
        
        // Update challenge mode section
        updateLabelWithIcon(label: challengeIconLabel, iconName: "shareplay", isDarkMode: isDarkMode)
        challengeModeLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        challengeModeSwitch.onTintColor = isDarkMode ? .systemGreenDark : .systemGreen
        
        // Update challenge team button
        challengeTeamButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        challengeTeamButton.setTitleColor(isDarkMode ? .systemGray2 : .darkGray, for: .normal)
        dropdownIcon.tintColor = isDarkMode ? .systemGray2 : .darkGray
        
        // Update team list container
        teamListContainer.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        
        // Update challenge button
        challengeButton.backgroundColor = isDarkMode ? .systemGreenDark : .systemGreen
        
        // Reload table view to update cell colors
        tableView.reloadData()
    }
    
    private func updateLabelWithIcon(label: UILabel, iconName: String, isDarkMode: Bool) {
        let iconColor = isDarkMode ? UIColor.systemGreenDark : UIColor.systemGreen
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        let attachment = NSTextAttachment()
        attachment.image = image?.withTintColor(iconColor)
        let attributedString = NSMutableAttributedString(attachment: attachment)
        label.attributedText = attributedString
    }
    
    private func updateTimeButtonColor(button: UIButton, isDarkMode: Bool) {
        let isPlaceholder = (button == fromTimeButton && fromTime == nil) ||
                           (button == toTimeButton && toTime == nil)
        
        if isPlaceholder {
            button.setTitleColor(isDarkMode ? .systemGray2 : .darkGray, for: .normal)
        } else {
            button.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        }
    }
    
    private func updateDateButtonColor(isDarkMode: Bool) {
        if selectedDate == nil {
            dateButton.setTitleColor(isDarkMode ? .systemGray2 : .darkGray, for: .normal)
        } else {
            dateButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        }
    }
    
    private func updateChallengeSectionVisibility() {
        let isHidden = !challengeModeSwitch.isOn
        
        // Hide/show challenge team dropdown
        challengeTeamButton.superview?.isHidden = isHidden
        teamListContainer.isHidden = true
        teamListHeightConstraint.constant = 0
        
        // Update container height
        if isHidden {
            // Collapse the team list if it's expanded
            isTeamListExpanded = false
            dropdownIcon.transform = .identity
        }
        
        // Update button title if hidden
        if isHidden {
            challengeTeamButton.setTitle("Challenge team", for: .normal)
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            challengeTeamButton.setTitleColor(isDarkMode ? .systemGray2 : .darkGray, for: .normal)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Picker Methods
    @objc private func timeButtonTapped(_ sender: UIButton) {
        activeTimeField = sender
        
        // Set the time picker's initial date
        if sender == fromTimeButton, let fromTime = fromTime {
            timePicker.date = fromTime
        } else if sender == toTimeButton, let toTime = toTime {
            timePicker.date = toTime
        } else {
            timePicker.date = Date()
        }
        
        // Create a container view for the picker
        let pickerContainer = UIView()
        pickerContainer.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .secondaryDark : .secondaryLight
        pickerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a toolbar with done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barStyle = traitCollection.userInterfaceStyle == .dark ? .black : .default
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(timePickerDoneTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(timePickerCancelTapped))
        toolbar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure time picker for dark mode
        if traitCollection.userInterfaceStyle == .dark {
            timePicker.setValue(UIColor.white, forKey: "textColor")
        } else {
            timePicker.setValue(UIColor.black, forKey: "textColor")
        }
        
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        
        pickerContainer.addSubview(toolbar)
        pickerContainer.addSubview(timePicker)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: pickerContainer.topAnchor, constant: 20),
            toolbar.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            
            timePicker.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            timePicker.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            timePicker.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            timePicker.bottomAnchor.constraint(equalTo: pickerContainer.bottomAnchor)
        ])
        
        // Create and present the picker view controller
        let pickerVC = UIViewController()
        pickerVC.view = pickerContainer
        pickerVC.preferredContentSize = CGSize(width: view.frame.width, height: 300)
        pickerVC.modalPresentationStyle = .pageSheet
        
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        present(pickerVC, animated: true, completion: nil)
    }
    
    @objc private func dateButtonTapped() {
        // Create a container view for the picker
        let pickerContainer = UIView()
        pickerContainer.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .secondaryDark : .secondaryLight
        pickerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a toolbar with done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barStyle = traitCollection.userInterfaceStyle == .dark ? .black : .default
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(datePickerDoneTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(datePickerCancelTapped))
        toolbar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure time picker for dark mode
        if traitCollection.userInterfaceStyle == .dark {
            datePicker.setValue(UIColor.white, forKey: "textColor")
        } else {
            datePicker.setValue(UIColor.black, forKey: "textColor")
        }
        
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        pickerContainer.addSubview(toolbar)
        pickerContainer.addSubview(datePicker)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: pickerContainer.topAnchor, constant: 20),
            toolbar.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            
            datePicker.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            datePicker.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: pickerContainer.bottomAnchor)
        ])
        
        // Create and present the picker view controller
        let pickerVC = UIViewController()
        pickerVC.view = pickerContainer
        pickerVC.preferredContentSize = CGSize(width: view.frame.width, height: 300)
        pickerVC.modalPresentationStyle = .pageSheet
        
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        present(pickerVC, animated: true, completion: nil)
    }
    
    @objc private func timePickerValueChanged(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if activeTimeField == fromTimeButton {
            // Set from time
            fromTime = sender.date
            fromTimeButton.setTitle(formatter.string(from: sender.date), for: .normal)
            updateTimeButtonColor(button: fromTimeButton, isDarkMode: traitCollection.userInterfaceStyle == .dark)
            
            // Automatically set to time to one hour later
            if let fromTime = fromTime {
                let calendar = Calendar.current
                if let newToTime = calendar.date(byAdding: .hour, value: 1, to: fromTime) {
                    toTime = newToTime
                    toTimeButton.setTitle(formatter.string(from: newToTime), for: .normal)
                    updateTimeButtonColor(button: toTimeButton, isDarkMode: traitCollection.userInterfaceStyle == .dark)
                }
            }
        } else if activeTimeField == toTimeButton {
            // Set to time only (user manually changed it)
            toTime = sender.date
            toTimeButton.setTitle(formatter.string(from: sender.date), for: .normal)
            updateTimeButtonColor(button: toTimeButton, isDarkMode: traitCollection.userInterfaceStyle == .dark)
        }
    }
    
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        selectedDate = sender.date
        dateButton.setTitle(formatter.string(from: sender.date), for: .normal)
        updateDateButtonColor(isDarkMode: traitCollection.userInterfaceStyle == .dark)
    }
    
    @objc private func timePickerDoneTapped() {
        dismiss(animated: true)
    }
    
    @objc private func timePickerCancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func datePickerDoneTapped() {
        dismiss(animated: true)
    }
    
    @objc private func datePickerCancelTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Actions
    @objc private func toggleTeamList() {
        isTeamListExpanded.toggle()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            if self.isTeamListExpanded {
                self.teamListContainer.isHidden = false
                let cellHeight: CGFloat = 70
                let spacing: CGFloat = 6 // Reduced spacing
                let topPadding: CGFloat = 16 // Reduced top padding
                let bottomPadding: CGFloat = 16
                let totalHeight = topPadding + (cellHeight + spacing) * CGFloat(self.availableTeamNames.count) - spacing + bottomPadding
                self.teamListHeightConstraint.constant = totalHeight
                self.challengeTeamButton.isHidden = true
            } else {
                self.teamListHeightConstraint.constant = 0
                self.challengeTeamButton.isHidden = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.teamListContainer.isHidden = true
                }
            }
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func challengeModeSwitchChanged() {
        updateChallengeSectionVisibility()
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            if translation.y > 100 || velocity.y > 500 {
                animateOut()
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.containerView.transform = .identity
                }
            }
        default:
            break
        }
    }
    
    @objc private func handleDimmedViewTap() {
        animateOut()
    }
    
    @objc private func sendButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < challengeTeams.count else { return }
        
        let selectedChallengeTeam = challengeTeams[index]
        selectedTeam = selectedChallengeTeam
        
        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ChallengeTeamCell {
            cell.updateToSentState()
        }
        
        // Update button title to show selected team
        challengeTeamButton.setTitle(selectedChallengeTeam.name, for: .normal)
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        challengeTeamButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        
        // Collapse the list
        toggleTeamList()
    }
    
    @objc private func challengeButtonTapped() {
        guard let venue = venueField.text, !venue.isEmpty else {
            showAlert(title: "Missing Field", message: "Please enter a venue")
            return
        }
        
        guard let fromTime = fromTime, let toTime = toTime else {
            showAlert(title: "Missing Field", message: "Please select time")
            return
        }
        
        guard let selectedDate = selectedDate else {
            showAlert(title: "Missing Field", message: "Please select date")
            return
        }
        
        Task {
            do {
                guard let currentTeam = currentTeam else {
                    throw NSError(domain: "ChallengeTeamMatchVC", code: 400, userInfo: [NSLocalizedDescriptionKey: "Current team not set"])
                }
                
                guard let currentUserId = try await dataService.getCurrentUserId() else {
                    throw NSError(domain: "ChallengeTeamMatchVC", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                let isCaptain = try await dataService.isUserCaptain(
                    userId: currentUserId,
                    teamId: currentTeam.id
                )
                
                guard isCaptain else {
                    showAlert(title: "Not Authorized", message: "Only team captain can create matches")
                    return
                }
                
                if challengeModeSwitch.isOn {
                    guard let selectedTeam = selectedTeam else {
                        showAlert(title: "Missing Field", message: "Please select a team to challenge")
                        return
                    }
                    
                    try await dataService.createMatchRequest(
                        challengingTeamId: currentTeam.id,
                        challengedTeamId: selectedTeam.id,
                        venue: venue,
                        date: selectedDate,
                        time: fromTime
                    )
                    
                    await MainActor.run {
                        showSuccessAlert(
                            title: "Challenge Sent!",
                            message: "Match request sent to \(selectedTeam.name)",
                            isChallengeMode: true
                        )
                    }
                } else {
                    let sportId = try await dataService.getTeamSportId(teamId: currentTeam.id)
                    
                    try await dataService.createInternalMatch(
                        venue: venue,
                        date: selectedDate,
                        time: fromTime,
                        teamId: currentTeam.id,
                        sportId: sportId,
                        postedByUserId: currentUserId
                    )
                    
                    await MainActor.run {
                        showSuccessAlert(
                            title: "Match Created!",
                            message: "Internal match has been scheduled",
                            isChallengeMode: false
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    // Helper function for success alert
    private func showSuccessAlert(title: String, message: String, isChallengeMode: Bool) {
        // Format date and time for display
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        var details = "Venue: \(venueField.text ?? "")\n"
        
        if let selectedDate = selectedDate {
            details += "Date: \(dateFormatter.string(from: selectedDate))\n"
        }
        
        if let fromTime = fromTime {
            details += "Time: \(timeFormatter.string(from: fromTime))"
            if let toTime = toTime {
                details += " - \(timeFormatter.string(from: toTime))"
            }
        }
        
        let alertMessage = isChallengeMode ?
            "\(message)\n\n\(details)" :
            "\(message)\n\n\(details)"
        
        let alert = UIAlertController(
            title: title,
            message: alertMessage,
            preferredStyle: .alert
        )
        
        alert.view.tintColor = traitCollection.userInterfaceStyle == .dark ? .systemGreenDark : .systemGreen
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.animateOut()
        })
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.view.tintColor = traitCollection.userInterfaceStyle == .dark ? .systemGreenDark : .systemGreen
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate
extension ChallengeTeamMatchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableTeamNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeTeamCell", for: indexPath) as? ChallengeTeamCell else {
            return UITableViewCell()
        }
        
        let team = challengeTeams[indexPath.row]
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        cell.configure(with: team.name, index: indexPath.row, isDarkMode: isDarkMode)
        cell.sendButton.tag = indexPath.row
        cell.sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - Custom Input Field (Keep as fallback but not used in this implementation)
class CustomInputField: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let textField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            iconLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            textField.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func configure(icon: String?, placeholder: String) {
        if let icon = icon {
            iconLabel.text = icon
            iconLabel.isHidden = false
        } else {
            iconLabel.isHidden = true
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        }
        
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        containerView.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        textField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: isDarkMode ? UIColor.systemGray2 : UIColor.darkGray]
        )
    }
}

// MARK: - Time Input Field (Keep as fallback but not used in this implementation)
class TimeInputField: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let textField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            textField.topAnchor.constraint(equalTo: containerView.topAnchor),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    func configure(placeholder: String) {
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        containerView.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        textField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: isDarkMode ? UIColor.systemGray2 : UIColor.darkGray]
        )
    }
}

// MARK: - Challenge Team Cell
class ChallengeTeamCell: UITableViewCell {
    let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        
        contentView.addSubview(containerView)
        containerView.addSubview(teamNameLabel)
        containerView.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            teamNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            teamNameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            teamNameLabel.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -16),
            
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 70),
            sendButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(with teamName: String, index: Int, isDarkMode: Bool) {
        teamNameLabel.text = teamName
        teamNameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        containerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = isDarkMode ? .systemGreenDark : .systemGreen
        sendButton.isEnabled = true
    }
    
    func updateToSentState() {
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        sendButton.setTitle("Sent", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = isDarkMode ? .quaternaryDark : .lightGray
        sendButton.isEnabled = false
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ChallengeTeamMatchViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChallengeTeamMatchViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .previewDisplayName("Dark Mode")
            
            ChallengeTeamMatchViewControllerRepresentable()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .previewDisplayName("Light Mode")
        }
    }
}

struct ChallengeTeamMatchViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ChallengeTeamMatchViewController {
        return ChallengeTeamMatchViewController()
    }
    
    func updateUIViewController(_ uiViewController: ChallengeTeamMatchViewController, context: Context) {
        uiViewController.updateColors()
    }
}
#endif
