//
//  VKAddFriendVC.swift
//  Verkko
//
//  Created by Justin Wong on 7/29/23.
//

import UIKit
import SwiftUI

class VKAddFriendVC: UIViewController {
    private enum VKAddFriendState {
        case addFriends, searchFriends
    }
    
    private let informationLabel = UILabel()
    private let searchBarHeader = UIStackView()
    private let friendsSearchBar = UISearchBar()
    private let tableView = UITableView()
    private let tableViewActivityIndicator = UIActivityIndicatorView(style: .medium)
    private let backButton = UIButton(type: .custom)
    private var addFriendsButtonView = UIView()
    
    private var filteredFetchedFriends = [VKUser]()
    private var fetchedFriends: [VKUser] {
        didSet {
            getFilteredFetchedFriends()
        }
    }
    private var addedFriends: [VKUser] {
        didSet {
            getFilteredFetchedFriends()
        }
    }
    private var searchText: String = ""
    private var presentationState: VKAddFriendState = .addFriends
    private var ommittedFriends: [String]!
    private var buttonTitle: String!
    
    weak var delegate: AddGroupMatchingDelegate?
    
    init(ommittedFriends: [String] = [String](), buttonTitle: String) {
        fetchedFriends = [VKUser]()
        addedFriends = [VKUser]()
        self.buttonTitle = buttonTitle
        self.ommittedFriends = ommittedFriends
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureInformationLabel()
        configureSearchBarHeader()
        configureAddedFriendsTableView()
        configureTableViewActivityIndicatorView()
        configureAddFriendsButton()
        
        reloadAddedFriendsTable()
    }
    
    private func fetchFriends() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        tableViewActivityIndicator.startAnimating()
        FirebaseManager.shared.getFriends { result in
            self.tableViewActivityIndicator.stopAnimating()
            switch result {
            case .success(let friendAssociatedDatas):
                let fetchedFriendUsers = friendAssociatedDatas.getFriendUsers()
                //Add to fetchedFriend to omitted friends if they block current user
                let friendsThatDontBlockCurrentUser = Set(fetchedFriendUsers.filter { !$0.blockedFriends.contains(currentUser.uid) }.map{ $0.uid })
                let ommittedFriendsSet = Set(self.ommittedFriends)
                let fetchedFriendsNotInGroupUIDs = Array(friendsThatDontBlockCurrentUser.subtracting(ommittedFriendsSet))
                let fetchedFriendsNotInGroup = fetchedFriendUsers.filter { fetchedFriendsNotInGroupUIDs.contains($0.uid) }
                self.fetchedFriends = fetchedFriendsNotInGroup
            case .failure(let error):
                self.presentVKAlert(title: "Error Fetching Friends", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    private func getFilteredFetchedFriends() {
        let fetchedFriendsSet = Set(fetchedFriends)
        let addedFriendsSet = Set(addedFriends)
        let fetchedFriendsWithoutAddedFriends = Array(fetchedFriendsSet.subtracting(addedFriendsSet))
        
        if searchText.isEmpty {
            filteredFetchedFriends = fetchedFriendsWithoutAddedFriends
        } else {
            filteredFetchedFriends = fetchedFriendsWithoutAddedFriends.filter{ $0.getFullName().lowercased().trimmingCharacters(in: .whitespacesAndNewlines).contains(searchText)}
        }
        
        filteredFetchedFriends.sortAlphabeticallyAscendingByFullName()
       
        reloadAddedFriendsTable()
    }
    
    @objc private func togglePresentationState() {
        if presentationState == .addFriends {
            searchBarHeader.insertArrangedSubview(backButton, at: 0)
            presentationState = .searchFriends
            self.backButton.layer.opacity = 1.0
            
        } else {
            UIView.animate(withDuration: 0.2, delay: 0.0, animations: {
                self.backButton.layer.opacity = 0.0
            }) { _ in
                self.backButton.removeFromSuperview()
            }
            friendsSearchBar.resignFirstResponder()
            presentationState = .addFriends
        }
        updateInformationLabel()
        reloadAddedFriendsTable()
    }
    
    private func configureInformationLabel() {
        informationLabel.textColor = UIColor.systemGreen
        informationLabel.font = UIFont.systemFont(ofSize: 16)
        informationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(informationLabel)
        
        NSLayoutConstraint.activate([
            informationLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            informationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func updateInformationLabel() {
        switch presentationState {
        case .addFriends:
            informationLabel.text = "\(addedFriends.count) \(addedFriends.count == 1 ? "Friend" : "Friends") Added"
        case .searchFriends:
            informationLabel.text = "\(filteredFetchedFriends.count) Matching \(filteredFetchedFriends.count == 1 ? "Result" : "Results")"
        }
    }
    
    private func configureSearchBarHeader() {
        searchBarHeader.axis = .horizontal
        searchBarHeader.spacing = 10
        searchBarHeader.distribution = .fill
        searchBarHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBarHeader)
        
        backButton.setImage(UIImage(systemName: "chevron.left.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30)), for: .normal)
        backButton.tintColor = .systemGreen.withAlphaComponent(0.7)
        backButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        backButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        backButton.addTarget(self, action: #selector(togglePresentationState), for: .touchUpInside)
        
        searchBarHeader.addArrangedSubview(createFriendsSearchBar())
        
        NSLayoutConstraint.activate([
            searchBarHeader.topAnchor.constraint(equalTo: informationLabel.bottomAnchor, constant: 5),
            searchBarHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchBarHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }
    
    private func createFriendsSearchBar() -> UISearchBar {
        friendsSearchBar.placeholder = "Search for a friend"
        friendsSearchBar.autocorrectionType = .no
        friendsSearchBar.searchBarStyle = .minimal
        friendsSearchBar.autocapitalizationType = .none
        friendsSearchBar.tintColor = UIColor.black
        friendsSearchBar.setContentHuggingPriority(.defaultLow, for: .horizontal)
        friendsSearchBar.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        friendsSearchBar.delegate = self
        friendsSearchBar.translatesAutoresizingMaskIntoConstraints = false
        return friendsSearchBar
    }
    
    private func configureAddedFriendsTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VKAvatarAndNameCell.self, forCellReuseIdentifier: VKAvatarAndNameCell.reuseID)
        tableView.register(VKAddAvatarAndNameCell.self, forCellReuseIdentifier: VKAddAvatarAndNameCell.subclassIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBarHeader.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureTableViewActivityIndicatorView() {
        tableViewActivityIndicator.tintColor = .lightGray
        tableViewActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(tableViewActivityIndicator)
        
        NSLayoutConstraint.activate([
            tableViewActivityIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            tableViewActivityIndicator.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 10),
            tableViewActivityIndicator.widthAnchor.constraint(equalToConstant: 30),
            tableViewActivityIndicator.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func reloadAddedFriendsTable() {
        switch presentationState {
        case .addFriends:
            if addedFriends.isEmpty {
                tableView.backgroundView = VKEmptyStateView(message: "No Friends Added To Group Yet")
            } else {
                tableView.backgroundView = nil
            }
        case .searchFriends:
            if fetchedFriends.isEmpty {
                tableView.backgroundView = VKEmptyStateView(message: "No Friends Available")
            } else if filteredFetchedFriends.isEmpty {
                tableView.backgroundView = VKEmptyStateView(message: "No Matching Search Results")
            } else {
                tableView.backgroundView = nil
            }
        }
        
        updateInformationLabel()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func configureAddFriendsButton() {
        addFriendsButtonView = UIHostingController(rootView: VKGradientButton(text: buttonTitle, gradientColors: [.blue.opacity(0.4), .green.opacity(0.5)], completion: {
            
        })).view!
        
        let tapAddCustomGroupButtonGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(createCustomGroup))
        addFriendsButtonView.addGestureRecognizer(tapAddCustomGroupButtonGestureRecognizer)
        addFriendsButtonView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addFriendsButtonView)
        
        NSLayoutConstraint.activate([
            addFriendsButtonView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            addFriendsButtonView.widthAnchor.constraint(equalToConstant: 300),
            addFriendsButtonView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addFriendsButtonView.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    @objc private func createCustomGroup() {
        delegate?.addGroupMatchingCustomGroup(withFriends: addedFriends.map{ $0.uid })
    }
}

//MARK - Table View Delegates
extension VKAddFriendVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        switch presentationState {
        case .addFriends:
            return addedFriends.count
        case .searchFriends:
            return filteredFetchedFriends.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        switch presentationState {
        case .addFriends:
            let cell = tableView.dequeueReusableCell(withIdentifier: VKAvatarAndNameCell.reuseID) as! VKAvatarAndNameCell
            cell.set(for: addedFriends[indexPath.section])
            return cell
        case .searchFriends:
            let cell = tableView.dequeueReusableCell(withIdentifier: VKAddAvatarAndNameCell.subclassIdentifier) as! VKAddAvatarAndNameCell
            cell.set(for: filteredFetchedFriends[indexPath.section])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard presentationState == .searchFriends else { return }
        let selectedFriend = filteredFetchedFriends[indexPath.section]
        addedFriends.append(selectedFriend)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard presentationState == .addFriends else { return }
        
        if editingStyle == .delete {
            addedFriends.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .left)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
}

//MARK: - UISearchBarDelegate
extension VKAddFriendVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        getFilteredFetchedFriends()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        fetchFriends()
        togglePresentationState()
    }
}

//MARK: - VKAddAvatarAndNameCell
class VKAddAvatarAndNameCell: VKAvatarAndNameCell {
    static let subclassIdentifier = "VKAddAvatarAndNameCell"
    
    private let addButton = UIButton(type: .custom)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func set(for user: VKUser, widthHeight: CGFloat = 45) {
        super.set(for: user, widthHeight: widthHeight)
    }
    
    private func configureCell() {
        selectionStyle = .none
        
        addButton.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20)), for: .normal)
        addButton.tintColor = .systemGreen
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }
}

