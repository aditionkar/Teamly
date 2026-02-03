//
//  SportsPostViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 27/01/26.
//

import UIKit

// MARK: - SportsPostViewController (Modal)
class SportsPostViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    private var sports: [SportItem] = []
    private var selectedSport: SportItem?
    private var isSportsExpanded = false
    private let buttonHeight: CGFloat = 50
    private let maxSportsSectionHeight: CGFloat = 300
    
    // MARK: - Time Properties
    private var fromTime: Date?
    private var toTime: Date?
    private var selectedDate: Date?
    
    // MARK: - Skill Properties
    private let skillLevels = ["Beginner", "Intermediate", "Experienced", "Advanced"]
    private var selectedSkill: String?
    private var isSkillExpanded = false
    private var skillSectionHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Players Property
    private var playersNeeded: Int = 2
    
    var preSelectedSportName: String?
    
    private var sportSectionHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Picker Properties
    private let timePicker = UIDatePicker()
    private let datePicker = UIDatePicker()
    private var activeTimeField: UIButton? // Track which time field is active
    
    private let sportsCloseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.3
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Sport Section Components
    private let sportsSportSectionContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // UPDATE: Remove image padding and adjust content insets for leading alignment
    private let sportsSelectSportButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        
        var config = UIButton.Configuration.plain()
        config.title = "Select sport"
        config.image = UIImage(systemName: "chevron.down")
        config.preferredSymbolConfigurationForImage =
            UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        config.imagePlacement = .trailing
        config.imagePadding = 10 // Reduced padding for trailing image
        config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20)
        button.configuration = config
        
        // Set content horizontal alignment to leading
        button.contentHorizontalAlignment = .leading
        
        return button
    }()
    
    private let sportsScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alpha = 0
        return scrollView
    }()
    
    private let sportsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let sportsVenueField: UITextField = {
        let textField = UITextField()
        textField.layer.cornerRadius = 25
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    // MARK: - Time Section Components (Updated to UIButton)
    private let sportsTimeContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sportsTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sportsFromTimeButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set placeholder text
        button.setTitle("From", for: .normal)
        button.contentHorizontalAlignment = .center
        
        return button
    }()
    
    private let sportsToTimeButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set placeholder text
        button.setTitle("To", for: .normal)
        button.contentHorizontalAlignment = .center
        
        return button
    }()
    
    // MARK: - Date Section Components (Updated to UIButton)
    private let sportsDateContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sportsDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sportsDateButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set placeholder text
        button.setTitle("Select Date", for: .normal)
        button.contentHorizontalAlignment = .center
        
        return button
    }()
    
    // MARK: - Skill Section Components (Updated to dropdown)
    private let sportsSkillContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sportsSkillLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sportsSkillDropdownContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sportsSelectSkillButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        
        var config = UIButton.Configuration.plain()
        config.title = "Select skill level"
        config.image = UIImage(systemName: "chevron.down")
        config.preferredSymbolConfigurationForImage =
            UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        config.imagePlacement = .trailing
        config.imagePadding = 40
        config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20)
        button.configuration = config
        
        return button
    }()
    
    private let sportsSkillScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alpha = 0
        return scrollView
    }()
    
    private let sportsSkillStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Players Section Components
    private let sportsPlayersContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sportsPlayersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sportsPlayersField: UITextField = {
        let textField = UITextField()
        textField.layer.cornerRadius = 25
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
        textField.leftViewMode = .always
        textField.keyboardType = .numberPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let sportsPostButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Post", for: .normal)
        button.setTitleColor(.primaryWhite, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 17
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSportsView()
        setupSportsCloseButton()
        setupSportsFormFields()
        setupSportsDropdownInteraction()
        setupSportsSkillDropdownInteraction()
        setupSportsPickers()
        updateSportsColors()
        fetchSportsFromSupabase()
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Set default players needed
        sportsPlayersField.text = "2"
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateSportsColors()
        }
        
        // Update post button position when layout changes
        updatePostButtonPosition()
    }
    
    // MARK: - Data Fetching
    private func fetchSportsFromSupabase() {
        PostDataService.shared.fetchSports { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedSports):
                self.sports = fetchedSports
                DispatchQueue.main.async {
                    self.setupSportsRows()
                    
                    // Check if we have a pre-selected sport
                    if let sportName = self.preSelectedSportName,
                       let sport = self.sports.first(where: { $0.name == sportName }) {
                        // Pre-select the sport and update UI
                        self.selectedSport = sport
                        self.updateSportSelectionUI(with: sport)
                        
                        // Disable the sport button interaction since it's already selected
                        self.sportsSelectSportButton.isUserInteractionEnabled = false
                        
                        // Hide the sports dropdown scroll view since we don't need it
                        self.sportsScrollView.isHidden = true
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Connection Error",
                        message: "Unable to load sports. Please check your internet connection and try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Setup
    private func setupSportsView() {
        view.backgroundColor = .secondaryDark
    }
    
    private func setupSportsCloseButton() {
        view.addSubview(sportsCloseButton)
        
        NSLayoutConstraint.activate([
            sportsCloseButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            sportsCloseButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sportsCloseButton.widthAnchor.constraint(equalToConstant: 40),
            sportsCloseButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        sportsCloseButton.addTarget(self, action: #selector(sportsCloseButtonTapped), for: .touchUpInside)
    }
    
    private func setupSportsFormFields() {
        view.addSubview(sportsSportSectionContainer)
        view.addSubview(sportsVenueField)
        
        // Add time container
        view.addSubview(sportsTimeContainer)
        sportsTimeContainer.addSubview(sportsTimeLabel)
        sportsTimeContainer.addSubview(sportsFromTimeButton)
        sportsTimeContainer.addSubview(sportsToTimeButton)
        
        // Add date container
        view.addSubview(sportsDateContainer)
        sportsDateContainer.addSubview(sportsDateLabel)
        sportsDateContainer.addSubview(sportsDateButton)
        
        // Add skill container
        view.addSubview(sportsSkillContainer)
        sportsSkillContainer.addSubview(sportsSkillLabel)
        
        // Add skill dropdown container
        view.addSubview(sportsSkillDropdownContainer)
        
        // Add players container
        view.addSubview(sportsPlayersContainer)
        sportsPlayersContainer.addSubview(sportsPlayersLabel)
        sportsPlayersContainer.addSubview(sportsPlayersField)
        
        view.addSubview(sportsPostButton)
        
        // Sport section setup
        sportsSportSectionContainer.addSubview(sportsSelectSportButton)
        sportsSportSectionContainer.addSubview(sportsScrollView)
        sportsScrollView.addSubview(sportsStackView)
        
        // Skill dropdown setup
        sportsSkillDropdownContainer.addSubview(sportsSelectSkillButton)
        sportsSkillDropdownContainer.addSubview(sportsSkillScrollView)
        sportsSkillScrollView.addSubview(sportsSkillStackView)
        
        sportSectionHeightConstraint = sportsSportSectionContainer.heightAnchor.constraint(equalToConstant: buttonHeight)
        skillSectionHeightConstraint = sportsSkillDropdownContainer.heightAnchor.constraint(equalToConstant: buttonHeight)
        
        NSLayoutConstraint.activate([
            // Sport section container
            sportsSportSectionContainer.topAnchor.constraint(equalTo: sportsCloseButton.bottomAnchor, constant: 40),
            sportsSportSectionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            sportsSportSectionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            sportSectionHeightConstraint,
            
            // Select Sport Button
            sportsSelectSportButton.topAnchor.constraint(equalTo: sportsSportSectionContainer.topAnchor),
            sportsSelectSportButton.leadingAnchor.constraint(equalTo: sportsSportSectionContainer.leadingAnchor),
            sportsSelectSportButton.trailingAnchor.constraint(equalTo: sportsSportSectionContainer.trailingAnchor),
            sportsSelectSportButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            // Sports Scroll View
            sportsScrollView.topAnchor.constraint(equalTo: sportsSelectSportButton.bottomAnchor),
            sportsScrollView.leadingAnchor.constraint(equalTo: sportsSportSectionContainer.leadingAnchor),
            sportsScrollView.trailingAnchor.constraint(equalTo: sportsSportSectionContainer.trailingAnchor),
            sportsScrollView.bottomAnchor.constraint(equalTo: sportsSportSectionContainer.bottomAnchor),
            
            // Sports Stack View
            sportsStackView.topAnchor.constraint(equalTo: sportsScrollView.topAnchor, constant: 5),
            sportsStackView.leadingAnchor.constraint(equalTo: sportsScrollView.leadingAnchor, constant: 15),
            sportsStackView.trailingAnchor.constraint(equalTo: sportsScrollView.trailingAnchor, constant: -15),
            sportsStackView.bottomAnchor.constraint(equalTo: sportsScrollView.bottomAnchor, constant: -15),
            sportsStackView.widthAnchor.constraint(equalTo: sportsScrollView.widthAnchor, constant: -30),
            
            // Venue field
            sportsVenueField.topAnchor.constraint(equalTo: sportsSportSectionContainer.bottomAnchor, constant: 25),
            sportsVenueField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            sportsVenueField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            sportsVenueField.heightAnchor.constraint(equalToConstant: 50),
            
            // Time container
            sportsTimeContainer.topAnchor.constraint(equalTo: sportsVenueField.bottomAnchor, constant: 25),
            sportsTimeContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            sportsTimeContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            sportsTimeContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // Time label
            sportsTimeLabel.leadingAnchor.constraint(equalTo: sportsTimeContainer.leadingAnchor),
            sportsTimeLabel.centerYAnchor.constraint(equalTo: sportsTimeContainer.centerYAnchor),
            sportsTimeLabel.widthAnchor.constraint(equalToConstant: 80),
            
            // From time button
            sportsFromTimeButton.leadingAnchor.constraint(equalTo: sportsTimeLabel.trailingAnchor, constant: 15),
            sportsFromTimeButton.centerYAnchor.constraint(equalTo: sportsTimeContainer.centerYAnchor),
            sportsFromTimeButton.heightAnchor.constraint(equalToConstant: 50),
            sportsFromTimeButton.widthAnchor.constraint(equalToConstant: 120),
            
            // To time button
            sportsToTimeButton.leadingAnchor.constraint(equalTo: sportsFromTimeButton.trailingAnchor, constant: 10),
            sportsToTimeButton.centerYAnchor.constraint(equalTo: sportsTimeContainer.centerYAnchor),
            sportsToTimeButton.heightAnchor.constraint(equalToConstant: 50),
            sportsToTimeButton.widthAnchor.constraint(equalToConstant: 120),
            sportsToTimeButton.trailingAnchor.constraint(lessThanOrEqualTo: sportsTimeContainer.trailingAnchor),
            
            // Date container
            sportsDateContainer.topAnchor.constraint(equalTo: sportsTimeContainer.bottomAnchor, constant: 25),
            sportsDateContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            sportsDateContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            sportsDateContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // Date label
            sportsDateLabel.leadingAnchor.constraint(equalTo: sportsDateContainer.leadingAnchor),
            sportsDateLabel.centerYAnchor.constraint(equalTo: sportsDateContainer.centerYAnchor),
            sportsDateLabel.widthAnchor.constraint(equalToConstant: 80),
            
            // Date button
            sportsDateButton.leadingAnchor.constraint(equalTo: sportsDateLabel.trailingAnchor, constant: 15),
            sportsDateButton.centerYAnchor.constraint(equalTo: sportsDateContainer.centerYAnchor),
            sportsDateButton.heightAnchor.constraint(equalToConstant: 50),
            sportsDateButton.trailingAnchor.constraint(equalTo: sportsDateContainer.trailingAnchor),
            
            // Skill container
            sportsSkillContainer.topAnchor.constraint(equalTo: sportsDateContainer.bottomAnchor, constant: 25),
            sportsSkillContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            sportsSkillContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            sportsSkillContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // Skill label
            sportsSkillLabel.leadingAnchor.constraint(equalTo: sportsSkillContainer.leadingAnchor),
            sportsSkillLabel.centerYAnchor.constraint(equalTo: sportsSkillContainer.centerYAnchor),
            sportsSkillLabel.widthAnchor.constraint(equalToConstant: 80),
            
            // Skill dropdown container
            sportsSkillDropdownContainer.topAnchor.constraint(equalTo: sportsSkillContainer.topAnchor),
            sportsSkillDropdownContainer.leadingAnchor.constraint(equalTo: sportsSkillLabel.trailingAnchor, constant: 15),
            sportsSkillDropdownContainer.trailingAnchor.constraint(equalTo: sportsSkillContainer.trailingAnchor),
            skillSectionHeightConstraint,
            
            // Select Skill Button
            sportsSelectSkillButton.topAnchor.constraint(equalTo: sportsSkillDropdownContainer.topAnchor),
            sportsSelectSkillButton.leadingAnchor.constraint(equalTo: sportsSkillDropdownContainer.leadingAnchor),
            sportsSelectSkillButton.trailingAnchor.constraint(equalTo: sportsSkillDropdownContainer.trailingAnchor),
            sportsSelectSkillButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            // Skill Scroll View
            sportsSkillScrollView.topAnchor.constraint(equalTo: sportsSelectSkillButton.bottomAnchor),
            sportsSkillScrollView.leadingAnchor.constraint(equalTo: sportsSkillDropdownContainer.leadingAnchor),
            sportsSkillScrollView.trailingAnchor.constraint(equalTo: sportsSkillDropdownContainer.trailingAnchor),
            sportsSkillScrollView.bottomAnchor.constraint(equalTo: sportsSkillDropdownContainer.bottomAnchor),
            
            // Skill Stack View
            sportsSkillStackView.topAnchor.constraint(equalTo: sportsSkillScrollView.topAnchor, constant: 5),
            sportsSkillStackView.leadingAnchor.constraint(equalTo: sportsSkillScrollView.leadingAnchor, constant: 15),
            sportsSkillStackView.trailingAnchor.constraint(equalTo: sportsSkillScrollView.trailingAnchor, constant: -15),
            sportsSkillStackView.bottomAnchor.constraint(equalTo: sportsSkillScrollView.bottomAnchor, constant: -15),
            sportsSkillStackView.widthAnchor.constraint(equalTo: sportsSkillScrollView.widthAnchor, constant: -30),
            
            // Players container
            sportsPlayersContainer.topAnchor.constraint(equalTo: sportsSkillDropdownContainer.bottomAnchor, constant: 25),
            sportsPlayersContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            sportsPlayersContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            sportsPlayersContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // Players label
            sportsPlayersLabel.leadingAnchor.constraint(equalTo: sportsPlayersContainer.leadingAnchor),
            sportsPlayersLabel.centerYAnchor.constraint(equalTo: sportsPlayersContainer.centerYAnchor),
            sportsPlayersLabel.widthAnchor.constraint(equalToConstant: 83),
            
            // Players field
            sportsPlayersField.leadingAnchor.constraint(equalTo: sportsPlayersLabel.trailingAnchor, constant: 15),
            sportsPlayersField.centerYAnchor.constraint(equalTo: sportsPlayersContainer.centerYAnchor),
            sportsPlayersField.heightAnchor.constraint(equalToConstant: 50),
            sportsPlayersField.trailingAnchor.constraint(equalTo: sportsPlayersContainer.trailingAnchor),
            
            // Post button
            sportsPostButton.topAnchor.constraint(equalTo: sportsPlayersContainer.bottomAnchor, constant: 40),
            sportsPostButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sportsPostButton.widthAnchor.constraint(equalToConstant: 94),
            sportsPostButton.heightAnchor.constraint(equalToConstant: 35),
            sportsPostButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
        
        setupSportsSkillRows()
        
        // Set text field delegates
        sportsVenueField.delegate = self
        sportsPlayersField.delegate = self
        
        // Add button targets
        sportsFromTimeButton.addTarget(self, action: #selector(sportsTimeButtonTapped(_:)), for: .touchUpInside)
        sportsToTimeButton.addTarget(self, action: #selector(sportsTimeButtonTapped(_:)), for: .touchUpInside)
        sportsDateButton.addTarget(self, action: #selector(sportsDateButtonTapped), for: .touchUpInside)
        sportsPostButton.addTarget(self, action: #selector(sportsPostButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Setup Pickers
    private func setupSportsPickers() {
        // Setup Time Picker
        timePicker.datePickerMode = .time
        if #available(iOS 13.4, *) {
            timePicker.preferredDatePickerStyle = .wheels
        }
        timePicker.addTarget(self, action: #selector(sportsTimePickerValueChanged(_:)), for: .valueChanged)
        
        // Setup Date Picker
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.addTarget(self, action: #selector(sportsDatePickerValueChanged(_:)), for: .valueChanged)
        
        // Set minimum date to today
        datePicker.minimumDate = Date()
    }
    
    // MARK: - Color Updates
    func updateSportsColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update view background
        view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        // Update close button
        sportsCloseButton.tintColor = isDarkMode ? .primaryWhite : .primaryBlack
        sportsCloseButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        
        // Update sport section
        sportsSportSectionContainer.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        sportsSportSectionContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        sportsSportSectionContainer.layer.borderWidth = isDarkMode ? 0 : 0.7
        
        // Update select sport button - special handling for pre-selected sport
        var config = sportsSelectSportButton.configuration
        if selectedSport != nil {
            // If sport is selected, use primary colors
            config?.baseForegroundColor = isDarkMode ? .primaryWhite : .primaryBlack
        } else {
            // If no sport selected, use gray colors
            config?.baseForegroundColor = isDarkMode ? UIColor.gray : UIColor.lightGray
        }
        
        // Remove dropdown arrow if sport is pre-selected
        if preSelectedSportName != nil {
            config?.image = nil
        }
        
        sportsSelectSportButton.configuration = config
        
        // Update venue field
        sportsVenueField.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        sportsVenueField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        sportsVenueField.attributedPlaceholder = NSAttributedString(
            string: "📍 Venue",
            attributes: [.foregroundColor: isDarkMode ? UIColor.gray : UIColor.lightGray]
        )
        
        // Update time label
        updateSportsLabelWithIcon(label: sportsTimeLabel,
                          iconName: "clock",
                          text: "Time",
                          isDarkMode: isDarkMode)
        
        // Update time buttons
        sportsFromTimeButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        sportsFromTimeButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        
        sportsToTimeButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        sportsToTimeButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        
        // Update date label
        updateSportsLabelWithIcon(label: sportsDateLabel,
                          iconName: "calendar",
                          text: "Date",
                          isDarkMode: isDarkMode)
        
        // Update date button
        sportsDateButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        sportsDateButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        
        // Update skill label
        updateSportsLabelWithIcon(label: sportsSkillLabel,
                          iconName: "target",
                          text: "Skill",
                          isDarkMode: isDarkMode)
        
        // Update skill dropdown container
        sportsSkillDropdownContainer.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        sportsSkillDropdownContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        sportsSkillDropdownContainer.layer.borderWidth = isDarkMode ? 0 : 0.7
        
        // Update select skill button
        var skillConfig = sportsSelectSkillButton.configuration
        if selectedSkill == nil {
            skillConfig?.baseForegroundColor = isDarkMode ? UIColor.gray : UIColor.lightGray
        } else {
            skillConfig?.baseForegroundColor = isDarkMode ? .primaryWhite : .primaryBlack
        }
        sportsSelectSkillButton.configuration = skillConfig
        
        // Update players label
        updateSportsLabelWithIcon(label: sportsPlayersLabel,
                          iconName: "person.3.fill",
                          text: "Players",
                          isDarkMode: isDarkMode)
        
        // Update players field
        sportsPlayersField.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        sportsPlayersField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        sportsPlayersField.attributedPlaceholder = NSAttributedString(
            string: "e.g., 4",
            attributes: [.foregroundColor: isDarkMode ? UIColor.gray : UIColor.lightGray]
        )
        
        // Update sport rows
        for case let rowView as UIView in sportsStackView.arrangedSubviews {
            for case let label as UILabel in rowView.subviews {
                if label.text?.count == 1 { // emoji label
                    continue
                }
                label.textColor = isDarkMode ? .primaryWhite : .primaryBlack
            }
        }
        
        // Update skill rows
        for case let rowView as UIView in sportsSkillStackView.arrangedSubviews {
            for case let label as UILabel in rowView.subviews {
                label.textColor = isDarkMode ? .primaryWhite : .primaryBlack
            }
        }
        
        // Update post button
        sportsPostButton.backgroundColor = isDarkMode ? .systemGreenDark : .systemGreen
        
        // Ensure date picker text color is correct in dark mode
        if isDarkMode {
            datePicker.setValue(UIColor.white, forKey: "textColor")
        } else {
            datePicker.setValue(UIColor.black, forKey: "textColor")
        }
    }
    
    private func updatePostButtonPosition() {
        // Ensure post button is always visible and properly positioned
        if isSkillExpanded {
            let totalContentHeight = CGFloat(skillLevels.count) * 60 + 30
            let expandedHeight = min(totalContentHeight, maxSportsSectionHeight - buttonHeight)
            
            UIView.animate(withDuration: 0.3) {
                self.sportsPostButton.transform = CGAffineTransform(
                    translationX: 0,
                    y: expandedHeight
                )
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.sportsPostButton.transform = .identity
            }
        }
    }
    
    private func updateSportsLabelWithIcon(label: UILabel, iconName: String, text: String, isDarkMode: Bool) {
        let iconColor = isDarkMode ? UIColor.systemGreenDark : UIColor.systemGreen
        let textColor = isDarkMode ? UIColor.primaryWhite : UIColor.primaryBlack
        
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = UIImage(systemName: iconName)?.withTintColor(iconColor, renderingMode: .alwaysOriginal)
        
        // For the players icon specifically, make it smaller
        if iconName == "person.3.fill" {
            iconAttachment.bounds = CGRect(x: 0, y: -2, width: 20, height: 17)
        } else {
            iconAttachment.bounds = CGRect(x: 0, y: -2, width: 20, height: 20)
        }
        
        let iconString = NSAttributedString(attachment: iconAttachment)
        let titleString = NSAttributedString(string: "  \(text)", attributes: [
            .foregroundColor: textColor,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ])
        
        let combined = NSMutableAttributedString()
        combined.append(iconString)
        combined.append(titleString)
        
        label.attributedText = combined
    }
    
    // MARK: - Helper Methods
    private func updateSportSelectionUI(with sport: SportItem) {
        // Update the select sport button to show the selected sport
        var config = sportsSelectSportButton.configuration
        config?.title = "\(sport.emoji ?? "🏃‍♂️") \(sport.name)"
        config?.baseForegroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack
        config?.image = nil // Remove the dropdown arrow since sport is already selected
        config?.imagePadding = 0 // Remove image padding when no image
        sportsSelectSportButton.configuration = config
        
        // Ensure text is aligned to leading edge
        sportsSelectSportButton.contentHorizontalAlignment = .leading
        sportsSelectSportButton.titleLabel?.textAlignment = .left
    }
    
    // MARK: - TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == sportsPlayersField {
            updatePlayersNeededFromField()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == sportsPlayersField {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            
            if !allowedCharacters.isSuperset(of: characterSet) && string != "" {
                return false
            }
            
            return true
        }
        return true
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func updatePlayersNeededFromField() {
        if let text = sportsPlayersField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if text.isEmpty {
                playersNeeded = 2
                sportsPlayersField.text = "2"
            } else if let number = Int(text), number > 0 {
                playersNeeded = number
            } else {
                playersNeeded = 2
                sportsPlayersField.text = "2"
            }
        }
    }
    
    // MARK: - Sport Dropdown Methods
    private func setupSportsDropdownInteraction() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sportsSportButtonTapped))
        sportsSelectSportButton.addGestureRecognizer(tapGesture)
    }
    
    @objc private func sportsSportButtonTapped() {
        toggleSportsDropdown()
    }
    
    private func setupSportsRows() {
        // Clear existing rows
        sportsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, sport) in sports.enumerated() {
            let sportRow = createSportsSportRow(sport: sport, index: index)
            sportsStackView.addArrangedSubview(sportRow)
        }
    }
    
    private func createSportsSportRow(sport: SportItem, index: Int) -> UIView {
        let rowView = UIView()
        rowView.backgroundColor = .clear
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        let emojiLabel = UILabel()
        emojiLabel.text = sport.emoji ?? "🏃‍♂️"
        emojiLabel.font = UIFont.systemFont(ofSize: 24)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.isUserInteractionEnabled = false
        
        let nameLabel = UILabel()
        nameLabel.text = sport.name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textAlignment = .left
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.isUserInteractionEnabled = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sportsSportRowTapped(_:)))
        rowView.addGestureRecognizer(tapGesture)
        rowView.isUserInteractionEnabled = true
        rowView.tag = index
        
        rowView.addSubview(emojiLabel)
        rowView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            rowView.heightAnchor.constraint(equalToConstant: 60),
            
            emojiLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 40),
            emojiLabel.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 17),
            nameLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -20)
        ])
        
        return rowView
    }
    
    @objc private func sportsSportRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let rowView = gesture.view else { return }
        let index = rowView.tag
        
        guard index >= 0 && index < sports.count else { return }
        
        selectedSport = sports[index]
        
        if let selectedSport = selectedSport {
            updateSportSelectionUI(with: selectedSport)
        }
        
        toggleSportsDropdown()
    }
    
    private func toggleSportsDropdown() {
        // Don't toggle if sport is pre-selected (dropdown is disabled)
        if preSelectedSportName != nil && !isSportsExpanded {
            return
        }
        
        isSportsExpanded.toggle()
        
        let totalContentHeight = CGFloat(sports.count) * 60 + 30
        let newSportsSectionHeight: CGFloat = isSportsExpanded ? min(totalContentHeight + buttonHeight, maxSportsSectionHeight) : buttonHeight
        
        sportSectionHeightConstraint.constant = newSportsSectionHeight
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.sportsScrollView.alpha = self.isSportsExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Skill Dropdown Methods
    private func setupSportsSkillDropdownInteraction() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sportsSkillButtonTapped))
        sportsSelectSkillButton.addGestureRecognizer(tapGesture)
    }
    
    @objc private func sportsSkillButtonTapped() {
        toggleSportsSkillDropdown()
    }
    
    private func setupSportsSkillRows() {
        for (index, skillLevel) in skillLevels.enumerated() {
            let skillRow = createSportsSkillRow(skill: skillLevel, index: index)
            sportsSkillStackView.addArrangedSubview(skillRow)
        }
    }
    
    private func createSportsSkillRow(skill: String, index: Int) -> UIView {
        let rowView = UIView()
        rowView.backgroundColor = .clear
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = skill
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.isUserInteractionEnabled = false
        
        let selectButton = UIButton(type: .system)
        selectButton.tag = index
        selectButton.backgroundColor = .clear
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.addTarget(self, action: #selector(sportsSkillRowTapped(_:)), for: .touchUpInside)
        
        rowView.addSubview(nameLabel)
        rowView.addSubview(selectButton)
        
        NSLayoutConstraint.activate([
            rowView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 20),
            nameLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -20),
            
            selectButton.topAnchor.constraint(equalTo: rowView.topAnchor),
            selectButton.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
            selectButton.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
            selectButton.bottomAnchor.constraint(equalTo: rowView.bottomAnchor)
        ])
        
        return rowView
    }
    
    @objc private func sportsSkillRowTapped(_ sender: UIButton) {
        let index = sender.tag
        
        guard index >= 0 && index < skillLevels.count else { return }
        
        selectedSkill = skillLevels[index]
        
        if let selectedSkill = selectedSkill {
            var config = sportsSelectSkillButton.configuration
            config?.title = selectedSkill
            config?.baseForegroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack
            config?.image = UIImage(systemName: "chevron.up")
            sportsSelectSkillButton.configuration = config
            
            sportsSelectSkillButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack, for: .normal)
        }
        
        toggleSportsSkillDropdown()
    }
    
    private func toggleSportsSkillDropdown() {
        isSkillExpanded.toggle()
        
        var config = sportsSelectSkillButton.configuration
        config?.image = isSkillExpanded ?
            UIImage(systemName: "chevron.up") :
            UIImage(systemName: "chevron.down")
        sportsSelectSkillButton.configuration = config
        
        let totalContentHeight = CGFloat(skillLevels.count) * 60 + 30
        let newSkillSectionHeight: CGFloat = isSkillExpanded ? min(totalContentHeight + buttonHeight, maxSportsSectionHeight) : buttonHeight
        
        skillSectionHeightConstraint.constant = newSkillSectionHeight
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.sportsSkillScrollView.alpha = self.isSkillExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
        
        // Update post button position when skill dropdown expands/collapses
        UIView.animate(withDuration: 0.3) {
            if self.isSkillExpanded {
                // When expanded, push post button down
                self.sportsPostButton.transform = CGAffineTransform(
                    translationX: 0,
                    y: min(totalContentHeight, self.maxSportsSectionHeight - self.buttonHeight)
                )
            } else {
                // When collapsed, bring post button back
                self.sportsPostButton.transform = .identity
            }
        }
    }
    
    // MARK: - Button Actions
    @objc private func sportsTimeButtonTapped(_ sender: UIButton) {
        activeTimeField = sender
        
        // Set the time picker's initial date
        if sender == sportsFromTimeButton, let fromTime = fromTime {
            timePicker.date = fromTime
        } else if sender == sportsToTimeButton, let toTime = toTime {
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
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(sportsTimePickerDoneTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(sportsTimePickerCancelTapped))
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
    
    @objc private func sportsDateButtonTapped() {
        // Set initial date for picker
        if let selectedDate = selectedDate {
            datePicker.date = selectedDate
        } else {
            datePicker.date = Date()
        }
        
        // Create a container view for the picker
        let pickerContainer = UIView()
        pickerContainer.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .secondaryDark : .secondaryLight
        pickerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a toolbar with done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barStyle = traitCollection.userInterfaceStyle == .dark ? .black : .default
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(sportsDatePickerDoneTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(sportsDatePickerCancelTapped))
        toolbar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure date picker text color for dark mode
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
    
    @objc private func sportsTimePickerValueChanged(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if activeTimeField == sportsFromTimeButton {
            fromTime = sender.date
            sportsFromTimeButton.setTitle(formatter.string(from: sender.date), for: .normal)
            sportsFromTimeButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack, for: .normal)
            
            // Automatically set to time to one hour later
            if let fromTime = fromTime {
                let calendar = Calendar.current
                if let newToTime = calendar.date(byAdding: .hour, value: 1, to: fromTime) {
                    toTime = newToTime
                    sportsToTimeButton.setTitle(formatter.string(from: newToTime), for: .normal)
                    sportsToTimeButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack, for: .normal)
                }
            }
        } else if activeTimeField == sportsToTimeButton {
            // Set to time only (user manually changed it)
            toTime = sender.date
            sportsToTimeButton.setTitle(formatter.string(from: sender.date), for: .normal)
            sportsToTimeButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack, for: .normal)
        }
    }
    
    @objc private func sportsDatePickerValueChanged(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        selectedDate = sender.date
        sportsDateButton.setTitle(formatter.string(from: sender.date), for: .normal)
        sportsDateButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack, for: .normal)
    }
    
    @objc private func sportsTimePickerDoneTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sportsTimePickerCancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sportsDatePickerDoneTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sportsDatePickerCancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sportsPostButtonTapped() {
        updatePlayersNeededFromField()
        
        guard validateForm() else {
            return
        }
        
        guard let (formattedDate, formattedTime) = getFormattedDateAndTime() else {
            showAlert(title: "Error", message: "Please select both date and time")
            return
        }
        
        guard let selectedSport = selectedSport else {
            showAlert(title: "Error", message: "Please select a sport")
            return
        }
        
        let matchData = MatchPostData(
            matchType: "sport_community",
            communityId: nil,
            venue: sportsVenueField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            matchDate: formattedDate,
            matchTime: formattedTime,
            sportId: selectedSport.id,
            skillLevel: selectedSkill,
            playersNeeded: playersNeeded,
            postedByUserId: UUID() // This will be replaced by actual user ID from session
        )
        
        saveMatchToDatabase(matchData: matchData)
    }
    
    private func validateForm() -> Bool {
        var errorMessages: [String] = []
        
        if selectedSport == nil {
            errorMessages.append("Please select a sport")
        }
        
        if let venueText = sportsVenueField.text?.trimmingCharacters(in: .whitespacesAndNewlines), venueText.isEmpty {
            errorMessages.append("Please enter a venue")
        }
        
        if selectedDate == nil {
            errorMessages.append("Please select a date")
        }
        
        if fromTime == nil {
            errorMessages.append("Please select a start time")
        }
        
        if selectedSkill == nil {
            errorMessages.append("Please select a skill level")
        }
        
        if playersNeeded <= 0 {
            errorMessages.append("Please enter a valid number of players needed")
        }
        
        if !errorMessages.isEmpty {
            let errorMessage = errorMessages.joined(separator: "\n")
            showAlert(title: "Missing Information", message: errorMessage)
            return false
        }
        
        return true
    }
    
    private func getFormattedDateAndTime() -> (date: String, time: String)? {
        guard let fromTime = fromTime, let selectedDate = selectedDate else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        let formattedDate = dateFormatter.string(from: selectedDate)
        let formattedTime = timeFormatter.string(from: fromTime)
        
        return (formattedDate, formattedTime)
    }
    
    private func saveMatchToDatabase(matchData: MatchPostData) {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        sportsPostButton.isEnabled = false
        sportsPostButton.alpha = 0.7
        
        PostDataService.shared.saveMatch(matchData: matchData) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                self.sportsPostButton.isEnabled = true
                self.sportsPostButton.alpha = 1.0
            }
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.showAlert(title: "Success", message: "Match posted successfully!") { _ in
                        self.dismiss(animated: true)
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Failed to post match: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        present(alert, animated: true)
    }
    
    @objc private func sportsCloseButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - SwiftUI Preview for SportsPostViewController
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SportsPostViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SportsPostViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .previewDisplayName("Dark Mode")
            
            SportsPostViewControllerRepresentable()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .previewDisplayName("Light Mode")
        }
    }
}

struct SportsPostViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SportsPostViewController {
        let vc = SportsPostViewController()
        // Test with a pre-selected sport
        vc.preSelectedSportName = "Football"
        return vc
    }
    
    func updateUIViewController(_ uiViewController: SportsPostViewController, context: Context) {
        uiViewController.updateSportsColors()
    }
}
#endif
