//
//  GroupMatchingVC.swift
//  Verkko
//
//  Created by Justin Wong on 5/24/23.
//

import UIKit
import SwiftUI
import FirebaseFirestore

protocol AddGroupMatchingDelegate: AnyObject {
    func addGroupMatchingSuggestedGroup(ofNum selectedIntPickerOption: Int)
    func addGroupMatchingCustomGroup(withFriends groupAddedFriendsUIDs: [String])
}

class GroupMatchingVC: UIViewController {
    private enum GroupMatchingVCPresentationState {
        case suggested
        case myGroups
    }
    
    private let groupsSC = UISegmentedControl(items: ["Suggested", "My Groups"])
    private var suggestedGroups = [VKGroup]()
    private var myGroups = [VKGroup]()
    private var cachedUsers = VKGroupCache()
    private var presentationState: GroupMatchingVCPresentationState = .suggested
    
    private let groupsTableView = UITableView()
    private let groupsTableViewActivityIndicator = UIActivityIndicatorView(style: .medium)
    private var presentedGroupDetailVC: GroupDetailVC? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector
                                               (receiveUpdatedCurrentUser), name: .updatedCurrentUser, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveUpdatedGroup), name: .updatedGroup, object: nil)
        
        configureNavigationBar()
        setConfigurationForMainVC()
        configureGroupsSC()
        configureGroupsTableView()
        fetchCurrentUserGroups()
        reloadGroupsTable()
    }
    
    @objc private func receiveUpdatedGroup(_ notification: Notification) {
        guard let updatedGroup = notification.object as? VKGroup else { return }
        if let updatedGroupIndex = myGroups.firstIndex(where: { $0.jointID == updatedGroup.jointID }) {
            myGroups[updatedGroupIndex] = updatedGroup
            
            if updatedGroup.jointID == presentedGroupDetailVC?.getGroup().jointID {
                presentedGroupDetailVC?.updateGroup(with: updatedGroup)
            }
        } else {
            //Newly Created Group
            myGroups.append(updatedGroup)

        }
        reFilterAndSortAllGroups()
    }
    
    //Listen to updates to currentUser's groups field to check for group deletions
    @objc private func receiveUpdatedCurrentUser(_ notification: Notification) {
        guard let updatedCurrentUser = notification.object as? VKUser,
        let newGroups = updatedCurrentUser.groups else { return }
        let allGroupsSet = Set(myGroups.map{ $0.jointID })
        let newGroupsSet = Set(newGroups)
        
        let deletions = Array(allGroupsSet.subtracting(newGroupsSet))
        for deletedGroupID in deletions {
            if let deletedGroupIndex = myGroups.firstIndex(where: { $0.jointID == deletedGroupID }) {
                myGroups.remove(at: deletedGroupIndex)
                //TODO: Is removing a listener from an already deleted group document necessary?
                FirebaseManager.shared.removeGroupListeners(for: [deletedGroupID])
                reFilterAndSortAllGroups()
            }
        }
    }
    
    private func fetchCurrentUserGroups() {
        guard let currentUser = FirebaseManager.shared.currentUser,
        let groups = currentUser.groups else { return }
        
        getSuggestedGroups()
        
        FirebaseManager.shared.fetchGroups(for: groups) { result in
            switch result {
            case .success(let groups):
                self.myGroups = groups
                FirebaseManager.shared.observeGroups(for: groups.map{ $0.jointID }) { error in
                    if let error = error {
                        self.presentVKAlert(title: "Cannot Observe Groups", message: error.getMessage(), buttonTitle: "OK")
                    }
                }
                self.reFilterAndSortAllGroups()
                self.reloadGroupsTable()
            case .failure(let error):
                self.presentVKAlert(title: "Cannot Fetch Groups", message: error.getMessage(), buttonTitle: "OK")
            }
        }
    }
    
    private func reFilterAndSortAllGroups() {
        suggestedGroups = suggestedGroups.sorted(by: { $0.membersAndStatus.count < $1.membersAndStatus.count
        })
        myGroups = myGroups.sorted(by: { $0.membersAndStatus.count < $1.membersAndStatus.count
        })
        reloadGroupsTable()
    }
    
    private func saveSuggestedGroups(for suggestedGroups: [VKGroup]) {
        let encoder = JSONEncoder()
        
        do {
            let encodedSuggestedGroups = try encoder.encode(suggestedGroups)
            UserDefaults.standard.set(encodedSuggestedGroups, forKey: "suggestedGroups")
            print("Successfully saved group")
        } catch {
            print("Cannot save suggested groups")
            self.presentVKAlert(title: "Cannot Save Suggested Groups", message: error.localizedDescription, buttonTitle: "OK")
        }
    }
    
    private func getSuggestedGroups() {
        if let savedData = UserDefaults.standard.object(forKey: "suggestedGroups") as? Data {
            do {
                let savedSuggestedGroups = try JSONDecoder().decode([VKGroup].self, from: savedData)
                suggestedGroups = savedSuggestedGroups
                print("Saved Suggested Groups: \(savedSuggestedGroups)")
                reFilterAndSortAllGroups()
            } catch {
                self.presentVKAlert(title: "Cannot Retrieve Suggested Groups", message: error.localizedDescription, buttonTitle: "OK")
            }
        } else {
            print("Can't get suggested gropus saved data")
        }
    }
    
    private func configureNavigationBar() {
        let addGroupNavbarButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addGroup))
        addGroupNavbarButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItem = addGroupNavbarButton
    }
    
    @objc private func addGroup() {
        let addSuggestedGroupVC = AddSuggestedGroupVC {
            self.dismiss(animated: true)
        }
        let addCustomGroupVC = VKAddFriendVC(buttonTitle: "Add Custom Group")
        addSuggestedGroupVC.delegate = self
        addCustomGroupVC.delegate = self
        
        let addGroupVC = AddGroupVC(addSuggestedGroupVC: addSuggestedGroupVC, addCustomGroupVC: addCustomGroupVC)
        let addGroupNC = UINavigationController(rootViewController: addGroupVC)
        present(addGroupNC, animated: true)
    }
    
    private func configureGroupsSC() {
        view.addSubview(groupsSC)
        
        groupsSC.translatesAutoresizingMaskIntoConstraints = false
        groupsSC.selectedSegmentIndex = 0
    
        // Style the Segmented Control
        groupsSC.layer.cornerRadius = 5.0  // Don't let background bleed
        groupsSC.backgroundColor = .systemBackground

        // Add target action method
        groupsSC.addTarget(self, action: #selector(toggleGroupsSC(sender:)), for: .valueChanged)

        NSLayoutConstraint.activate([
            groupsSC.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            groupsSC.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            groupsSC.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            groupsSC.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func toggleGroupsSC(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            //Suggested
            presentationState = .suggested
            break
        default:
            //My Groups
            presentationState = .myGroups
            break
        }
        reloadGroupsTable()
    }
    
    private func configureGroupsTableView() {
        groupsTableView.layer.cornerRadius = 10
        groupsTableView.sectionHeaderTopPadding = 0
        groupsTableView.delegate = self
        groupsTableView.dataSource = self
        groupsTableView.register(GroupMatchingCell.self, forCellReuseIdentifier: GroupMatchingCell.reuseIdentifier)
        groupsTableView.separatorStyle = .none
        groupsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(groupsTableView)
        
        configureGroupsTableViewActivityIndicator()
        
        NSLayoutConstraint.activate([
            groupsTableView.topAnchor.constraint(equalTo: groupsSC.bottomAnchor, constant: 10),
            groupsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            groupsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            groupsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -getTabbarHeight())
        ])
    }
    
    private func reloadGroupsTable() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        if presentationState == .myGroups && myGroups.isEmpty {
            groupsTableView.backgroundView = VKEmptyStateView(message: "No Groups")
        } else if currentUser.friends.isEmpty {
            groupsTableView.backgroundView = VKEmptyStateView(message: "No Friends: Cannot Create Suggested Groups")
        } else if presentationState == .suggested && suggestedGroups.isEmpty {
            groupsTableView.backgroundView = createEmptySuggestedGroupsView()
        } else {
            groupsTableView.backgroundView = nil
        }
        
        DispatchQueue.main.async {
            self.groupsTableView.reloadData()
        }
    }
    
    private func configureGroupsTableViewActivityIndicator() {
        groupsTableViewActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        groupsTableView.addSubview(groupsTableViewActivityIndicator)
        
        NSLayoutConstraint.activate([
            groupsTableViewActivityIndicator.centerXAnchor.constraint(equalTo: groupsTableView.centerXAnchor),
            groupsTableViewActivityIndicator.centerYAnchor.constraint(equalTo: groupsTableView.centerYAnchor)
        ])
    }
    
    private func createEmptySuggestedGroupsView() -> UIView {
        let emptySuggestedGroupsView = UIView()
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.distribution = .equalSpacing
        containerStackView.spacing = 10
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        emptySuggestedGroupsView.addSubview(containerStackView)
        
        let emptyTitle = UILabel()
        emptyTitle.text = "No Suggested Groups"
        emptyTitle.textAlignment = .center
        emptyTitle.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        emptyTitle.textColor = .lightGray
        containerStackView.addArrangedSubview(emptyTitle)
        
        let generateSuggestedGroupsButton = UIHostingController(rootView: VKGradientButton(text: "Generate ⚙️", gradientColors: [.blue.opacity(0.4), .purple.opacity(0.5)], completion: {
            GroupMatchingManager.generateSuggestedGroups(minMembersCount: 3, maxMembersCount: 6, allGroups: self.suggestedGroups + self.myGroups) { newSuggestedGroups in
                self.suggestedGroups.append(contentsOf: newSuggestedGroups)
                self.saveSuggestedGroups(for: self.suggestedGroups)
                
                DispatchQueue.main.async {
                    self.reFilterAndSortAllGroups()
                }
            }
        })).view!
        containerStackView.addArrangedSubview(generateSuggestedGroupsButton)
        
        NSLayoutConstraint.activate([
            generateSuggestedGroupsButton.heightAnchor.constraint(equalToConstant: 50),
            
            containerStackView.heightAnchor.constraint(equalToConstant: 100),
            containerStackView.centerYAnchor.constraint(equalTo: emptySuggestedGroupsView.centerYAnchor, constant: -getTabbarHeight()),
            containerStackView.leadingAnchor.constraint(equalTo: emptySuggestedGroupsView.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: emptySuggestedGroupsView.trailingAnchor)
        ])

        return emptySuggestedGroupsView
    }
    
    private func createAndObserveGroups(for groups: [VKGroup]) {
        FirebaseManager.shared.createGroups(for: groups) { error in
            if let error = error {
                self.presentVKAlert(title: "Cannot Create New Group", message: error.getMessage(), buttonTitle: "OK")
            } else {
                for group in groups {
                    group.addGroupToOtherMembers { error in
                        if let error = error {
                            self.presentVKAlert(title: "Cannot Add Users To Group", message: error.getMessage(), buttonTitle: "OK")
                        } else {
                            FirebaseManager.shared.observeGroups(for: [group.jointID]) { error in
                                if let error = error {
                                    self.presentVKAlert(title: "Cannot Observe Groups", message: error.getMessage(), buttonTitle: "OK")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func removeSuggestedGroup(for suggestedGroup: VKGroup) {
        if let selectedGroupIndex = self.suggestedGroups.firstIndex(of: suggestedGroup) {
            self.suggestedGroups.remove(at: selectedGroupIndex)
            self.saveSuggestedGroups(for: self.suggestedGroups)
            self.getSuggestedGroups()
        }
    }
}

private func getHaventGoneThroughElementSet(from mainArray: [String], subtractWith subtractingArray: [String]) -> [String] {
    let mainSet = Set(mainArray)
    let subtractingSet = Set(subtractingArray)
    let result = mainSet.subtracting(subtractingSet)
    return Array(result)
}

//MARK: - Table View Delegates
extension GroupMatchingVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        switch presentationState {
        case .suggested:
            return suggestedGroups.count
        case .myGroups:
            return myGroups.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroupMatchingCell.reuseIdentifier) as! GroupMatchingCell
        switch presentationState {
        case .suggested:
            cell.set(for: suggestedGroups[indexPath.section], groupCache: cachedUsers)
        case .myGroups:
            cell.set(for: myGroups[indexPath.section], groupCache: cachedUsers)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch presentationState {
        case .suggested:
            break
        case .myGroups:
            let group = myGroups[indexPath.section]
            presentedGroupDetailVC = GroupDetailVC(group: group, groupCache: cachedUsers)
            navigationController?.pushViewController(presentedGroupDetailVC!, animated: true)
        }
    }
    
    //Create "illusion" of Table View Spacing
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 5))
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 7.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 7.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let selectedSection = indexPath.section
        var selectedGroup: VKGroup!
        
        switch presentationState {
        case .suggested:
            selectedGroup = self.suggestedGroups[selectedSection]
            break
        case .myGroups:
            selectedGroup = self.myGroups[selectedSection]
            break
        }
        
        guard let selectedGroup = selectedGroup else { return nil }
        
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ -> UIMenu? in
            let addAction = UIAction(title: "Add To My Groups", image: UIImage(systemName: "plus")) { _ in
                //Update current user's acceptance status in joint group document in Firestore
                self.removeSuggestedGroup(for: selectedGroup)
                self.createAndObserveGroups(for: [selectedGroup])
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)) { _ in
                switch self.presentationState {
                case .suggested:
                    self.removeSuggestedGroup(for: selectedGroup)
                case .myGroups:
                    FirebaseManager.shared.deleteGroups(for: [selectedGroup]) { error in
                        if let error = error {
                            self.presentVKAlert(title: "Cannot Delete Group", message: error.getMessage(), buttonTitle: "OK")
                        } else {
                            self.reFilterAndSortAllGroups()
                        }
                    }
                }
            }
            
            var childrenItems = [UIMenuElement]()
            
            switch self.presentationState {
            case .suggested:
                childrenItems = [addAction, deleteAction]
            case .myGroups:
                childrenItems = [deleteAction]
            }
            return UIMenu(title: "", children: childrenItems)
        }
        
        return configuration
    }
}

//MARK: - AddGroupMatchingDelegate
extension GroupMatchingVC: AddGroupMatchingDelegate {
    func addGroupMatchingSuggestedGroup(ofNum selectedIntPickerOption: Int) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        GroupMatchingManager.generateSuggestedGroup(for: selectedIntPickerOption, allGroups: suggestedGroups + myGroups, person: currentUser) { group in
            if let group = group {
                let newSuggestedGroups = self.suggestedGroups + [group]
                self.saveSuggestedGroups(for: newSuggestedGroups)
                self.getSuggestedGroups()
                self.dismiss(animated: true)
            } else {
                print("Cannot create suggested group")
                self.dismiss(animated: true)
                self.presentVKAlert(title: "Cannot Create Suggested Group", message: VKError.unableToCreateSuggestedGroup.getMessage(), buttonTitle: "OK")
            }
        }
    }
    
    func addGroupMatchingCustomGroup(withFriends groupAddedFriendsUIDs: [String]) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }

        var membersAndStatus = groupAddedFriendsUIDs.reduce(into: [String: VKGroupAcceptanceStatus]()) {
            $0[$1] = .pending
        }
        //Set currentUser's status to be accepted so that it reflects that this is a custom group
        membersAndStatus[currentUser.uid] = .accepted
        let newCustomGroup = VKGroup(jointID: UUID().uuidString, name: "New Group", membersAndStatus: membersAndStatus, createdBy: currentUser.uid, dateCreated: Date())

        self.createAndObserveGroups(for: [newCustomGroup])
    }
}
