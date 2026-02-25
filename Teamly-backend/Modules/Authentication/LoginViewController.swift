//
//  LoginViewController.swift
//  SupabaseDemo
//
//  Created by user@37 on 23/01/26.
//


import UIKit
import Auth

class LoginViewController: UIViewController {
    
    var onLoginSuccess: (() -> Void)?
    var onRegister: (() -> Void)?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let registerLabel = UILabel()
    private let registerButton = UIButton(type: .system)
    
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
        updateColors()
        
        setupScrollView()
        setupContentView()
        setupTitleLabel()
        setupEmailTextField()
        setupPasswordTextField()
        setupLoginButton()
        setupRegisterSection()
    }
    
    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
    }
    
    private func setupContentView() {
        scrollView.addSubview(contentView)
    }
    
    private func setupTitleLabel() {
        titleLabel.text = "Login"
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

        updateTextFieldPlaceholders()
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        passwordTextField.leftView = paddingView
        passwordTextField.leftViewMode = .always
        
        contentView.addSubview(passwordTextField)
    }
    
    private func setupLoginButton() {
        loginButton.setTitle("LOGIN", for: .normal)
        loginButton.backgroundColor = .systemGreen
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        loginButton.layer.cornerRadius = 25
        loginButton.layer.masksToBounds = true
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        contentView.addSubview(loginButton)
    }
    
    private func setupRegisterSection() {
        registerLabel.text = "Not a member? "
        registerLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        contentView.addSubview(registerLabel)
        
        registerButton.setTitle("Register Now", for: .normal)
        registerButton.setTitleColor(.systemGreen, for: .normal)
        registerButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        contentView.addSubview(registerButton)
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        registerLabel.translatesAutoresizingMaskIntoConstraints = false
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            // Login Button
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Register section
            registerLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 30),
            registerLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -45),
            registerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            registerButton.centerYAnchor.constraint(equalTo: registerLabel.centerYAnchor),
            registerButton.leadingAnchor.constraint(equalTo: registerLabel.trailingAnchor, constant: 0),
            registerButton.heightAnchor.constraint(equalToConstant: 44)
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
        
        emailTextField.backgroundColor = isDarkMode ? .tertiaryDark: .tertiaryLight
        passwordTextField.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        
        emailTextField.layer.borderColor = (isDarkMode ? UIColor.quaternaryDark : UIColor.quaternaryLight).cgColor
        passwordTextField.layer.borderColor = (isDarkMode ? UIColor.quaternaryDark : UIColor.quaternaryLight).cgColor
        
        // Update placeholder attributes
        updateTextFieldPlaceholders()
        
        // Update register label
        registerLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
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
    }
    
    // MARK: - Actions
    @objc private func loginTapped() {
        // Dismiss keyboard
        view.endEditing(true)
        
        // Basic validation
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Show error
            print("Please fill all fields")
            return
        }
        
        // Check email format
        guard email.contains("@") && email.contains(".") else {
            print("Invalid email format")
            return
        }
        
        // Create loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        loginButton.isEnabled = false
        
        // Make the API call
        Task {
            do {
                // Call AuthManager to login
                let session = try await AuthManager.shared.signInWithEmail(
                    email: email,
                    password: password
                )
                
                // Get the user ID from the session
                let userId = session.user.id
                
                // Check if onboarding is complete
                let isOnboardingComplete = try await AuthManager.shared.isOnboardingComplete(userId: userId)
                
                // Success - get back to main thread
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    loginButton.isEnabled = true
                    
                    print("Login successful! Onboarding complete: \(isOnboardingComplete)")
                    
                    if isOnboardingComplete {
                        // Navigate to TabBarController
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
                    } else {
                        // Navigate to onboarding screen (NameAndGenderViewController)
                        let nameAndGenderVC = NameAndGenderViewController()
                        
                        // Get the window from the current scene
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            
                            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                                window.rootViewController = UINavigationController(rootViewController: nameAndGenderVC)
                            }, completion: nil)
                        }
                    }
                }
                
            } catch {
                // Error - get back to main thread
                await MainActor.run {
                    loadingIndicator.removeFromSuperview()
                    loginButton.isEnabled = true
                    
                    print("Login error: \(error.localizedDescription)")
                    
                    // Show error alert with user-friendly message
                    let errorMessage: String
                    if error.localizedDescription.contains("Invalid login credentials") ||
                       error.localizedDescription.contains("invalid credentials") {
                        errorMessage = "Invalid email or password"
                    } else if error.localizedDescription.contains("Email not confirmed") {
                        errorMessage = "Please confirm your email address first"
                    } else if error.localizedDescription.contains("rate limit") {
                        errorMessage = "Too many attempts. Please try again later"
                    } else {
                        errorMessage = "Login failed: \(error.localizedDescription)"
                    }
                    
                    let alert = UIAlertController(
                        title: "Login Failed",
                        message: errorMessage,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func registerTapped() {
        onRegister?()
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI)
import SwiftUI

struct LoginViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")

            LoginViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct LoginViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LoginViewController {
        return LoginViewController()
    }

    func updateUIViewController(_ uiViewController: LoginViewController, context: Context) {
        // Update the view controller if needed
    }
}
#endif
