//
//  AvatarSelectionViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 24/01/26.
//

import UIKit
import PhotosUI
import Auth
import Supabase

// MARK: - Avatar Selection View Controller
class AvatarSelectionViewController: UIViewController,
                                     UIImagePickerControllerDelegate,
                                     UINavigationControllerDelegate,
                                     PHPickerViewControllerDelegate {

    // MARK: - UI Elements
    private let topGreenTint: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let gradientLayer = CAGradientLayer()

    private let progressView: UIProgressView = {
        let pv = UIProgressView()
        pv.progress = 1.0
        pv.progressTintColor = .systemGreen
        pv.layer.cornerRadius = 3
        pv.clipsToBounds = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add a profile pic"
        label.font = .systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let avatarContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 35
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()


    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = false // 👈 IMPORTANT
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()



    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        let arrow = UIImage(systemName: "chevron.down")
        button.setImage(arrow, for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let skipButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        var title = AttributedString("Skip")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        config.attributedTitle = title
        config.background.cornerRadius = 25
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

   
    // MARK: - State
    private var selectedAvatar: UIImage?
    private var personSizeConstraints: [NSLayoutConstraint] = []
    private var fillConstraints: [NSLayoutConstraint] = []   // ✅ ADD THIS



    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        updateColors()

        showDefaultPersonIcon()

    }
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // Update colors when view appears to ensure correct mode
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
        view.addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(selectButton)
        view.addSubview(skipButton)
        view.addSubview(nextButton)
    }
    private func showDefaultPersonIcon() {
        avatarImageView.image = UIImage(systemName: "person.fill")
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.clipsToBounds = false
        avatarImageView.tintColor = traitCollection.userInterfaceStyle == .dark
            ? .quaternaryLight
            : .quaternaryDark

        NSLayoutConstraint.deactivate(fillConstraints)
        NSLayoutConstraint.deactivate(personSizeConstraints)

        personSizeConstraints = [
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor, constant: 40)
        ]

        NSLayoutConstraint.activate(personSizeConstraints)
    }

    private func showUploadedImage(_ image: UIImage) {
        avatarImageView.image = image
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.tintColor = .clear

        NSLayoutConstraint.deactivate(personSizeConstraints)
        NSLayoutConstraint.deactivate(fillConstraints)

        fillConstraints = [
            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor)
        ]

        NSLayoutConstraint.activate(fillConstraints)
    }



    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Top Green Tint
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -30),

            // Progress View
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            progressView.heightAnchor.constraint(equalToConstant: 7),

            // Title
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Avatar Container
            avatarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            avatarContainer.widthAnchor.constraint(equalToConstant: 200),
            avatarContainer.heightAnchor.constraint(equalToConstant: 200),

//            // Avatar Image (FULL FILL ✅)
//            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
//            avatarImageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
//            avatarImageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
//            avatarImageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),

            // Select Button
            selectButton.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            selectButton.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: -30),

            // Next Button
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 50),

            // Skip Button
            skipButton.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -16),
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.widthAnchor.constraint(equalToConstant: 120),
            skipButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }


    // MARK: - Colors
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        // Background
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite

        // Progress track
        progressView.trackTintColor = isDarkMode
            ? UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            : UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

        // Title
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack

        // Avatar container
        avatarContainer.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight

        // Avatar icon
        avatarImageView.tintColor = isDarkMode ? .quaternaryLight : .quaternaryDark

        // Select button
        selectButton.setTitleColor(isDarkMode ? .primaryWhite : .primaryBlack, for: .normal)
        selectButton.tintColor = isDarkMode ? .primaryWhite : .primaryBlack

        // Skip button
        skipButton.configuration?.baseBackgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        skipButton.configuration?.baseForegroundColor = isDarkMode ? .primaryWhite : .primaryBlack

        // Next button (always green)
        nextButton.configuration?.baseBackgroundColor = .systemGreen
        nextButton.configuration?.baseForegroundColor = .primaryWhite
    }


    private func updateGradientColors() {
        let dark = traitCollection.userInterfaceStyle == .dark
        gradientLayer.colors = dark
            ? [UIColor(red: 0, green: 0.15, blue: 0, alpha: 1).cgColor, UIColor.clear.cgColor]
            : [UIColor(red: 53/255, green: 199/255, blue: 89/255, alpha: 0.3).cgColor, UIColor.clear.cgColor]
        gradientLayer.locations = [0, 0.25]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }
    
    // MARK: - Actions
    private func setupActions() {
        selectButton.addTarget(self, action: #selector(selectTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(selectTapped))
        avatarContainer.addGestureRecognizer(avatarTap)

    }

    @objc private func selectTapped() {
        let modal = AvatarOptionModalViewController()
        modal.onOptionSelected = { [weak self] option in
            self?.handleAvatarOption(option)
        }

        if let sheet = modal.sheetPresentationController {
            sheet.detents = [.custom { _ in 240 }]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }

        present(modal, animated: true)
    }

    @objc private func nextTapped() {
            guard let selectedAvatar = selectedAvatar else {
                // No image selected, just navigate
                navigateToNextScreen()
                return
            }
            
            // Show loading indicator
            let loadingIndicator = UIActivityIndicatorView(style: .medium)
            loadingIndicator.center = view.center
            loadingIndicator.startAnimating()
            view.addSubview(loadingIndicator)
            nextButton.isEnabled = false
            skipButton.isEnabled = false
            
            Task {
                do {
                    // Get current user session
                    let session = try await SupabaseManager.shared.client.auth.session
                    let userId = session.user.id
                    
                    print("🔄 Starting profile picture upload for user: \(userId)")
                    
                    // Upload profile picture
                    let _ = try await ProfileManager.shared.uploadProfilePicture(
                        userId: userId,
                        image: selectedAvatar
                    )
                    
                    // Success - navigate to next screen
                    await MainActor.run {
                        loadingIndicator.removeFromSuperview()
                        self.navigateToNextScreen()
                    }
                    
                } catch {
                    await MainActor.run {
                        loadingIndicator.removeFromSuperview()
                        self.nextButton.isEnabled = true
                        self.skipButton.isEnabled = true
                        
                        print("❌ Error uploading profile picture: \(error.localizedDescription)")
                        
                        // Show error alert with retry option
                        self.showUploadErrorAlert(error: error)
                    }
                }
            }
        }
        
        @objc private func skipTapped() {
            navigateToNextScreen()
        }
    
    private func handleAvatarOption(_ option: AvatarOption) {
        DispatchQueue.main.async {
            switch option {
            case .takePhoto:
                self.openCamera()
            case .choosePhoto:
                self.openGallery()
            }
        }
    }
        
        // MARK: - Navigation
        private func navigateToNextScreen() {
            let vc = SearchingCommunitiesViewController()
            
            if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                nav.setNavigationBarHidden(true, animated: false)
                present(nav, animated: true)
            }
        }
    
    // MARK: - Error Handling
        private func showUploadErrorAlert(error: Error) {
            let alert = UIAlertController(
                title: "Upload Failed",
                message: "Failed to upload profile picture. Would you like to try again or skip?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
                self.nextTapped()
            })
            
            alert.addAction(UIAlertAction(title: "Skip for Now", style: .default) { _ in
                self.navigateToNextScreen()
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(alert, animated: true)
        }
    
    // MARK: - Camera / Gallery
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            openGallery() // fallback
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openGallery() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true) {
                if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
                    // Resize image to reduce file size
                    let resizedImage = self.resizeImage(image: image, targetSize: CGSize(width: 800, height: 800))
                    
                    self.showUploadedImage(resizedImage)
                    self.selectedAvatar = resizedImage
                    
                    // Enable next button when image is selected
                    self.nextButton.isEnabled = true
                    self.nextButton.configuration?.baseBackgroundColor = .systemGreen
                }
            }
        }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    guard let self = self, let image = image as? UIImage else { return }
                    
                    // Resize image to reduce file size
                    let resizedImage = self.resizeImage(image: image, targetSize: CGSize(width: 800, height: 800))
                    
                    self.avatarImageView.tintColor = .clear
                    self.showUploadedImage(resizedImage)
                    self.selectedAvatar = resizedImage
                    
                    // Enable next button when image is selected
                    self.nextButton.isEnabled = true
                    self.nextButton.configuration?.baseBackgroundColor = .systemGreen
                }
            }
        }
    
    // MARK: - Helper Methods
        private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
            let size = image.size
            
            let widthRatio  = targetSize.width  / size.width
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
}

// MARK: - Avatar Option Modal View Controller (FULL UI RESTORED)
class AvatarOptionModalViewController: UIViewController {

    var onOptionSelected: ((AvatarOption) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add profile picture"
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let optionsContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let takePhotoButton = AvatarOptionModalViewController.makeButton(
        title: "Take photo",
        icon: "camera"
    )

    private let choosePhotoButton = AvatarOptionModalViewController.makeButton(
        title: "Choose photo",
        icon: "photo"
    )

    private let separatorLine: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        updateColors()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(optionsContainer)
        optionsContainer.addSubview(takePhotoButton)
        optionsContainer.addSubview(separatorLine)
        optionsContainer.addSubview(choosePhotoButton)

        preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 240)
    }


    
    private func updateColors() {
        let presentingStyle = presentingViewController?.traitCollection.userInterfaceStyle
            ?? traitCollection.userInterfaceStyle

        let isDarkMode = presentingStyle == .dark

        // Modal background
        view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight

        // Title
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack

        // Options container
        optionsContainer.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight

        // Buttons
        takePhotoButton.configuration?.baseForegroundColor = isDarkMode ? .primaryWhite : .primaryBlack
        choosePhotoButton.configuration?.baseForegroundColor = isDarkMode ? .primaryWhite : .primaryBlack

        // Separator
        separatorLine.backgroundColor = isDarkMode
            ? UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
            : UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    }


    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            optionsContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            optionsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            optionsContainer.heightAnchor.constraint(equalToConstant: 112),

            takePhotoButton.topAnchor.constraint(equalTo: optionsContainer.topAnchor),
            takePhotoButton.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
            takePhotoButton.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            takePhotoButton.heightAnchor.constraint(equalToConstant: 56),

            separatorLine.topAnchor.constraint(equalTo: takePhotoButton.bottomAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor, constant: 20),
            separatorLine.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor, constant: -20),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),

            choosePhotoButton.topAnchor.constraint(equalTo: separatorLine.bottomAnchor),
            choosePhotoButton.leadingAnchor.constraint(equalTo: optionsContainer.leadingAnchor),
            choosePhotoButton.trailingAnchor.constraint(equalTo: optionsContainer.trailingAnchor),
            choosePhotoButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func setupActions() {
        takePhotoButton.addTarget(self, action: #selector(takePhotoTapped), for: .touchUpInside)
        choosePhotoButton.addTarget(self, action: #selector(choosePhotoTapped), for: .touchUpInside)
    }

    @objc private func takePhotoTapped() {
        dismiss(animated: true) {
            self.onOptionSelected?(.takePhoto)
        }
    }

    @objc private func choosePhotoTapped() {
        dismiss(animated: true) {
            self.onOptionSelected?(.choosePhoto)
        }
    }


    private static func makeButton(title: String, icon: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        button.configuration = config
        button.contentHorizontalAlignment = .fill
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        return button
    }
}

// MARK: - Enum
enum AvatarOption {
    case takePhoto
    case choosePhoto
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct AvatarSelectionViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AvatarSelectionViewControllerRepresentable()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .previewDisplayName("Dark Mode")
            
            AvatarSelectionViewControllerRepresentable()
                .preferredColorScheme(.light)
                .ignoresSafeArea()
                .previewDisplayName("Light Mode")
        }
    }
}

struct AvatarSelectionViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AvatarSelectionViewController {
        return AvatarSelectionViewController()
    }
    
    func updateUIViewController(_ uiViewController: AvatarSelectionViewController, context: Context) {
        // No update needed
    }
}
#endif
