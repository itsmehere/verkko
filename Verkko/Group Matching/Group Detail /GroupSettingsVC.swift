//
//  GroupSettingsVC.swift
//  Verkko
//
//  Created by Justin Wong on 7/26/23.
//

import UIKit

class GroupSettingsVC: VKCenterModalVC {
    private let headerView = UIView()
    private let roomNameTextField = VKTextField()
    private let mainStackView = UIStackView()
    private let saveButton = UIButton(type: .custom)
    
    private var group: VKGroup!
    private var returnToGroupMatchingVC: (() -> Void)!
    private lazy var isCurrentUserRoomCreator: Bool = {
        guard let currentUser = FirebaseManager.shared.currentUser else { return false }
        return group.createdBy == currentUser.uid
    }()
    
    init(group: VKGroup, returnToGroupMatchingVC: @escaping () -> Void, closeButtonClosure: @escaping () -> Void) {
        self.returnToGroupMatchingVC = returnToGroupMatchingVC
        self.group = group
        super.init(closeButtonClosure: closeButtonClosure)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHeaderView()
        configureMainStackView()
    }
    
    private func configureHeaderView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerView)
        
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25)), for: .normal)
        closeButton.tintColor = .lightGray
        closeButton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(closeButton)
        
        let titleLabel = UILabel()
        titleLabel.text = group.name + " Settings"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),
            
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureMainStackView() {
        mainStackView.axis = .vertical
        mainStackView.spacing = 10
        mainStackView.distribution = .fillProportionally
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mainStackView)
        
        roomNameTextField.delegate = self
        roomNameTextField.placeholder = group.name
        roomNameTextField.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        roomNameTextField.layer.cornerRadius = 10
        roomNameTextField.backgroundColor = .lightGray.withAlphaComponent(0.4)
        mainStackView.insertArrangedSubview(roomNameTextField, at: 0)
        
        //TODO: Not sure if we want to have a transfer ownership button.
        let transferOwnershipButton = VKButton(backgroundColor: .systemIndigo.withAlphaComponent(0.7), title: "Transfer Ownership")
        transferOwnershipButton.layer.cornerRadius = 10
//        mainStackView.addArrangedSubview(transferOwnershipButton)
        
        let leaveGroupButton = VKButton(backgroundColor: .systemRed.withAlphaComponent(0.7), title: "Leave Group")
        leaveGroupButton.layer.cornerRadius = 10
        leaveGroupButton.addTarget(self, action: #selector(leaveGroup), for: .touchUpInside)
        mainStackView.addArrangedSubview(leaveGroupButton)
        
        let deleteGroupButton = VKButton(backgroundColor: .systemRed.withAlphaComponent(0.9), title: "Delete Group")
        deleteGroupButton.layer.cornerRadius = 10
        deleteGroupButton.addTarget(self, action: #selector(deleteGroup), for: .touchUpInside)
        
        if isCurrentUserRoomCreator {
            mainStackView.insertArrangedSubview(deleteGroupButton, at: 2)
        } else {
            roomNameTextField.isEnabled = false
            roomNameTextField.layer.opacity = 0.5
        }
        
        configureSaveButton()
        
        NSLayoutConstraint.activate([
            mainStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            roomNameTextField.heightAnchor.constraint(equalToConstant: 50),
            transferOwnershipButton.heightAnchor.constraint(equalToConstant: 50),
            leaveGroupButton.heightAnchor.constraint(equalToConstant: 50),
            deleteGroupButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func leaveGroup() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        FirebaseManager.shared.removeFromGroup(from: group, forUID: currentUser.uid)
        dismissVC()
        returnToGroupMatchingVC()
    }
    
    @objc private func deleteGroup() {
        FirebaseManager.shared.deleteGroups(for: [group]) { error in
            if let error = error {
                self.presentVKAlert(title: "Cannot Delete Group", message: error.getMessage(), buttonTitle: "OK")
            } else {
                self.dismissVC()
                self.returnToGroupMatchingVC()
            }
        }
    }
    
    private func configureSaveButton() {
        saveButton.isHidden = true 
        saveButton.setTitleColor(.systemGreen, for: .normal)
        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveGroupSettings), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(saveButton)
        NSLayoutConstraint.activate([
            saveButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            saveButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }
    
    @objc private func saveGroupSettings() {
        FirebaseManager.shared.updateGroup(for: group.jointID, fields: [
            "name": roomNameTextField.text ?? group.name
        ]) { error in
            if let error = error {
                self.presentVKAlert(title: "Cannot Update Group", message: error.getMessage(), buttonTitle: "OK")
            } else {
                self.closeButtonClosure()
            }
        }
    }
}

extension GroupSettingsVC: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let newGroupName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        
        if newGroupName.isEmpty {
            saveButton.isHidden = true
        } else if newGroupName == group.name.trimmingCharacters(in: .whitespacesAndNewlines) {
            roomNameTextField.setBorderColor(color: UIColor.systemRed.cgColor)
            saveButton.isHidden = true
        } else {
            roomNameTextField.setBorderColor(color: UIColor.lightGray.cgColor)
            saveButton.isHidden = false
        }
    }
}

