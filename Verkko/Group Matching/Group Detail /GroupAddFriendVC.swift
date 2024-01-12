//
//  GroupAddFriendVC.swift
//  Verkko
//
//  Created by Justin Wong on 7/29/23.
//

import UIKit
import FirebaseFirestore

class GroupAddFriendVC: UIViewController {
    private var addFriendsVC: VKAddFriendVC!
    private let group: VKGroup!
    
    init(group: VKGroup) {
        self.group = group
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        configureVC()
    }
    
    private func configureVC() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        var omittedFriendsSet = Set(group.getMembersUIDs())
        //Add current user's blocked friends
        currentUser.blockedFriends.forEach({ omittedFriendsSet.insert($0) })
        addFriendsVC = VKAddFriendVC(ommittedFriends: Array(omittedFriendsSet), buttonTitle: "Add Friends To Group")
    
        view.backgroundColor = .systemBackground
        title = "Add Friend To \(group.name)"
        addCloseButton()
        
        addFriendsVC.delegate = self
        add(childVC: addFriendsVC, to: view)
    }
}

extension GroupAddFriendVC: AddGroupMatchingDelegate {
    func addGroupMatchingSuggestedGroup(ofNum selectedIntPickerOption: Int) {}
    
    func addGroupMatchingCustomGroup(withFriends groupAddedFriendsUIDs: [String]) {
        let newMembersAndStatus = groupAddedFriendsUIDs.reduce(into: [String: VKGroupAcceptanceStatus]()) {
            $0[$1] = .pending
        }
        
        let mergedMembersAndStatus = group.membersAndStatus.merging(newMembersAndStatus) { current, _ in
            current
        }
        
        let newGroupMembersAndStatus = mergedMembersAndStatus.mapValues { value in
            return value.description
        }
        
        FirebaseManager.shared.updateGroup(for: group.jointID, fields: [
            VKConstants.membersAndStatus: newGroupMembersAndStatus
        ]) { error in
            if let error = error {
                self.presentVKAlert(title: "Error Add Friends", message: error.getMessage(), buttonTitle: "OK")
            } else {
                self.dismiss(animated: true)
            }
        }
    }
}
