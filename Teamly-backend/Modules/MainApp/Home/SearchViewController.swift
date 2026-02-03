import UIKit

final class SearchViewController: UIViewController {

    // MARK: - Models
    struct Player {
        let name: String
        let imageName: String
    }

    private let allPlayers: [Player] = [
        Player(name: "Rashmika", imageName: "rashmika"),
        Player(name: "Aditi", imageName: "aditi")
    ]

    private var filteredPlayers: [Player] = []

    // MARK: - Top Green Gradient
    private let topGreenTint: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let gradientLayer = CAGradientLayer()

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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTable()
        setupBackButton()
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

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .backgroundPrimary

        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        topGreenTint.isUserInteractionEnabled = false

        view.addSubview(glassBackButton)
        view.addSubview(searchBar)
        view.addSubview(tableView)

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
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        updateSearchBarAppearance()
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PlayerCell.self, forCellReuseIdentifier: "PlayerCell")

        // ✅ FIX: enough height for container + spacing
        tableView.rowHeight = 50
    }

    private func setupBackButton() {
        glassBackButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
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

    // MARK: - Actions
    @objc private func backButtonTapped() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}

// MARK: - Search Logic
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.lowercased()
        filteredPlayers = query.isEmpty
            ? []
            : allPlayers.filter { $0.name.lowercased().contains(query) }
        tableView.reloadData()
    }
}

// MARK: - TableView
extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredPlayers.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "PlayerCell",
            for: indexPath
        ) as! PlayerCell

        cell.configure(
            player: filteredPlayers[indexPath.row],
            isDarkMode: traitCollection.userInterfaceStyle == .dark
        )
        return cell
    }
}

// MARK: - Player Cell (👤 Placeholder + gray separator)
final class PlayerCell: UITableViewCell {

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

    private let separatorLine: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(separatorLine)

        NSLayoutConstraint.activate([
            // 👤 Icon
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 41),
            iconView.heightAnchor.constraint(equalToConstant: 41),

            // Name
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            nameLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

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

    func configure(player: SearchViewController.Player, isDarkMode: Bool) {
        nameLabel.text = player.name
        nameLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack

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