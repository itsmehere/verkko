//
//  BirthdayVC.swift
//  Verkko
//
//  Created by Justin Wong on 8/22/23.
//

import UIKit

class BirthdayVC: OnboardingStepVC {
    private let email: String!
    private let phoneNumber: String!
    private let firstName: String!
    private let lastName: String!
    private let interests: [String]!
    
    private let datePicker = UIDatePicker()

    init(email: String, phoneNumber: String, firstName: String, lastName: String, interests: [String]) {
        self.email = email
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.interests = interests
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitle(with: "Enter your birthday 🥳")
        configureDatePicker()
        goToNextStep = nextStepToSetSharingPermissios
    }
    
    private func configureDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.tintColor = .systemGreen
        datePicker.maximumDate = Date()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            datePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func nextStepToSetSharingPermissios() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        self.navigationController?.pushViewController(SetSharingPermissionsVC(email: email, phoneNumber: phoneNumber, firstName: firstName, lastName: lastName, interests: interests, birthday: datePicker.date), animated: true)
    }
}

