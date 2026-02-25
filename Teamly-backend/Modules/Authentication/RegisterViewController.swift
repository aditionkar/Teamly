//
//  RegisterViewController.swift
//  Teamly-backend
//
//  Created by user@37 on 22/01/26.
//

import UIKit

class RegisterViewController: UIViewController {
    
    var onRegisterSuccess: (() -> Void)?
    var onLogin: (() -> Void)?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let confirmPasswordTextField = UITextField()
    private let signUpButton = UIButton(type: .system)
    private let loginLabel = UILabel()
    private let loginButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateColors()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Set initial background color based on current mode
        updateColors()
        
        setupScrollView()
        setupContentView()
        setupTitleLabel()
        setupEmailTextField()
        setupPasswordTextField()
        setupConfirmPasswordTextField()
        setupSignUpButton()
        setupLoginSection()
    }
    
    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
    }
    
    private func setupContentView() {
        scrollView.addSubview(contentView)
    }
    
    private func setupTitleLabel() {
        titleLabel.text = "Sign Up"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
    }
    
    private func setupEmailTextField() {
        emailTextField.placeholder = "Email"
        emailTextField.textColor = traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack
        emailTextField.tintColor = .systemGreen
        emailTextField.layer.cornerRadius = 25
        emailTextField.layer.borderWidth = 0.7
        emailTextField.layer.masksToBounds = true
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        
        // Set placeholder attributes
        updateTextFieldPlaceholders()
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        emailTextField.leftView = paddingView
        emailTextField.leftViewMode = .always
        
        contentView.addSubview(emailTextField)
    }
    
    private func setupPasswordTextField() {
        passwordTextField.placeholder = "Password"
        passwordTextField.textColor = traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack
        passwordTextField.tintColor = .systemGreen
        passwordTextField.layer.cornerRadius = 25
        passwordTextField.layer.borderWidth = 0.7
        passwordTextField.layer.masksToBounds = true
        passwordTextField.isSecureTextEntry = true
        
        // Set placeholder attributes
        updateTextFieldPlaceholders()
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        passwordTextField.leftView = paddingView
        passwordTextField.leftViewMode = .always
        
        contentView.addSubview(passwordTextField)
    }
    
    private func setupConfirmPasswordTextField() {
        confirmPasswordTextField.placeholder = "Confirm Password"
        confirmPasswordTextField.textColor = traitCollection.userInterfaceStyle == .dark ? .primaryWhite : .primaryBlack
        confirmPasswordTextField.tintColor = .systemGreen
        confirmPasswordTextField.layer.cornerRadius = 25
        confirmPasswordTextField.layer.borderWidth = 0.7
        confirmPasswordTextField.layer.masksToBounds = true
        confirmPasswordTextField.isSecureTextEntry = true
        
        // Set placeholder attributes
        updateTextFieldPlaceholders()
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        confirmPasswordTextField.leftView = paddingView
        confirmPasswordTextField.leftViewMode = .always
        
        contentView.addSubview(confirmPasswordTextField)
    }
    
    private func setupSignUpButton() {
        signUpButton.setTitle("SIGN UP", for: .normal)
        signUpButton.backgroundColor = .systemGreen
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        signUpButton.layer.cornerRadius = 25
        signUpButton.layer.masksToBounds = true
        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        contentView.addSubview(signUpButton)
    }
    
    private func setupLoginSection() {
        loginLabel.text = "Already a member? "
        loginLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        contentView.addSubview(loginLabel)
        
        loginButton.setTitle("Login", for: .normal)
        loginButton.setTitleColor(.systemGreen, for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        contentView.addSubview(loginButton)
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll View - Fill the entire view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View - Width matches scroll view, height depends on content
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            // Email Text Field
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Password Text Field
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Confirm Password Text Field
            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Sign Up Button
            signUpButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 30),
            signUpButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            signUpButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            signUpButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Login section
            loginLabel.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 30),
            loginLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -38),
            loginLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            loginButton.centerYAnchor.constraint(equalTo: loginLabel.centerYAnchor),
            loginButton.leadingAnchor.constraint(equalTo: loginLabel.trailingAnchor, constant: 0),
            loginButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Update view background
        view.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        contentView.backgroundColor = isDarkMode ? .secondaryDark : .secondaryLight
        
        // Update title label color
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        // Update text fields
        emailTextField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        passwordTextField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        confirmPasswordTextField.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        
        emailTextField.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        passwordTextField.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        confirmPasswordTextField.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        
        emailTextField.layer.borderColor = (isDarkMode ? UIColor.quaternaryDark : UIColor.quaternaryLight).cgColor
        passwordTextField.layer.borderColor = (isDarkMode ? UIColor.quaternaryDark : UIColor.quaternaryLight).cgColor
        confirmPasswordTextField.layer.borderColor = (isDarkMode ? UIColor.quaternaryDark : UIColor.quaternaryLight).cgColor
        
        // Update placeholder attributes
        updateTextFieldPlaceholders()
        
        // Update login label
        loginLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
    }
    
    private func updateTextFieldPlaceholders() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let placeholderColor = isDarkMode ?
            UIColor.primaryWhite :
            UIColor.primaryBlack
        
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [
                NSAttributedString.Key.foregroundColor: placeholderColor,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)
            ]
        )
        
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [
                NSAttributedString.Key.foregroundColor: placeholderColor,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)
            ]
        )
        
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(
            string: "Confirm Password",
            attributes: [
                NSAttributedString.Key.foregroundColor: placeholderColor,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)
            ]
        )
    }
    
    // MARK: - Actions
    
    @objc private func signUpTapped() {
        // Dismiss keyboard if needed
        view.endEditing(true)
        
        // Basic validation
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            // Show error alert
            showAlert(title: "Missing Information", message: "Please fill all fields")
            return
        }
        
        // Check passwords match
        guard password == confirmPassword else {
            showAlert(title: "Password Mismatch", message: "Passwords don't match")
            return
        }
        
        // Check email format (basic check)
        guard email.contains("@") && email.contains(".") else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address")
            return
        }
        
        // Check password length (6 characters minimum as per your AuthManager)
        guard password.count >= 6 else {
            showAlert(title: "Password Too Short", message: "Password must be at least 6 characters")
            return
        }
        
        // Create a loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        signUpButton.isEnabled = false
        
        // Make the API call
        Task {
            do {
                // Call AuthManager to register
                let authResponse = try await AuthManager.shared.registerNewUserWithEmail(
                    email: email,
                    password: password
                )
                
                // Success - get back to main thread
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    signUpButton.isEnabled = true
                    
                    print("Registration successful!")
                    
                    // Navigate to NameAndGenderViewController
                    let basicInfoVC = NameAndGenderViewController()
                    let navController = UINavigationController(rootViewController: basicInfoVC)
                    navController.modalPresentationStyle = .fullScreen
                    navController.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
                    self.present(navController, animated: true)
                }
                
            } catch {
                // Error - get back to main thread
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    signUpButton.isEnabled = true
                    
                    // Show error alert with user-friendly message
                    let errorMessage: String
                    if error.localizedDescription.contains("already registered") ||
                       error.localizedDescription.contains("already exists") ||
                       error.localizedDescription.contains("user already exists") {
                        errorMessage = "This email is already registered. Please use a different email or login."
                    } else if error.localizedDescription.contains("invalid email") ||
                              error.localizedDescription.contains("email format") {
                        errorMessage = "Please enter a valid email address"
                    } else if error.localizedDescription.contains("password") ||
                              error.localizedDescription.contains("weak") ||
                              error.localizedDescription.contains("6 characters") {
                        errorMessage = "Password must be at least 6 characters"
                    } else if error.localizedDescription.contains("ValidationError") {
                        errorMessage = "Invalid email or password"
                    } else if error.localizedDescription.contains("network") ||
                              error.localizedDescription.contains("connection") {
                        errorMessage = "Network error. Please check your internet connection"
                    } else {
                        errorMessage = "Registration failed. Please try again."
                    }
                    
                    showAlert(title: "Registration Failed", message: errorMessage)
                }
            }
        }
    }

    // Helper method to show alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    @objc private func loginTapped() {
        onLogin?()
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI)
import SwiftUI

struct RegisterViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegisterViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            RegisterViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct RegisterViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> RegisterViewController {
        return RegisterViewController()
    }
    
    func updateUIViewController(_ uiViewController: RegisterViewController, context: Context) {
        // Update the view controller if needed
    }
}
#endif
