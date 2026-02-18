//
//  CollegeCityViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 17/02/26.
//

import UIKit
import Supabase

//struct College: Codable {
//    let id: Int
//    let name: String
//    let location: String?
//    let created_at: String?
//
//    enum CodingKeys: String, CodingKey {
//        case id
//        case name
//        case location
//        case created_at
//    }
//}


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
        sb.placeholder = "Search City"
        sb.searchBarStyle = .minimal
        sb.returnKeyType = .search
        sb.autocorrectionType = .no
        sb.autocapitalizationType = .words
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

    // MARK: - "No colleges" empty state - matches the screenshot

    private let selectedCityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.alpha = 0
        return label
    }()

    private let noCollegesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0
        label.textColor = UIColor.systemGray // Gray color as shown in screenshot
        return label
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Data

    private var allCities: [IndianCity] = []
    private var filteredCities: [IndianCity] = []
    private var selectedCity: String?
    private var selectedState: String?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        loadCitiesData()
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

    // MARK: - Load Cities Data

    private func loadCitiesData() {
        allCities = IndianCitiesData.all.sorted { $0.name < $1.name }
        print("✅ Loaded \(allCities.count) Indian cities")
    }

    // MARK: - Setup

    private func setupAppearance() {
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

        view.backgroundColor = isDark ? .secondaryDark : .secondaryLight
        resultsContainerView.backgroundColor = isDark ? .secondaryDark : .secondaryLight

        selectedCityLabel.textColor = isDark ? .white : .black
        // noCollegesLabel keeps systemGray - don't override it

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = isDark ? .tertiaryDark : .tertiaryLight
            textField.textColor = isDark ? .white : .black
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search City",
                attributes: [.foregroundColor: (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.4)]
            )
            textField.leftView?.tintColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.5)
        }

        tableView.reloadData()
    }

    private func setupSearchBarAppearance() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
            textField.backgroundColor = isDark ? .tertiaryDark : .tertiaryLight
            textField.textColor = isDark ? .white : .black
            textField.font = UIFont.systemFont(ofSize: 15, weight: .regular)
            textField.leftView?.tintColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.5)
        }
    }

    private func setupLayout() {
        view.addSubview(dragIndicator)
        view.addSubview(searchBar)
        view.addSubview(resultsContainerView)
        view.addSubview(selectedCityLabel)
        view.addSubview(noCollegesLabel)
        view.addSubview(loadingIndicator)

        resultsContainerView.addSubview(tableView)

        NSLayoutConstraint.activate([
            // Drag Indicator
            dragIndicator.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            dragIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dragIndicator.widthAnchor.constraint(equalToConstant: 40),
            dragIndicator.heightAnchor.constraint(equalToConstant: 5),

            // Search Bar
            searchBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 46),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            searchBar.heightAnchor.constraint(equalToConstant: 52),

            // Results Container
            resultsContainerView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            resultsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resultsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resultsContainerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8),

            // TableView
            tableView.topAnchor.constraint(equalTo: resultsContainerView.topAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: resultsContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: resultsContainerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: resultsContainerView.bottomAnchor, constant: -8),

            // Selected city label — centered vertically in the view
            selectedCityLabel.centerYAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 50),
            selectedCityLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            selectedCityLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // "Sorry" label — centered below city label
            noCollegesLabel.topAnchor.constraint(equalTo: selectedCityLabel.bottomAnchor, constant: 80),
            noCollegesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            noCollegesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupDelegates() {
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: - Search Logic

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            filteredCities = []
            tableView.reloadData()
            hideResultsContainer()
            return
        }

        // Filter cities that start with the query (case-insensitive)
        filteredCities = allCities.filter { city in
            city.name.lowercased().hasPrefix(trimmed.lowercased()) ||
            city.name.lowercased().contains(" " + trimmed.lowercased()) // Handle multi-word cities
        }

        tableView.reloadData()
        filteredCities.isEmpty ? hideResultsContainer() : showResultsContainer()
    }

    // MARK: - Animations

    private func showResultsContainer() {
        guard resultsContainerView.alpha == 0 else { return }
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.resultsContainerView.alpha = 1
        }
    }

    private func hideResultsContainer() {
        guard resultsContainerView.alpha == 1 else { return }
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.resultsContainerView.alpha = 0
        }
    }

    private func showSelectedCityName(_ city: String, state: String) {
        selectedCity = city
        selectedState = state
        selectedCityLabel.text = "\(city) , \(state)"
        noCollegesLabel.alpha = 0
        UIView.animate(withDuration: 0.25) { self.selectedCityLabel.alpha = 1 }
    }

    private func showNoCollegesMessage(city: String) {
        noCollegesLabel.text = "Sorry we're not operating in\n\(city) at this moment"
        UIView.animate(withDuration: 0.3) { self.noCollegesLabel.alpha = 1 }
    }

    private func hideEmptyState() {
        UIView.animate(withDuration: 0.2) {
            self.selectedCityLabel.alpha = 0
            self.noCollegesLabel.alpha = 0
        } completion: { _ in
            self.selectedCity = nil
            self.selectedState = nil
        }
    }

    // MARK: - College Verification

    private func checkCollegesForCity(city: String, state: String) {
        loadingIndicator.startAnimating()

        Task {
            do {
                let response: [College] = try await SupabaseManager.shared.client
                    .from("colleges")
                    .select("id, name, location, created_at")
                    .filter("location", operator: "ilike", value: "%\(city)%")
                    .execute()
                    .value

                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    if response.isEmpty {
                        self.showNoCollegesMessage(city: city)
                    } else {
                        self.presentCollegesModal(with: response, city: city, state: state)
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    print("Error checking colleges: \(error)")
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to check colleges. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func presentCollegesModal(with colleges: [College], city: String, state: String) {
        let collegesModalVC = CollegesModalViewController()
        collegesModalVC.colleges = colleges
        collegesModalVC.cityName = "\(city), \(state)"
        if let sheet = collegesModalVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        collegesModalVC.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
        present(collegesModalVC, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension CollegeCityViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(query: searchText)
        hideEmptyState()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource & Delegate

extension CollegeCityViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CityResultCell.identifier,
            for: indexPath
        ) as? CityResultCell else { return UITableViewCell() }

        let city = filteredCities[indexPath.row]
        let isLast = indexPath.row == filteredCities.count - 1
        let isDark = traitCollection.userInterfaceStyle == .dark
        cell.configure(city: city.name, state: city.state, isDark: isDark, hideSeparator: isLast)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let city = filteredCities[indexPath.row]
        hideResultsContainer()
        showSelectedCityName(city.name, state: city.state)
        checkCollegesForCity(city: city.name, state: city.state)
        searchBar.resignFirstResponder()
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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

    func configure(city: String, state: String, isDark: Bool, hideSeparator: Bool) {
        cityLabel.text = "\(city) , \(state)"
        cityLabel.textColor = isDark ? .white : .black
        separatorLine.backgroundColor = (isDark ? UIColor.white : UIColor.black).withAlphaComponent(0.12)
        separatorLine.isHidden = hideSeparator
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.15) {
            self.contentView.alpha = highlighted ? 0.5 : 1.0
        }
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct CollegeCityViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CollegeCityViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .previewDisplayName("Dark Mode")

            CollegeCityViewControllerRepresentable()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .previewDisplayName("Light Mode")
        }
    }
}

struct CollegeCityViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CollegeCityViewController {
        let vc = CollegeCityViewController()
        vc.onCitySelected = { city, state in
            print("Selected city: \(city), state: \(state)")
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: CollegeCityViewController, context: Context) {}
}
#endif
