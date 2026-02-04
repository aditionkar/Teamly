//
//  SearchViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 03/02/26.
//

import UIKit
import Supabase

final class SearchViewController: UIViewController {

    // MARK: - Models
    struct UserProfile {
        let id: UUID
        let name: String
        let gender: String?
        let age: Int?
        let college_id: Int?
        let profile_pic: String?
    }

    private var allUsers: [UserProfile] = []
    private var filteredUsers: [UserProfile] = []

    // MARK: - UI Components
    private let topGreenTint: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let gradientLayer = CAGradientLayer()
    private let supabase = SupabaseManager.shared.client

    // MARK: - Glass Back Button
    private let glassBackButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Search Bar
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search players"
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

    // MARK: - Table View
    private let tableView: UITableView = {
        let table = UITableView()
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTable()
        setupBackButton()
        updateColors()
        
        // Fetch all users on load
        Task {
            await fetchAllUsers()
        }
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

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .backgroundPrimary

        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        topGreenTint.isUserInteractionEnabled = false

        view.addSubview(glassBackButton)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)

        searchBar.delegate = self

        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),

            glassBackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            glassBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            glassBackButton.widthAnchor.constraint(equalToConstant: 40),
            glassBackButton.heightAnchor.constraint(equalToConstant: 40),

            searchBar.topAnchor.constraint(equalTo: glassBackButton.bottomAnchor, constant: 16),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            searchBar.heightAnchor.constraint(equalToConstant: 50),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        updateSearchBarAppearance()
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UserSearchCell.self, forCellReuseIdentifier: "UserSearchCell")
        tableView.rowHeight = 60
    }

    private func setupBackButton() {
        glassBackButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    // MARK: - Data Fetching
    private func fetchAllUsers() async {
        await MainActor.run {
            loadingIndicator.startAnimating()
        }
        
        do {
            // Fetch all profiles from the database
            let profiles: [Profile] = try await supabase
                .from("profiles")
                .select()
                .order("name", ascending: true)
                .execute()
                .value
            
            // Convert to UserProfile struct
            self.allUsers = profiles.map { profile in
                UserProfile(
                    id: profile.id,
                    name: profile.name ?? "Unknown",
                    gender: profile.gender,
                    age: profile.age,
                    college_id: profile.college_id,
                    profile_pic: profile.profile_pic
                )
            }
            
            await MainActor.run {
                loadingIndicator.stopAnimating()
                tableView.reloadData()
            }
            
        } catch {
            print("Error fetching users: \(error)")
            await MainActor.run {
                loadingIndicator.stopAnimating()
                showError(message: "Failed to load users")
            }
        }
    }

    // MARK: - Colors
    private func updateColors() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDark ? .primaryBlack : .primaryWhite
        updateGlassButton(glassBackButton, isDarkMode: isDark)
        updateSearchBarAppearance()
    }

    private func updateGlassButton(_ button: UIButton, isDarkMode: Bool) {
        button.backgroundColor = isDarkMode ? UIColor(white: 1, alpha: 0.1) : UIColor(white: 0, alpha: 0.05)
        button.layer.borderColor = (isDarkMode ? UIColor(white: 1, alpha: 0.2) : UIColor(white: 0, alpha: 0.1)).cgColor
        button.tintColor = isDarkMode ? .systemGreenDark : .systemGreen
    }

    private func updateGradientColors() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        gradientLayer.colors = [
            (isDark
                ? UIColor(red: 0, green: 0.15, blue: 0, alpha: 1)
                : UIColor(red: 53/255, green: 199/255, blue: 89/255, alpha: 0.3)
            ).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0, 0.25]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }

    private func updateSearchBarAppearance() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        if let tf = searchBar.value(forKey: "searchField") as? UITextField {
            tf.backgroundColor = isDark ? .secondaryDark : .tertiaryLight
            tf.textColor = isDark ? .primaryWhite : .primaryBlack
            tf.layer.cornerRadius = 8
            tf.clipsToBounds = true
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Actions
    @objc private func backButtonTapped() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    private func navigateToUserProfile(userId: UUID) {
        let userProfileVC = UserProfileViewController()
        userProfileVC.userId = userId
        
        if let navController = navigationController {
            navController.pushViewController(userProfileVC, animated: true)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        } else {
            let navController = UINavigationController(rootViewController: userProfileVC)
            navController.modalPresentationStyle = .fullScreen
            navController.setNavigationBarHidden(true, animated: false)
            navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
            present(navController, animated: true)
        }
    }
}

// MARK: - Search Logic
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        
        if query.isEmpty {
            filteredUsers = []
        } else {
            filteredUsers = allUsers.filter { user in
                user.name.lowercased().contains(query)
            }
        }
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - TableView
extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "UserSearchCell",
            for: indexPath
        ) as! UserSearchCell

        let user = filteredUsers[indexPath.row]
        cell.configure(
            user: user,
            isDarkMode: traitCollection.userInterfaceStyle == .dark
        )
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = filteredUsers[indexPath.row]
        navigateToUserProfile(userId: user.id)
    }
}

// MARK: - User Search Cell
final class UserSearchCell: UITableViewCell {

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let detailsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let separatorLine: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(iconView)
        contentView.addSubview(stackView)
        contentView.addSubview(separatorLine)
        
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(detailsLabel)

        NSLayoutConstraint.activate([
            // 👤 Icon
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 41),
            iconView.heightAnchor.constraint(equalToConstant: 41),

            // Stack View
            stackView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            stackView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Separator
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(user: SearchViewController.UserProfile, isDarkMode: Bool) {
        nameLabel.text = user.name
        nameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Create details text
        var details = ""
        if let age = user.age {
            details += "\(age) years"
        }
        if let gender = user.gender {
            if !details.isEmpty { details += " • " }
            details += gender
        }
        
        detailsLabel.text = details.isEmpty ? "No details" : details
        detailsLabel.textColor = isDarkMode ? .gray : .darkGray

        // 👤 Gray placeholder icon
        iconView.tintColor = .backgroundQuaternary

        // Gray separator
        separatorLine.backgroundColor = .backgroundQuaternary
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Search – Light Mode")

            SearchViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Search – Dark Mode")
        }
    }
}

struct SearchViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SearchViewController {
        return SearchViewController()
    }

    func updateUIViewController(_ uiViewController: SearchViewController, context: Context) {}
}
#endif
