//
//  EditAgeViewController.swift
//  Teamly-backend
//
//  Created by admin20 on 18/02/26.
//

//
//  EditAgeViewController.swift
//  Teamly-backend
//

import UIKit
import Supabase

class EditAgeViewController: UIViewController {

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

    private let ageScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = .fast
        scrollView.bounces = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let ageStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let saveButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        var title = AttributedString("Save")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        config.attributedTitle = title
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .white
        config.background.cornerRadius = 25
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Properties
    var currentAge: Int?
    var onAgeUpdated: (() -> Void)?

    private let ages = Array(16...100)
    private var ageLabels: [UILabel] = []
    private var selectedAge: Int = 20
    private var itemWidth: CGFloat = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupAgeSelector()
        updateColors()

        if let age = currentAge, ages.contains(age) {
            selectedAge = age
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        itemWidth = view.bounds.width / 4

        let contentWidth = CGFloat(ages.count) * itemWidth
        ageStackView.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollToAge(self.selectedAge, animated: false)
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
            updateAgeAppearance()
        }
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite

        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)

        view.addSubview(cancelButton)
        view.addSubview(ageScrollView)
        view.addSubview(saveButton)

        ageScrollView.addSubview(ageStackView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -30),

            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 34),
            cancelButton.heightAnchor.constraint(equalToConstant: 34),

            ageScrollView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            ageScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ageScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ageScrollView.heightAnchor.constraint(equalToConstant: 120),

            ageStackView.topAnchor.constraint(equalTo: ageScrollView.topAnchor),
            ageStackView.leadingAnchor.constraint(equalTo: ageScrollView.leadingAnchor),
            ageStackView.trailingAnchor.constraint(equalTo: ageScrollView.trailingAnchor),
            ageStackView.bottomAnchor.constraint(equalTo: ageScrollView.bottomAnchor),
            ageStackView.centerYAnchor.constraint(equalTo: ageScrollView.centerYAnchor),

            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 120),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }

    private func setupAgeSelector() {
        for age in ages {
            let label = UILabel()
            label.text = "\(age)"
            label.font = UIFont.systemFont(ofSize: 95, weight: .black)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            ageLabels.append(label)
            ageStackView.addArrangedSubview(label)
        }

        ageScrollView.delegate = self
        ageScrollView.clipsToBounds = false
        updateAgeAppearance()
    }

    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
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

    @objc private func saveButtonTapped() {
        let loader = UIActivityIndicatorView(style: .medium)
        loader.center = view.center
        loader.startAnimating()
        view.addSubview(loader)
        saveButton.isEnabled = false

        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id

                try await SupabaseManager.shared.client
                    .from("profiles")
                    .update(["age": selectedAge])
                    .eq("id", value: userId.uuidString)
                    .execute()

                await MainActor.run {
                    loader.removeFromSuperview()
                    saveButton.isEnabled = true
                    onAgeUpdated?()
                    cancelTapped()
                }

            } catch {
                await MainActor.run {
                    loader.removeFromSuperview()
                    saveButton.isEnabled = true
                    print("🔴 Error: \(error)")
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func scrollToAge(_ age: Int, animated: Bool) {
        guard let index = ages.firstIndex(of: age), itemWidth > 0 else { return }
        let xPosition = (CGFloat(index) * itemWidth) - (view.bounds.width / 2) + (itemWidth / 2)
        ageScrollView.setContentOffset(CGPoint(x: xPosition, y: 0), animated: animated)
        selectedAge = age
        updateAgeAppearance()
    }

    private func updateAgeAppearance() {
        guard itemWidth > 0 else { return }
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let centerX = ageScrollView.contentOffset.x + view.bounds.width / 2

        for (index, label) in ageLabels.enumerated() {
            let labelCenterX = (CGFloat(index) * itemWidth) + (itemWidth / 2)
            let distanceFromCenter = abs(labelCenterX - centerX)

            if distanceFromCenter < itemWidth / 2 {
                label.font = UIFont.systemFont(ofSize: 95, weight: .black)
                label.textColor = .systemGreen
                label.alpha = 1.0
                selectedAge = ages[index]
            } else if distanceFromCenter < itemWidth * 1.5 {
                label.font = UIFont.systemFont(ofSize: 65, weight: .heavy)
                label.textColor = isDarkMode ? .white.withAlphaComponent(0.4) : .black.withAlphaComponent(0.4)
                label.alpha = 0.6
            } else {
                label.font = UIFont.systemFont(ofSize: 50, weight: .bold)
                label.textColor = isDarkMode ? .white.withAlphaComponent(0.2) : .black.withAlphaComponent(0.2)
                label.alpha = 0.0
            }
        }
    }

    private func snapToNearestAge() {
        guard itemWidth > 0 else { return }
        let centerX = ageScrollView.contentOffset.x + view.bounds.width / 2
        var closestIndex = 0
        var minDistance: CGFloat = .greatestFiniteMagnitude

        for (index, _) in ages.enumerated() {
            let labelCenterX = (CGFloat(index) * itemWidth) + (itemWidth / 2)
            let distance = abs(labelCenterX - centerX)
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }
        scrollToAge(ages[closestIndex], animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension EditAgeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateAgeAppearance()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapToNearestAge()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { snapToNearestAge() }
    }
}