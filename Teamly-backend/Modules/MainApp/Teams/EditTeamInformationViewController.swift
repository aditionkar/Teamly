//
//  EditTeamInformationViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 02/02/26.
//

import UIKit
import Supabase

class EditTeamInformationViewController: UIViewController {
    
    // MARK: - UI Components
    private let navigationBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Edit Team"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let teamIconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 50
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let teamIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "person.3.fill")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let editIconButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: "pencil.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .systemGreen
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Team Name"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let teamNameContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.layer.borderWidth = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let teamNameTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = .clear
        textField.font = .systemFont(ofSize: 17, weight: .regular)
        textField.placeholder = "Enter team name"
        textField.textAlignment = .center
        textField.returnKeyType = .done
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    var team: BackendTeam?
    var onSave: ((BackendTeam) -> Void)?
    private var gradientLayer: CAGradientLayer?
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardHandling()
        
        // Set initial text from team
        teamNameTextField.text = team?.name
        updateSaveButtonState()
        updateColors()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.teamNameTextField.becomeFirstResponder()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient layer frame
        gradientLayer?.frame = view.bounds
        
        // Ensure rounded corners are maintained
        teamNameContainerView.layer.cornerRadius = teamNameContainerView.bounds.height / 2
        saveButton.layer.cornerRadius = saveButton.bounds.height / 2
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Add gradient background
        setupGradientBackground()
        
        // Add subviews
        view.addSubview(navigationBar)
        navigationBar.addSubview(titleLabel)
        navigationBar.addSubview(closeButton)
        
        view.addSubview(teamIconContainerView)
        teamIconContainerView.addSubview(teamIconImageView)
        view.addSubview(editIconButton)
        view.addSubview(teamNameLabel)
        view.addSubview(teamNameContainerView)
        teamNameContainerView.addSubview(teamNameTextField)
        view.addSubview(saveButton)
        saveButton.addSubview(loadingIndicator)
        
        setupConstraints()
    }
    
    private func setupGradientBackground() {
        gradientLayer = CAGradientLayer()
        gradientLayer?.frame = view.bounds
        view.layer.insertSublayer(gradientLayer!, at: 0)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Navigation bar
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44),
            
            // Title label
            titleLabel.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            
            // Close button
            closeButton.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -20),
            closeButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Icon container
            teamIconContainerView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 40),
            teamIconContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            teamIconContainerView.widthAnchor.constraint(equalToConstant: 100),
            teamIconContainerView.heightAnchor.constraint(equalToConstant: 100),
            
            // Team icon
            teamIconImageView.centerXAnchor.constraint(equalTo: teamIconContainerView.centerXAnchor),
            teamIconImageView.centerYAnchor.constraint(equalTo: teamIconContainerView.centerYAnchor),
            teamIconImageView.widthAnchor.constraint(equalToConstant: 50),
            teamIconImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Edit icon button
            editIconButton.bottomAnchor.constraint(equalTo: teamIconContainerView.bottomAnchor, constant: -5),
            editIconButton.trailingAnchor.constraint(equalTo: teamIconContainerView.trailingAnchor, constant: -5),
            editIconButton.widthAnchor.constraint(equalToConstant: 36),
            editIconButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Team name label
            teamNameLabel.topAnchor.constraint(equalTo: teamIconContainerView.bottomAnchor, constant: 40),
            teamNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Team name container (capsule)
            teamNameContainerView.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 12),
            teamNameContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            teamNameContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            teamNameContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            // Team name text field inside container
            teamNameTextField.leadingAnchor.constraint(equalTo: teamNameContainerView.leadingAnchor, constant: 20),
            teamNameTextField.trailingAnchor.constraint(equalTo: teamNameContainerView.trailingAnchor, constant: -20),
            teamNameTextField.centerYAnchor.constraint(equalTo: teamNameContainerView.centerYAnchor),
            teamNameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Save button
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 150),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        editIconButton.addTarget(self, action: #selector(editIconButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        teamNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        teamNameTextField.delegate = self
    }
    
    private func setupKeyboardHandling() {
        // Dismiss keyboard on tap outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - UI Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update gradient background
        gradientLayer?.colors = isDarkMode ? [
            UIColor.secondaryDark.cgColor,
            UIColor.secondaryDark.cgColor
        ] : [
            UIColor.backgroundSecondary.cgColor,
            UIColor.backgroundSecondary.cgColor
        ]
        gradientLayer?.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer?.endPoint = CGPoint(x: 0.5, y: 1)
        
        // Update text colors
        titleLabel.textColor = isDarkMode ? .white : .primaryBlack
        closeButton.tintColor = isDarkMode ? .white : .primaryBlack
        teamIconImageView.tintColor = isDarkMode ? .white : .primaryBlack
        
        // Update team icon container
        teamIconContainerView.backgroundColor = isDarkMode ?
            UIColor(white: 1, alpha: 0.1) :
            UIColor(white: 0, alpha: 0.05)
        
        // Update edit icon button
        editIconButton.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        editIconButton.layer.borderColor = editIconButton.backgroundColor?.cgColor
        
        // Update team name label
        teamNameLabel.textColor = isDarkMode ?
            .white.withAlphaComponent(0.7) :
            .primaryBlack.withAlphaComponent(0.7)
        
        // Update team name container
        teamNameContainerView.backgroundColor = isDarkMode ?
            .tertiaryDark : .tertiaryLight
        teamNameContainerView.layer.borderColor = isDarkMode ?
        UIColor.quaternaryDark as! CGColor : UIColor.quaternaryLight as! CGColor
        
        // Update team name text field
        teamNameTextField.textColor = isDarkMode ? .white : .primaryBlack
        teamNameTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter team name",
            attributes: [.foregroundColor: isDarkMode ?
                UIColor.white.withAlphaComponent(0.5) :
                UIColor.black.withAlphaComponent(0.5)]
        )
        
        // Update save button
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        loadingIndicator.color = .white
        
        // Update save button state
        updateSaveButtonState()
    }
    
    private func updateSaveButtonState() {
        let newName = teamNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let originalName = team?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isEnabled = !newName.isEmpty && newName != originalName && newName.count <= 30
        
        saveButton.isEnabled = isEnabled
        saveButton.alpha = isEnabled ? 1.0 : 0.5
        
        // Visual feedback for container
        if isEnabled {
            teamNameContainerView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.5).cgColor
        } else {
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            teamNameContainerView.layer.borderColor = isDarkMode ?
                UIColor.white.withAlphaComponent(0.2).cgColor :
                UIColor.black.withAlphaComponent(0.2).cgColor
        }
    }
    
    // MARK: - Database Operations
    private func updateTeamNameInDatabase(newName: String) {
        guard let team = team else {
            showError("Team information is missing")
            return
        }
        
        let teamId = team.id
        
        // Show loading
        loadingIndicator.startAnimating()
        saveButton.setTitle("", for: .normal)
        saveButton.isEnabled = false
        
        Task {
            do {
                // Update team in database using a proper Encodable struct
                struct TeamUpdate: Encodable {
                    let name: String
                }
                
                let updateData = TeamUpdate(name: newName)
                
                let response = try await supabase
                    .from("teams")
                    .update(updateData)
                    .eq("id", value: teamId.uuidString)
                    .execute()
                
                print("✅ Team updated successfully")
                
                // Create updated team object
                let updatedTeam = BackendTeam(
                    id: teamId,
                    name: newName,
                    sport_id: team.sport_id,
                    captain_id: team.captain_id,
                    college_id: team.college_id,
                    created_at: team.created_at
                )
                
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.saveButton.setTitle("Saved!", for: .normal)
                    self.saveButton.backgroundColor = .systemGreen
                    
                    // Call the completion handler
                    self.onSave?(updatedTeam)
                    
                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.dismiss(animated: true)
                    }
                }
                
            } catch {
                print("❌ ERROR updating team: \(error)")
                
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.saveButton.setTitle("Save", for: .normal)
                    self.saveButton.isEnabled = true
                    
                    self.showError("Failed to update team name. Please try again.")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func editIconButtonTapped() {
        // Handle edit icon action (e.g., show image picker for team logo)
        print("Edit icon tapped - would show image picker for team logo")
        
        let alert = UIAlertController(
            title: "Change Team Logo",
            message: "Team logo feature coming soon!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let newName = teamNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !newName.isEmpty else {
            showError("Please enter a team name")
            return
        }
        
        // Validate name length
        if newName.count > 30 {
            showError("Team name must be 30 characters or less")
            return
        }
        
        // Check if name is different from current
        guard newName != team?.name else {
            showError("Team name is the same as before")
            return
        }
        
        // Update in database
        updateTeamNameInDatabase(newName: newName)
    }
    
    @objc private func textFieldDidChange() {
        updateSaveButtonState()
        
        // Validate length in real-time
        if let text = teamNameTextField.text, text.count > 30 {
            // Truncate to 30 characters
            teamNameTextField.text = String(text.prefix(30))
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension EditTeamInformationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Limit to 30 characters
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= 30
    }
}

// MARK: - Presentation Helper
extension EditTeamInformationViewController {
    static func present(from viewController: UIViewController, team: BackendTeam, onSave: @escaping (BackendTeam) -> Void) {
        let editVC = EditTeamInformationViewController()
        editVC.team = team
        editVC.onSave = onSave
        
        // Configure as full screen modal
        editVC.modalPresentationStyle = .fullScreen
        
        viewController.present(editVC, animated: true)
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct EditTeamInformationViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EditTeamInformationViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            EditTeamInformationViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct EditTeamInformationViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> EditTeamInformationViewController {
        let viewController = EditTeamInformationViewController()
        viewController.team = BackendTeam(
            id: UUID(),
            name: "All Stars FC",
            sport_id: 1,
            captain_id: UUID(),
            college_id: 1,
            created_at: "2024-01-28T12:00:00Z"
        )
        
        // Set up onSave handler for preview
        viewController.onSave = { updatedTeam in
            print("Team name saved: \(updatedTeam.name ?? "Unknown")")
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: EditTeamInformationViewController, context: Context) {
        // Update the view controller if needed
    }
}
#endif
