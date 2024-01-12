//
//  OnboardingStepVC.swift
//  Verkko
//
//  Created by Justin Wong on 8/22/23.
//

import UIKit

class OnboardingStepVC: UIViewController {
    var stackView = UIStackView()
    var goToNextStep: (() -> Void)?
    
    private let namePageTitle = UILabel()
    private let nextButton = VKButton(backgroundColor: .systemGreen, title: "Next")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureVC()
        configureStackView()
        configureNextButton()
    }
    
    func setTitle(with title: String) {
        namePageTitle.text = title
        namePageTitle.font = .systemFont(ofSize: 25, weight: .bold)
        namePageTitle.textAlignment = .center
        namePageTitle.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.insertArrangedSubview(namePageTitle, at: 0)
    }
    
    func setSubtitle(with subtitle: String) {
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: namePageTitle.bottomAnchor, constant: 2.5)
        ])
    }
    
    func setNextButtonTitle(with title: String) {
        nextButton.setTitle(title, for: .normal)
    }
    
    private func configureVC() {
        createDismissKeyboardTapGesture()
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .black
        
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(cancelRegistration))
        backButton.tintColor = .systemGreen
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func cancelRegistration() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func configureStackView() {
        stackView.distribution = .equalSpacing
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
        ])
    }
    
    private func configureNextButton() {
        nextButton.addTarget(self, action: #selector(proceedToNextStep), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            nextButton.heightAnchor.constraint(equalToConstant: VKConstants.nextButtonHeight),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }
    
    @objc private func proceedToNextStep() {
        goToNextStep?()
    }
}
