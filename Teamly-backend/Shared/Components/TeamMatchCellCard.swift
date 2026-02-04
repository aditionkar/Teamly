//
//  TeamMatchCellCard.swift
//  Teamly-backend
//
//  Created by user@37 on 02/02/26.
//

import UIKit

// MARK: - TeamMatch Model for Database
struct TeamMatch {
    let id: UUID
    let matchType: String
    let teamId: UUID?
    let opponentTeamId: UUID?
    let venue: String
    let matchDate: Date
    let matchTime: Date
    let sportId: Int
    let sportName: String?
    let skillLevel: String?
    let playersNeeded: Int
    let postedByUserId: UUID
    let createdAt: Date
    
    // For display - these would be fetched via joins
    var teamName: String?
    var opponentTeamName: String?
    var playersRSVPed: Int = 0
    
    // Add this computed property
    var isNightTime: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: matchTime)
        // Define night as 6 PM to 6 AM (18:00 to 5:59)
        return hour >= 18 || hour < 6
    }
    
    // Computed property to get the correct opponent name for display
        func opponentNameForDisplay(currentTeamName: String?) -> String? {
            guard matchType == "team_challenge" else { return nil }
            
            guard let currentTeamName = currentTeamName else {
                return opponentTeamName ?? teamName ?? "Opponent Team"
            }
            
            if let opponentName = opponentTeamName,
               opponentName != currentTeamName {
                return opponentName
            } else if let teamName = teamName,
                      teamName != currentTeamName {
                return teamName
            }
            
            return "Opponent Team"
        }
    
    static func fromDictionary(_ dict: [String: Any]) -> TeamMatch? {
        print("Creating TeamMatch from dictionary: \(dict.keys)")
        
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let matchType = dict["match_type"] as? String,
              let venue = dict["venue"] as? String,
              let dateString = dict["match_date"] as? String,
              let timeString = dict["match_time"] as? String,
              let sportId = dict["sport_id"] as? Int,
              let playersNeeded = dict["players_needed"] as? Int,
              let postedByIdString = dict["posted_by_user_id"] as? String,
              let postedByUserId = UUID(uuidString: postedByIdString),
              let createdAtString = dict["created_at"] as? String else {
            
            print("Missing required fields in team match data")
            print("ID: \(dict["id"] as? String ?? "nil")")
            print("Match Type: \(dict["match_type"] as? String ?? "nil")")
            print("Venue: \(dict["venue"] as? String ?? "nil")")
            print("Date: \(dict["match_date"] as? String ?? "nil")")
            print("Time: \(dict["match_time"] as? String ?? "nil")")
            print("Sport ID: \(dict["sport_id"] as? Int ?? 0)")
            print("Players Needed: \(dict["players_needed"] as? Int ?? 0)")
            print("Posted By: \(dict["posted_by_user_id"] as? String ?? "nil")")
            print("Created At: \(dict["created_at"] as? String ?? "nil")")
            
            return nil
        }
        
        // Parse date from "2026-01-26" format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let matchDate = dateFormatter.date(from: dateString) else {
            print("Failed to parse date: \(dateString)")
            return nil
        }
        
        // Parse time from "HH:mm:ss" format
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let matchTime = timeFormatter.date(from: timeString) else {
            print("Failed to parse time: \(timeString)")
            return nil
        }
        
        // Parse created_at (ISO format)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let createdAt = isoFormatter.date(from: createdAtString) ?? Date()
        
        // Parse optional fields
        let teamId = (dict["team_id"] as? String).flatMap(UUID.init)
        let opponentTeamId = (dict["opponent_team_id"] as? String).flatMap(UUID.init)
        
        return TeamMatch(
            id: id,
            matchType: matchType,
            teamId: teamId,
            opponentTeamId: opponentTeamId,
            venue: venue,
            matchDate: matchDate,
            matchTime: matchTime,
            sportId: sportId,
            sportName: dict["sport_name"] as? String,
            skillLevel: dict["skill_level"] as? String,
            playersNeeded: playersNeeded,
            postedByUserId: postedByUserId,
            createdAt: createdAt,
            teamName: dict["team_name"] as? String,
            opponentTeamName: dict["opponent_team_name"] as? String,
            playersRSVPed: dict["players_rsvped"] as? Int ?? 0
        )
    }
}


class TeamMatchCellCard: UICollectionViewCell {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondaryDark
        view.layer.cornerRadius = 35
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let venueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = .primaryWhite
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        label.textColor = .primaryWhite
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        label.textColor = .primaryWhite
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let goingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .primaryWhite
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let againstTeamLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .primaryWhite
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .white.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Properties
    var onTap: (() -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupTapGesture()
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
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(containerView)
        
        containerView.addSubview(venueLabel)
        containerView.addSubview(separator)
        containerView.addSubview(dateLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(againstTeamLabel)
        containerView.addSubview(goingLabel)
        
        NSLayoutConstraint.activate([
            // Container constraints
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Venue label above separator
            venueLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            venueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            venueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Separator below venue
            separator.topAnchor.constraint(equalTo: venueLabel.bottomAnchor, constant: 12),
            separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Date and time constraints with proper breathing room
            dateLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 28),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 22),
            
            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 15),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 22),
            timeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            // Against team label aligned with date (in place of slots)
            againstTeamLabel.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            againstTeamLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            
            // Going label aligned with time (in place of against team)
            goingLabel.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            goingLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ])
    }
    
    // MARK: - Color Updates
    func updateColors(isDarkMode: Bool? = nil) {
        let isDarkMode = isDarkMode ?? (traitCollection.userInterfaceStyle == .dark)
        
        // Update container view
        containerView.backgroundColor = isDarkMode ? .secondaryDark : .tertiaryLight
        
        // Update all labels
        venueLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        dateLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        timeLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        againstTeamLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        goingLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update separator
        separator.backgroundColor = isDarkMode ?
            UIColor.white.withAlphaComponent(0.3) :
            UIColor.black.withAlphaComponent(0.2)
        
        // Update shadow for tap gesture
        containerView.layer.shadowColor = (isDarkMode ? UIColor.black : UIColor.gray).cgColor
    }
    
    private func setupTapGesture() {
        // Add visual feedback for tap
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
    }
    
    // MARK: - Configuration
    func configure(with teamMatch: TeamMatch, onTap: (() -> Void)? = nil, currentTeamName: String? = nil) {
        self.onTap = onTap
        
        venueLabel.text = "📍 \(teamMatch.venue)"
        
        // Format date with day-specific calendar icon
        dateLabel.attributedText = formattedDateText(for: teamMatch.matchDate, isDarkMode: traitCollection.userInterfaceStyle == .dark)
        
        // Format time with AM/PM specific icon and duration
        timeLabel.attributedText = formattedTimeText(for: teamMatch.matchTime, isDarkMode: traitCollection.userInterfaceStyle == .dark)
        
        // Set going label
        goingLabel.text = "\(teamMatch.playersRSVPed + 1) going"
        
        // Set against team label based on match type (beside date)
        if teamMatch.matchType == "team_challenge",
           let opponentName = teamMatch.opponentNameForDisplay(currentTeamName: currentTeamName) {
            // Create attributed string with SF Symbol
            let flagSymbol = NSTextAttachment()
            let flagImage = UIImage(systemName: "flag.2.crossed.fill")?.withTintColor(.systemGray)
            flagSymbol.image = flagImage
            flagSymbol.bounds = CGRect(x: 0, y: -3, width: 20, height: 17)
            
            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(attachment: flagSymbol))
            attributedString.append(NSAttributedString(string: "  \(opponentName)"))
            
            againstTeamLabel.attributedText = attributedString
            againstTeamLabel.isHidden = false
        } else {
                againstTeamLabel.isHidden = true
        }
        
        // Set initial colors based on current trait collection
        updateColors()
    }
    
    // MARK: - Private Helpers
    private func formattedDateText(for date: Date, isDarkMode: Bool) -> NSAttributedString {
        let calendarIcon = NSTextAttachment()
        
        // Format date as DD/MM/YY
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        let formattedDate = dateFormatter.string(from: date)
        
        // Check if date is today or tomorrow
        let calendar = Calendar.current
        
        let calendarImage: UIImage
        if calendar.isDateInToday(date) || calendar.isDateInTomorrow(date) {
            // Today or tomorrow: use regular calendar icon
            calendarImage = UIImage(systemName: "calendar")!.withTintColor(isDarkMode ? .white : .black)
        } else {
            // Other date: use date-specific calendar icon with day number
            let dayComponent = calendar.component(.day, from: date)
            calendarImage = UIImage(systemName: "\(dayComponent).calendar")?.withTintColor(isDarkMode ? .white : .black) ?? UIImage(systemName: "calendar")!.withTintColor(isDarkMode ? .white : .black)
        }
        
        calendarIcon.image = calendarImage
        calendarIcon.bounds = CGRect(x: 0, y: -2, width: 20, height: 20)
        
        // Determine date text
        let dateText: String
        if calendar.isDateInToday(date) {
            dateText = "  Today"
        } else if calendar.isDateInTomorrow(date) {
            dateText = "  Tomorrow"
        } else {
            dateText = "  \(formattedDate)"
        }
        
        let fullString = NSMutableAttributedString()
        fullString.append(NSAttributedString(attachment: calendarIcon))
        fullString.append(NSAttributedString(string: dateText))
        
        return fullString
    }
    
    private func formattedTimeText(for timeDate: Date, isDarkMode: Bool) -> NSAttributedString {
        let timeIcon = NSTextAttachment()
        
        // Format start time in 12-hour format
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let startTime = timeFormatter.string(from: timeDate)
        
        // Determine if it's AM or PM
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "a"
        let amPm = hourFormatter.string(from: timeDate)
        
        let timeIconImage: UIImage
        if amPm.uppercased() == "PM" {
            // PM = moon icon in systemBlue
            timeIconImage = UIImage(systemName: "moon.fill")!
            timeIcon.bounds = CGRect(x: 0, y: -2, width: 20, height: 20)
        } else {
            // AM = sun icon in systemYellow
            timeIconImage = UIImage(systemName: "sun.horizon")!
            timeIcon.bounds = CGRect(x: 0, y: -2, width: 30, height: 20)
        }
        
        // Use specified colors for icons
        let tintColor = amPm.uppercased() == "PM" ? UIColor.systemBlue : UIColor.systemYellow
        timeIcon.image = timeIconImage.withTintColor(tintColor)
        
        // Calculate end time (add 1 hour)
        let calendar = Calendar.current
        guard let endTimeDate = calendar.date(byAdding: .hour, value: 1, to: timeDate) else {
            // If can't calculate end time, just show start time
            let fullString = NSMutableAttributedString()
            fullString.append(NSAttributedString(attachment: timeIcon))
            fullString.append(NSAttributedString(string: "  \(startTime)"))
            return fullString
        }
        
        let endTime = timeFormatter.string(from: endTimeDate)
        
        let fullString = NSMutableAttributedString()
        fullString.append(NSAttributedString(attachment: timeIcon))
        fullString.append(NSAttributedString(string: "  \(startTime) - \(endTime)"))
        
        return fullString
    }
}
