//
//  NameAndGenderViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 24/01/26.
//

import UIKit
import Auth
import Supabase

class NameAndGenderViewController: UIViewController {
    
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
    
    private let progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progress = 0.2
        progressView.progressTintColor = .systemGreen
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Set up your profile"
        label.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.translatesAutoresizingMaskIntoConstraints = false

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private let nameTextFieldContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.frame = view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.layer.borderWidth = 0.7
        
        return view
    }()

    private let maleButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "Male")
        config.imagePadding = 10
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let maleLabel: UILabel = {
        let label = UILabel()
        label.text = "Male"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.alpha = 1.0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let maleVerticalStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let maleButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 35
        view.clipsToBounds = true
        view.frame = view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.layer.borderWidth = 0.7

        return view
    }()

    private let femaleButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "Female")
        config.imagePadding = 10
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let femaleLabel: UILabel = {
        let label = UILabel()
        label.text = "Female"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.alpha = 1.0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let femaleVerticalStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let femaleButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 35
        view.clipsToBounds = true
        view.frame = view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.layer.borderWidth = 0.7
        
        return view
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        
        var title = AttributedString("Next")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        config.attributedTitle = title
        
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .primaryWhite
        config.background.cornerRadius = 25
        
        button.configuration = config
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let genderStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 28
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Properties
    private var selectedGender: String?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
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
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
            
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
            
        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(nameTextFieldContainer)
        nameTextFieldContainer.addSubview(nameTextField)
        view.addSubview(genderStackView)
        view.addSubview(nextButton)
        
        // Setup male container with vertical stack
        maleVerticalStack.addArrangedSubview(maleButton)
        maleVerticalStack.addArrangedSubview(maleLabel)
        maleButtonContainer.addSubview(maleVerticalStack)
        
        // Setup female container with vertical stack
        femaleVerticalStack.addArrangedSubview(femaleButton)
        femaleVerticalStack.addArrangedSubview(femaleLabel)
        femaleButtonContainer.addSubview(femaleVerticalStack)
        
        genderStackView.addArrangedSubview(maleButtonContainer)
        genderStackView.addArrangedSubview(femaleButtonContainer)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: genderStackView.bottomAnchor, constant: 50),

            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            progressView.heightAnchor.constraint(equalToConstant: 7),

            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            nameTextFieldContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 80),
            nameTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            nameTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nameTextFieldContainer.heightAnchor.constraint(equalToConstant: 50),

            nameTextField.topAnchor.constraint(equalTo: nameTextFieldContainer.topAnchor),
            nameTextField.leadingAnchor.constraint(equalTo: nameTextFieldContainer.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: nameTextFieldContainer.trailingAnchor),
            nameTextField.bottomAnchor.constraint(equalTo: nameTextFieldContainer.bottomAnchor),

            genderStackView.topAnchor.constraint(equalTo: nameTextFieldContainer.bottomAnchor, constant: 60),
            genderStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            genderStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            genderStackView.heightAnchor.constraint(equalToConstant: 140),

            maleButtonContainer.widthAnchor.constraint(equalToConstant: 120),
            femaleButtonContainer.widthAnchor.constraint(equalToConstant: 120),

            maleVerticalStack.centerXAnchor.constraint(equalTo: maleButtonContainer.centerXAnchor),
            maleVerticalStack.centerYAnchor.constraint(equalTo: maleButtonContainer.centerYAnchor),
            maleVerticalStack.leadingAnchor.constraint(equalTo: maleButtonContainer.leadingAnchor, constant: 8),
            maleVerticalStack.trailingAnchor.constraint(equalTo: maleButtonContainer.trailingAnchor, constant: -8),

            femaleVerticalStack.centerXAnchor.constraint(equalTo: femaleButtonContainer.centerXAnchor),
            femaleVerticalStack.centerYAnchor.constraint(equalTo: femaleButtonContainer.centerYAnchor),
            femaleVerticalStack.leadingAnchor.constraint(equalTo: femaleButtonContainer.leadingAnchor, constant: 8),
            femaleVerticalStack.trailingAnchor.constraint(equalTo: femaleButtonContainer.trailingAnchor, constant: -8),

            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        maleButton.addTarget(self, action: #selector(maleButtonTapped), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(femaleButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite

        progressView.trackTintColor = isDarkMode ?
            UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) :
            UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack

        nameTextField.attributedPlaceholder = NSAttributedString(
            string: "Name",
            attributes: [NSAttributedString.Key.foregroundColor: isDarkMode ? UIColor.gray : UIColor.lightGray]
        )
        nameTextField.textColor = isDarkMode ? .primaryWhite : .primaryBlack

        nameTextFieldContainer.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        nameTextFieldContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight).cgColor

        maleButtonContainer.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        femaleButtonContainer.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        maleButtonContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        femaleButtonContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor

        if isDarkMode {
            maleLabel.textColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
            femaleLabel.textColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        } else {
            maleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            femaleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        }

        updateGenderSelection()
    }
    
    private func updateGradientColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if isDarkMode {
            let darkGreen = UIColor(red: 0.0, green: 0.15, blue: 0.0, alpha: 1.0)
            gradientLayer.colors = [
                darkGreen.cgColor,
                UIColor.clear.cgColor
            ]
        } else {
            let lightGreen = UIColor(red: 53/255, green: 199/255, blue: 89/255, alpha: 0.3)
            gradientLayer.colors = [
                lightGreen.cgColor,
                UIColor.clear.cgColor
            ]
        }
        
        gradientLayer.locations = [0.0, 0.25]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange() {
        updateNextButtonState()
    }
    
    @objc private func maleButtonTapped() {
        selectedGender = "male"
        updateGenderSelection()
        updateNextButtonState()
    }
    
    @objc private func femaleButtonTapped() {
        selectedGender = "female"
        updateGenderSelection()
        updateNextButtonState()
    }
    
    @objc private func nextButtonTapped() {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty,
              let gender = selectedGender else {
            return
        }

        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        nextButton.isEnabled = false
        
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id

                try await ProfileManager.shared.saveNameAndGender(
                    userId: userId,
                    name: name,
                    gender: gender
                )
                
                // Success - navigate to next screen
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    nextButton.isEnabled = true
                    
                    let ageVC = AgeViewController()

                    if let navController = navigationController {
                        navController.pushViewController(ageVC, animated: true)
                        navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
                    } else {
                        let navController = UINavigationController(rootViewController: ageVC)
                        navController.modalPresentationStyle = .fullScreen
                        navController.setNavigationBarHidden(true, animated: false)
                        navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
                        present(navController, animated: true)
                    }
                }
                
            } catch {
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    nextButton.isEnabled = true
                    
                    print("Error saving profile: \(error.localizedDescription)")
                    
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to save profile. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    
    // MARK: - Helper Methods
    private func updateGenderSelection() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        maleButtonContainer.layer.borderWidth = isDarkMode ? 0.7 : 0.9
        femaleButtonContainer.layer.borderWidth = isDarkMode ? 0.7 : 0.9

        maleButtonContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight).cgColor
        femaleButtonContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight).cgColor

        if selectedGender == "male" {
            maleButtonContainer.layer.borderColor = UIColor.systemGreen.cgColor
        } else if selectedGender == "female" {
            femaleButtonContainer.layer.borderColor = UIColor.systemGreen.cgColor
        }
    }
    
    private func updateNextButtonState() {
        let isNameNotEmpty = !(nameTextField.text?.isEmpty ?? true)
        let isGenderSelected = selectedGender != nil
        
        nextButton.isEnabled = isNameNotEmpty && isGenderSelected
    }
}

// MARK: - SwiftUI Preview
import SwiftUI

struct NameAndGenderViewController_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            NameAndGenderViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            NameAndGenderViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct NameAndGenderViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NameAndGenderViewController {
        return NameAndGenderViewController()
    }
    
    func updateUIViewController(_ uiViewController: NameAndGenderViewController, context: Context) {
        // Update the view controller if needed
    }
}
