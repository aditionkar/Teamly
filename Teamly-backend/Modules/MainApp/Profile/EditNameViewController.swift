//
//  EditNameViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 19/02/26.
//

import UIKit
import Supabase

class EditNameViewController: UIViewController {

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
        view.layer.borderWidth = 0.7
        return view
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
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Properties
    var currentName: String?
    var onNameUpdated: (() -> Void)?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        updateColors()
        prefillData()
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

    // MARK: - Prefill
    private func prefillData() {
        // Set current name as the text (editable), not placeholder
        if let name = currentName {
            nameTextField.text = name
        }

        updateSaveButtonState()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite

        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)

        view.addSubview(cancelButton)
        view.addSubview(nameTextFieldContainer)
        nameTextFieldContainer.addSubview(nameTextField)
        view.addSubview(saveButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: 100),

            // Cancel (X) button — top right
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 34),
            cancelButton.heightAnchor.constraint(equalToConstant: 34),

            // Name field - centered vertically
            nameTextFieldContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            nameTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            nameTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nameTextFieldContainer.heightAnchor.constraint(equalToConstant: 50),

            nameTextField.topAnchor.constraint(equalTo: nameTextFieldContainer.topAnchor),
            nameTextField.leadingAnchor.constraint(equalTo: nameTextFieldContainer.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: nameTextFieldContainer.trailingAnchor),
            nameTextField.bottomAnchor.constraint(equalTo: nameTextFieldContainer.bottomAnchor),

            // Save button
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 120),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupActions() {
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }

    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite

        nameTextField.attributedPlaceholder = NSAttributedString(
            string: "Name",
            attributes: [.foregroundColor: isDarkMode ? UIColor.gray : UIColor.lightGray]
        )
        nameTextField.textColor = isDarkMode ? .primaryWhite : .primaryBlack

        nameTextFieldContainer.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        nameTextFieldContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight).cgColor
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
    @objc private func textFieldDidChange() {
        updateSaveButtonState()
    }

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
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else { return }

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
                    .update(["name": name])
                    .eq("id", value: userId.uuidString)
                    .execute()

                await MainActor.run {
                    loader.removeFromSuperview()
                    saveButton.isEnabled = true
                    onNameUpdated?()
                    cancelTapped()
                }

            } catch {
                await MainActor.run {
                    loader.removeFromSuperview()
                    saveButton.isEnabled = true
                    print("🔴 Error: \(error)")
                    let alert = UIAlertController(
                        title: "Error",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Helpers
    private func updateSaveButtonState() {
        let isNameNotEmpty = !(nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        saveButton.isEnabled = isNameNotEmpty
    }
}
