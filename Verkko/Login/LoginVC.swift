//
//  LoginVC.swift
//  Verkko
//
//  Created by Justin Wong on 6/1/23.
//

import UIKit
import FirebaseAuth

class LoginVC: OnboardingStepVC {
    private var emailTextField: VKVerticalLabelTextField!
    private var passwordTextField: VKVerticalLabelTextField!
    private let loginButton = UIButton(type: .custom)
    private let forgotPasswordButton = UIButton(type: .custom)
    private let accountInformationLabel = UILabel()
    
    private let hPadding: CGFloat = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        // Replace "< Back" in nav bar with X icon
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(cancelLogin))
        closeButton.tintColor = .systemGreen
        navigationItem.leftBarButtonItem = closeButton
        
        setTitle(with: "Welcome Back 👋!")
        setNextButtonTitle(with: "Log In")
        configureTextFields()
        configureForgotPasswordLabel()
        
        goToNextStep = didPressLoginButton
    }
    
    @objc private func cancelLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    private func configureTextFields() {
        emailTextField = VKVerticalLabelTextField(labelText: "EMAIL", placeholder: "Email") {
            self.didPressLoginButton()
        }
        emailTextField.getTextField().keyboardType = .emailAddress
        emailTextField.setDelegate(vc: self)
        stackView.addArrangedSubview(emailTextField)
        
        passwordTextField = VKVerticalLabelTextField(labelText: "PASSWORD", placeholder: "Password", isSecure: true) {
            self.didPressLoginButton()
        }
        passwordTextField.setDelegate(vc: self)
        stackView.addArrangedSubview(passwordTextField)
    }
    
    private func configureForgotPasswordLabel() {
        forgotPasswordButton.setTitle("Forgot your password?", for: .normal)
        forgotPasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        forgotPasswordButton.setTitleColor(.systemGreen, for: .normal)
        forgotPasswordButton.addTarget(self, action: #selector(sendPasswordResetEmail), for: .touchUpInside)
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(forgotPasswordButton)
        
        NSLayoutConstraint.activate([
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 25),
            forgotPasswordButton.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor)
        ])
    }
    
    @objc private func sendPasswordResetEmail() {
        let passwordResetAlert = UIAlertController(title: "Password Reset", message: "Please enter a valid email. Instructions to reset your password will be sent to this email.", preferredStyle: .alert)
        passwordResetAlert.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }
        passwordResetAlert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak passwordResetAlert] (_) in
            guard let passwordResetAlert = passwordResetAlert else { return }
            let textField = passwordResetAlert.textFields![0] // Force unwrapping because we know it exists.
            guard let emailToBeSentPasswordReset = textField.text else { return }
            
            if !Utils.isValidEmail(emailToBeSentPasswordReset) {
                self.presentVKAlert(title: "Invalid Email", message: "Please enter a valid email.", buttonTitle: "OK")
                return
            }
            
            Auth.auth().sendPasswordReset(withEmail: emailToBeSentPasswordReset) { error in
                if let error = error {
                    self.presentVKAlert(title: "Cannot Send Password Reset", message: error.localizedDescription, buttonTitle: "OK")
                } else {
                    self.presentVKAlert(title: "Password Reset Sent", message: "Please reset your password at \(emailToBeSentPasswordReset)", buttonTitle: "OK")
                }
            }
        }))
        
        passwordResetAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(passwordResetAlert, animated: true)
    }
    
    @objc private func didPressLoginButton() {
        let generator = UINotificationFeedbackGenerator()
        let email = emailTextField.getLabelText().trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.getLabelText().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if email.isEmpty {
            generator.notificationOccurred(.error)
            emailTextField.showError(text: "Email cannot be empty")
            return
        }
        
        if !Utils.isValidEmail(email) {
            generator.notificationOccurred(.error)
            emailTextField.showError(text: "Email is not valid")
            return
        }
        
        if password.isEmpty {
            generator.notificationOccurred(.error)
            passwordTextField.showError(text: "Password cannot be empty")
            return
        }
        
        //TODO: Put this into an extension of UIViewController? But how to control the loading animations
        view.endEditing(true)
        
        let loadingVC = VKLoadingVC()
        loadingVC.modalPresentationStyle = .overFullScreen
        loadingVC.modalTransitionStyle = .crossDissolve
        present(loadingVC, animated: true)
        loadingVC.startLoadingAnimation()
        
        FirebaseManager.shared.loginInUser(email: emailTextField.getLabelText(), password: passwordTextField.getLabelText()) { result in
            self.dismiss(animated: true)

            switch result {
            case .success(_):
                generator.notificationOccurred(.success)
                break
            case .failure(_):
                generator.notificationOccurred(.error)
                self.displayLoginErrorMessage()
                self.passwordTextField.setLabelText(text: "")
            }
        }
    }
    
    private func displayLoginErrorMessage() {
        emailTextField.showError(text: "Email or password is invalid")
        passwordTextField.showError(text: "Email or password is invalid")
    }
}


//MARK: - UITextFieldDelegate
extension LoginVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if emailTextField.getTextField() == textField as? VKTextField {
            emailTextField.removeError()
        }
        
        if passwordTextField.getTextField() == textField as? VKTextField {
            passwordTextField.removeError()
        }
    }
}
