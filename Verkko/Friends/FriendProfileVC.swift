//
//  FriendProfileVC.swift
//  Verkko
//
//  Created by Mihir Rao on 5/29/23.
//

import UIKit
import MapKit
import Contacts
import ContactsUI
import MessageUI
import FirebaseFirestore

class FriendProfileVC: UIViewController {
    private let blockedFriendIndicatorView = UIView()
    private let wholeProfileScrollView = UIScrollView()
    private let topSectionHStackView = UIStackView()
    private let vInfoStackView = UIStackView()
    private var mutualFriendsView: UIView?
    private var contactInfoContentView: FriendsHeaderContentView!
    private let contactInfoTableView = UITableView()
    private let segmentControllerView = UIView()
    private let statisticsViewContentContainerView = UIView()
    private var interestsHeaderContentView: FriendsHeaderContentView!
    private var statsHeaderContentView: FriendsHeaderContentView!
    private let statsTableView = UITableView()
    private var tapMapHeaderContentView: FriendsHeaderContentView!
    private var photosContentView: UIView?
    private let loadingPhotosIndicator = UIActivityIndicatorView(style: .medium)
    private let expandImageView = UIImageView(image: UIImage(systemName: "arrow.up.left.and.arrow.down.right.circle.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 28, weight: .regular))))
    
    private let headerLabelFontSize: CGFloat = 15
    private let hPadding: CGFloat = 15
    private let contactInfoTitles = ["Phone Number",
                                     "Email",
                                     "Birthday"]
    private let statTitles = ["Current Daily Streak",
                              "Max Daily Streak",
                              "Current Weekly Streak",
                              "Max Weekly Streak",
                              "Total Taps",
                              "First Tap"]
    private let noPhotosView = UIView()
    
    private var friend: VKUser!
    private var friendAssociatedData: VKFriendAssociatedData! {
        didSet {
            friendSharingPermissions = friendAssociatedData.friendInfo.sharingPermissions?[friend.uid]
        }
    }
    
    lazy private var friendSharingPermissions: VKSharingPermission! = {
        return friendAssociatedData.friendInfo.sharingPermissions?[friend.uid]
    }()
    
    init(friend: VKUser, friendAssociatedData: VKFriendAssociatedData) {
        self.friend = friend
        self.friendAssociatedData = friendAssociatedData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureScrollView()
        configureBlockedFriendIndicatorView()
        setConfigurationForMainVC()
        configureNavBarSettings()
        configureTopSectionView()
        configureSegmentControl()
        configureStatisticsViewContentContainerView()
        updateBlockedFriendIndicatorView()
        
        // Show loading indicator when fetching photos
        loadingPhotosIndicator.translatesAutoresizingMaskIntoConstraints = false
        wholeProfileScrollView.addSubview(loadingPhotosIndicator)
        
        NSLayoutConstraint.activate([
            loadingPhotosIndicator.centerYAnchor.constraint(equalTo: segmentControllerView.bottomAnchor, constant: 35),
            loadingPhotosIndicator.centerXAnchor.constraint(equalTo: segmentControllerView.centerXAnchor),
        ])
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
       if (traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)) {
           setExpandImageViewTintColor()
       }
    }
    
    //MARK: - Update 
    func updateFriendInfo(with updatedFriendInfo: VKFriendInfo) {
        FirebaseManager.shared.getUsers(for: updatedFriendInfo.mutualFriends) { result in
            switch result {
            case .success(let mutualFriends):
                FirebaseManager.shared.getLastTappedAddress(friendInfo: updatedFriendInfo) { result in
                    switch result {
                    case .success(let address):
                        self.friendAssociatedData = VKFriendAssociatedData(friend: self.friendAssociatedData.friend, friendInfo: updatedFriendInfo, mutualFriends: mutualFriends, lastTapAddress: address)
                        self.updateUI()
                    case .failure(let error):
                        self.presentVKAlert(title: "Cannot Update Friend Profile", message: error.localizedDescription, buttonTitle: "OK")
                    }
                }
            case .failure(let error):
                self.presentVKAlert(title: "Cannot Update Friend Profile", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    func updateFriendUser(with updatedFriend: VKUser) {
        friend = updatedFriend

        updateUI()
    }
    
    func updateCurrentUser(with updatedCurrentUser: VKUser) {
        updateBlockedFriendIndicatorView()
        configureNavBarSettings()
    }
    
    private func updateUI() {
        interestsHeaderContentView.updateContentView(with: createInterestsHorizontalScrollView())
        tapMapHeaderContentView.updateContentView(with: configureContentTapMapView())
        
        if let photosContentView = photosContentView {
            photosContentView.removeFromSuperview()
            configurePhotosView()
        }
        
        if friendAssociatedData.mutualFriends.count > 0 {
            mutualFriendsView?.removeFromSuperview()
            mutualFriendsView = configureMutualFriendsView()
            vInfoStackView.addArrangedSubview(mutualFriendsView!)
        }
       
        DispatchQueue.main.async {
            self.contactInfoTableView.reloadData()
            self.statsTableView.reloadData()
        }
    }
    
    private func configureScrollView() {
        wholeProfileScrollView.contentSize = CGSize(width: view.frame.size.width, height: view.frame.size.height * 1.25)
        wholeProfileScrollView.showsVerticalScrollIndicator = false
        wholeProfileScrollView.showsHorizontalScrollIndicator = false
        wholeProfileScrollView.bounces = true
        wholeProfileScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wholeProfileScrollView)
        
        NSLayoutConstraint.activate([
            wholeProfileScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            wholeProfileScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            wholeProfileScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            wholeProfileScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    //MARK: Nav Bar Settings
    private func configureNavBarSettings() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        navigationController?.navigationBar.tintColor = .systemGreen
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
        
        let friendFirstName = friendAssociatedData.friend.firstName
        var moreMenuActions = [
            UIAction(title: "Add To Contacts", image: UIImage(systemName: "person.crop.circle.badge.plus")) { _ in
                self.addFriendToContacts()
            }
        ]
        
        if friendSharingPermissions.isPhoneNumberVisible {
            moreMenuActions.insert(UIAction(title: "Call \(friendFirstName)", image: UIImage(systemName: "phone")) { _ in
                self.callFriend()
            }, at: 0)
        }
        
        if MFMessageComposeViewController.canSendText() && friendSharingPermissions.isPhoneNumberVisible {
            moreMenuActions.insert(UIAction(title: "Message \(friendFirstName)", image: UIImage(systemName: "message")) { action in
                self.messageFriend()
            }, at: 1)
        }
        
        if MFMailComposeViewController.canSendMail() && friendSharingPermissions.isEmailVisible {
            moreMenuActions.insert(UIAction(title: "Email \(friendFirstName)", image: UIImage(systemName: "envelope")) { action in
                self.emailFriend()
            }, at: 2)
        }
        
        if currentUser.blockedFriends.contains(friend.uid) {
            moreMenuActions.append(UIAction(title: "Unblock Friend", image: UIImage(systemName: "hand.raised.slash")) { _ in
                self.unblockFriend()
            })
        } else {
            moreMenuActions.append(UIAction(title: "Block Friend", image: UIImage(systemName: "hand.raised"), attributes: .destructive) { _ in
                self.blockFriend()
            })
        }
        
        let moreMenu = UIMenu(title: "", children: moreMenuActions)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), primaryAction: nil, menu: moreMenu)
        navigationItem.rightBarButtonItem?.tintColor = .systemGreen
        
        title = "Profile"
    }
    
    private func addFriendToContacts() {
        let contactStore = CNContactStore()
        //Request Access to Contacts
        contactStore.requestAccess(for: .contacts) { status, error in
            if let error = error {
                self.presentVKAlert(title: "Privacy Request Error", message: "\(error.localizedDescription)", buttonTitle: "OK")
            } else {
                if status {
                    //user did authorized
                    let newContact = CNMutableContact()
                    
                    newContact.imageData = self.friend.profilePictureData
                    newContact.givenName =  self.friend.firstName
                    newContact.familyName = self.friend.lastName
                    
                    if self.friendSharingPermissions.isPhoneNumberVisible {
                        newContact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: self.friend.phoneNumber))]
                    }
                   
                    if self.friendSharingPermissions.isEmailVisible {
                        let homeEmail = CNLabeledValue(label: CNLabelHome, value: self.friend.email as NSString)
                        newContact.emailAddresses = [homeEmail]
                    }
                    
                    if self.friendSharingPermissions.isBirthdayVisible {
                        var friendBirthdayDateComponents = DateComponents()
                        friendBirthdayDateComponents.day = self.friend.birthday.getDayComponent()
                        friendBirthdayDateComponents.month = self.friend.birthday.getMonthComponent()
                        friendBirthdayDateComponents.year = self.friend.birthday.getYearComponent()
                        newContact.birthday = friendBirthdayDateComponents
                    }
                    
                    DispatchQueue.main.async {
                        let contactVC = CNContactViewController(forNewContact: newContact)
                        contactVC.title = "Add \(self.friend.firstName)"
                        contactVC.contactStore = contactStore
                        let contactVCNavigationController = UINavigationController(rootViewController: contactVC)
                        contactVC.delegate = self
                       
                        self.present(contactVCNavigationController, animated: true)
                    }
                   
                } else {
                    //user did not authorize
                    self.presentVKAlert(title: "Request Required", message: "In order to add \(self.friend.firstName) to your Contacts. Verkko must request permission.", buttonTitle: "OK")
                }
            }
        }
    }
    
    private func callFriend() {
        if let url = URL(string: "tel://\(friendAssociatedData.friend.phoneNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func messageFriend() {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self
        messageComposeVC.recipients = [friendAssociatedData.friend.phoneNumber]
        messageComposeVC.body = "Hi \(friendAssociatedData.friend.firstName) 👋!"
        present(messageComposeVC, animated: true)
    }
    
    private func emailFriend() {
        let emailComposeVC = MFMailComposeViewController()
        emailComposeVC.mailComposeDelegate = self
        emailComposeVC.setToRecipients([friendAssociatedData.friend.email])
        emailComposeVC.setSubject("Hello 👋!")
        present(emailComposeVC, animated: true)
    }
    
    private func unblockFriend() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        FirebaseManager.shared.updateUserData(for: currentUser.uid, with: [
            VKConstants.blockedFriends: FieldValue.arrayRemove([self.friend.uid])
        ]) { error in
            if let error = error {
                self.presentVKAlert(title: "Cannot Unblock Friend", message: error.getMessage(), buttonTitle: "OK")
            }
        }
    }
    
    private func blockFriend() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        let blockFriendConfirmationAlert = UIAlertController(title: "Block \(friend.firstName)?",
                                            message: "Once blocked, you will not be able to view \(friend.firstName)'s Moments Feed and add each other to groups. Are you sure you want to block \(friend.firstName)?",
                                            preferredStyle: .alert)
        blockFriendConfirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        blockFriendConfirmationAlert.addAction(UIAlertAction(title: "Block", style: .default, handler: {_ in
            FirebaseManager.shared.updateUserData(for: currentUser.uid, with: [
                VKConstants.blockedFriends: FieldValue.arrayUnion([self.friend.uid])
            ]) { error in
                if let error = error {
                    self.presentVKAlert(title: "Cannot Block Friend", message: error.getMessage(), buttonTitle: "OK")
                }
            }
        }))
        present(blockFriendConfirmationAlert, animated: true)
    }
    
    private func configureBlockedFriendIndicatorView() {
        blockedFriendIndicatorView.backgroundColor = .systemRed.withAlphaComponent(0.7)
        blockedFriendIndicatorView.layer.zPosition = 0
        blockedFriendIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        blockedFriendIndicatorView.isHidden = true
        view.addSubview(blockedFriendIndicatorView)
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        blockedFriendIndicatorView.addSubview(stackView)
        
        let blockedImageView = UIImageView(image: UIImage(systemName: "hand.raised.fill"))
        blockedImageView.tintColor = .white
        blockedImageView.contentMode = .scaleAspectFit
        stackView.addArrangedSubview(blockedImageView)
        
        let blockedFriendLabel = UILabel()
        blockedFriendLabel.text = "Blocked"
        blockedFriendLabel.textColor = .white
        stackView.addArrangedSubview(blockedFriendLabel)
        
        NSLayoutConstraint.activate([
            blockedFriendIndicatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            blockedFriendIndicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blockedFriendIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blockedFriendIndicatorView.heightAnchor.constraint(equalToConstant: 30),
            
            stackView.centerXAnchor.constraint(equalTo: blockedFriendIndicatorView.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: blockedFriendIndicatorView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: blockedFriendIndicatorView.bottomAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 100),
            
            blockedImageView.widthAnchor.constraint(equalToConstant: 20),
            blockedImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func updateBlockedFriendIndicatorView() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        if currentUser.blockedFriends.contains(friend.uid) {
            blockedFriendIndicatorView.isHidden = false
        } else {
            blockedFriendIndicatorView.isHidden = true
        }
    }
    
    //MARK: Top PFP and Name Section View
    private func configureTopSectionView() {
        topSectionHStackView.translatesAutoresizingMaskIntoConstraints = false
        topSectionHStackView.axis = .horizontal
        topSectionHStackView.spacing = 10
        topSectionHStackView.alignment = .center
        topSectionHStackView.distribution = .fill
        wholeProfileScrollView.addSubview(topSectionHStackView)
        
        let profileImageWidthAndHeight: CGFloat = 110
        let profileImageView = VKProfileImageView(user: friend, widthHeight: profileImageWidthAndHeight)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        topSectionHStackView.addArrangedSubview(profileImageView)
        
        // Stack view for name and mutuals
        vInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        vInfoStackView.axis = .vertical
        vInfoStackView.spacing = 8
        topSectionHStackView.addArrangedSubview(vInfoStackView)
        
        let nameLabel = UILabel()
        nameLabel.text = friend.getFullName()
        nameLabel.textColor = .systemGreen
        nameLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        vInfoStackView.addArrangedSubview(nameLabel)

        if friendAssociatedData.mutualFriends.count > 0 {
            mutualFriendsView = configureMutualFriendsView()
            vInfoStackView.addArrangedSubview(mutualFriendsView!)
        }
        
        NSLayoutConstraint.activate([
            topSectionHStackView.topAnchor.constraint(equalTo: wholeProfileScrollView.topAnchor, constant: 20),
            topSectionHStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: hPadding - 5),
            topSectionHStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -(hPadding - 5)),
            topSectionHStackView.heightAnchor.constraint(equalToConstant: 135),
            
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
        ])
    }
    
    private func configureMutualFriendsView() -> UIView {
        let profileImageSize: CGFloat = 26
        
        let mutualFriendsView = UIView()
        mutualFriendsView.translatesAutoresizingMaskIntoConstraints = false
        
        let mutualFriendsProfileImageStackView = UIStackView()
        mutualFriendsProfileImageStackView.axis = .horizontal
        mutualFriendsProfileImageStackView.spacing = -14
        mutualFriendsProfileImageStackView.translatesAutoresizingMaskIntoConstraints = false
        mutualFriendsView.addSubview(mutualFriendsProfileImageStackView)
        
        // Fetch and display only first 2 mutual friends
        let maxIndex = min(2, friendAssociatedData.mutualFriends.count)
        let shortenedMutualFriends = Array(friendAssociatedData.getMutualFriendUIDS()[0..<maxIndex])
        
        FirebaseManager.shared.getUsers(for: shortenedMutualFriends) { result in
            switch result {
            case .success(let shortenedMutualFriendUsers):
                for fetchedMutualUser in shortenedMutualFriendUsers {
                    let mutualFriendProfileImageView = VKProfileImageView(user: fetchedMutualUser, widthHeight: profileImageSize)
                    mutualFriendProfileImageView.addImageBorder(borderColor: .systemBackground)
                    mutualFriendsProfileImageStackView.addArrangedSubview(mutualFriendProfileImageView)
                    
                    NSLayoutConstraint.activate([
                        mutualFriendProfileImageView.widthAnchor.constraint(equalToConstant: profileImageSize),
                        mutualFriendProfileImageView.heightAnchor.constraint(equalToConstant: profileImageSize)
                    ])
                }
                
                let mutualFriendsLabel = UILabel()
                mutualFriendsLabel.font = .systemFont(ofSize: 12, weight: .regular)
                mutualFriendsLabel.text = Utils.getFormattedMutualFriendsString(mutualFriends: shortenedMutualFriendUsers, totalMutualFriends: self.friendAssociatedData.mutualFriends.count)
                mutualFriendsLabel.numberOfLines = 0
                mutualFriendsLabel.lineBreakMode = .byWordWrapping
                mutualFriendsLabel.translatesAutoresizingMaskIntoConstraints = false
                mutualFriendsView.addSubview(mutualFriendsLabel)
                
                NSLayoutConstraint.activate([
                    mutualFriendsLabel.centerYAnchor.constraint(equalTo: mutualFriendsView.centerYAnchor),
                    mutualFriendsLabel.leadingAnchor.constraint(equalTo: mutualFriendsProfileImageStackView.trailingAnchor, constant: 5),
                    mutualFriendsLabel.trailingAnchor.constraint(equalTo: mutualFriendsView.trailingAnchor, constant: -10)
                ])
            case .failure(let error):
                self.presentVKAlert(title: "Error Fetching Mutual Friends", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
        
        NSLayoutConstraint.activate([
            mutualFriendsView.heightAnchor.constraint(equalToConstant: profileImageSize),
            
            mutualFriendsProfileImageStackView.topAnchor.constraint(equalTo: mutualFriendsView.topAnchor),
            mutualFriendsProfileImageStackView.leadingAnchor.constraint(equalTo: mutualFriendsView.leadingAnchor),
            mutualFriendsView.widthAnchor.constraint(equalToConstant: 50),
            mutualFriendsView.bottomAnchor.constraint(equalTo: mutualFriendsView.bottomAnchor)
        ])
        
        return mutualFriendsView
    }
    
    //MARK: Navigation View
    private func configureSegmentControl() {
        segmentControllerView.translatesAutoresizingMaskIntoConstraints = false
        wholeProfileScrollView.addSubview(segmentControllerView)
        
        let items = ["Statistics", "Photos"]
        let segmentController = UISegmentedControl(items: items)
        segmentController.tintColor = .white
        segmentController.selectedSegmentIndex = 0
        segmentController.addTarget(self, action: #selector(self.segmentedValueChanged(_:)), for: .valueChanged)
        segmentController.translatesAutoresizingMaskIntoConstraints = false
        segmentControllerView.addSubview(segmentController)
        
        NSLayoutConstraint.activate([
            segmentControllerView.topAnchor.constraint(equalTo: topSectionHStackView.bottomAnchor, constant: 15),
            segmentControllerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            segmentControllerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            segmentController.topAnchor.constraint(equalTo: segmentControllerView.topAnchor),
            segmentController.leadingAnchor.constraint(equalTo: segmentControllerView.leadingAnchor, constant: 10),
            segmentController.trailingAnchor.constraint(equalTo: segmentControllerView.trailingAnchor, constant: -10),
            segmentController.bottomAnchor.constraint(equalTo: segmentControllerView.bottomAnchor),
        ])
    }
    
    private func configureStatisticsViewContentContainerView() {
        statisticsViewContentContainerView.translatesAutoresizingMaskIntoConstraints = false
        wholeProfileScrollView.addSubview(statisticsViewContentContainerView)

        configureContactInfoView()
        configureInterestsView()
        configureUserTapMapView()
        configureStatsView()
        
        let config = UIImage.SymbolConfiguration(pointSize: 70, weight: .ultraLight)
        let noPhotosIcon = UIImageView(image: UIImage(systemName: "camera", withConfiguration: config))
        noPhotosIcon.tintColor = .systemGray
        noPhotosIcon.translatesAutoresizingMaskIntoConstraints = false
        noPhotosView.addSubview(noPhotosIcon)

        let noPhotosLabel = UILabel()
        noPhotosLabel.text = "No Photos Yet"
        noPhotosLabel.font = .systemFont(ofSize: 20, weight: .bold)
        noPhotosLabel.textColor = .systemGray
        noPhotosLabel.translatesAutoresizingMaskIntoConstraints = false
        noPhotosView.addSubview(noPhotosLabel)
        
        NSLayoutConstraint.activate([
            noPhotosIcon.topAnchor.constraint(equalTo: noPhotosView.topAnchor, constant: 80),
            noPhotosIcon.centerXAnchor.constraint(equalTo: noPhotosView.centerXAnchor),
            noPhotosLabel.centerXAnchor.constraint(equalTo: noPhotosView.centerXAnchor),
            noPhotosLabel.topAnchor.constraint(equalTo: noPhotosIcon.bottomAnchor, constant: 10),
            statisticsViewContentContainerView.topAnchor.constraint(equalTo: segmentControllerView.bottomAnchor, constant: 20),
            statisticsViewContentContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            statisticsViewContentContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            statisticsViewContentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    //MARK: - Contacts View
    private func configureContactInfoView() {
        let contactInfoLabel = UILabel()
        contactInfoLabel.text = "Contact Information"
        contactInfoLabel.font = .systemFont(ofSize: VKConstants.headerLabelFontSize, weight: .semibold)
        contactInfoLabel.textColor = .systemGreen
        contactInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contactInfoContentView = FriendsHeaderContentView(headerView: contactInfoLabel, contentView: configureContactInfoTableView(), headerLeadPadding: hPadding + 5, contentLeadPadding: 0, headerContentPadding: 5)
        contactInfoContentView.translatesAutoresizingMaskIntoConstraints = false
        statisticsViewContentContainerView.addSubview(contactInfoContentView)
        
        NSLayoutConstraint.activate([
            contactInfoContentView.topAnchor.constraint(equalTo: statisticsViewContentContainerView.topAnchor),
            contactInfoContentView.leadingAnchor.constraint(equalTo: statisticsViewContentContainerView.leadingAnchor),
            contactInfoContentView.trailingAnchor.constraint(equalTo: statisticsViewContentContainerView.trailingAnchor),
            contactInfoContentView.heightAnchor.constraint(equalToConstant: 200),
        ])
    }
    
    private func configureContactInfoTableView() -> UIView {
        contactInfoTableView.delegate = self
        contactInfoTableView.dataSource = self
        contactInfoTableView.backgroundColor = .systemBackground
        contactInfoTableView.register(StatisticsCell.self, forCellReuseIdentifier: StatisticsCell.reuseID)
        contactInfoTableView.translatesAutoresizingMaskIntoConstraints = false
        contactInfoTableView.isScrollEnabled = false
        
        return contactInfoTableView
    }
    
    //MARK: Interests View
    private func configureInterestsView() {
        let userInterestsLabel = UILabel()
        userInterestsLabel.text = "Interests"
        userInterestsLabel.font = .systemFont(ofSize: VKConstants.headerLabelFontSize, weight: .semibold)
        userInterestsLabel.textColor = .systemGreen
        userInterestsLabel.translatesAutoresizingMaskIntoConstraints = false
    
        // Add 5 to get the headerLabel to be slightly more indented
        interestsHeaderContentView = FriendsHeaderContentView(headerView: userInterestsLabel, contentView: createInterestsHorizontalScrollView(), headerLeadPadding: hPadding + 5, contentLeadPadding: 0, headerContentPadding: 0)
        interestsHeaderContentView.translatesAutoresizingMaskIntoConstraints = false
        statisticsViewContentContainerView.addSubview(interestsHeaderContentView)
        
        NSLayoutConstraint.activate([
            interestsHeaderContentView.topAnchor.constraint(equalTo: contactInfoContentView.bottomAnchor),
            interestsHeaderContentView.leadingAnchor.constraint(equalTo: statisticsViewContentContainerView.leadingAnchor),
            interestsHeaderContentView.trailingAnchor.constraint(equalTo: statisticsViewContentContainerView.trailingAnchor),
            interestsHeaderContentView.heightAnchor.constraint(equalToConstant: 90)
        ])
    }
    
    private func createInterestsHorizontalScrollView() -> UIView {
        if friend.interests.count > 0 && friendSharingPermissions.areInterestsVisible  {
            print("Create more than one interests view")
            let scrollView = UIScrollView(frame: view.bounds)
            scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            scrollView.contentSize = CGSize(width: 1000, height: 60)
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 18
            stackView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(stackView)
            
            let interestCellBackgroundColor = UIColor(red: 108.0/255.0, green: 187.0/255.0, blue: 60.0/255.0, alpha: 1.0)
            
            for interest in friend.interests {
                let interestView = InterestsDisplayTileView(interest: interest, interestColor: interestCellBackgroundColor)
                interestView.translatesAutoresizingMaskIntoConstraints = false
                stackView.addArrangedSubview(interestView)
            }
            
            let padding: CGFloat = 10
            
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: padding),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: padding),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -padding)
            ])
            
            return scrollView
        } else {
            print("show no interests view")
            let noInterestsView = UILabel()
            noInterestsView.text = "No Interests Added"
            noInterestsView.textColor = .systemGray4
            noInterestsView.font = .systemFont(ofSize: 18, weight: .semibold)
            noInterestsView.translatesAutoresizingMaskIntoConstraints = false
            noInterestsView.textAlignment = .center

            return noInterestsView
        }
    }
    
    //MARK: Tap Map View
    private func configureUserTapMapView() {
        let tapMapLabel = UILabel()
        tapMapLabel.text = "Tap Map"
        tapMapLabel.font = .systemFont(ofSize: VKConstants.headerLabelFontSize, weight: .semibold)
        tapMapLabel.textColor = .systemGreen
        tapMapLabel.translatesAutoresizingMaskIntoConstraints = false
        
        tapMapHeaderContentView = FriendsHeaderContentView(headerView: tapMapLabel, contentView: configureContentTapMapView(), headerLeadPadding: hPadding + 5, contentLeadPadding: 25, headerContentPadding: 20)
        tapMapHeaderContentView.translatesAutoresizingMaskIntoConstraints = false
        statisticsViewContentContainerView.addSubview(tapMapHeaderContentView)
        
        NSLayoutConstraint.activate([
            tapMapHeaderContentView.topAnchor.constraint(equalTo: interestsHeaderContentView.bottomAnchor),
            tapMapHeaderContentView.leadingAnchor.constraint(equalTo: statisticsViewContentContainerView.leadingAnchor),
            tapMapHeaderContentView.trailingAnchor.constraint(equalTo: statisticsViewContentContainerView.trailingAnchor),
            tapMapHeaderContentView.heightAnchor.constraint(equalToConstant: 180)
        ])
    }
    
    private func configureContentTapMapView() -> UIView {
        let mostRecentLatCoord = friendAssociatedData.friendInfo.tappedLocations["lat"]?.last
        let mostRecentLonCoord = friendAssociatedData.friendInfo.tappedLocations["lon"]?.last
        
        if let mostRecentLatCoord = mostRecentLatCoord, let mostRecentLonCoord = mostRecentLonCoord {
            let tapMapPreviewView = VKMapPreviewView(locationCoordinate: CLLocationCoordinate2D(latitude: mostRecentLatCoord, longitude: mostRecentLonCoord))
            tapMapPreviewView.isUserInteractionEnabled = true
            
            let gesture = UITapGestureRecognizer(target: self, action: #selector(viewMapTapped))
            tapMapPreviewView.addGestureRecognizer(gesture)
            
            setExpandImageViewTintColor()
            expandImageView.translatesAutoresizingMaskIntoConstraints = false
            tapMapPreviewView.addSubview(expandImageView)
            
            NSLayoutConstraint.activate([
                expandImageView.topAnchor.constraint(equalTo: tapMapPreviewView.topAnchor, constant: 12),
                expandImageView.trailingAnchor.constraint(equalTo: tapMapPreviewView.trailingAnchor, constant: -12),
            ])
            
            return tapMapPreviewView
        }
        
        return UIView()
    }
    
    private func setExpandImageViewTintColor() {
        if traitCollection.userInterfaceStyle == .dark {
            expandImageView.tintColor = .white.withAlphaComponent(0.4)
        } else {
            expandImageView.tintColor = .black.withAlphaComponent(0.4)
        }
    }
    
    //MARK: Statistics View
    private func configureStatsView() {
        let statisticsLabel = UILabel()
        statisticsLabel.text = "Statistics with " + friend.firstName
        statisticsLabel.font = .systemFont(ofSize: VKConstants.headerLabelFontSize, weight: .semibold)
        statisticsLabel.textColor = .systemGreen
        statisticsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statsHeaderContentView = FriendsHeaderContentView(headerView: statisticsLabel, contentView: configureStatsContentView(), headerLeadPadding: hPadding + 5, contentLeadPadding: 0, headerContentPadding: 5)
        statsHeaderContentView.translatesAutoresizingMaskIntoConstraints = false
        statisticsViewContentContainerView.addSubview(statsHeaderContentView)
        
        NSLayoutConstraint.activate([
            statsHeaderContentView.topAnchor.constraint(equalTo: tapMapHeaderContentView.bottomAnchor, constant: 20),
            statsHeaderContentView.leadingAnchor.constraint(equalTo: statisticsViewContentContainerView.leadingAnchor),
            statsHeaderContentView.trailingAnchor.constraint(equalTo: statisticsViewContentContainerView.trailingAnchor),
            statsHeaderContentView.heightAnchor.constraint(equalToConstant: 330),
        ])
    }
    
    private func configureStatsContentView() -> UIView {
        statsTableView.delegate = self
        statsTableView.dataSource = self
        statsTableView.backgroundColor = .systemBackground
        statsTableView.register(StatisticsCell.self, forCellReuseIdentifier: StatisticsCell.reuseID)
        statsTableView.translatesAutoresizingMaskIntoConstraints = false
        statsTableView.isScrollEnabled = false
        
        return statsTableView
    }
    
    //MARK: Photos View:
    private func configurePhotosView() {
        loadingPhotosIndicator.startAnimating()
        createPhotosGridView() { view in
            self.loadingPhotosIndicator.stopAnimating()
            self.photosContentView = view
            self.photosContentView!.translatesAutoresizingMaskIntoConstraints = false
            self.wholeProfileScrollView.addSubview(self.photosContentView!)

            NSLayoutConstraint.activate([
                self.photosContentView!.topAnchor.constraint(equalTo: self.segmentControllerView.bottomAnchor, constant: 35),
                self.photosContentView!.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                self.photosContentView!.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            ])
        }
    }
    
    private func createPhotosGridView(completed: @escaping(UIView) -> Void) {
        let photosGrid = UIStackView()
        photosGrid.axis = .vertical
        photosGrid.spacing = 1
        photosGrid.alignment = .fill
        photosGrid.distribution = .fillEqually
        photosGrid.translatesAutoresizingMaskIntoConstraints = false
        
        let spacer1 = UIView()
        spacer1.translatesAutoresizingMaskIntoConstraints = false
        
        let spacer2 = UIView()
        spacer2.translatesAutoresizingMaskIntoConstraints = false
        
        FirebaseManager.shared.getFriendPhotos(photoIDs: friendAssociatedData.friendInfo.photoIDs) { result in
            switch result {
            case .success(var photoList):
                
                if photoList.count == 0 {
                    completed(self.noPhotosView)
                    break
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yy"

                photoList = photoList.sorted {
                    guard let date1 = $0.1, let date2 = $1.1 else { return false}
                    return date1 > date2
                }
                
                var counter = 0
                var currentHStack: UIStackView!
                
                for photo in photoList {
                    let photoToAdd = UIImageView(image: photo.0)
                    
                    if counter % 3 == 0 {
                        currentHStack = UIStackView()
                        currentHStack.axis = .horizontal
                        currentHStack.alignment = .fill
                        currentHStack.distribution = .fillEqually
                        currentHStack.spacing = 1
                        currentHStack.translatesAutoresizingMaskIntoConstraints = false
                        
                        NSLayoutConstraint.activate([
                            currentHStack.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 10) / 3),
                        ])

                        photosGrid.addArrangedSubview(currentHStack)
                        
                        currentHStack.addArrangedSubview(photoToAdd)
                        currentHStack.addArrangedSubview(spacer1)
                        currentHStack.addArrangedSubview(spacer2)
                    } else if counter % 3 == 1 {
                        currentHStack.removeArrangedSubview(spacer2)
                        currentHStack.removeArrangedSubview(spacer1)
                        currentHStack.addArrangedSubview(photoToAdd)
                        currentHStack.addArrangedSubview(spacer1)
                    } else if counter % 3 == 2 {
                        currentHStack.removeArrangedSubview(spacer1)
                        currentHStack.addArrangedSubview(photoToAdd)
                    }
                    
                    counter += 1
                }
                
                completed(photosGrid)
            case .failure(let error):
                self.loadingPhotosIndicator.stopAnimating()
                self.presentVKAlert(title: "Failed to fetch photos", message: error.localizedDescription, buttonTitle: "OK")
                completed(self.noPhotosView)
            }
        }
    }
    
    @objc private func viewMapTapped() {
        let tapMapVC = TapMapVC(friend: friend, withFriendInfo: friendAssociatedData.friendInfo)
        navigationController?.pushViewController(tapMapVC, animated: true)
    }
    
    @objc func segmentedValueChanged(_ sender:UISegmentedControl!) {
        switch sender.selectedSegmentIndex {
        case 0:
            statisticsViewContentContainerView.isHidden = false
            photosContentView?.isHidden = true
            
            break
        case 1:
            statisticsViewContentContainerView.isHidden = true

            if photosContentView == nil {
                configurePhotosView()
            } else {
                photosContentView?.isHidden = false
            }
            
            break
        default:
            break
        }
    }
}


//MARK: - Delegates
extension FriendProfileVC: UITableViewDelegate, UITableViewDataSource {
    // TableView Delegate Method Implementations
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == statsTableView {
            return statTitles.count
        } else {
            return contactInfoTitles.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == statsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: StatisticsCell.reuseID) as! StatisticsCell
            
            // Configure cell info for given statistic
            cell.set(title: statTitles[indexPath.row], value: statsIndexToValue(index: indexPath.row))
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: StatisticsCell.reuseID) as! StatisticsCell
        
        // Configure cell info for given statistic
        cell.set(title: contactInfoTitles[indexPath.row], value: contactInfoIndexToValue(index: indexPath.row))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    private func statsIndexToValue(index: Int) -> String{
        switch index {
        case 0:
            //Current daily streak
            return String(getCurrentDailyStreak())
        case 1:
            //Max current daily streak
            return String(getMaximumDailyStreak())
        case 2:
            //Current weekly streak
            return String(getCurrentWeeklyStreak())
        case 3:
            //Max weekly streak
            return String(getMaximumWeeklyStreak())
        case 4:
            return String(friendAssociatedData.friendInfo.tappedTimes.count)
        case 5:
            return Utils.ddMMYY(dateStamp: friendAssociatedData.friendInfo.tappedTimes[0])
        default:
            return ""
        }
    }
    
    private func getCurrentDailyStreak() -> Int {
        let reversedTappedTimes = Array(friendAssociatedData.friendInfo.tappedTimes.reversed())
        let calendar = Calendar.current
        
        var consecutiveCount = 1
        
        for i in 1..<reversedTappedTimes.count {
            if calendar.isDate(reversedTappedTimes[i], inSameDayAs: calendar.date(byAdding: .day, value: -1, to: reversedTappedTimes[i - 1])!) {
                consecutiveCount += 1
            } else {
                return consecutiveCount
            }
        }
        
        return consecutiveCount
    }
    
    private func getMaximumDailyStreak() -> Int {
        let reversedTappedTimes = Array(friendAssociatedData.friendInfo.tappedTimes.reversed())
        let calendar = Calendar.current
        
        var consecutiveCount = 1
        var maxConsecutiveCount = 1
        
        for i in 1..<reversedTappedTimes.count {
            if calendar.isDate(reversedTappedTimes[i], inSameDayAs: calendar.date(byAdding: .day, value: -1, to: reversedTappedTimes[i - 1])!) {
                consecutiveCount += 1
                maxConsecutiveCount = max(maxConsecutiveCount, consecutiveCount)
            } else {
                consecutiveCount = 1
            }
        }
        
        return maxConsecutiveCount
    }
    
    private func getCurrentWeeklyStreak() -> Int {
        let reversedTappedTimes = Array(friendAssociatedData.friendInfo.tappedTimes.reversed())
        
        var consecutiveCount = 1
        guard var mostRecentWeek = reversedTappedTimes[0].getWeekComponent() else { return 1}
        
        for i in 1..<reversedTappedTimes.count {
            guard let currWeekComponent = reversedTappedTimes[i].getWeekComponent() else { return consecutiveCount }
            if mostRecentWeek - currWeekComponent == 1 {
                mostRecentWeek = currWeekComponent
                consecutiveCount += 1
            }
        
            if mostRecentWeek - currWeekComponent > 1 {
                return consecutiveCount
            }
        }
        
        return consecutiveCount
    }
    
    private func getMaximumWeeklyStreak() -> Int {
        let reversedTappedTimes = Array(friendAssociatedData.friendInfo.tappedTimes.reversed())
        
        var consecutiveCount = 1
        var maxConsecutiveCount = 1
        guard var mostRecentWeek = reversedTappedTimes[0].getWeekComponent() else { return 1}
        
        for i in 1..<reversedTappedTimes.count {
            guard let currWeekComponent = reversedTappedTimes[i].getWeekComponent() else { return consecutiveCount }
            
            if mostRecentWeek - currWeekComponent == 1 {
                consecutiveCount += 1
                maxConsecutiveCount = max(maxConsecutiveCount, consecutiveCount)
            } else if mostRecentWeek - currWeekComponent > 1 {
                consecutiveCount = 1
            }
            
            mostRecentWeek = currWeekComponent
        }
        
        return maxConsecutiveCount
    }
    
    private func contactInfoIndexToValue(index: Int) -> String {
        guard let friendSharingPermissions = friendSharingPermissions else { return "N/A" }
        switch index {
        case 0:
            //Phone Number
            return friendSharingPermissions.isPhoneNumberVisible ? friendAssociatedData.friend.phoneNumber : "N/A"
        case 1:
            //Email
            return friendSharingPermissions.isEmailVisible ? friendAssociatedData.friend.email : "N/A"
        case 2:
            //Birthday
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/dd/yyyy"
            return friendSharingPermissions.isBirthdayVisible ? dateFormatter.string(from: friendAssociatedData.friend.birthday) : "N/A"
        default:
            return ""
        }
    }
}

extension FriendProfileVC: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        self.dismiss(animated: true)
    }
}

extension FriendProfileVC: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

extension FriendProfileVC: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
