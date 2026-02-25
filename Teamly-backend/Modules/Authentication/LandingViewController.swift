//
//  LandingViewController.swift
//  Practice - teamly
//
//  Created by user@37 on 23/10/25.
//

import UIKit

class LandingViewController: UIViewController {
    
    var onGetStarted: (() -> Void)?
    
    // MARK: - UI Components
    private let topGreenTint: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        return gradient
    }()
    
    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let separatorLine = UIView()
    private let descriptionLabel = UILabel()
    private let getStartedButton = UIButton(type: .system)
    
    // MARK: - Properties
    private var timer: Timer?
    private let autoScrollInterval: TimeInterval = 3.0
    private var currentPage: Int = 0 {
        didSet {
            updatePageControl()
        }
    }
    
    // MARK: - Computed Properties for Image Names
    private var imageNames: [String] {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        if isDarkMode {
            // Dark mode images
            return ["Landing11", "Landing22", "Landing33"]
        } else {
            // Light mode images
            return ["HomeWhite11", "HomeWhite22", "HomeWhite33"]
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupImageSlider()
        startAutoScroll()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = topGreenTint.bounds
        updateGradientColors()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
            updateGradientColors()
            // Update images when theme changes
            setupImageSlider()
            // Reset to first page when theme changes
            currentPage = 0
            let offset = CGPoint(x: 0, y: 0)
            scrollView.setContentOffset(offset, animated: false)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        updateColors()
            
        view.addSubview(topGreenTint)
        topGreenTint.layer.addSublayer(gradientLayer)
        
        setupScrollView()
        setupPageControl()
        setupTextContent()
        setupSeparatorLine()
        setupGetStartedButton()
        setupConstraints()
    }
    
    private func setupScrollView() {
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.layer.cornerRadius = 12
        scrollView.clipsToBounds = true
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
    }
    
    private func setupPageControl() {
        pageControl.numberOfPages = imageNames.count
        pageControl.currentPage = 0
        updatePageControlColors()
        view.addSubview(pageControl)
    }
    
    private func setupTextContent() {
        titleLabel.text = "Teamly"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        subtitleLabel.text = "From chaos to kickoff!"
        subtitleLabel.font = UIFont.italicSystemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0.8
        view.addSubview(subtitleLabel)
        
        descriptionLabel.text = "Create your account and start playing!"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.alpha = 0.7
        view.addSubview(descriptionLabel)

        updateLabelColors()
    }
    
    private func setupSeparatorLine() {
        separatorLine.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .tertiaryDark : .tertiaryLight
        view.addSubview(separatorLine)
    }
    
    private func setupGetStartedButton() {
        getStartedButton.setTitle("Let's Start", for: .normal)
        getStartedButton.backgroundColor = .systemGreen
        getStartedButton.setTitleColor(.white, for: .normal)
        getStartedButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        getStartedButton.layer.cornerRadius = 28
        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        view.addSubview(getStartedButton)
    }
    
    private func setupImageSlider() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        for (index, imageName) in imageNames.enumerated() {
            let containerView = UIView()
            containerView.backgroundColor = .clear
            
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            
            if let image = UIImage(named: imageName) {
                imageView.image = image
            } else {
                let fallbackName = imageName.replacingOccurrences(of: "Landing/LandingWhite", with: "Landing/Landing")
                                            .replacingOccurrences(of: "LandingWhite", with: "Landing")
                imageView.image = UIImage(named: fallbackName) ?? UIImage(systemName: "photo")
                imageView.tintColor = .systemGreen
            }
            
            containerView.addSubview(imageView)
            scrollView.addSubview(containerView)

            containerView.frame = CGRect(
                x: CGFloat(index) * (view.frame.width - 80),
                y: 0,
                width: view.frame.width - 80,
                height: 250
            )

            imageView.frame = containerView.bounds
        }
        
        scrollView.contentSize = CGSize(
            width: (view.frame.width - 80) * CGFloat(imageNames.count),
            height: 280
        )
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topGreenTint.topAnchor.constraint(equalTo: view.topAnchor),
            topGreenTint.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topGreenTint.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topGreenTint.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            scrollView.heightAnchor.constraint(equalToConstant: 280),

            pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: 35),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            separatorLine.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -20),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),

            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            descriptionLabel.bottomAnchor.constraint(equalTo: getStartedButton.topAnchor, constant: -30),

            getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            getStartedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            getStartedButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    // MARK: - Color Updates
    private func updateColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        view.backgroundColor = isDarkMode ? .primaryBlack : .primaryWhite

        separatorLine.backgroundColor = isDarkMode ? .tertiaryDark : .tertiaryLight


        updatePageControlColors()
    }
    
    private func updateLabelColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        titleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        subtitleLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
        descriptionLabel.textColor = isDarkMode ? .primaryWhite : .primaryBlack
    }
    
    private func updatePageControlColors() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        pageControl.pageIndicatorTintColor = isDarkMode ? .tertiaryDark : .tertiaryLight
        pageControl.currentPageIndicatorTintColor = .systemGreen
        pageControl.numberOfPages = imageNames.count
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
    
    // MARK: - Auto Scroll
    private func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: autoScrollInterval, repeats: true) { [weak self] _ in
            self?.scrollToNextPage()
        }
    }
    
    private func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }
    
    private func scrollToNextPage() {
        let nextPage = (currentPage + 1) % imageNames.count
        let offset = CGPoint(x: CGFloat(nextPage) * (view.frame.width - 80), y: 0)
        scrollView.setContentOffset(offset, animated: true)
        currentPage = nextPage
    }
    
    private func updatePageControl() {
        pageControl.currentPage = currentPage
    }
    
    // MARK: - Actions
    @objc private func getStartedTapped() {
        showLoginModal()
    }
        
    private func showLoginModal() {
        let loginVC = LoginViewController()

        loginVC.onLoginSuccess = { [weak self] in
            self?.dismiss(animated: true) {
                self?.onGetStarted?()
            }
        }
        
        loginVC.onRegister = { [weak self] in
            let registerVC = RegisterViewController()
            
            registerVC.onRegisterSuccess = { [weak self] in
                self?.dismiss(animated: true) {
                    self?.onGetStarted?()
                }
            }
            
            registerVC.onLogin = { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }

            if let sheet = registerVC.sheetPresentationController {
                let registerDetent = UISheetPresentationController.Detent.custom { context in
                    return 490
                }
                sheet.detents = [registerDetent]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }

            registerVC.overrideUserInterfaceStyle = self?.traitCollection.userInterfaceStyle ?? .unspecified
            loginVC.present(registerVC, animated: true, completion: nil)
        }

        if let sheet = loginVC.sheetPresentationController {
            let loginDetent = UISheetPresentationController.Detent.custom { context in
                return 420
            }
            sheet.detents = [loginDetent]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }

        loginVC.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle
        
        present(loginVC, animated: true, completion: nil)
    }
}

// MARK: - UIScrollViewDelegate
extension LandingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / (view.frame.width - 80))
        currentPage = Int(pageIndex)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScroll()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        startAutoScroll()
    }
}

// MARK: - SwiftUI Preview
#if canImport(SwiftUI)
import SwiftUI

struct LandingViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LandingViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            LandingViewControllerRepresentable()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

struct LandingViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LandingViewController {
        return LandingViewController()
    }
    
    func updateUIViewController(_ uiViewController: LandingViewController, context: Context) {
    }
}
#endif
