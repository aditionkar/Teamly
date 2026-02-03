//
//  CollegeVerificationViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 24/01/26.
//

import UIKit

class CollegeVerificationViewController: UIViewController {
    
    // MARK: - Properties
    var selectedCollege: College?
    var onVerifySuccess: (() -> Void)? // Add this callback
    
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Verify College Id"
        label.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocapitalizationType = .none // ← ADD THIS LINE
        textField.autocorrectionType = .no // ← ALSO ADD THIS TO PREVENT AUTO-CORRECTION
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        return textField
    }()
    
    private let emailTextFieldContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.frame = view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.layer.borderWidth = 0.7
        
        return view
    }()
    
    private let sendOTPButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        var title = AttributedString("Send OTP")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        config.attributedTitle = title
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .primaryWhite
        config.background.cornerRadius = 25
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        // Set initial background color
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
            
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(titleLabel)
        view.addSubview(emailTextFieldContainer)
        emailTextFieldContainer.addSubview(emailTextField)
        view.addSubview(sendOTPButton)
        
        // Set up text field delegate
        emailTextField.delegate = self
    }
    
    private func setupConstraints() {
        // Create a container view to help with vertical centering
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Add elements to container view
        containerView.addSubview(titleLabel)
        containerView.addSubview(emailTextFieldContainer)
        containerView.addSubview(sendOTPButton)
        
        NSLayoutConstraint.activate([
            
            // Top Green Tint
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container View - Positioned higher up
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 180),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Title Label - Positioned at top of container
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Email Text Field Container
            emailTextFieldContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 100),
            emailTextFieldContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            emailTextFieldContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            emailTextFieldContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // Email Text Field
            emailTextField.topAnchor.constraint(equalTo: emailTextFieldContainer.topAnchor),
            emailTextField.leadingAnchor.constraint(equalTo: emailTextFieldContainer.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: emailTextFieldContainer.trailingAnchor),
            emailTextField.bottomAnchor.constraint(equalTo: emailTextFieldContainer.bottomAnchor),
            
            // Send OTP Button
            sendOTPButton.topAnchor.constraint(equalTo: emailTextFieldContainer.bottomAnchor, constant: 50),
            sendOTPButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 120),
            sendOTPButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -120),
            sendOTPButton.heightAnchor.constraint(equalToConstant: 50),
            sendOTPButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupActions() {
        sendOTPButton.addTarget(self, action: #selector(sendOTPTapped), for: .touchUpInside)
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Add text change listener for real-time validation
        emailTextField.addTarget(self, action: #selector(emailTextFieldDidChange), for: .editingChanged)
    }

    @objc private func emailTextFieldDidChange() {
        // Call the delegate method
        if let text = emailTextField.text {
            emailTextField.text = text.lowercased() // Auto lowercase
        }
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update view background
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Update title label color
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update text field placeholder and text color
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "College mail id",
            attributes: [NSAttributedString.Key.foregroundColor: isDarkMode ? UIColor.gray : UIColor.lightGray]
        )
        emailTextField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update text field container colors
        emailTextFieldContainer.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        emailTextFieldContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
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
    @objc private func sendOTPTapped() {
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(message: "Please enter your college email address")
            return
        }
        
        // Validate email format
        if !isValidEmail(email) {
            showAlert(message: "Please enter a valid email address")
            return
        }
        
        // Check if email domain matches selected college
        if let college = selectedCollege {
            let isDomainValid = validateEmailForCollege(email: email, collegeId: college.id)
            if !isDomainValid {
                showAlert(message: "Please enter a valid \(getCollegeDomain(collegeId: college.id)) email address")
                return
            }
        }
        
        print("Sending OTP to: \(email)")
        
        // Navigate to OTP Verification Screen
        let otpVC = CollegeVerificationOTPViewController()
        otpVC.email = email // Pass the email
        
        // Present modally instead of pushing
        otpVC.modalPresentationStyle = .fullScreen
        otpVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        present(otpVC, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - College Email Validation Helpers
    private func validateEmailForCollege(email: String, collegeId: Int) -> Bool {
        let domain = getCollegeDomain(collegeId: collegeId)
        let emailLowercased = email.lowercased()
        
        // Check if email ends with the college domain
        return emailLowercased.hasSuffix(domain)
    }

    private func getCollegeDomain(collegeId: Int) -> String {
        // Map college IDs to their email domains
        switch collegeId {
        case 1: // SRM University
            return "@srmist.edu.in"
        // Add more colleges as needed:
        // case 2: // VIT Chennai
        //     return "@vit.ac.in"
        // case 3: // Anna University
        //     return "@annauniv.edu"
        default:
            // Default to SRM if not specified
            return "@srmist.edu.in"
        }
    }
    
    // MARK: - Helpers
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        // Use system appearance
        alert.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
        
        present(alert, animated: true)
    }
    
    // When verification is successful, call the callback
        private func verificationSuccessful() {
            // Dismiss and notify parent
            dismiss(animated: true) {
                self.onVerifySuccess?()
            }
        }
}

// MARK: - UITextFieldDelegate
// Add this method to your extension
extension CollegeVerificationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendOTPTapped()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // Optional: Real-time validation UI feedback
        if let email = textField.text, !email.isEmpty,
           let college = selectedCollege {
            let isValid = validateEmailForCollege(email: email, collegeId: college.id)
            
            // Change border color based on validation
            if isValid {
                emailTextFieldContainer.layer.borderColor = UIColor.systemGreen.cgColor
            } else {
                let isDarkMode = traitCollection.userInterfaceStyle == .dark
                emailTextFieldContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
            }
        }
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct CollegeVerificationViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CollegeVerificationViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            CollegeVerificationViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct CollegeVerificationViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CollegeVerificationViewController {
        return CollegeVerificationViewController()
    }
    
    func updateUIViewController(_ uiViewController: CollegeVerificationViewController, context: Context) {
        // No update needed
    }
}
#endif
