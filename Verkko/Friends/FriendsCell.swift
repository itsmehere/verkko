//
//  FriendsCell.swift
//  Verkko
//
//  Created by Mihir Rao on 5/26/23.
//

import UIKit
import CoreLocation

class FriendsCell: UITableViewCell {
    static let reuseID = "FriendsCell"
    
    private var profileImageView: VKProfileImageView!
    private var vInfoStackView: UIStackView!
    private var expandProfileButton: UIButton!
    
    private var userNameLabel: UILabel!
    private var lastSeenLabel: UILabel!
    private var lastTappedLocationLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureCell() {
        // removes gray background on cell tap
        selectionStyle = .none
        let profileImageWidthAndHeight: CGFloat = 52
        
        profileImageView = VKProfileImageView(widthHeight: profileImageWidthAndHeight)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileImageView)
        
        configureVInfoStackView()
        configureExpandView()
        
        let hPadding: CGFloat = 10
        let vPadding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: hPadding),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
            
            vInfoStackView.topAnchor.constraint(equalTo: topAnchor, constant: vPadding),
            vInfoStackView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            vInfoStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            vInfoStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPadding),
            
            expandProfileButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            expandProfileButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -hPadding),
            expandProfileButton.widthAnchor.constraint(equalToConstant: 30),
            expandProfileButton.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    private func configureVInfoStackView() {
        vInfoStackView = UIStackView()
        vInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        vInfoStackView.axis = .vertical
        vInfoStackView.spacing = -12
        vInfoStackView.distribution = .fillEqually
        addSubview(vInfoStackView)
        
        let nameAndLastSeenHourView = UIView()
        vInfoStackView.addArrangedSubview(nameAndLastSeenHourView)
        
        let nameLabel = UILabel()
        nameLabel.text = "Han Solo"
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.userNameLabel = nameLabel
        nameAndLastSeenHourView.addSubview(nameLabel)
        
        let lastSeenLabel = UILabel()
        lastSeenLabel.text = "· 2hr"
        lastSeenLabel.font = .systemFont(ofSize: 14, weight: .regular)
        lastSeenLabel.translatesAutoresizingMaskIntoConstraints = false
        self.lastSeenLabel = lastSeenLabel
        nameAndLastSeenHourView.addSubview(lastSeenLabel)
        
        let lastLocationLabel = UILabel()
        lastLocationLabel.text = "Last Seen: Brown's Cafe"
        lastLocationLabel.font = .systemFont(ofSize: 12.5, weight: .regular)
        lastLocationLabel.textColor = .secondaryLabel
        self.lastTappedLocationLabel = lastLocationLabel
        vInfoStackView.addArrangedSubview(lastLocationLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: nameAndLastSeenHourView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: nameAndLastSeenHourView.leadingAnchor),
            
            lastSeenLabel.centerYAnchor.constraint(equalTo: nameAndLastSeenHourView.centerYAnchor),
            lastSeenLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
        ])
    }
    
    private func configureExpandView() {
        expandProfileButton = UIButton()
        expandProfileButton.translatesAutoresizingMaskIntoConstraints = false
        expandProfileButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        expandProfileButton.tintColor = .systemGreen
        addSubview(expandProfileButton)
    }
    
    func set(for friend: VKUser, withInfo friendAssociatedData: VKFriendAssociatedData) {
        let friendInfo = friendAssociatedData.friendInfo
        // Display Profile Picture
        if friend.profilePictureData != nil {
            profileImageView.setImage(for: friend.getProfileUIImage())
        } else {
            profileImageView.setToDefault(for: friend)
        }
        
        // Display Name
        self.userNameLabel.text = friend.getFullName()
    
        // Display Last Tapped Time
        self.lastSeenLabel.text = "· " + Utils.getLastSeenTime(dateStamp: friendInfo.tappedTimes[friendInfo.tappedTimes.count - 1])
        
        // Display Last Tapped Location
        self.lastTappedLocationLabel.text = "Last Seen: " + self.getLastTappedLocationLabelText(address: friendAssociatedData.lastTapAddress ?? "No Location")
    }
    
    private func getLastTappedLocationLabelText(address: String) -> String {
        let displayLength = 30
        var displayLocation = "Unknown Location"
        let addressArr = address.components(separatedBy: ", ")
        
        if address.isEmpty {
            return displayLocation
        } else if addressArr.count == 1 {
            displayLocation = addressArr[0]
        } else {
            displayLocation = addressArr[0] + ", " + addressArr[1]
        }
        
        return Utils.getFormattedLengthyEllipseText(labelText: displayLocation, maxLength: displayLength)
    }
}
