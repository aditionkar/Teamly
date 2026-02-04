//
//  PostViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import UIKit

class PostViewController: UIViewController, UITextFieldDelegate {
    
    private var sports: [SportItem] = []
    private var selectedSport: SportItem?
    private var isSportsExpanded = false
    private let buttonHeight: CGFloat = 50
    private let maxSportsSectionHeight: CGFloat = 300
    
    private var fromTime: Date?
    private var toTime: Date?
    private var selectedDate: Date?
    
    private let skillLevels = ["Beginner", "Intermediate", "Experienced", "Advanced"]
    private var selectedSkill: String?
    private var isSkillExpanded = false
    private var skillDropdownHeightConstraint: NSLayoutConstraint!
    private var sportSectionHeightConstraint: NSLayoutConstraint!
    
    private var playersNeeded: Int = 2
    
    private let timePicker = UIDatePicker()
    private let datePicker = UIDatePicker()
    private var activeTimeField: UIButton?
    
    private let closeButton: UIButton = {
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
    
    private let sportSectionContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let selectSportButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        
        var config = UIButton.Configuration.plain()
        config.title = "Select sport"
        config.image = UIImage(systemName: "chevron.down")
        config.preferredSymbolConfigurationForImage =
            UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        config.imagePlacement = .trailing
        config.imagePadding = 120
        config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20)
        button.configuration = config
        
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
    
    private let venueField: UITextField = {
        let textField = UITextField()
        textField.layer.cornerRadius = 25
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let timeContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fromTimeButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("From", for: .normal)
        button.contentHorizontalAlignment = .center
        return button
    }()
    
    private let toTimeButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("To", for: .normal)
        button.contentHorizontalAlignment = .center
        return button
    }()
    
    private let dateContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Select Date", for: .normal)
        button.contentHorizontalAlignment = .center
        return button
    }()
    
    private let skillContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let skillLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let skillDropdownContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let selectSkillButton: UIButton = {
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
    
    private let skillScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alpha = 0
        return scrollView
    }()
    
    private let skillStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let playersLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playersNeededField: UITextField = {
        let textField = UITextField()
        textField.layer.cornerRadius = 25
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
        textField.leftViewMode = .always
        textField.keyboardType = .numberPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Post", for: .normal)
        button.setTitleColor(.primaryWhite, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 17
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupCloseButton()
        setupFormFields()
        setupSportDropdownInteraction()
        setupSkillDropdownInteraction()
        setupPickers()
        updateColors()
        fetchSportsFromSupabase()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    private func fetchSportsFromSupabase() {
        PostDataService.shared.fetchSports { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedSports):
                self.sports = fetchedSports
                DispatchQueue.main.async {
                    self.setupSportRows()
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
    
    private func setupView() {
        view.backgroundColor = .secondaryDark
    }
    
    private func setupCloseButton() {
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupFormFields() {
        view.addSubview(sportSectionContainer)
        view.addSubview(venueField)
        
        view.addSubview(timeContainer)
        timeContainer.addSubview(timeLabel)
        timeContainer.addSubview(fromTimeButton)
        timeContainer.addSubview(toTimeButton)
        
        view.addSubview(dateContainer)
        dateContainer.addSubview(dateLabel)
        dateContainer.addSubview(dateButton)
        
        view.addSubview(skillDropdownContainer)
        view.addSubview(skillLabel)
        
        view.addSubview(playersLabel)
        view.addSubview(playersNeededField)
        
        view.addSubview(postButton)
        
        sportSectionContainer.addSubview(selectSportButton)
        sportSectionContainer.addSubview(sportsScrollView)
        sportsScrollView.addSubview(sportsStackView)
        
        skillDropdownContainer.addSubview(selectSkillButton)
        skillDropdownContainer.addSubview(skillScrollView)
        skillScrollView.addSubview(skillStackView)
        
        sportSectionHeightConstraint = sportSectionContainer.heightAnchor.constraint(equalToConstant: buttonHeight)
        skillDropdownHeightConstraint = skillDropdownContainer.heightAnchor.constraint(equalToConstant: buttonHeight)
        
        NSLayoutConstraint.activate([
            sportSectionContainer.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 40),
            sportSectionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            sportSectionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            sportSectionHeightConstraint,
            
            selectSportButton.topAnchor.constraint(equalTo: sportSectionContainer.topAnchor),
            selectSportButton.leadingAnchor.constraint(equalTo: sportSectionContainer.leadingAnchor),
            selectSportButton.trailingAnchor.constraint(equalTo: sportSectionContainer.trailingAnchor),
            selectSportButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            sportsScrollView.topAnchor.constraint(equalTo: selectSportButton.bottomAnchor),
            sportsScrollView.leadingAnchor.constraint(equalTo: sportSectionContainer.leadingAnchor),
            sportsScrollView.trailingAnchor.constraint(equalTo: sportSectionContainer.trailingAnchor),
            sportsScrollView.bottomAnchor.constraint(equalTo: sportSectionContainer.bottomAnchor),
            
            sportsStackView.topAnchor.constraint(equalTo: sportsScrollView.topAnchor, constant: 5),
            sportsStackView.leadingAnchor.constraint(equalTo: sportsScrollView.leadingAnchor, constant: 15),
            sportsStackView.trailingAnchor.constraint(equalTo: sportsScrollView.trailingAnchor, constant: -15),
            sportsStackView.bottomAnchor.constraint(equalTo: sportsScrollView.bottomAnchor, constant: -15),
            sportsStackView.widthAnchor.constraint(equalTo: sportsScrollView.widthAnchor, constant: -30),
            
            venueField.topAnchor.constraint(equalTo: sportSectionContainer.bottomAnchor, constant: 25),
            venueField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            venueField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            venueField.heightAnchor.constraint(equalToConstant: 50),
            
            timeContainer.topAnchor.constraint(equalTo: venueField.bottomAnchor, constant: 25),
            timeContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            timeContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            timeContainer.heightAnchor.constraint(equalToConstant: 50),
            
            timeLabel.leadingAnchor.constraint(equalTo: timeContainer.leadingAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: timeContainer.centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 80),
            
            fromTimeButton.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 15),
            fromTimeButton.centerYAnchor.constraint(equalTo: timeContainer.centerYAnchor),
            fromTimeButton.heightAnchor.constraint(equalToConstant: 50),
            fromTimeButton.widthAnchor.constraint(equalToConstant: 120),
            
            toTimeButton.leadingAnchor.constraint(equalTo: fromTimeButton.trailingAnchor, constant: 10),
            toTimeButton.centerYAnchor.constraint(equalTo: timeContainer.centerYAnchor),
            toTimeButton.heightAnchor.constraint(equalToConstant: 50),
            toTimeButton.widthAnchor.constraint(equalToConstant: 120),
            toTimeButton.trailingAnchor.constraint(lessThanOrEqualTo: timeContainer.trailingAnchor),
            
            dateContainer.topAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: 25),
            dateContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            dateContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            dateContainer.heightAnchor.constraint(equalToConstant: 50),
            
            dateLabel.leadingAnchor.constraint(equalTo: dateContainer.leadingAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: dateContainer.centerYAnchor),
            dateLabel.widthAnchor.constraint(equalToConstant: 80),
            
            dateButton.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 15),
            dateButton.centerYAnchor.constraint(equalTo: dateContainer.centerYAnchor),
            dateButton.heightAnchor.constraint(equalToConstant: 50),
            dateButton.trailingAnchor.constraint(equalTo: dateContainer.trailingAnchor),
            
            skillLabel.topAnchor.constraint(equalTo: dateContainer.bottomAnchor, constant: 25),
            skillLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            skillLabel.widthAnchor.constraint(equalToConstant: 80),
            
            skillDropdownContainer.topAnchor.constraint(equalTo: skillLabel.topAnchor),
            skillDropdownContainer.leadingAnchor.constraint(equalTo: skillLabel.trailingAnchor, constant: 15),
            skillDropdownContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            skillDropdownHeightConstraint,
            
            selectSkillButton.topAnchor.constraint(equalTo: skillDropdownContainer.topAnchor),
            selectSkillButton.leadingAnchor.constraint(equalTo: skillDropdownContainer.leadingAnchor),
            selectSkillButton.trailingAnchor.constraint(equalTo: skillDropdownContainer.trailingAnchor),
            selectSkillButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            skillScrollView.topAnchor.constraint(equalTo: selectSkillButton.bottomAnchor),
            skillScrollView.leadingAnchor.constraint(equalTo: skillDropdownContainer.leadingAnchor),
            skillScrollView.trailingAnchor.constraint(equalTo: skillDropdownContainer.trailingAnchor),
            skillScrollView.bottomAnchor.constraint(equalTo: skillDropdownContainer.bottomAnchor),
            
            skillStackView.topAnchor.constraint(equalTo: skillScrollView.topAnchor, constant: 5),
            skillStackView.leadingAnchor.constraint(equalTo: skillScrollView.leadingAnchor, constant: 15),
            skillStackView.trailingAnchor.constraint(equalTo: skillScrollView.trailingAnchor, constant: -15),
            skillStackView.bottomAnchor.constraint(equalTo: skillScrollView.bottomAnchor, constant: -15),
            skillStackView.widthAnchor.constraint(equalTo: skillScrollView.widthAnchor, constant: -30),
            
            playersLabel.topAnchor.constraint(equalTo: skillDropdownContainer.bottomAnchor, constant: 25),
            playersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            playersLabel.widthAnchor.constraint(equalToConstant: 83),
            
            playersNeededField.topAnchor.constraint(equalTo: playersLabel.topAnchor),
            playersNeededField.leadingAnchor.constraint(equalTo: playersLabel.trailingAnchor, constant: 15),
            playersNeededField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            playersNeededField.heightAnchor.constraint(equalToConstant: 50),
            
            postButton.topAnchor.constraint(equalTo: playersNeededField.bottomAnchor, constant: 40),
            postButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            postButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            postButton.widthAnchor.constraint(equalToConstant: 94),
            postButton.heightAnchor.constraint(equalToConstant: 35)
        ])
        
        setupSportRows()
        setupSkillRows()
        
        venueField.delegate = self
        playersNeededField.delegate = self
        
        playersNeededField.text = "2"
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        fromTimeButton.addTarget(self, action: #selector(timeButtonTapped(_:)), for: .touchUpInside)
        toTimeButton.addTarget(self, action: #selector(timeButtonTapped(_:)), for: .touchUpInside)
        dateButton.addTarget(self, action: #selector(dateButtonTapped), for: .touchUpInside)
        postButton.addTarget(self, action: #selector(postButtonTapped), for: .touchUpInside)
    }

    private func setupPickers() {
        timePicker.datePickerMode = .time
        timePicker.minuteInterval = 30  
        
        if #available(iOS 13.4, *) {
            timePicker.preferredDatePickerStyle = .wheels
        }
        timePicker.addTarget(self, action: #selector(timePickerValueChanged(_:)), for: .valueChanged)
        
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        
        datePicker.minimumDate = startOfToday
        
        if let maxDate = calendar.date(byAdding: .day, value: 30, to: startOfToday) {
            datePicker.maximumDate = maxDate
        }
    }
    
    private func roundToNearest30Minutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        guard let hour = components.hour, let minute = components.minute else {
            return date
        }
        
        // Round minutes to nearest 30
        let roundedMinute: Int
        if minute < 15 {
            roundedMinute = 0
        } else if minute < 45 {
            roundedMinute = 30
        } else {
            // If minute is 45 or above, round up to next hour with 00 minutes
            let nextHour = hour + 1
            let newDate = calendar.date(bySettingHour: nextHour % 24, minute: 0, second: 0, of: date)
            return newDate ?? date
        }
        
        return calendar.date(bySettingHour: hour, minute: roundedMinute, second: 0, of: date) ?? date
    }
    
    func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        closeButton.tintColor = isDarkMode ? .primaryWhite : .primaryBlack
        closeButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        
        sportSectionContainer.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        sportSectionContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        sportSectionContainer.layer.borderWidth = isDarkMode ? 0 : 0.7
        
        var config = selectSportButton.configuration
        if selectedSport == nil {
            config?.baseForegroundColor = isDarkMode ? UIColor.gray : UIColor.lightGray
        } else {
            config?.baseForegroundColor = isDarkMode ? .primaryWhite : .primaryBlack
        }
        selectSportButton.configuration = config
        
        venueField.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        venueField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        venueField.attributedPlaceholder = NSAttributedString(
            string: "📍 Venue",
            attributes: [.foregroundColor: isDarkMode ? UIColor.gray : UIColor.lightGray]
        )
        
        updateLabelWithIcon(label: timeLabel,
                          iconName: "clock",
                          text: "Time",
                          isDarkMode: isDarkMode)
        
        fromTimeButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        fromTimeButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        
        toTimeButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        toTimeButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        
        updateLabelWithIcon(label: dateLabel,
                          iconName: "calendar",
                          text: "Date",
                          isDarkMode: isDarkMode)
        
        dateButton.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        dateButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        
        updateLabelWithIcon(label: skillLabel,
                          iconName: "target",
                          text: "Skill",
                          isDarkMode: isDarkMode)
        
        skillDropdownContainer.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        skillDropdownContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        skillDropdownContainer.layer.borderWidth = isDarkMode ? 0 : 0.7
        
        var skillConfig = selectSkillButton.configuration
        if selectedSkill == nil {
            skillConfig?.baseForegroundColor = isDarkMode ? UIColor.gray : UIColor.lightGray
        } else {
            skillConfig?.baseForegroundColor = isDarkMode ? .primaryWhite : .primaryBlack
        }
        selectSkillButton.configuration = skillConfig
        
        updateLabelWithIcon(label: playersLabel,
                          iconName: "person.3.fill",
                          text: "Players",
                          isDarkMode: isDarkMode)
        
        playersNeededField.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        playersNeededField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        playersNeededField.attributedPlaceholder = NSAttributedString(
            string: "e.g., 4",
            attributes: [.foregroundColor: isDarkMode ? UIColor.gray : UIColor.lightGray]
        )
        
        for case let rowView as UIView in sportsStackView.arrangedSubviews {
            for case let label as UILabel in rowView.subviews {
                if label.text?.count == 1 { continue }
                label.textColor = isDarkMode ? .primaryWhite : .primaryBlack
            }
        }
        
        for case let rowView as UIView in skillStackView.arrangedSubviews {
            for case let label as UILabel in rowView.subviews {
                label.textColor = isDarkMode ? .primaryWhite : .primaryBlack
            }
        }
        
        postButton.backgroundColor = isDarkMode ? .systemGreenDark : .systemGreen
    }
    
    private func updateLabelWithIcon(label: UILabel, iconName: String, text: String, isDarkMode: Bool) {
        let iconColor = isDarkMode ? UIColor.systemGreenDark : UIColor.systemGreen
        let textColor = isDarkMode ? UIColor.primaryWhite : UIColor.primaryBlack
        
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = UIImage(systemName: iconName)?.withTintColor(iconColor, renderingMode: .alwaysOriginal)
        iconAttachment.bounds = CGRect(x: 0, y: -2, width: 20, height: 20)
        
        // For the players icon specifically, make it smaller
            if iconName == "person.3.fill" {
                iconAttachment.bounds = CGRect(x: 0, y: -2, width: 20, height: 18)  // Reduced from 20x20 to 18x18
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == playersNeededField {
            updatePlayersNeededFromField()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == playersNeededField {
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
        if let text = playersNeededField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if text.isEmpty {
                playersNeeded = 2
                playersNeededField.text = "2"
            } else if let number = Int(text), number > 0 {
                playersNeeded = number
            } else {
                playersNeeded = 2
                playersNeededField.text = "2"
            }
        }
    }
    
    private func setupSportDropdownInteraction() {
        selectSportButton.addTarget(self, action: #selector(sportButtonTapped), for: .touchUpInside)
    }
    
    @objc private func sportButtonTapped() {
        toggleSportsDropdown()
    }
    
    private func setupSportRows() {
        sportsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, sport) in sports.enumerated() {
            let sportRow = createSportRow(sport: sport, index: index)
            sportsStackView.addArrangedSubview(sportRow)
        }
    }
    
    private func createSportRow(sport: SportItem, index: Int) -> UIView {
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
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.isUserInteractionEnabled = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sportRowTapped(_:)))
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
    
    @objc private func sportRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let rowView = gesture.view else { return }
        let index = rowView.tag
        
        guard index >= 0 && index < sports.count else { return }
        
        selectedSport = sports[index]
        
        if let selectedSport = selectedSport {
            var config = selectSportButton.configuration
            config?.title = "\(selectedSport.emoji ?? "🏃‍♂️") \(selectedSport.name)"
            config?.baseForegroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack
            selectSportButton.configuration = config
        }
        
        toggleSportsDropdown()
    }
    
    private func toggleSportsDropdown() {
        isSportsExpanded.toggle()
        
        let totalContentHeight = CGFloat(sports.count) * 60 + 30
        let newSportsSectionHeight: CGFloat = isSportsExpanded ? min(totalContentHeight + buttonHeight, maxSportsSectionHeight) : buttonHeight
        
        sportSectionHeightConstraint.constant = newSportsSectionHeight
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.sportsScrollView.alpha = self.isSportsExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupSkillDropdownInteraction() {
        selectSkillButton.addTarget(self, action: #selector(skillButtonTapped), for: .touchUpInside)
    }
    
    @objc private func skillButtonTapped() {
        toggleSkillDropdown()
    }
    
    private func setupSkillRows() {
        for (index, skillLevel) in skillLevels.enumerated() {
            let skillRow = createSkillRow(skill: skillLevel, index: index)
            skillStackView.addArrangedSubview(skillRow)
        }
    }
    
    private func createSkillRow(skill: String, index: Int) -> UIView {
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
        selectButton.addTarget(self, action: #selector(skillButtonRowTapped(_:)), for: .touchUpInside)
        
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
    
    @objc private func skillButtonRowTapped(_ sender: UIButton) {
        let index = sender.tag
        
        guard index >= 0 && index < skillLevels.count else { return }
        
        selectedSkill = skillLevels[index]
        
        if let selectedSkill = selectedSkill {
            var config = selectSkillButton.configuration
            config?.title = selectedSkill
            config?.baseForegroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack
            config?.image = UIImage(systemName: "chevron.up")
            selectSkillButton.configuration = config
            
            selectSkillButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack, for: .normal)
        }
        
        toggleSkillDropdown()
    }
    
    private func toggleSkillDropdown() {
        isSkillExpanded.toggle()
        
        var config = selectSkillButton.configuration
        config?.image = isSkillExpanded ?
            UIImage(systemName: "chevron.up") :
            UIImage(systemName: "chevron.down")
        selectSkillButton.configuration = config
        
        let totalContentHeight = CGFloat(skillLevels.count) * 60 + 30
        let newSkillDropdownHeight: CGFloat = isSkillExpanded ? min(totalContentHeight + buttonHeight, maxSportsSectionHeight) : buttonHeight
        
        skillDropdownHeightConstraint.constant = newSkillDropdownHeight
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.skillScrollView.alpha = self.isSkillExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func timeButtonTapped(_ sender: UIButton) {
        activeTimeField = sender
        
        var initialDate = Date()
        
        if sender == fromTimeButton, let fromTime = fromTime {
            initialDate = fromTime
        } else if sender == toTimeButton, let toTime = toTime {
            initialDate = toTime
        }
        
        // Round the initial date to nearest 30 minutes
        let roundedInitialDate = roundToNearest30Minutes(initialDate)
        timePicker.date = roundedInitialDate
        
        let pickerContainer = UIView()
        pickerContainer.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .secondaryDark : .secondaryLight
        pickerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barStyle = traitCollection.userInterfaceStyle == .dark ? .black : .default
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(timePickerDoneTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(timePickerCancelTapped))
        toolbar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        if traitCollection.userInterfaceStyle == .dark {
            timePicker.setValue(UIColor.white, forKey: "textColor")
        } else {
            timePicker.setValue(UIColor.black, forKey: "textColor")
        }
        
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        
        pickerContainer.addSubview(toolbar)
        pickerContainer.addSubview(timePicker)
        
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
        let pickerContainer = UIView()
        pickerContainer.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .secondaryDark : .secondaryLight
        pickerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.barStyle = traitCollection.userInterfaceStyle == .dark ? .black : .default
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(datePickerDoneTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(datePickerCancelTapped))
        toolbar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        pickerContainer.addSubview(toolbar)
        pickerContainer.addSubview(datePicker)
        
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
        
        // Round the selected time to nearest 30 minutes
        let roundedDate = roundToNearest30Minutes(sender.date)
        
        if activeTimeField == fromTimeButton {
            fromTime = roundedDate
            fromTimeButton.setTitle(formatter.string(from: roundedDate), for: .normal)
            fromTimeButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack, for: .normal)
            
            if let fromTime = fromTime {
                let calendar = Calendar.current
                if let newToTime = calendar.date(byAdding: .hour, value: 1, to: fromTime) {
                    toTime = newToTime
                    toTimeButton.setTitle(formatter.string(from: newToTime), for: .normal)
                    toTimeButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack, for: .normal)
                }
            }
        } else if activeTimeField == toTimeButton {
            toTime = roundedDate
            toTimeButton.setTitle(formatter.string(from: roundedDate), for: .normal)
            toTimeButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack, for: .normal)
        }
    }
    
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        dateButton.setTitle(formatter.string(from: sender.date), for: .normal)
        dateButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack, for: .normal)
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
    
    private func validateTimeRange() -> Bool {
        guard let fromTime = fromTime, let toTime = toTime else {
            return true // No validation needed if times aren't set
        }
        
        if fromTime >= toTime {
            showAlert(title: "Invalid Time", message: "End time must be after start time")
            return false
        }
        
        return true
    }
    
    @objc private func postButtonTapped() {
        updatePlayersNeededFromField()
        
        guard validateForm() else {
            return
        }
        
        // FIXED: Changed "!" to use the correct validation logic
        guard validateTimeRange() else {
            return
        }
        
        guard let (formattedDate, formattedTime) = getFormattedDateAndTime() else {
            showAlert(title: "Error", message: "Please select both date and time")
            return
        }
        
        let matchData = MatchPostData(
            matchType: "sport_community",
            communityId: nil,
            venue: venueField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            matchDate: formattedDate,
            matchTime: formattedTime,
            sportId: selectedSport?.id ?? 0,
            skillLevel: selectedSkill,
            playersNeeded: playersNeeded,
            postedByUserId: UUID()
        )
        
        saveMatchToDatabase(matchData: matchData)
    }
    private func validateForm() -> Bool {
        var errorMessages: [String] = []
        
        if selectedSport == nil {
            errorMessages.append("Please select a sport")
        }
        
        if let venueText = venueField.text?.trimmingCharacters(in: .whitespacesAndNewlines), venueText.isEmpty {
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
        
        // Ensure fromTime is rounded
        let roundedFromTime = roundToNearest30Minutes(fromTime)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        let formattedDate = dateFormatter.string(from: selectedDate)
        let formattedTime = timeFormatter.string(from: roundedFromTime)
        
        return (formattedDate, formattedTime)
    }
    
    private func saveMatchToDatabase(matchData: MatchPostData) {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        postButton.isEnabled = false
        postButton.alpha = 0.7
        
        PostDataService.shared.saveMatch(matchData: matchData) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                self.postButton.isEnabled = true
                self.postButton.alpha = 1.0
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
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct PostViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PostViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .previewDisplayName("Dark Mode")
            
            PostViewControllerRepresentable()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .previewDisplayName("Light Mode")
        }
    }
}

struct PostViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PostViewController {
        return PostViewController()
    }
    
    func updateUIViewController(_ uiViewController: PostViewController, context: Context) {
        uiViewController.updateColors()
    }
}
#endif
