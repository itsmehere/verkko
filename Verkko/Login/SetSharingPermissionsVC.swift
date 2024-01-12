//
//  SetSharingPermissionsVC.swift
//  Verkko
//
//  Created by Justin Wong on 8/26/23.
//

import UIKit
import SwiftUI

class SetSharingPermissionsVC: OnboardingStepVC {
    private let email: String!
    private let phoneNumber: String!
    private let firstName: String!
    private let lastName: String!
    private let interests: [String]!
    private let birthday: Date!
    
    init(email: String, phoneNumber: String, firstName: String, lastName: String, interests: [String], birthday: Date) {
        self.email = email
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.interests = interests
        self.birthday = birthday
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitle(with: "Set your sharing permissions")
        setNextButtonTitle(with: "Next")
        configureVC()
        goToNextStep = nextStepToPassword
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureVC() {
        let hostingController = UIHostingController(rootView: SettingsSharePersonalInfoVisibilitiesView(model: SettingsViewModel()))
        stackView.addArrangedSubview(hostingController.view)
    }
    
    @objc private func nextStepToPassword() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        self.navigationController?.pushViewController(PasswordVC(email: email, phoneNumber: phoneNumber, firstName: firstName, lastName: lastName, interests: interests, birthday: birthday), animated: true)
    }
}
