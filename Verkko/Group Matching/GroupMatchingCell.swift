//
//  GroupMatchingCell.swift
//  Verkko
//
//  Created by Justin Wong on 7/24/23.
//

import UIKit

class GroupMatchingCell: UITableViewCell, SkeletonLoadable {
    static let reuseIdentifier = "GroupMatchingCell"
    private var group: VKGroup?
    private var groupMembers = [VKUser]()
    private let headerView = UIView()
    private let headerViewLayer = CAGradientLayer()
    private let membersProfilePictureStackView = UIStackView()
    private let membersNameLabelView = UIView()
    private let membersCountLabel = UILabel()
    
    private let membersNameLabel = UILabel()
    private let membersNameLabelLayer = CAGradientLayer()
    
    private var groupCache: VKGroupCache?
    
    // Constants:
    private let profilePictureWidthAndHeight: CGFloat = 35
    private let padding: CGFloat = 10
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        groupMembers = [VKUser]()
        super.init(style: style, reuseIdentifier: GroupMatchingCell.reuseIdentifier)
        configureCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        headerViewLayer.frame = headerView.bounds
        headerViewLayer.cornerRadius = headerView.bounds.height / 2
        
        membersNameLabelLayer.frame = membersNameLabelView.bounds
        membersNameLabelLayer.cornerRadius = membersNameLabelView.bounds.height / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(for group: VKGroup, groupCache: VKGroupCache) {
        self.group = group
        self.groupCache = groupCache
        setColors()
        membersCountLabel.text = "\(group.membersAndStatus.count) Members"
        groupCache.fetchGroupMembers(for: group) { members in
            if let members = members {
                self.groupMembers = members
                self.groupMembers.sortAlphabeticallyAscendingByFullName()
                self.updateMembersProfilePictureStackView()
            }
        }
    }
    
    private func configureCell() {
        selectionStyle = .none
        layer.cornerRadius = 10
        clipsToBounds = true
        
        configureHeaderView()
        configureMembersNameLabel()
    }
    
    //Background color is based on the number of members in the group
    private func setColors() {
        guard let group = group else { return }
        var color: UIColor = .lightGray
        
        switch group.membersAndStatus.count {
        case 3:
            color = .systemRed
            break
        case 4:
            color = .systemOrange
            break
        case 5:
            color = .systemBlue
            break
        case 6:
            color = .systemIndigo
            break
        default:
            color = .lightGray
            break
        }
        
        backgroundColor = color.withAlphaComponent(0.3)
        membersCountLabel.backgroundColor = color.withAlphaComponent(0.45)
        layer.borderColor = color.cgColor
        layer.borderWidth = 1
        
        setUpSkeletonLoaders(with: color)
    }
    
    //MARK: Skeleton Loaders
    private func setUpSkeletonLoaders(with baseColor: UIColor) {
        hideViews()
        
        headerViewLayer.startPoint = CGPoint(x: 0, y: 0.5)
        headerViewLayer.endPoint = CGPoint(x: 0, y: 0.5)
        headerView.layer.addSublayer(headerViewLayer)
        
        membersNameLabelLayer.startPoint = CGPoint(x: 0, y: 0.5)
        membersNameLabelLayer.endPoint = CGPoint(x: 0, y: 0.5)
        membersNameLabelView.layer.addSublayer(membersNameLabelLayer)
        
        let headerViewGroup = makeAnimationGroup(baseColor: baseColor)
        headerViewGroup.beginTime = 0.0
        headerViewLayer.add(headerViewGroup, forKey: "backgroundColor")
        
        let membersNameLabelGroup = makeAnimationGroup(baseColor: baseColor, previousGroup: headerViewGroup)
        membersNameLabelLayer.add(membersNameLabelGroup, forKey: "backgroundColor")
    }
    
    private func stopSkeletonLoaders() {
        showViews()
        headerViewLayer.removeFromSuperlayer()
        membersNameLabelLayer.removeFromSuperlayer()
    }
    
    //MARK: - UI Configurations
    private func configureHeaderView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)
        
        configureMembersProfilePictureStackView()
        configureMembersCountLabel()
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            headerView.heightAnchor.constraint(equalToConstant: profilePictureWidthAndHeight)
        ])
    }
    
    private func configureMembersProfilePictureStackView() {
        membersProfilePictureStackView.axis = .horizontal
        membersProfilePictureStackView.distribution = .fill
        membersProfilePictureStackView.spacing = -10
        membersProfilePictureStackView.layer.cornerRadius = 7
        membersProfilePictureStackView.clipsToBounds = true
        membersProfilePictureStackView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(membersProfilePictureStackView)
        
        NSLayoutConstraint.activate([
            membersProfilePictureStackView.topAnchor.constraint(equalTo: headerView.topAnchor),
            membersProfilePictureStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            membersProfilePictureStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
    }
    
    private func configureMembersCountLabel() {
        membersCountLabel.isHidden = true
        membersCountLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        membersCountLabel.textAlignment = .center
        membersCountLabel.layer.cornerRadius = 7
        membersCountLabel.clipsToBounds = true
        membersCountLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(membersCountLabel)
        
        NSLayoutConstraint.activate([
            membersCountLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            membersCountLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            membersCountLabel.widthAnchor.constraint(equalToConstant: 100),
            membersCountLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
    }
    
    private func configureMembersNameLabel() {
        membersNameLabelView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(membersNameLabelView)
        
        membersNameLabel.numberOfLines = 0
        membersNameLabel.textAlignment = .left
        membersNameLabel.lineBreakMode = .byWordWrapping
        membersNameLabel.sizeToFit()
        membersNameLabel.translatesAutoresizingMaskIntoConstraints = false
        membersNameLabelView.addSubview(membersNameLabel)
        
        NSLayoutConstraint.activate([
            membersNameLabel.leadingAnchor.constraint(equalTo: membersNameLabelView.leadingAnchor),
            membersNameLabel.trailingAnchor.constraint(equalTo: membersNameLabelView.trailingAnchor),
            membersNameLabel.centerYAnchor.constraint(equalTo: membersNameLabelView.centerYAnchor),
            membersNameLabel.centerXAnchor.constraint(equalTo: membersNameLabelView.centerXAnchor),
            
            membersNameLabelView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: padding),
            membersNameLabelView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            membersNameLabelView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            membersNameLabelView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
    }
    
    private func updateMembersProfilePictureStackView() {
        stopSkeletonLoaders()
        
        membersProfilePictureStackView.removeAllArrangedSubviews()
        var membersNameArray = [String]()
        
        // Add Profile Images to stack view
        for groupMember in groupMembers {
            let groupMemberProfileImageView = VKProfileImageView(user: groupMember, widthHeight: profilePictureWidthAndHeight)
            groupMemberProfileImageView.addImageBorder()
            groupMemberProfileImageView.addShadow(color: UIColor.lightGray.cgColor)
            membersProfilePictureStackView.addArrangedSubview(groupMemberProfileImageView)
            
            membersNameArray.append("\(groupMember.getFullName())")
            
            NSLayoutConstraint.activate([
                groupMemberProfileImageView.widthAnchor.constraint(equalToConstant: profilePictureWidthAndHeight),
                groupMemberProfileImageView.heightAnchor.constraint(equalToConstant: profilePictureWidthAndHeight)
            ])
        }
        
        // Adds "spacer" at end of stack view
        let spacerView = UIView()
        membersProfilePictureStackView.addArrangedSubview(spacerView)
        NSLayoutConstraint.activate([
            spacerView.widthAnchor.constraint(equalToConstant: profilePictureWidthAndHeight),
            spacerView.heightAnchor.constraint(equalToConstant: profilePictureWidthAndHeight)
        ])
        
        membersNameLabel.text = membersNameArray.joined(separator: ", ")
    }
    
    private func hideViews() {
        membersCountLabel.isHidden = true
        membersProfilePictureStackView.isHidden = true
        membersNameLabel.isHidden = true
    }
    
    private func showViews() {
        membersCountLabel.isHidden = false
        membersProfilePictureStackView.isHidden = false
        membersNameLabel.isHidden = false
    }
}

//MARK: - SkeletonLoadable
protocol SkeletonLoadable {}

extension SkeletonLoadable {
    
    func makeAnimationGroup(baseColor: UIColor, previousGroup: CAAnimationGroup? = nil) -> CAAnimationGroup {
        let lightBaseColor = baseColor.withAlphaComponent(0.1)
        let darkBaseColor = baseColor.withAlphaComponent(0.9)
        
        let animDuration: CFTimeInterval = 1.5
        let anim1 = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.backgroundColor))
        anim1.fromValue = lightBaseColor.cgColor
        anim1.toValue = darkBaseColor.cgColor
        anim1.duration = animDuration
        anim1.beginTime = 0.0

        let anim2 = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.backgroundColor))
        anim2.fromValue = darkBaseColor.cgColor
        anim2.toValue = lightBaseColor.cgColor
        anim2.duration = animDuration
        anim2.beginTime = anim1.beginTime + anim1.duration

        let group = CAAnimationGroup()
        group.animations = [anim1, anim2]
        group.repeatCount = .greatestFiniteMagnitude // infinite
        group.duration = anim2.beginTime + anim2.duration
        group.isRemovedOnCompletion = false

        if let previousGroup = previousGroup {
            // Offset groups by 0.33 seconds for effect
            group.beginTime = previousGroup.beginTime + 0.33
        }

        return group
    }
}


