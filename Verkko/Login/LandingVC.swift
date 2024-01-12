//
//  LandingVC.swift
//  Verkko
//
//  Created by Mihir Rao on 6/26/23.
//

import UIKit

class LandingVC: UIViewController {
    
    private var landingTitle: UILabel!
    private var loginButton: UIButton!
    private var registerButton: UIButton!
    private let generator = UINotificationFeedbackGenerator()
    
    private var hPadding: CGFloat = 40
   
    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundImageView = UIImageView(image: UIImage(named: "landingWallpaper.jpeg"))
        backgroundImageView.frame = view.frame
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        configureLandingTitle()
        configureRegisterButton()
        configureLoginButton()
    }
    
    private func configureLandingTitle() {
        landingTitle = UILabel()
        landingTitle.text = "Welcome to Verkko"
        landingTitle.numberOfLines = 2
        landingTitle.font = .systemFont(ofSize: 50, weight: .regular)
        landingTitle.textColor = .black
        landingTitle.textAlignment = .center
        landingTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(landingTitle)
        
        NSLayoutConstraint.activate([
            landingTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            landingTitle.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            landingTitle.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])
    }
    
    private func configureLoginButton() {
        loginButton = UIButton(type: .custom)
        loginButton.setTitle("Log in", for: .normal)
        loginButton.backgroundColor = .systemGreen
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        loginButton.layer.cornerRadius = 22.5
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(pressedLoginButton), for: .touchUpInside)
        view.addSubview(loginButton)
        
        NSLayoutConstraint.activate([
            loginButton.bottomAnchor.constraint(equalTo: registerButton.topAnchor, constant: -15),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: hPadding),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hPadding),
            loginButton.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func configureRegisterButton() {
        registerButton = UIButton(type: .custom)
        registerButton.setTitle("Register", for: .normal)
        registerButton.backgroundColor = UIColor(white: 0, alpha: 0)
        registerButton.layer.borderColor = UIColor.white.cgColor
        registerButton.layer.borderWidth = 1
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        registerButton.layer.cornerRadius = 22.5
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.addTarget(self, action: #selector(pressedRegisterButton), for: .touchUpInside)
        view.addSubview(registerButton)
        
        NSLayoutConstraint.activate([
            registerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: hPadding),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hPadding),
            registerButton.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    @objc private func pressedLoginButton() {
        generator.notificationOccurred(.success)
        self.navigationController?.pushViewController(LoginVC(), animated: true)
    }
    
    @objc private func pressedRegisterButton() {
        generator.notificationOccurred(.success)
        self.navigationController?.pushViewController(EmailVC(), animated: true)
    }
}


