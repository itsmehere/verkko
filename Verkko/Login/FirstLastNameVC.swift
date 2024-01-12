//
//  FirstLastNameVC.swift
//  Verkko
//
//  Created by Mihir Rao on 6/24/23.
//

import UIKit

class FirstLastNameVC: OnboardingStepVC {
    private let email: String!
    private let phoneNumber: String!
    
    private let firstNameField = VKVerticalLabelTextField(labelText: "FIRST NAME", placeholder: "First Name")
    private let lastNameField = VKVerticalLabelTextField(labelText: "LAST NAME", placeholder: "Last Name")

    init(email: String, phoneNumber: String) {
        self.email = email
        self.phoneNumber = phoneNumber
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createDismissKeyboardTapGesture()
        setTitle(with: "Enter your name")
        configureTextFields()
        goToNextStep = nextStepToInterests
    }
    
    private func configureTextFields() {
        firstNameField.setDelegate(vc: self)
        lastNameField.setDelegate(vc: self)
        
        firstNameField.setReturnHandler(with: nextStepToInterests)
        lastNameField.setReturnHandler(with: nextStepToInterests)
        
        stackView.addArrangedSubview(firstNameField)
        stackView.addArrangedSubview(lastNameField)
    }
    
    @objc private func nextStepToInterests() {
        let generator = UINotificationFeedbackGenerator()
        let firstName = firstNameField.getLabelText().trimmingCharacters(in: .whitespacesAndNewlines).capitalizeFirstAndLowercaseRest()
        let lastName = lastNameField.getLabelText().trimmingCharacters(in: .whitespacesAndNewlines).capitalizeFirstAndLowercaseRest()

        if firstName.isEmpty {
            generator.notificationOccurred(.error)
            firstNameField.showError(text: "First name cannot be empty")
            return
        }
        
        if lastName.isEmpty {
            generator.notificationOccurred(.error)
            lastNameField.showError(text: "Last name cannot be empty")
            return
        }
       
        firstNameField.removeError()
        lastNameField.removeError()
        generator.notificationOccurred(.success)
        self.navigationController?.pushViewController(InterestsVC(email: email, phoneNumber: phoneNumber, firstName: firstName, lastName: lastName), animated: true)
    }
}

//MARK: - UITextFieldDelegate
extension FirstLastNameVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if firstNameField.getTextField() == textField as? VKTextField {
            firstNameField.removeError()
        }
        
        if lastNameField.getTextField() == textField as? VKTextField {
            lastNameField.removeError()
        }
    }
}
