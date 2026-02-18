//
//  MatchCellCard.swift
//  Teamly-backend
//
//  Created by user@37 on 26/01/26.
//

import UIKit

// MARK: - Updated DBMatch Model
struct DBMatch {
    let id: UUID
    let matchType: String
    let communityId: String?
    let venue: String
    let matchDate: Date
    let matchTime: Date
    let sportId: Int
    let sportName: String
    let skillLevel: String?
    let playersNeeded: Int
    let postedByUserId: UUID
    let createdAt: Date
    var playersRSVPed: Int
    let postedByName: String
    var isFriend: Bool
    var isCreatedByUser: Bool? = false // Add this
    
    // Add this computed property
    var isNightTime: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: matchTime)
        // Define night as 6 PM to 6 AM (18:00 to 5:59)
        return hour >= 18 || hour < 6
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> DBMatch? {
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
            print("Missing required fields in match data")
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
        
        // Parse time from "19:00:00" format
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
        
        return DBMatch(
            id: id,
            matchType: matchType,
            communityId: dict["community_id"] as? String,
            venue: venue,
            matchDate: matchDate,
            matchTime: matchTime,
            sportId: sportId,
            sportName: dict["sport_name"] as? String ?? "Unknown Sport",
            skillLevel: dict["skill_level"] as? String,
            playersNeeded: playersNeeded,
            postedByUserId: postedByUserId,
            createdAt: createdAt,
            playersRSVPed: dict["players_rsvped"] as? Int ?? 0,
            postedByName: dict["posted_by_name"] as? String ?? "Unknown",
            isFriend: dict["is_friend"] as? Bool ?? false,
            isCreatedByUser: dict["is_created_by_user"] as? Bool ?? false
        )
    }
}

class MatchCellCard: UICollectionViewCell {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondaryDark
        view.layer.cornerRadius = 33
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
    
    private let slotsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .primaryWhite
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
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
        
        // Add all subviews to container
        containerView.addSubview(venueLabel)
        containerView.addSubview(separator)
        containerView.addSubview(dateLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(slotsLabel)
        containerView.addSubview(goingLabel)
        
        NSLayoutConstraint.activate([
            // Container constraints - added padding
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Venue label above separator - REDUCED padding
            venueLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            venueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            venueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Separator below venue - TIGHTER spacing
            separator.topAnchor.constraint(equalTo: venueLabel.bottomAnchor, constant: 12),
            separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Date and time below separator - MORE breathing room
            dateLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 28),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 22),
            
            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 15),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 22),
            timeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            slotsLabel.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            slotsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            slotsLabel.widthAnchor.constraint(equalToConstant: 100),
            slotsLabel.heightAnchor.constraint(equalToConstant: 25),
            
            goingLabel.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            goingLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ])
    }
    
    // MARK: - Color Updates
    func updateColors(isDarkMode: Bool? = nil) {
        let isDarkMode = isDarkMode ?? (traitCollection.userInterfaceStyle == .dark)
        
        // Update container view
        containerView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        // Update all labels
        venueLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        dateLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        timeLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        goingLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update separator
        separator.backgroundColor = isDarkMode ?
            UIColor.white.withAlphaComponent(0.3) :
            UIColor.black.withAlphaComponent(0.2)
        
        // Update shadow for tap gesture
        containerView.layer.shadowColor = (isDarkMode ? UIColor.black : UIColor.gray).cgColor
    }
    
    private func setupTapGesture() {
        // Remove any existing gestures first
        containerView.gestureRecognizers?.forEach { containerView.removeGestureRecognizer($0) }
        
        // Create a tap gesture that doesn't interfere with collection view selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.cancelsTouchesInView = false  // IMPORTANT: Allows touch to pass to collection view
        tapGesture.delaysTouchesBegan = false
        tapGesture.delaysTouchesEnded = false
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        
        // Add visual feedback for tap
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
    }
    
    @objc private func handleTap() {
        // Add brief visual feedback without interfering with collection view
        UIView.animate(withDuration: 0.1, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            self.containerView.alpha = 0.9
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = .identity
                self.containerView.alpha = 1.0
            }
        }
    }
    
    // MARK: - Configuration
    func configure(with match: DBMatch, onTap: (() -> Void)? = nil) {
        venueLabel.text = "📍 \(match.venue)"
        
        // Format date with day-specific calendar icon
        dateLabel.attributedText = formattedDateText(for: match.matchDate, isDarkMode: traitCollection.userInterfaceStyle == .dark)
        
        // Format time with AM/PM specific icon
        timeLabel.attributedText = formattedTimeText(for: match.matchTime, isDarkMode: traitCollection.userInterfaceStyle == .dark)
        
        // Calculate slots left
        let slotsLeft = match.playersNeeded - match.playersRSVPed
        slotsLabel.text = "\(slotsLeft) slots left"
        
        // Determine fill ratio for color coding - using 25%/75% thresholds like frontend
        let fillRatio = Double(match.playersRSVPed) / Double(match.playersNeeded)
        
        // Change background color based on how many have RSVP'd
        if fillRatio <= 0.25 {
            // Within first 25% filled → Green
            slotsLabel.backgroundColor = .systemGreen.withAlphaComponent(0.8)
        } else if fillRatio >= 0.75 {
            // Within last 25% filled → Red
            slotsLabel.backgroundColor = .systemRed.withAlphaComponent(0.8)
        } else {
            // Middle range → Yellow
            slotsLabel.backgroundColor = .systemYellow.withAlphaComponent(0.8)
        }
        
        // Configure going label (formatted as "X / Y going")
        goingLabel.text = "\(match.playersRSVPed) / \(match.playersNeeded) going"
        
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
        let today = Date()
        
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
        
        // Check if it's night time (6 PM to 6 AM)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timeDate)
        let isNightTime = hour >= 18 || hour < 6
        
        let timeIconImage: UIImage
        let tintColor: UIColor
        
        if isNightTime {
            // Between 6:00 PM and 5:59 AM → moon.fill in systemBlue
            timeIconImage = UIImage(systemName: "moon.fill")!
            tintColor = .systemBlue
            timeIcon.bounds = CGRect(x: 0, y: -2, width: 20, height: 20)
        } else {
            // Between 6:00 AM and 5:59 PM → sun.horizon in systemYellow
            timeIconImage = UIImage(systemName: "sun.horizon")!
            tintColor = .systemYellow
            timeIcon.bounds = CGRect(x: 0, y: -2, width: 30, height: 20)
        }
        
        // Set the icon with appropriate color
        timeIcon.image = timeIconImage.withTintColor(tintColor)
        
        // Calculate end time (add 1 hour)
        guard let endTimeDate = calendar.date(byAdding: .hour, value: 1, to: timeDate) else {
            return NSAttributedString(string: startTime)
        }
        let endTime = timeFormatter.string(from: endTimeDate)
        
        let fullString = NSMutableAttributedString()
        fullString.append(NSAttributedString(attachment: timeIcon))
        fullString.append(NSAttributedString(string: "  \(startTime) - \(endTime)"))
        
        return fullString
    }
}
