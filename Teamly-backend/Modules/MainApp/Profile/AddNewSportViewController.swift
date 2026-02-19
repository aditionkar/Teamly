//
//  AddNewSportViewController.swift
//  Teamly-backend
//
//  Created by admin20 on 19/02/26.
//

//
//  AddNewSportViewController.swift
//  Teamly-backend
//

import UIKit
import Supabase

class AddNewSportViewController: UIViewController {

    // MARK: - UI Elements
    private let topGreenTint: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        return gradient
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray
        button.backgroundColor = UIColor.systemGray.withAlphaComponent(0.15)
        button.layer.cornerRadius = 17
        button.clipsToBounds = true
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add a sport"
        label.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let sportsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    private let nextButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        var title = AttributedString("Next")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        config.attributedTitle = title
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .white
        config.background.cornerRadius = 25
        button.configuration = config
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties
    var onSportsUpdated: (() -> Void)?
    var existingSportIds: [Int] = [] // sports user already has

    private var selectedSports: [Sport] = []
    private var sports: [Sport] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupCollectionView()
        updateColors()
        fetchSports()
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
            sportsCollectionView.reloadData()
        }
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite

        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)

        view.addSubview(cancelButton)
        view.addSubview(titleLabel)
        view.addSubview(sportsCollectionView)
        view.addSubview(nextButton)
        view.addSubview(loadingIndicator)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -30),

            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 34),
            cancelButton.heightAnchor.constraint(equalToConstant: 34),

            titleLabel.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            sportsCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            sportsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            sportsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            sportsCollectionView.heightAnchor.constraint(equalToConstant: 220),

            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 50),

            loadingIndicator.centerXAnchor.constraint(equalTo: sportsCollectionView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: sportsCollectionView.centerYAnchor)
        ])
    }

    private func setupCollectionView() {
        sportsCollectionView.delegate = self
        sportsCollectionView.dataSource = self
        sportsCollectionView.register(SportCollectionViewCell.self, forCellWithReuseIdentifier: "SportCollectionViewCell")
    }

    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }

    // MARK: - Fetch Sports
    private func fetchSports() {
        loadingIndicator.startAnimating()

        Task {
            do {
                let response: [Sport] = try await SupabaseManager.shared.client
                    .from("sports")
                    .select("id, name, emoji")
                    .order("id", ascending: true)
                    .execute()
                    .value

                await MainActor.run {
                    // Filter out sports user already has
                    self.sports = response.filter { !self.existingSportIds.contains($0.id) }
                    self.sportsCollectionView.reloadData()
                    self.loadingIndicator.stopAnimating()
                }

            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    let alert = UIAlertController(title: "Error", message: "Failed to load sports. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        loadingIndicator.color = isDarkMode ? .white : .black
    }

    private func updateGradientColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        if isDarkMode {
            gradientLayer.colors = [UIColor(red: 0.0, green: 0.15, blue: 0.0, alpha: 1.0).cgColor, UIColor.clear.cgColor]
        } else {
            gradientLayer.colors = [UIColor(red: 53/255, green: 199/255, blue: 89/255, alpha: 0.3).cgColor, UIColor.clear.cgColor]
        }
        gradientLayer.locations = [0.0, 0.25]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }

    private func updateNextButtonState() {
        nextButton.isEnabled = !selectedSports.isEmpty
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        if let nav = navigationController {
            if nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                nav.dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func nextButtonTapped() {
        guard !selectedSports.isEmpty else { return }

        let skillVC = NewSportSkillViewController(selectedSports: selectedSports)
        skillVC.onSportsUpdated = onSportsUpdated

        if let nav = navigationController {
            nav.pushViewController(skillVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: skillVC)
            nav.setNavigationBarHidden(true, animated: false)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
}

// MARK: - UICollectionView
extension AddNewSportViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sports.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SportCollectionViewCell", for: indexPath) as! SportCollectionViewCell
        let sport = sports[indexPath.item]
        let isSelected = selectedSports.contains(where: { $0.id == sport.id })
        cell.configure(with: sport, isSelected: isSelected)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sport = sports[indexPath.item]
        if let index = selectedSports.firstIndex(where: { $0.id == sport.id }) {
            selectedSports.remove(at: index)
        } else {
            selectedSports.append(sport)
        }
        collectionView.reloadData()
        updateNextButtonState()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 90, height: 90)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let totalWidth = collectionView.frame.width
        let totalCellWidth: CGFloat = 90 * 3
        let totalSpacing: CGFloat = 20 * 2
        let leftInset = (totalWidth - totalCellWidth - totalSpacing) / 2
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: leftInset)
    }
}