//
//  FriendsVC.swift
//  Verkko
//
//  Created by Justin Wong on 5/24/23.
//

import UIKit
import FirebaseFirestore

class FriendsVC: UIViewController {
    private var friendsTableView = UITableView()
    private let friendsTableActivityIndicator = UIActivityIndicatorView(style: .medium)
    private var searchBar: UISearchBar!
    
    private var allFriends = [VKUser]() {
        didSet {
            self.filterFriends(with: self.searchQuery)
        }
    }
    
    private var filteredFriends = [VKUser]()
    private var cachedFriends = VKFriendCache()
    private var searchQuery = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUser), name: .updatedCurrentUser, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFriendInfo), name: .updatedFriendInfo, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFriend), name: .updatedFriend, object: nil)
        
        setConfigurationForMainVC()
        configureSearchBarView()
        configureFriendsTableView()
        configureFriendsTableActivityIndicator()
        
        // Uncomment to test adding friends
//        let tappedLocations = ["lat": [43.72298, 43.72409], "lon": [10.39668, 10.39494]]
//        let fields = [VKConstants.currentStreak: 1, VKConstants.maxStreak: 1, VKConstants.totalTaps: 1, VKConstants.tappedTimes: [Date(), Date()], VKConstants.tappedLocations: tappedLocations, VKConstants.firstTapDate: "5/14/23", VKConstants.mutualFriends: [String]()] as [String : Any]
//
//        addFriend(friendUID: "lnqinz4DadMJEKZTtnYZxTCR2mq2", with: fields)
    }
    
    // Adds a friend with uid friendUID to current user
//    private func addFriend(friendUID: String, with fields: [String : Any]) {
//        FirebaseManager.shared.initializeFriendship(userUID: currentUser.uid, friendUID: friendUID, with: fields) { error in
//            if let error = error {
//                self.presentVKAlert(title: "Failed to Initialize", message: error.localizedDescription, buttonTitle: "OK")
//            } else {
//                self.updateFriendsList(with: friendUID)
//            }
//        }
//    }
//
//    // Updates allFriends and filteredFriends when a currentUser gets a new friend
//    private func updateFriendsList(with uid: String) {
//        FirebaseManager.shared.fetchUserDocument(for: uid) { result in
//            switch result {
//            case .success(let newFriend):
//                self.allFriends.append(newFriend)
//                self.filteredFriends.append(newFriend)
//            case .failure(_):
//                print("Failure in fetching user document")
//            }
//        }
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        getUpdatedFriendList(for: currentUser)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //Remove All Listeners
//        FirebaseManager.shared.removeAllFriendListeners()
//        FirebaseManager.shared.removeAllFriendInfoListeners()
    }
    
    // Gets a list of all of current user's friends as VKUser objects - call as little as possible
    private func getUpdatedFriendList(for user: VKUser) {
        // Only start central refreshing indicator if its not user initiated
        self.friendsTableActivityIndicator.startAnimating()
        
        cachedFriends.fetchFriendsAndInfo(for: user) { result in
            self.friendsTableActivityIndicator.stopAnimating()
            
            switch result {
            case .success(let friendAssociatedDatas):
                self.allFriends = friendAssociatedDatas.getFriendUsers()
                self.allFriends.sortAlphabeticallyAscendingByFullName()
                
                let friendInfoJointIDs = friendAssociatedDatas.getFriendInfos().getJointIDs()
                //Observe Friend VKUsers
                FirebaseManager.shared.observeFriends(for: self.allFriends.getUIDs()) { error in
                    if let error = error {
                        self.presentVKAlert(title: "Cannot Observe Friend", message: error.localizedDescription, buttonTitle: "OK")
                    }
                }
                
                print("FriendInfoJointIDS: \(friendInfoJointIDs)")
                //Observe FriendInfos
                FirebaseManager.shared.observeFriendInfos(for: friendInfoJointIDs) { error in
                    if let error = error {
                        self.presentVKAlert(title: "Cannot Observe Friend Info", message: error.localizedDescription, buttonTitle: "OK")
                    }
                }
            case .failure(let error):
                self.presentVKAlert(title: "Failed To Retrieve Friends", message: error.localizedDescription, buttonTitle: "OK")
                return
            }
        }
    }
    
    private func configureSearchBarView() {
        let VKSearchBar = UISearchBar()
        VKSearchBar.placeholder = "Search"
        
        searchBar = VKSearchBar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.autocorrectionType = .no
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.tintColor = .systemGreen
        
        view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func configureFriendsTableView() {
        friendsTableView = UITableView()
        friendsTableView.backgroundColor = .systemBackground
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        friendsTableView.register(FriendsCell.self, forCellReuseIdentifier: FriendsCell.reuseID)
        friendsTableView.translatesAutoresizingMaskIntoConstraints = false
        friendsTableView.separatorStyle = .none
        view.addSubview(friendsTableView)
        
        NSLayoutConstraint.activate([
            friendsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 5),
            friendsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            friendsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            friendsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
    
    private func configureFriendsTableActivityIndicator() {
        friendsTableActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        friendsTableView.addSubview(friendsTableActivityIndicator)

        NSLayoutConstraint.activate([
            friendsTableActivityIndicator.centerXAnchor.constraint(equalTo: friendsTableView.centerXAnchor),
            friendsTableActivityIndicator.centerYAnchor.constraint(equalTo: friendsTableView.centerYAnchor)
        ])
    }
    
    private func filterFriends(with searchWord: String) {
        searchQuery = searchWord
        
        if searchWord.isEmpty {
            searchQuery = ""
            filteredFriends = allFriends
        } else {
            filteredFriends = allFriends.filter({ $0.firstName.lowercased().contains(searchWord.lowercased()) || $0.lastName.lowercased().contains(searchWord.lowercased()) })
        }
        
        reloadTableView()
    }
    
    private func reloadTableView() {
        if allFriends.isEmpty {
            friendsTableView.backgroundView = VKEmptyStateView(message: "No Friends Yet.")
            searchBar.isUserInteractionEnabled = false
            searchBar.alpha = 0.5
        } else if filteredFriends.isEmpty {
            friendsTableView.backgroundView = VKEmptyStateView(message: "No Users Found.")
            searchBar.isUserInteractionEnabled = true
            searchBar.alpha = 1
        } else {
            friendsTableView.backgroundView = nil
            searchBar.isUserInteractionEnabled = true
            searchBar.alpha = 1
        }
        
        DispatchQueue.main.async {
            self.friendsTableView.reloadData()
        }
    }
    
    @objc func updateUser(_ notification: Notification) {
        if let updatedUser = notification.object as? VKUser {
            print("Updated Current User: \(updatedUser)")
            getUpdatedFriendList(for: updatedUser)
            
            if let presentingVC = navigationController?.topViewController as? FriendProfileVC {
                presentingVC.updateCurrentUser(with: updatedUser)
            }
        }
    }
    
    @objc func updateFriendInfo(_ notification: Notification) {
        if let updatedFriendInfo = notification.object as? VKFriendInfo {
            let friendsSet = Set(updatedFriendInfo.friends)
            guard let currentUser = FirebaseManager.shared.currentUser, friendsSet.count == 2 else { return }
            
            if let friendUID = Array(friendsSet.subtracting(Set([currentUser.uid]))).first,
               let oldFriendInfo = cachedFriends.value(forKey: friendUID) {
       
                FirebaseManager.shared.getLastTappedAddress(friendInfo: updatedFriendInfo) { result in
                    switch result {
                    case .success(let address):
                        let newFriendAssociatedData = VKFriendAssociatedData(friend: oldFriendInfo.friend, friendInfo: updatedFriendInfo, mutualFriends: oldFriendInfo.mutualFriends, lastTapAddress: address)
                        self.cachedFriends.insert(newFriendAssociatedData, forKey: friendUID)
                        self.reloadTableView()
                    case .failure(let error):
                        self.presentVKAlert(title: "Cannot Update Friend Profile", message: error.localizedDescription, buttonTitle: "OK")
                    }
                }
            }
            
            if let presentingVC = navigationController?.topViewController as? FriendProfileVC {
                presentingVC.updateFriendInfo(with: updatedFriendInfo)
            }
        }
    }
    
    @objc func updateFriend(_ notification: Notification) {
        if let presentingVC = navigationController?.topViewController as? FriendProfileVC, let updatedFriend = notification.object as? VKUser {
            presentingVC.updateFriendUser(with: updatedFriend)
        }
    }
}

//MARK: - Table View Delegates
extension FriendsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchQuery.isEmpty ? allFriends.count : filteredFriends.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend = filteredFriends[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendsCell.reuseID) as! FriendsCell

        // Configure cell info for given friend
        if let friendAssociatedData = cachedFriends.value(forKey: friend.uid) {
            cell.set(for: friend, withInfo: friendAssociatedData)
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friend = filteredFriends[indexPath.row]
        
        if let friendAssociatedData = cachedFriends.value(forKey: friend.uid) {
            let vc = FriendProfileVC(friend: friend, friendAssociatedData: friendAssociatedData)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

//MARK: - UISearchBarDelegate
extension FriendsVC: UISearchBarDelegate  {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchQuery = searchText
        self.friendsTableActivityIndicator.startAnimating()
        filterFriends(with: searchText)
        self.friendsTableActivityIndicator.stopAnimating()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        
        searchQuery = ""
        filterFriends(with: searchQuery)
    }
}
    
