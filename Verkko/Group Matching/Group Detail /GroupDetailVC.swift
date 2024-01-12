//
//  GroupDetailVC.swift
//  Verkko
//
//  Created by Justin Wong on 7/25/23.
//

import UIKit
import MapKit

class GroupDetailVC: UIViewController {
    private let groupDetailScrollView = UIScrollView()
    private let scrollContentView = UIView()
    private var informationHeaderContentView: HeaderContentView!
    private var locationHeaderContentView: FriendsHeaderContentView!
    private var groupLocationMapPreview: VKMapPreviewView?
    private var groupMeetingTimeContentView: FriendsHeaderContentView!
    private let informationTableStats = ["Created By", "Date Created"]
    private let informationTableView = UITableView()
    private let membersTableView = UITableView()
    private let membersCountBadgeView = UIView()
    private let membersCountLabel = UILabel()
    private let membersTableViewActivityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var group: VKGroup!
    private var groupAddress: String?
    private var groupCache: VKGroupCache!
    private var groupMembers = [VKUser]()
    
    private var locationContentViewHeightAnchor: NSLayoutConstraint?
    private var locationContentViewHeight: CGFloat = 180
    
    lazy private var isCurrentUserGroupCreator: Bool = {
        guard let currentUser = FirebaseManager.shared.currentUser else { return false }
        return currentUser.uid == group.createdBy
    }()
    
    init(group: VKGroup, groupCache: VKGroupCache) {
        self.group = group
        self.groupCache = groupCache
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateGroup(with newGroup: VKGroup) {
        group = newGroup
        title = group.name
        fetchGroupMembers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavbar()
        configureGroupDetailScrollView()
        configureGroupLocationSection()
        configureGroupMeetingTimeSection()
        configureGroupInfoSection()
        configureMembersSection()
    
        groupCache.fetchGroupMembers(for: group) { members in
            if let members = members {
                self.groupMembers = members
                self.groupMembers.sortAlphabeticallyAscendingByFullName()
                self.updateVC()
            }
        }
    }
    
    private func fetchGroupMembers() {
        guard let group = group else { return }
        membersTableViewActivityIndicator.startAnimating()
        FirebaseManager.shared.getUsers(for: Array(group.membersAndStatus.keys)) { result in
            self.membersTableViewActivityIndicator.stopAnimating()
            switch result {
            case .success(let users):
                self.groupMembers = users
                self.groupMembers.sortAlphabeticallyAscendingByFullName()
                self.updateVC()
            case .failure(let error):
                self.presentVKAlert(title: "Cannot Fetch Group Members", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    private func updateVC() {
        DispatchQueue.main.async {
            self.membersCountLabel.text = "\(self.groupMembers.count)"
            self.membersCountBadgeView.isHidden = false
            self.updateGroupLocationSection()
            
            self.groupMeetingTimeContentView.updateContentView(with: self.createGroupMeetingTimeView())
            
            self.membersTableView.reloadData()
            self.informationTableView.reloadData()
        }
    }
    
    private func getGroupCreatorFullName() -> String? {
        for member in groupMembers {
            if member.uid == group.createdBy {
                return member.getFullName()
            }
        }
        return nil
    }
    
    private func configureNavbar() {
        view.backgroundColor = .systemBackground
        title = group.name 
        
        navigationController?.navigationBar.tintColor = .systemGreen
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
        
        let addFriendNavbarButton = UIBarButtonItem(image: UIImage(systemName: "person.badge.plus"), style: .plain, target: self, action: #selector(addFriendToGroup))
        addFriendNavbarButton.tintColor = .systemGreen
        
        let roomSettingsNavbarButton = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(showRoomSettingsModal))
        roomSettingsNavbarButton.tintColor = .systemGreen
        
        navigationItem.rightBarButtonItems = [roomSettingsNavbarButton, addFriendNavbarButton]
    }
    
    @objc private func addFriendToGroup() {
        let addFriendModal = UINavigationController(rootViewController: GroupAddFriendVC(group: group))
        present(addFriendModal, animated: true)
    }
    
    @objc private func showRoomSettingsModal() {
        let roomSettingsModal = GroupSettingsVC(group: group, returnToGroupMatchingVC: {
            self.navigationController?.popViewController(animated: true)
        }) {
            self.dismiss(animated: true)
        }
        roomSettingsModal.modalPresentationStyle = .overFullScreen
        roomSettingsModal.modalTransitionStyle = .crossDissolve
        present(roomSettingsModal, animated: true)
    }
    
    private func configureGroupDetailScrollView() {
        groupDetailScrollView.showsVerticalScrollIndicator = false
        groupDetailScrollView.showsHorizontalScrollIndicator = false
        groupDetailScrollView.bounces = true
        groupDetailScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(groupDetailScrollView)
    
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        groupDetailScrollView.addSubview(scrollContentView)
        
        NSLayoutConstraint.activate([
            groupDetailScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            groupDetailScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            groupDetailScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            groupDetailScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            scrollContentView.topAnchor.constraint(equalTo: groupDetailScrollView.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: groupDetailScrollView.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: groupDetailScrollView.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: groupDetailScrollView.bottomAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: groupDetailScrollView.widthAnchor),
            scrollContentView.heightAnchor.constraint(equalToConstant: view.frame.size.height)
        ])
    }
    
    //MARK: - Location Section
    private func updateGroupLocationSection() {
        if let newGroupLocation = group.getLocationAsCLLocationCoordinate2D() {
            groupLocationMapPreview?.updateView(at: newGroupLocation)
        }
    }
    
    private func configureGroupLocationSection() {
        let groupLocationHeaderView = UIView()
        groupLocationHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        let locationSectionLabel = UILabel()
        locationSectionLabel.text = "Location"
        locationSectionLabel.font = .systemFont(ofSize: VKConstants.headerLabelFontSize, weight: .semibold)
        locationSectionLabel.textColor = .systemGreen
        locationSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        groupLocationHeaderView.addSubview(locationSectionLabel)
        
        let editGroupLocationButton = UIButton(type: .custom)
        editGroupLocationButton.setTitle("Edit", for: .normal)
        editGroupLocationButton.setTitleColor(.lightGray, for: .normal)
        editGroupLocationButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        editGroupLocationButton.addTarget(self, action: #selector(editGroupLocation), for: .touchUpInside)
        editGroupLocationButton.translatesAutoresizingMaskIntoConstraints = false
        groupLocationHeaderView.addSubview(editGroupLocationButton)
        
        if isCurrentUserGroupCreator {
            editGroupLocationButton.isHidden = false
            editGroupLocationButton.isEnabled = true
        } else {
            editGroupLocationButton.isHidden = true
            editGroupLocationButton.isEnabled = false
        }
        
        locationHeaderContentView =
        FriendsHeaderContentView(headerView: groupLocationHeaderView, contentView: createLocationContentView(), headerLeadPadding: 10, contentLeadPadding: 10, headerContentPadding: 10)
        
        locationHeaderContentView.translatesAutoresizingMaskIntoConstraints = false
        scrollContentView.addSubview(locationHeaderContentView)
        
        locationContentViewHeightAnchor =  locationHeaderContentView.heightAnchor.constraint(equalToConstant: locationContentViewHeight)
        locationContentViewHeightAnchor?.isActive = true
        
        NSLayoutConstraint.activate([
            locationHeaderContentView.topAnchor.constraint(equalTo: scrollContentView.topAnchor, constant: 20),
            locationHeaderContentView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            locationHeaderContentView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),
            
            locationSectionLabel.topAnchor.constraint(equalTo: groupLocationHeaderView.topAnchor),
            locationSectionLabel.leadingAnchor.constraint(equalTo: groupLocationHeaderView.leadingAnchor),
            locationSectionLabel.bottomAnchor.constraint(equalTo: groupLocationHeaderView.bottomAnchor),
            locationSectionLabel.widthAnchor.constraint(equalToConstant: 100),
            
            editGroupLocationButton.topAnchor.constraint(equalTo: groupLocationHeaderView.topAnchor),
            editGroupLocationButton.bottomAnchor.constraint(equalTo: groupLocationHeaderView.bottomAnchor),
            editGroupLocationButton.trailingAnchor.constraint(equalTo: groupLocationHeaderView.trailingAnchor),
            editGroupLocationButton.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func editGroupLocation() {
        let groupAddLocationNC = UINavigationController(rootViewController: GroupAddEditLocationVC(group: group, isEdit: true))
        present(groupAddLocationNC, animated: true)
    }
    
    private func createLocationContentView() -> UIView {
        if let groupLocationCoordinate = group.getLocationAsCLLocationCoordinate2D() {
            locationContentViewHeight = 180
            return createLocationStackView(groupLocationCoordinate: groupLocationCoordinate)
        } else {
            if isCurrentUserGroupCreator {
                let containerView = UIView()
                
                let addInitialGroupLocationButton = VKButton(backgroundColor: .systemBlue.withAlphaComponent(0.2), title: "Set Group Meeting Location")
                addInitialGroupLocationButton.setTitleColor(.systemBlue, for: .normal)
                addInitialGroupLocationButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
                addInitialGroupLocationButton.layer.cornerRadius = 10
                addInitialGroupLocationButton.addTarget(self, action: #selector(presentGroupAddLocationVC), for: .touchUpInside)
                addInitialGroupLocationButton.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(addInitialGroupLocationButton)
                
                locationContentViewHeight = 80
                
                NSLayoutConstraint.activate([
                    addInitialGroupLocationButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    addInitialGroupLocationButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    addInitialGroupLocationButton.widthAnchor.constraint(equalToConstant: 250),
                    addInitialGroupLocationButton.heightAnchor.constraint(equalToConstant: 50)
                ])
                
                return containerView
            }
        } 
        //No Group Location & current user is not group creator
        locationContentViewHeight = 80
        return VKEmptyStateView(message: "No Location Available")
    }
    
    @objc private func presentGroupAddLocationVC() {
        let groupAddLocationNC = UINavigationController(rootViewController: GroupAddEditLocationVC(group: group, isEdit: false))
        present(groupAddLocationNC, animated: true)
    }
    
    private func createLocationStackView(groupLocationCoordinate: CLLocationCoordinate2D) -> UIStackView {
        let locationStackView = UIStackView()
        locationStackView.axis = .vertical
        locationStackView.distribution = .fill
        locationStackView.spacing = 8
        locationStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let innerPadding: CGFloat = 8
        
        let locationAddressView = UIStackView()
        locationAddressView.axis = .horizontal
        locationAddressView.spacing = 10
        locationAddressView.distribution = .fill
        locationAddressView.backgroundColor = .systemGreen.withAlphaComponent(0.2)
        locationAddressView.layer.cornerRadius = 10
        locationAddressView.layoutMargins = UIEdgeInsets(top: innerPadding, left: innerPadding, bottom: innerPadding, right: innerPadding)
        locationAddressView.isLayoutMarginsRelativeArrangement = true
        locationAddressView.translatesAutoresizingMaskIntoConstraints = false
        
        let addressLabel = UILabel()
        addressLabel.textColor = .systemGreen
        addressLabel.font = UIFont.systemFont(ofSize: 16)
        addressLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        addressLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        locationAddressView.addArrangedSubview(addressLabel)

        let launchInMapsSymbolImage = UIImage(systemName: "arrowshape.turn.up.right.fill")
        let launchInMapsSymbolImageView = UIImageView(image: launchInMapsSymbolImage)
        launchInMapsSymbolImageView.tintColor = .systemGreen
        locationAddressView.addArrangedSubview(launchInMapsSymbolImageView)
        
        group.getLocationAddress { address in
            if let address = address {
                self.groupAddress = address
                addressLabel.text = address
            } else {
                addressLabel.text = "Unable to Retrieve Location Address"
            }
        }
        
        let launchAddressTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(launchGroupLocationInMaps))
        locationAddressView.addGestureRecognizer(launchAddressTapGestureRecognizer)
        
        locationStackView.addArrangedSubview(locationAddressView)
        
        if let groupLocationCoordinate = group.getLocationAsCLLocationCoordinate2D() {
            groupLocationMapPreview = VKMapPreviewView(locationCoordinate: groupLocationCoordinate)
            locationStackView.addArrangedSubview(groupLocationMapPreview!)
        }

        return locationStackView
    }
    
    @objc private func launchGroupLocationInMaps() {
        guard let groupLocationCoordinate = group.getLocationAsCLLocationCoordinate2D(), let groupAddress = groupAddress else { return }
        
        Utils.launchMaps(location: groupLocationCoordinate, address: groupAddress)
    }
    
    //MARK: Meeting Time Section
    private func configureGroupMeetingTimeSection() {
        let groupMeetingTimeHeaderView = UIView()
        groupMeetingTimeHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        let groupMeetingTimeLabel = UILabel()
        groupMeetingTimeLabel.text = "Meeting Time"
        groupMeetingTimeLabel.font = .systemFont(ofSize: VKConstants.headerLabelFontSize, weight: .semibold)
        groupMeetingTimeLabel.textColor = .systemGreen
        groupMeetingTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        groupMeetingTimeHeaderView.addSubview(groupMeetingTimeLabel)
        
        let editGroupMeetingTimeButton = UIButton(type: .custom)
        editGroupMeetingTimeButton.setTitle("Edit", for: .normal)
        editGroupMeetingTimeButton.setTitleColor(.lightGray, for: .normal)
        editGroupMeetingTimeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        editGroupMeetingTimeButton.addTarget(self, action: #selector(editGroupMeetingTime), for: .touchUpInside)
        editGroupMeetingTimeButton.translatesAutoresizingMaskIntoConstraints = false
        groupMeetingTimeHeaderView.addSubview(editGroupMeetingTimeButton)
        
        if isCurrentUserGroupCreator {
            editGroupMeetingTimeButton.isHidden = false
            editGroupMeetingTimeButton.isEnabled = true
        } else {
            editGroupMeetingTimeButton.isHidden = true
            editGroupMeetingTimeButton.isEnabled = false
        }
        
        groupMeetingTimeContentView = FriendsHeaderContentView(headerView: groupMeetingTimeHeaderView, contentView: createGroupMeetingTimeView(), headerLeadPadding: 10, contentLeadPadding: 10, headerContentPadding: 10)
        groupMeetingTimeContentView.translatesAutoresizingMaskIntoConstraints = false
        scrollContentView.addSubview(groupMeetingTimeContentView)
        
        NSLayoutConstraint.activate([
            groupMeetingTimeContentView.topAnchor.constraint(equalTo: locationHeaderContentView.bottomAnchor, constant: 20),
            groupMeetingTimeContentView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            groupMeetingTimeContentView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),
            groupMeetingTimeContentView.heightAnchor.constraint(equalToConstant: 100),
            
            groupMeetingTimeLabel.topAnchor.constraint(equalTo: groupMeetingTimeHeaderView.topAnchor),
            groupMeetingTimeLabel.leadingAnchor.constraint(equalTo: groupMeetingTimeHeaderView.leadingAnchor),
            groupMeetingTimeLabel.bottomAnchor.constraint(equalTo: groupMeetingTimeHeaderView.bottomAnchor),
            groupMeetingTimeLabel.widthAnchor.constraint(equalToConstant: 100),
            
            editGroupMeetingTimeButton.topAnchor.constraint(equalTo: groupMeetingTimeHeaderView.topAnchor),
            editGroupMeetingTimeButton.bottomAnchor.constraint(equalTo: groupMeetingTimeHeaderView.bottomAnchor),
            editGroupMeetingTimeButton.trailingAnchor.constraint(equalTo: groupMeetingTimeHeaderView.trailingAnchor),
            editGroupMeetingTimeButton.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func createGroupMeetingTimeView() -> UIView {
        if let groupMeetingDate = group.meetingDateTime {
            let groupDateTimeStackView = UIStackView()
            groupDateTimeStackView.axis = .horizontal
            groupDateTimeStackView.spacing = 10
            groupDateTimeStackView.alignment = .center
            groupDateTimeStackView.distribution = .fillEqually
            groupDateTimeStackView.layer.cornerRadius = 10
            groupDateTimeStackView.backgroundColor = .systemGreen.withAlphaComponent(0.2)
            groupDateTimeStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let dateLabel = UILabel()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/dd/yyyy"
            let formattedDate = dateFormatter.string(from: groupMeetingDate)
            dateLabel.text = formattedDate
            dateLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
            dateLabel.textColor = .systemGreen
            dateLabel.textAlignment = .center
            groupDateTimeStackView.addArrangedSubview(dateLabel)
            
            let timeLabel = UILabel()
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let formattedTime = timeFormatter.string(from: groupMeetingDate)
            timeLabel.text = formattedTime
            timeLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
            timeLabel.textColor = .systemGreen
            timeLabel.textAlignment = .center
            groupDateTimeStackView.addArrangedSubview(timeLabel)
            
            return groupDateTimeStackView
        }
        
        //Show empty state view
        let emptyStateView = VKEmptyStateView(message: "No Group Meeting Date & Time", textAlignment: .center)
        return emptyStateView
    }
    
    @objc private func editGroupMeetingTime() {
        let editGroupDateOverlayNC = UINavigationController(rootViewController: EditGroupDateOverlayVC(group: group))
        editGroupDateOverlayNC.modalPresentationStyle = .overFullScreen
        editGroupDateOverlayNC.modalTransitionStyle = .coverVertical
        present(editGroupDateOverlayNC, animated: true)
    }
    
    //MARK: - Information Section
    private func configureGroupInfoSection() {
        let informationSectionLabel = UILabel()
        informationSectionLabel.text = "Information"
        informationSectionLabel.font = .systemFont(ofSize: VKConstants.headerLabelFontSize, weight: .semibold)
        informationSectionLabel.textColor = .systemGreen
        informationSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        informationHeaderContentView = HeaderContentView(headerView: informationSectionLabel, contentView: createInformationSectionTable())
        informationHeaderContentView.translatesAutoresizingMaskIntoConstraints = false
        scrollContentView.addSubview(informationHeaderContentView)
        
        NSLayoutConstraint.activate([
            informationHeaderContentView.topAnchor.constraint(equalTo: groupMeetingTimeContentView.bottomAnchor, constant: 20),
            informationHeaderContentView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            informationHeaderContentView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),
            informationHeaderContentView.heightAnchor.constraint(equalToConstant: 140)
        ])
    }
    
    private func createInformationSectionTable() -> UITableView {
        informationTableView.dataSource = self
        informationTableView.delegate = self
        informationTableView.backgroundColor = .systemBackground
        informationTableView.register(StatisticsCell.self, forCellReuseIdentifier: StatisticsCell.reuseID)
        informationTableView.translatesAutoresizingMaskIntoConstraints = false
        informationTableView.isScrollEnabled = false
        return informationTableView
    }
    
    //MARK: - Members Section
    private func configureMembersSection() {
        let membersSectionLabel = UILabel()
        membersSectionLabel.text = "Members"
        membersSectionLabel.font = .systemFont(ofSize: VKConstants.headerLabelFontSize, weight: .semibold)
        membersSectionLabel.textColor = .systemGreen
        membersSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let membersSectionHeaderView = UIView()
        membersSectionHeaderView.translatesAutoresizingMaskIntoConstraints = false
        membersSectionHeaderView.addSubview(membersSectionLabel)
        
        membersTableViewActivityIndicator.tintColor = .lightGray
        membersTableViewActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        membersSectionHeaderView.addSubview(membersTableViewActivityIndicator)
        
        let membersCountBadgeWidthHeight: CGFloat = 23
        
       
        membersCountBadgeView.isHidden = true
        membersCountBadgeView.backgroundColor = .systemGreen.withAlphaComponent(0.3)
        membersCountBadgeView.frame = CGRect(x: 0, y: 0, width: membersCountBadgeWidthHeight, height: membersCountBadgeWidthHeight)
        membersCountBadgeView.layer.cornerRadius = membersCountBadgeView.frame.size.width / 2
        membersCountBadgeView.translatesAutoresizingMaskIntoConstraints = false
        membersSectionHeaderView.addSubview(membersCountBadgeView)
        
        membersCountLabel.textColor = .systemGreen
        membersCountLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        membersCountLabel.translatesAutoresizingMaskIntoConstraints = false
        membersSectionHeaderView.addSubview(membersCountLabel)
    
        // Add 5 to get the headerLabel to be slightly more indented
        let membersHeaderContentView = HeaderContentView(headerView: membersSectionHeaderView, contentView: createMembersSectionTable())
        membersHeaderContentView.translatesAutoresizingMaskIntoConstraints = false
        scrollContentView.addSubview(membersHeaderContentView)
        
        NSLayoutConstraint.activate([
            membersSectionLabel.centerYAnchor.constraint(equalTo: membersSectionHeaderView.centerYAnchor),
            membersSectionLabel.leadingAnchor.constraint(equalTo: membersSectionHeaderView.leadingAnchor),
            membersSectionLabel.widthAnchor.constraint(equalToConstant: 80),
            
            membersTableViewActivityIndicator.centerYAnchor.constraint(equalTo: membersSectionHeaderView.centerYAnchor),
            membersTableViewActivityIndicator.leadingAnchor.constraint(equalTo: membersSectionLabel.trailingAnchor, constant: 10),
            
            membersCountBadgeView.heightAnchor.constraint(equalToConstant: membersCountBadgeWidthHeight),
            membersCountBadgeView.widthAnchor.constraint(equalToConstant: membersCountBadgeWidthHeight),
            membersCountBadgeView.centerYAnchor.constraint(equalTo: membersSectionHeaderView.centerYAnchor),
            membersCountBadgeView.trailingAnchor.constraint(equalTo: membersSectionHeaderView.trailingAnchor),
            
            membersCountLabel.centerXAnchor.constraint(equalTo: membersCountBadgeView.centerXAnchor),
            membersCountLabel.centerYAnchor.constraint(equalTo: membersCountBadgeView.centerYAnchor),
            
            membersHeaderContentView.topAnchor.constraint(equalTo: informationHeaderContentView.bottomAnchor, constant: 20),
            membersHeaderContentView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            membersHeaderContentView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),
            membersHeaderContentView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor, constant: -10)
        ])
    }
    
    private func createMembersSectionTable() -> UITableView {
        membersTableView.dataSource = self
        membersTableView.delegate = self
        membersTableView.alwaysBounceVertical = false
        membersTableView.backgroundColor = .systemBackground
        membersTableView.register(VKGroupMemberStatusCell.self, forCellReuseIdentifier: VKGroupMemberStatusCell.subclassReuseID)
        membersTableView.translatesAutoresizingMaskIntoConstraints = false
        return membersTableView
    }
    
    func getGroup() -> VKGroup {
        return group
    }
}

//MARK: - Table View Delegates
extension GroupDetailVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == informationTableView {
            return informationTableStats.count
        } else {
            return groupMembers.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == informationTableView {
            let statsCell = tableView.dequeueReusableCell(withIdentifier: StatisticsCell.reuseID) as! StatisticsCell
            statsCell.set(title: informationTableStats[indexPath.row], value: getInformationStatsCellValue(at: indexPath.row))
            return statsCell
        } else {
            let memberCell = tableView.dequeueReusableCell(withIdentifier: VKGroupMemberStatusCell.subclassReuseID) as! VKGroupMemberStatusCell
            memberCell.set(for: groupMembers[indexPath.row], group: group, widthHeight: 40) { error in
                self.presentVKAlert(title: "Error", message: error.getMessage(), buttonTitle: "OK")
            }
            return memberCell
        }
    }
    
    private func getInformationStatsCellValue(at index: Int) -> String {
        switch index {
        case 0:
            return getGroupCreatorFullName() ?? "N/A"
        case 1:
            return String(group.dateCreated.formatted(date: .abbreviated, time: .omitted))
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let currentUser = FirebaseManager.shared.currentUser, let group = group, currentUser.uid == group.createdBy, tableView != informationTableView else { return false }
        
        let member = groupMembers[indexPath.row]
        
        return member.uid != currentUser.uid
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let group = group else { return }
        
        let selectedMember = groupMembers[indexPath.row]
        
        if editingStyle == .delete {
            removeMemberFromGroup(for: selectedMember, in: group)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let currentUser = FirebaseManager.shared.currentUser, let group = group, currentUser.uid == group.createdBy else { return nil }
        
        let selectedMember = groupMembers[indexPath.row]
        
        guard selectedMember.uid != currentUser.uid else { return nil}
        
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ -> UIMenu? in
            
            let deleteAction = UIAction(title: "Remove From Group", image: UIImage(systemName: "person.crop.circle.badge.minus")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)) { _ in
                self.removeMemberFromGroup(for: selectedMember, in: group)
            }
            
            return UIMenu(title: "", children: [deleteAction])
        }
        
        return configuration
    }
    
    private func removeMemberFromGroup(for member: VKUser, in group: VKGroup) {
        var groupTemp = group
        groupTemp.membersAndStatus.removeValue(forKey: member.uid)
        let newGroupMembersAndStatus = groupTemp.membersAndStatus.mapValues { value in
            return value.description
        }
        
        FirebaseManager.shared.updateGroup(for: group.jointID, fields: [
            VKConstants.membersAndStatus: newGroupMembersAndStatus
        ]) { error in
            if let error = error {
                self.presentVKAlert(title: "Cannot Remove User", message: error.getMessage(), buttonTitle: "OK")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

//MARK: - VKMapPreviewView
class VKMapPreviewView: MKMapView {
    private var locationCoordinate: CLLocationCoordinate2D!
    
    init(locationCoordinate: CLLocationCoordinate2D) {
        self.locationCoordinate = locationCoordinate
        super.init(frame: .zero)
        configureView()
        centerMapAndAddCoordinate()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateView(at newCoordinate: CLLocationCoordinate2D) {
        locationCoordinate = newCoordinate
        centerMapAndAddCoordinate()
    }
    
    private func configureView() {
        isScrollEnabled = false
        isZoomEnabled = false
        isRotateEnabled = false
        isUserInteractionEnabled = false
        layer.cornerRadius = 15
        layer.borderWidth = 1.0
        layer.borderColor = CGColor(gray: 0.5, alpha: 1)
        preferredConfiguration.elevationStyle = .realistic
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }
    
    private func centerMapAndAddCoordinate() {
        // Center map view around most recent tap location
        let centeredRegion = MKCoordinateRegion(center: locationCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04))
        setRegion(centeredRegion, animated: true)
        
        let newPin = MKPointAnnotation()
        newPin.coordinate = locationCoordinate
        addAnnotation(newPin)
    }
}

//MARK: - SetGroupDateOverlayVC
class EditGroupDateOverlayVC: UIViewController {
    private let datePicker = UIDatePicker()
    private let updateGroupDateButton = UIButton(type: .custom)
    
    private var group: VKGroup!
    
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
        configureDatePicker()
        configureUpdateGroupDateButton()
    }
    
    private func configureVC() {
        addFullScreenBlurBackground()
        addCloseButton()
        
        title = "Update Group Meeting Date & Time"
        
        let backgroundDismissTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeVC))
        view.addGestureRecognizer(backgroundDismissTapRecognizer)
    }
    
    private func configureDatePicker() {
        datePicker.tintColor = .systemGreen
        datePicker.minimumDate = Date()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            datePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func configureUpdateGroupDateButton() {
        updateGroupDateButton.setTitle("Update", for: .normal)
        updateGroupDateButton.setTitleColor(.white, for: .normal)
        updateGroupDateButton.titleLabel?.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        updateGroupDateButton.layer.cornerRadius = 25
        updateGroupDateButton.layer.shadowColor = UIColor.lightGray.cgColor
        updateGroupDateButton.layer.shadowOpacity = 0.5
        updateGroupDateButton.layer.shadowRadius = 10
        updateGroupDateButton.backgroundColor = .systemGreen
        updateGroupDateButton.addTarget(self, action: #selector(updateGroupDate), for: .touchUpInside)
        updateGroupDateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(updateGroupDateButton)
        
        NSLayoutConstraint.activate([
            updateGroupDateButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            updateGroupDateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            updateGroupDateButton.widthAnchor.constraint(equalToConstant: 200),
            updateGroupDateButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func updateGroupDate() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
        
        FirebaseManager.shared.updateGroup(for: group.jointID, fields: [
            VKConstants.meetingDateTime: datePicker.date
        ]) { error in
            if let error = error {
                self.presentVKAlert(title: "Cannot Update Group Date & Time", message: error.getMessage(), buttonTitle: "OK")
            } else {
                self.closeVC()
            }
        }
    }
}

