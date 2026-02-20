//
//  EditProfileViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 19/02/26.
//

import UIKit
import Supabase

// MARK: - Edit Profile Row
private struct EditProfileRow {
    let title: String
    let action: () -> Void
}

// MARK: - Edit Profile View Controller
class EditProfileViewController: UIViewController {

    // MARK: - Callback
    /// Called when the user finishes editing so ProfileViewController can refresh
    var onProfileUpdated: (() -> Void)?

    // MARK: - Data passed in from ProfileViewController
    var currentAvatarImage: UIImage?
    var currentName: String?
    var currentGender: String?
    // Add with other properties
    var currentAge: Int?
    var currentUserId: UUID?

    // MARK: - UI Components

    // Avatar
    private lazy var avatarButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set default person.fill image WITHOUT any tint configuration
        let config = UIImage.SymbolConfiguration(pointSize: 36)
        if let image = UIImage(systemName: "person.fill", withConfiguration: config) {
            button.setImage(image, for: .normal)
        }
        
        button.layer.cornerRadius = 55
        button.clipsToBounds = true
        button.isUserInteractionEnabled = false
        button.layer.borderWidth = 1.0
        button.imageView?.contentMode = .scaleAspectFill
        
        // Set the tint color directly on the button
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        button.tintColor = isDarkMode ? .quaternaryLight : .quaternaryDark
        
        return button
    }()

    private let editAvatarButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Edit", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.systemGreen, for: .normal)
        return button
    }()

    // Options container
    private let optionsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        return view
    }()

    private let optionsStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 0
        sv.distribution = .fill
        return sv
    }()

    // Loading indicator for avatar upload
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Row definitions (lazy so self is available)
    private lazy var rows: [EditProfileRow] = [
        EditProfileRow(title: "Edit Name")      { [weak self] in self?.handleEditName() },
        EditProfileRow(title: "Edit Age")       { [weak self] in self?.handleEditAge() },
        EditProfileRow(title: "Add Sport")      { [weak self] in self?.handleAddSport() },
        EditProfileRow(title: "Update Skill level") { [weak self] in self?.handleUpdateSkillLevel() }
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateColors()
        configureAvatar()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(avatarButton)
        view.addSubview(editAvatarButton)
        view.addSubview(optionsContainer)
        view.addSubview(loadingIndicator)
        optionsContainer.addSubview(optionsStackView)

        buildOptionRows()
        setupConstraints()

        editAvatarButton.addTarget(self, action: #selector(editAvatarTapped), for: .touchUpInside)
    }

    private func configureAvatar() {
        if let img = currentAvatarImage {
            avatarButton.setImage(img, for: .normal)
            avatarButton.imageView?.contentMode = .scaleAspectFill
            avatarButton.tintColor = .clear
        }
    }

    private func buildOptionRows() {
        for (index, row) in rows.enumerated() {
            let rowView = makeRowView(title: row.title, tag: index)
            optionsStackView.addArrangedSubview(rowView)

            // Add divider between rows (not after the last one)
            if index < rows.count - 1 {
                let divider = makeDivider()
                optionsStackView.addArrangedSubview(divider)
            }
        }
    }

    private func makeRowView(title: String, tag: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.tag = tag

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)

        let chevron = UIImageView()
        chevron.translatesAutoresizingMaskIntoConstraints = false
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevron.contentMode = .scaleAspectFit

        container.addSubview(label)
        container.addSubview(chevron)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 54),

            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

            chevron.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            chevron.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 14)
        ])

        // Tap recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:)))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true

        return container
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return divider
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Avatar — centered, below the grabber
            avatarButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 36),
            avatarButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarButton.widthAnchor.constraint(equalToConstant: 110),
            avatarButton.heightAnchor.constraint(equalToConstant: 110),

            // "Edit" text under avatar
            editAvatarButton.topAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 10),
            editAvatarButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: avatarButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: avatarButton.centerYAnchor),

            // Options container
            optionsContainer.topAnchor.constraint(equalTo: editAvatarButton.bottomAnchor, constant: 32),
            optionsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Options stack view fills the container
            optionsStackView.topAnchor.constraint(equalTo: optionsContainer.topAnchor),
            optionsStackView.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
            optionsStackView.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            optionsStackView.bottomAnchor.constraint(equalTo: optionsContainer.bottomAnchor)
        ])
    }

    // MARK: - Color Updates
    private func updateColors() {
        let isDark = traitCollection.userInterfaceStyle == .dark

        view.backgroundColor = isDark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)   // ~systemBackground dark
            : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)   // ~systemGroupedBackground light

        // Update avatar button colors
        avatarButton.backgroundColor = isDark ? .secondaryDark : .secondaryLight
        avatarButton.layer.borderColor = (isDark ? UIColor.tertiaryDark.withAlphaComponent(0.5) : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        
        avatarButton.tintColor = isDark ? .quaternaryLight : .quaternaryDark

        // Options container background
        optionsContainer.backgroundColor = isDark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
            : UIColor.white

        // Row labels & chevrons
        for subview in optionsStackView.arrangedSubviews {
            // Row containers have a tag >= 0 (set in makeRowView)
            if subview.tag >= 0, let label = subview.subviews.first(where: { $0 is UILabel }) as? UILabel {
                label.textColor = isDark ? .primaryWhite : .primaryBlack
            }
            if let chevron = subview.subviews.first(where: { $0 is UIImageView }) as? UIImageView {
                chevron.tintColor = isDark
                    ? UIColor(white: 1, alpha: 0.3)
                    : UIColor(white: 0, alpha: 0.3)
            }
            // Dividers
            if subview.subviews.isEmpty {
                subview.backgroundColor = isDark
                    ? UIColor(white: 1, alpha: 0.1)
                    : UIColor(white: 0, alpha: 0.1)
            }
        }
    }

    // MARK: - Actions
    @objc private func rowTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag, tag < rows.count else { return }

        // Brief highlight feedback
        UIView.animate(withDuration: 0.08, animations: {
            gesture.view?.alpha = 0.5
        }, completion: { _ in
            UIView.animate(withDuration: 0.08) {
                gesture.view?.alpha = 1
            }
        })

        rows[tag].action()
    }

    @objc private func editAvatarTapped() {
        let alert = UIAlertController(title: "Change Profile Picture", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.openCamera()
        })
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.openPhotoLibrary()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(message: "Camera is not available on this device")
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Avatar Upload
    private func uploadAvatarImage(_ image: UIImage) {
        guard let userIdUUID = currentUserId else {
            print("❌ No user ID available")
            showAlert(message: "User ID not found. Please try again.")
            return
        }

        // Show loading state
        loadingIndicator.startAnimating()
        avatarButton.alpha = 0.5
        editAvatarButton.isEnabled = false

        // Resize image to reduce file size
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 800, height: 800))

        Task {
            do {
                print("🔄 Starting profile picture upload for user: \(userIdUUID)")
                
                // Upload profile picture using ProfileManager
                let _ = try await ProfileManager.shared.uploadProfilePicture(
                    userId: userIdUUID,
                    image: resizedImage
                )
                
                // Update UI on success
                await MainActor.run {
                    self.avatarButton.setImage(resizedImage, for: .normal)
                    self.avatarButton.imageView?.contentMode = .scaleAspectFill
                    self.avatarButton.tintColor = .clear
                    
                    self.loadingIndicator.stopAnimating()
                    self.avatarButton.alpha = 1.0
                    self.editAvatarButton.isEnabled = true
                    
                    // Notify ProfileViewController to refresh
                    self.onProfileUpdated?()
                    
                    print("✅ Profile picture updated successfully")
                }
                
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.avatarButton.alpha = 1.0
                    self.editAvatarButton.isEnabled = true
                    
                    print("❌ Error uploading profile picture: \(error.localizedDescription)")
                    self.showUploadErrorAlert(error: error)
                }
            }
        }
    }

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }

    private func showUploadErrorAlert(error: Error) {
        let alert = UIAlertController(
            title: "Upload Failed",
            message: "Failed to upload profile picture. Would you like to try again?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
            if let currentImage = self?.avatarButton.image(for: .normal) {
                self?.uploadAvatarImage(currentImage)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }

    // MARK: - Row Handlers (wire up to your real VCs)
    private func handleEditName() {
        let editNameVC = EditNameViewController()
        editNameVC.currentName = currentName
        //editNameVC.currentGender = currentGender
        editNameVC.onNameUpdated = { [weak self] in
            self?.onProfileUpdated?()
        }

        if let nav = navigationController {
            nav.pushViewController(editNameVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: editNameVC)
            nav.setNavigationBarHidden(true, animated: false)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    private func handleEditAge() {
        let editAgeVC = EditAgeViewController()
        editAgeVC.currentAge = currentAge
        editAgeVC.onAgeUpdated = { [weak self] in
            self?.onProfileUpdated?()
        }

        if let nav = navigationController {
            nav.pushViewController(editAgeVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: editAgeVC)
            nav.setNavigationBarHidden(true, animated: false)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    // Add property
    var existingSportIds: [Int] = []

    private func handleAddSport() {
        let addSportVC = AddNewSportViewController()
        addSportVC.existingSportIds = existingSportIds
        addSportVC.onSportsUpdated = { [weak self] in
            self?.onProfileUpdated?()
        }

        if let nav = navigationController {
            nav.pushViewController(addSportVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: addSportVC)
            nav.setNavigationBarHidden(true, animated: false)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    var currentSports: [SportWithSkill] = []
    
    private func handleUpdateSkillLevel() {
        let updateSkillVC = UpdateSkillViewController(sports: currentSports)
        updateSkillVC.onSkillUpdated = { [weak self] in
            self?.onProfileUpdated?()
        }

        if let nav = navigationController {
            nav.pushViewController(updateSkillVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: updateSkillVC)
            nav.setNavigationBarHidden(true, animated: false)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        let chosenImage = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        guard let image = chosenImage else { return }

        // Upload the image
        uploadAvatarImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
