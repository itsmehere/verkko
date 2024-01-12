//
//  InterestsVC.swift
//  Verkko
//
//  Created by Mihir Rao on 7/1/23.
//

import UIKit

class InterestsVC: OnboardingStepVC {
    private let email: String!
    private let phoneNumber: String!
    private let firstName: String!
    private let lastName: String!
    
    private var interests = [VKVerticalLabelTextField(labelText: "INTEREST 1", placeholder: "eg. 🏄‍♂️ Surfing"),
                             VKVerticalLabelTextField(labelText: "INTEREST 2", placeholder: "eg. 🏌️ Golfing\""),
                             VKVerticalLabelTextField(labelText: "INTEREST 3", placeholder: "eg. ⛺️ Camping")]
    
    init(email: String, phoneNumber: String, firstName: String, lastName: String) {
        self.email = email
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setTitle(with: "Tell us about your interests")
        setSubtitle(with: "This helps Verkko connect you with similar people")
        configureStackView()
        goToNextStep = nextStepToPassword
    }
    
    private func configureStackView() {
        for i in interests {
            stackView.addArrangedSubview(i)
        }
    }
    
    @objc private func nextStepToPassword() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        var interestsText = [String]()
        
        for i in interests {
            let trimmedInterestText = i.getLabelText().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !trimmedInterestText.isEmpty {
                interestsText.append(trimmedInterestText)
            }
        }
                
        self.navigationController?.pushViewController(BirthdayVC(email: email, phoneNumber: phoneNumber, firstName: firstName, lastName: lastName, interests: interestsText), animated: true)
    }
}
