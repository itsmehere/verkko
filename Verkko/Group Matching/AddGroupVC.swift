//
//  AddGroupVC.swift
//  Verkko
//
//  Created by Justin Wong on 7/20/23.
//

import UIKit
import SwiftUI

class AddGroupVC: UIViewController {
    private enum AddGroupVCState {
        case suggested, custom
    }
    private let addGroupSC = UISegmentedControl(items: ["Suggested", "Custom"])
    private var presentationState: AddGroupVCState = .suggested
    private var containerView = UIView()
    
    private var addSuggestedGroupVC: AddSuggestedGroupVC!
    private var addCustomGroupVC: VKAddFriendVC!
    
    init(addSuggestedGroupVC: AddSuggestedGroupVC, addCustomGroupVC: VKAddFriendVC) {
        self.addSuggestedGroupVC = addSuggestedGroupVC
        self.addCustomGroupVC = addCustomGroupVC
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavbar()
        configureAddGroupSC()
        configureContainerView()
        
        updateContainerView()
    }
    
    private func configureNavbar() {
        title = "Add Group"
        view.backgroundColor = .systemBackground
        
        let backButton = UIBarButtonItem(image: UIImage(systemName: "xmark.circle.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: VKConstants.closeButtonWidthAndHeight)), style: .plain, target: self, action: #selector(goBackToGroupMatchingVC))
        backButton.tintColor = UIColor.lightGray
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func goBackToGroupMatchingVC() {
        self.dismiss(animated: true)
    }
    
    private func configureAddGroupSC() {
        addGroupSC.translatesAutoresizingMaskIntoConstraints = false
        addGroupSC.selectedSegmentIndex = 0
        addGroupSC.addTarget(self, action: #selector(toggleGroupsSC(sender:)), for: .valueChanged)
        view.addSubview(addGroupSC)
        
        NSLayoutConstraint.activate([
            addGroupSC.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            addGroupSC.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            addGroupSC.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            addGroupSC.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func toggleGroupsSC(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            //Suggested
            presentationState = .suggested
        default:
            //Custom
            presentationState = .custom
        }
        updateContainerView()
    }
    
    private func configureContainerView() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: addGroupSC.bottomAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateContainerView() {
        if presentationState == .suggested {
            add(childVC: addSuggestedGroupVC, to: containerView)
            addCustomGroupVC.remove()
        } else {
            add(childVC: addCustomGroupVC, to: containerView)
            addSuggestedGroupVC.remove()
        }
    }
}

//MARK: - AddSuggestedGroupVC
class AddSuggestedGroupVC: UIViewController {
    private let numOfPeopleSelectionStackView = UIStackView()
    private let numOfPeoplePickerOptions = ["3", "4", "5", "6"]
    private var selectedPickerOption: String?
    private var dismissHandler: (() -> Void)?
    weak var delegate: AddGroupMatchingDelegate?
    
    init(dismissHandler: (() -> Void)?) {
        self.dismissHandler = dismissHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNumOfPeopleSelectionStackView()
        createAndConfigureCreateSuggestedGroupButton()
    }
    
    private func configureNumOfPeopleSelectionStackView() {
        numOfPeopleSelectionStackView.axis = .vertical
        numOfPeopleSelectionStackView.spacing = 10
        numOfPeopleSelectionStackView.distribution = .fillProportionally
        numOfPeopleSelectionStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(numOfPeopleSelectionStackView)
        
        numOfPeopleSelectionStackView.addArrangedSubview(createInformationLabel())
        numOfPeopleSelectionStackView.addArrangedSubview(createSelectNumOfPeopleLabel())
        numOfPeopleSelectionStackView.addArrangedSubview(createNumOfPeoplePickerView())
        
        NSLayoutConstraint.activate([
            numOfPeopleSelectionStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            numOfPeopleSelectionStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            numOfPeopleSelectionStackView.widthAnchor.constraint(equalToConstant: 300),
            numOfPeopleSelectionStackView.heightAnchor.constraint(equalToConstant: 400)
        ])
    }
    
    private func createInformationLabel() -> UILabel {
        let informationLabel = UILabel()
        informationLabel.text = "If a group cannot be made per the selected requirement, Verkko will try to create a group with fewer people"
        informationLabel.textColor = .systemRed.withAlphaComponent(0.7)
        informationLabel.numberOfLines = 0
        informationLabel.font = UIFont.systemFont(ofSize: 15)
        informationLabel.textAlignment = .center
        informationLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        informationLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return informationLabel
    }
    
    private func createSelectNumOfPeopleLabel() -> UILabel {
        let selectNumOfPeopleLabel = UILabel()
        selectNumOfPeopleLabel.text = "Number of People:"
        selectNumOfPeopleLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        selectNumOfPeopleLabel.textAlignment = .center
        selectNumOfPeopleLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        selectNumOfPeopleLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        selectNumOfPeopleLabel.translatesAutoresizingMaskIntoConstraints = false

        return selectNumOfPeopleLabel
    }
    
    private func createNumOfPeoplePickerView() -> UIPickerView {
        let numOfPeoplePickerView = UIPickerView()
        numOfPeoplePickerView.delegate = self
        numOfPeoplePickerView.dataSource = self
        numOfPeoplePickerView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        numOfPeoplePickerView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        numOfPeoplePickerView.translatesAutoresizingMaskIntoConstraints = false
        
        return numOfPeoplePickerView
    }
    
    private func createAndConfigureCreateSuggestedGroupButton() {
        let createSuggestedGroupButtonView = UIHostingController(rootView: VKGradientButton(text: "Create Suggested Group", gradientColors: [.blue.opacity(0.4), .purple.opacity(0.5)], completion: {
            
        })).view!
        let createSuggestedGroupButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(createSuggestedGroup))
        createSuggestedGroupButtonView.addGestureRecognizer(createSuggestedGroupButtonTapGestureRecognizer)
        createSuggestedGroupButtonView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createSuggestedGroupButtonView)
        
        NSLayoutConstraint.activate([
            createSuggestedGroupButtonView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            createSuggestedGroupButtonView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createSuggestedGroupButtonView.widthAnchor.constraint(equalToConstant: 300),
            createSuggestedGroupButtonView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func createSuggestedGroup() {
        guard let selectedPickerOption = selectedPickerOption,
              let selectedIntPickerOption = Int(selectedPickerOption) else { return }
        
        delegate?.addGroupMatchingSuggestedGroup(ofNum: selectedIntPickerOption)
    }
}

//MARK: AddSuggestedGroupVC Delegates
extension AddSuggestedGroupVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numOfPeoplePickerOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        selectedPickerOption = numOfPeoplePickerOptions[row]
        return numOfPeoplePickerOptions[row]
    }
}

