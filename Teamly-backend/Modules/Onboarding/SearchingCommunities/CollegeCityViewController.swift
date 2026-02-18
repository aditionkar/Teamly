import UIKit
import MapKit

// MARK: - CollegeCityViewController

class CollegeCityViewController: UIViewController {

    // MARK: - Callback

    var onCitySelected: ((String, String) -> Void)? // (city, state)

    // MARK: - UI Components

    private let dragIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.layer.cornerRadius = 2.5
        return view
    }()

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.translatesAutoresizingMaskIntoConstraints = false
        sb.placeholder = "Search Destination"
        sb.searchBarStyle = .minimal
        sb.returnKeyType = .search
        sb.autocorrectionType = .no
        sb.autocapitalizationType = .words

        // Remove default background
        sb.backgroundImage = UIImage()
        sb.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)

        return sb
    }()

    private let resultsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.alpha = 0
        return view
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 64
        tv.register(CityResultCell.self, forCellReuseIdentifier: CityResultCell.identifier)
        return tv
    }()

    // MARK: - Data

    private var searchCompleter = MKLocalSearchCompleter()
    private var results: [MKLocalSearchCompletion] = []
    private var searchTask: DispatchWorkItem?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupLayout()
        setupDelegates()
        setupSearchBarAppearance()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }

    // MARK: - Setup

    private func setupAppearance() {
        // Modal presentation style
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 24
        }

        updateColors()
    }

    private func updateColors() {
        let isDark = traitCollection.userInterfaceStyle == .dark

        // Modal background
        view.backgroundColor = isDark ? .secondaryDark : .secondaryLight

        // Results container background (tertiary)
        resultsContainerView.backgroundColor = isDark ? .tertiaryDark : .tertiaryLight

        // Search bar background
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = isDark ? .tertiaryDark : .tertiaryLight
            textField.textColor = isDark ? .white : .black
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search Destination",
                attributes: [.foregroundColor: (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.4)]
            )
            textField.leftView?.tintColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.5)
        }

        tableView.reloadData()
    }

    private func setupSearchBarAppearance() {
        let isDark = traitCollection.userInterfaceStyle == .dark

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.layer.cornerRadius = 14
            textField.clipsToBounds = true
            textField.backgroundColor = isDark ? .tertiaryDark : .tertiaryLight
            textField.textColor = isDark ? .white : .black
            textField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            textField.leftView?.tintColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.5)
        }
    }

    private func setupLayout() {
        view.addSubview(dragIndicator)
        view.addSubview(searchBar)
        view.addSubview(resultsContainerView)
        resultsContainerView.addSubview(tableView)

        NSLayoutConstraint.activate([
            // Drag Indicator
            dragIndicator.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            dragIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dragIndicator.widthAnchor.constraint(equalToConstant: 40),
            dragIndicator.heightAnchor.constraint(equalToConstant: 5),

            // Search Bar
            searchBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 36),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            searchBar.heightAnchor.constraint(equalToConstant: 52),

            // Results Container
            resultsContainerView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            resultsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resultsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resultsContainerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16),

            // TableView inside results container
            tableView.topAnchor.constraint(equalTo: resultsContainerView.topAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: resultsContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: resultsContainerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: resultsContainerView.bottomAnchor, constant: -8)
        ])
    }

    private func setupDelegates() {
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self

        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }

    // MARK: - Search Logic

    private func performSearch(query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            tableView.reloadData()
            hideResultsContainer()
            return
        }

        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.searchCompleter.queryFragment = query
        }

        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }

    // MARK: - Animations

    private func showResultsContainer() {
        guard resultsContainerView.alpha == 0 else { return }
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.resultsContainerView.alpha = 1
            self.resultsContainerView.transform = .identity
        }
    }

    private func hideResultsContainer() {
        guard resultsContainerView.alpha == 1 else { return }
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.resultsContainerView.alpha = 0
        }
    }
}

// MARK: - UISearchBarDelegate

extension CollegeCityViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(query: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension CollegeCityViewController: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter to only results that have both city and state info
        results = completer.results.filter { result in
            let subtitle = result.subtitle
            return !subtitle.isEmpty
        }

        tableView.reloadData()

        if results.isEmpty {
            hideResultsContainer()
        } else {
            showResultsContainer()
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}

// MARK: - UITableViewDataSource & Delegate

extension CollegeCityViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CityResultCell.identifier,
            for: indexPath
        ) as? CityResultCell else {
            return UITableViewCell()
        }

        let result = results[indexPath.row]
        let isLast = indexPath.row == results.count - 1
        let isDark = traitCollection.userInterfaceStyle == .dark
        cell.configure(with: result, isDark: isDark, hideSeparator: isLast)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let result = results[indexPath.row]
        let city = result.title
        let state = result.subtitle.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? result.subtitle

        onCitySelected?(city, state)
        dismiss(animated: true)
    }
}

// MARK: - CityResultCell

final class CityResultCell: UITableViewCell {

    static let identifier = "CityResultCell"

    private let pinImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(systemName: "mappin.fill")
        iv.tintColor = .systemRed
        iv.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        return iv
    }()

    private let cityLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        lbl.numberOfLines = 1
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.8
        return lbl
    }()

    private let separatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        contentView.addSubview(pinImageView)
        contentView.addSubview(cityLabel)
        contentView.addSubview(separatorLine)

        NSLayoutConstraint.activate([
            pinImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pinImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            pinImageView.widthAnchor.constraint(equalToConstant: 24),
            pinImageView.heightAnchor.constraint(equalToConstant: 24),

            cityLabel.leadingAnchor.constraint(equalTo: pinImageView.trailingAnchor, constant: 12),
            cityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cityLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            cityLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            cityLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),

            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    // MARK: - Configure

    func configure(with result: MKLocalSearchCompletion, isDark: Bool, hideSeparator: Bool) {
        // Build display string: "City , State"
        let city = result.title
        let statePart = result.subtitle.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? ""
        let displayText = statePart.isEmpty ? city : "\(city) , \(statePart)"

        cityLabel.text = displayText
        cityLabel.textColor = isDark ? .white : .black
        separatorLine.backgroundColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.12)
        separatorLine.isHidden = hideSeparator
    }

    // MARK: - Highlight

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.15) {
            self.contentView.alpha = highlighted ? 0.5 : 1.0
        }
    }
}

// MARK: - UIColor Extension (Fallback stubs if not defined globally)
// These are referenced from your existing colour definitions. 
// Remove this extension if colours are already globally defined.

extension UIColor {
    @objc class var secondaryDark: UIColor {
        return UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
    }

    @objc class var secondaryLight: UIColor {
        return UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
    }

    @objc class var tertiaryDark: UIColor {
        return UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1)
    }

    @objc class var tertiaryLight: UIColor {
        return UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1)
    }
}