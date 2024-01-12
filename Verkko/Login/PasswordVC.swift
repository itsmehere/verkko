//
//  PasswordVC.swift
//  Verkko
//
//  Created by Mihir Rao on 6/24/23.
//

import UIKit

class PasswordVC: OnboardingStepVC {
    private let email: String!
    private let phoneNumber: String!
    private let firstName: String!
    private let lastName: String!
    private let interests: [String]!
    private let birthday: Date!
    
    private let passwordField = VKVerticalLabelTextField(labelText: "PASSWORD", placeholder: "Password", isSecure: true)
    private let confirmPasswordField = VKVerticalLabelTextField(labelText: "CONFIRM PASSWORD", placeholder: "Confirm Password", isSecure: true)
    
    init(email: String, phoneNumber: String, firstName: String, lastName: String, interests: [String], birthday: Date) {
        self.email = email
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.interests = interests
        self.birthday = birthday
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitle(with: "Choose a password")
        setNextButtonTitle(with: "Register")
        configureStackView()
        goToNextStep = register
    }
    
    private func configureStackView() {
        passwordField.setDelegate(vc: self)
        confirmPasswordField.setDelegate(vc: self)
        
        passwordField.setReturnHandler(with: register)
        confirmPasswordField.setReturnHandler(with: register)
        
        stackView.addArrangedSubview(passwordField)
        stackView.addArrangedSubview(confirmPasswordField)
    }
    
    @objc private func backToInterestsVC() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func register() {
        let generator = UINotificationFeedbackGenerator()
        let password = passwordField.getLabelText().trimmingCharacters(in: .whitespacesAndNewlines)
        let confirmPassword = confirmPasswordField.getLabelText().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if password.isEmpty {
            generator.notificationOccurred(.error)
            passwordField.showError(text: "Password cannot be empty")
            return
        }
        
        if confirmPassword.isEmpty {
            generator.notificationOccurred(.error)
            confirmPasswordField.showError(text: "Please reenter your password")
            return
        }
        
        if password != confirmPassword {
            generator.notificationOccurred(.error)
            passwordField.showError(text: "Passwords do not match")
            confirmPasswordField.showError(text: "Passwords do not match")
            return 
        }
        
        generator.notificationOccurred(.success)
        FirebaseManager.shared.registerUser(firstName: firstName, lastName: lastName, interests: interests, email: email, phoneNumber: phoneNumber, password: password, confirmPassword: confirmPassword, birthday: birthday) { error in
            if let error = error {
                self.presentVKAlert(title: "Cannot Register User", message: error.getMessage(), buttonTitle: "OK")
            }
        }
    }
}

//MARK: - UITextFieldDelegate
extension PasswordVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if passwordField.getTextField() == textField as? VKTextField {
            passwordField.removeError()
        }
        
        if confirmPasswordField.getTextField() == textField as? VKTextField {
            confirmPasswordField.removeError()
        }
    }
}
