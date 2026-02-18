//
//  CollegeVerificationOTPViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 25/01/26.
//

import UIKit
import Supabase

class CollegeVerificationOTPViewController: UIViewController {
    
    // MARK: - Properties
    var email: String = ""
    var selectedCollege: College? // Add this property to receive the college
    
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
        label.text = "Enter OTP"
        label.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Add email display field container
    private let emailDisplayField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField.textAlignment = .center
        textField.isUserInteractionEnabled = false // Make it non-editable
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = paddingView
        textField.rightViewMode = .always
        
        return textField
    }()
    
    private let emailDisplayFieldContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        view.frame = view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.layer.borderWidth = 0.7
        
        return view
    }()
    
    private let otpStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let verifyButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        var title = AttributedString("Verify")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        config.attributedTitle = title
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .primaryWhite
        config.background.cornerRadius = 25
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let resendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Resend OTP", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var otpTextFields: [UITextField] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupOTPFields()
        updateColors()
        
        // Set the email in the display field
        emailDisplayField.text = email
        
        // Auto-focus first OTP field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.otpTextFields.first?.becomeFirstResponder()
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
            updateOTPFieldsColors()
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Setup
    private func setupUI() {
        // Set initial background color
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .primaryBlack : .primaryWhite
            
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        view.addSubview(titleLabel)
        view.addSubview(emailDisplayFieldContainer)
        emailDisplayFieldContainer.addSubview(emailDisplayField)
        view.addSubview(otpStackView)
        view.addSubview(verifyButton)
        view.addSubview(resendButton)
    }
    
    private func setupConstraints() {
        // Create a container view to help with vertical centering
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Add elements to container view
        containerView.addSubview(titleLabel)
        containerView.addSubview(emailDisplayFieldContainer)
        containerView.addSubview(otpStackView)
        containerView.addSubview(verifyButton)
        containerView.addSubview(resendButton)
        
        NSLayoutConstraint.activate([
            // Top Green Tint
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container View - Positioned higher up
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Title Label - Positioned at top of container
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Email Display Field Container - Below title
            emailDisplayFieldContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 100),
            emailDisplayFieldContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            emailDisplayFieldContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            emailDisplayFieldContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // Email Display Field
            emailDisplayField.topAnchor.constraint(equalTo: emailDisplayFieldContainer.topAnchor),
            emailDisplayField.leadingAnchor.constraint(equalTo: emailDisplayFieldContainer.leadingAnchor),
            emailDisplayField.trailingAnchor.constraint(equalTo: emailDisplayFieldContainer.trailingAnchor),
            emailDisplayField.bottomAnchor.constraint(equalTo: emailDisplayFieldContainer.bottomAnchor),
            
            // OTP Stack View - Below email field
            otpStackView.topAnchor.constraint(equalTo: emailDisplayFieldContainer.bottomAnchor, constant: 30),
            otpStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            otpStackView.heightAnchor.constraint(equalToConstant: 50),
            
            // Verify Button - Below OTP
            verifyButton.topAnchor.constraint(equalTo: otpStackView.bottomAnchor, constant: 50),
            verifyButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 120),
            verifyButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -120),
            verifyButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Resend Button - Below verify button
            resendButton.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 20),
            resendButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            resendButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupOTPFields() {
        for i in 0..<4 {
            let textField = UITextField()
            textField.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            textField.textAlignment = .center
            textField.layer.cornerRadius = 12
            textField.clipsToBounds = true
            textField.keyboardType = .numberPad
            textField.delegate = self
            textField.tag = i
            
            // Add border
            textField.layer.borderWidth = 0.7
            
            otpStackView.addArrangedSubview(textField)
            otpTextFields.append(textField)
            
            NSLayoutConstraint.activate([
                textField.widthAnchor.constraint(equalToConstant: 50),
                textField.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
        updateOTPFieldsColors()
    }
    
    private func updateOTPFieldsColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        for textField in otpTextFields {
            textField.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
            textField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
            textField.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        }
    }
    
    private func setupActions() {
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update view background
        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite
        
        // Update title label color
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update email display field colors
        emailDisplayField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        emailDisplayFieldContainer.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        emailDisplayFieldContainer.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        
        // Update resend button color
        let resendTitleColor = isDarkMode ? UIColor.systemGreen : UIColor.systemGreenDark
        resendButton.setTitleColor(resendTitleColor, for: .normal)
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
    
    // MARK: - College ID Saving Function
    private func saveCollegeId(_ collegeId: Int) {
        // Show loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        
        Task {
            do {
                // Get the current user's session
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id
                
                print("📝 Saving college ID \(collegeId) for user: \(userId)")
                
                // Update the user's profile with the college ID
                try await SupabaseManager.shared.client
                    .from("profiles")
                    .update(["college_id": collegeId])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    
                    print("✅ College ID saved successfully!")
                    
                    // Show success message
                    let alert = UIAlertController(
                        title: "Success",
                        message: "College verified and saved successfully!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        // Navigate to tab bar controller after success
                        self.navigateToTabBarController()
                    })
                    self.present(alert, animated: true)
                }
                
            } catch {
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    
                    print("❌ Error saving college ID: \(error.localizedDescription)")
                    
                    // Show error alert with retry option
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to save college. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                        self.saveCollegeId(collegeId)
                    })
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func verifyTapped() {
        let otp = otpTextFields.map { $0.text ?? "" }.joined()
        
        // Changed to 4-digit OTP validation
        guard otp.count == 4 else {
            showAlert(message: "Please enter the complete 4-digit OTP")
            return
        }
        
        // Check if college is selected
        guard let college = selectedCollege else {
            showAlert(message: "College information missing")
            return
        }
        
        print("🔐 Verifying OTP: \(otp) for email: \(email)")
        print("🏫 College: \(college.name) (ID: \(college.id))")
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Verifying OTP...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // Handle actual OTP verification API call here
        verifyOTP(otp: otp, college: college, loadingAlert: loadingAlert)
    }

    private func verifyOTP(otp: String, college: College, loadingAlert: UIAlertController) {
        Task {
            do {
                print("📤 Sending verification request...")
                print("🔍 Request details:")
                print("  - Function: verify-college-otp")
                print("  - Body: [\"email\": \"\(email)\", \"otp\": \"\(otp)\"]")
                
                let response = try await SupabaseManager.shared.client.functions.invoke(
                    "verify-college-otp",
                    options: FunctionInvokeOptions(
                        body: [
                            "email": email,
                            "otp": otp
                        ]
                    )
                )
                
                // Dismiss loading indicator
                await MainActor.run {
                    loadingAlert.dismiss(animated: true)
                }
                
                print("✅ OTP verification successful!")
                print("📦 Response: \(response)")
                
                // Check if response contains any data
                if let responseData = response as? [String: Any] {
                    print("Response data: \(responseData)")
                }

                // Save the college ID to the user's profile
                await MainActor.run {
                    self.saveCollegeId(college.id)
                }

            } catch {
                // Dismiss loading indicator
                await MainActor.run {
                    loadingAlert.dismiss(animated: true)
                }
                
                // Log detailed error information
                print("❌ OTP verification failed")
                print("Error type: \(type(of: error))")
                print("Error description: \(error.localizedDescription)")
                
                // Try to cast to NSError for more details
                if let nsError = error as NSError? {
                    print("NSError details:")
                    print("  - Domain: \(nsError.domain)")
                    print("  - Code: \(nsError.code)")
                    print("  - UserInfo: \(nsError.userInfo)")
                    
                    // Check for network errors
                    if nsError.domain == NSURLErrorDomain {
                        switch nsError.code {
                        case NSURLErrorNotConnectedToInternet:
                            await MainActor.run {
                                showAlert(message: "No internet connection. Please check your network and try again.")
                            }
                            return
                        case NSURLErrorTimedOut:
                            await MainActor.run {
                                showAlert(message: "Request timed out. Please try again.")
                            }
                            return
                        default:
                            break
                        }
                    }
                }
                
                // Try to decode error response if it's data
                if let errorData = error as? Data {
                    do {
                        if let jsonError = try JSONSerialization.jsonObject(with: errorData) as? [String: Any] {
                            print("📄 Error response JSON: \(jsonError)")
                            
                            if let errorMessage = jsonError["message"] as? String {
                                await MainActor.run {
                                    showAlert(message: errorMessage)
                                }
                                return
                            }
                        }
                    } catch {
                        print("Could not parse error data: \(error)")
                    }
                }
                
                await MainActor.run {
                    showAlert(message: "Invalid or expired OTP")
                    otpTextFields.forEach { $0.text = "" }
                    otpTextFields.first?.becomeFirstResponder()
                }
            }
        }
    }

    private func navigateToTabBarController() {
        let tabBarController = TabBarController()
        
        // Get the current interface style
        let currentStyle = self.traitCollection.userInterfaceStyle
        
        // Apply to tab bar controller
        tabBarController.overrideUserInterfaceStyle = currentStyle
        
        // Get the window from the current scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            // Apply style to window
            window.overrideUserInterfaceStyle = currentStyle
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = tabBarController
            }, completion: nil)
        }
    }
    
    @objc private func resendTapped() {
        print("🔄 Resend OTP requested for email: \(email)")
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Resending OTP...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        Task {
            do {
                print("📤 Sending resend OTP request...")
                print("🔍 Request details:")
                print("  - Function: send-college-otp")
                print("  - Body: [\"email\": \"\(email)\"]")
                
                let response = try await SupabaseManager.shared.client.functions.invoke(
                    "send-college-otp",
                    options: FunctionInvokeOptions(
                        body: [
                            "email": email
                        ]
                    )
                )
                
                // Dismiss loading indicator
                await MainActor.run {
                    loadingAlert.dismiss(animated: true)
                }
                
                print("✅ OTP resent successfully!")
                print("📦 Response: \(response)")

                await MainActor.run {
                    otpTextFields.forEach { $0.text = "" }
                    otpTextFields.first?.becomeFirstResponder()
                    showAlert(message: "OTP resent to \(email)")
                }

            } catch {
                // Dismiss loading indicator
                await MainActor.run {
                    loadingAlert.dismiss(animated: true)
                }
                
                print("❌ Failed to resend OTP")
                print("Error type: \(type(of: error))")
                print("Error description: \(error.localizedDescription)")
                
                if let nsError = error as NSError? {
                    print("NSError details:")
                    print("  - Domain: \(nsError.domain)")
                    print("  - Code: \(nsError.code)")
                    print("  - UserInfo: \(nsError.userInfo)")
                }
                
                await MainActor.run {
                    showAlert(message: "Failed to resend OTP. Please try again.")
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Use system appearance
        alert.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
        
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension CollegeVerificationOTPViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow only numbers and limit to 1 character per field
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        
        guard allowedCharacters.isSuperset(of: characterSet) else {
            return false
        }
        
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        if updatedText.count <= 1 {
            textField.text = updatedText
            
            // Auto-focus to next field
            if updatedText.count == 1 {
                let nextTag = textField.tag + 1
                if let nextTextField = otpTextFields.first(where: { $0.tag == nextTag }) {
                    nextTextField.becomeFirstResponder()
                } else {
                    // Last field, dismiss keyboard
                    textField.resignFirstResponder()
                }
            }
            
            return false
        }
        
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Highlight the active field
        textField.layer.borderColor = UIColor.systemGreen.cgColor
        textField.layer.borderWidth = 0.6
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Remove highlight
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        textField.layer.borderColor = (isDarkMode ? UIColor.tertiaryDark : UIColor.tertiaryLight.withAlphaComponent(0.5)).cgColor
        textField.layer.borderWidth = 0.7
    }
}
