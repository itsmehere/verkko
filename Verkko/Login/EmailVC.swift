//
//  EmailVC.swift
//  Verkko
//
//  Created by Mihir Rao on 6/23/23.
//

import UIKit

class EmailVC: OnboardingStepVC {
    private let emailTextField = VKVerticalLabelTextField(labelText: "EMAIL", placeholder: "Email")
    private let phoneNumberTextField = VKVerticalLabelTextField(labelText: "PHONE NUMBER", placeholder: "Phone Number")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setTitle(with: "Enter email and phone")
        configureTextFields()
        goToNextStep = nextStepToFirstLastName
    }
    
    private func configureTextFields() {
        emailTextField.getTextField().keyboardType = .emailAddress
        phoneNumberTextField.getTextField().keyboardType = .phonePad
        
        emailTextField.setDelegate(vc: self)
        phoneNumberTextField.setDelegate(vc: self)
        
        emailTextField.setReturnHandler(with: nextStepToFirstLastName)
        phoneNumberTextField.setReturnHandler(with: nextStepToFirstLastName)
        
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(phoneNumberTextField)
    }
    
    @objc private func nextStepToFirstLastName() {
        let generator = UINotificationFeedbackGenerator()
        let email = emailTextField.getLabelText().trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneNumber = phoneNumberTextField.getLabelText().trimmingCharacters(in: .whitespacesAndNewlines)
        
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
        
        if phoneNumber.isEmpty {
            generator.notificationOccurred(.error)
            phoneNumberTextField.showError(text: "Phone number cannot be empty")
            return
        }
        
        generator.notificationOccurred(.success)
        self.navigationController?.pushViewController(FirstLastNameVC(email: email, phoneNumber: phoneNumber), animated: true)
    }
}

//MARK: - UITextFieldDelegate
extension EmailVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if emailTextField.getTextField() == textField as? VKTextField {
            emailTextField.removeError()
        }
        
        if phoneNumberTextField.getTextField() == textField as? VKTextField {
            phoneNumberTextField.removeError()
        }
    }
}


