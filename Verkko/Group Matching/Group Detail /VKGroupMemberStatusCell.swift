//
//  VKGroupMemberStatusCell.swift
//  Verkko
//
//  Created by Justin Wong on 7/31/23.
//

import UIKit

class VKGroupMemberStatusCell: VKAvatarAndNameCell {
    static let subclassReuseID = "VKGroupMemberStatusCell"
    
    private let statusView = UIView()
    private let statusLabel = UILabel()
    
    private var member: VKUser?
    private var group: VKGroup?
    private var cellActionHandler: ((VKError) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureStatusView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(for user: VKUser, group: VKGroup, widthHeight: CGFloat = 45, cellActionHandler: ((VKError) -> Void)?) {
        self.member = user
        self.group = group
        self.cellActionHandler = cellActionHandler
        super.set(for: user, widthHeight: widthHeight)
        
        updateStatusView()
    }
    
    private func configureStatusView() {
        statusLabel.textColor = .white
        statusLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusView.addSubview(statusLabel)
        
        statusView.layer.cornerRadius = 8
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        
        let toggleStatusTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleStatus))
        statusView.addGestureRecognizer(toggleStatusTapGestureRecognizer)
        
        NSLayoutConstraint.activate([
            statusLabel.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
            statusLabel.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            
            statusView.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusView.widthAnchor.constraint(equalToConstant: 100),
            statusView.heightAnchor.constraint(equalToConstant: 30),
            statusView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }
    
    private func updateStatusView() {
        guard let currentUser = FirebaseManager.shared.currentUser, let group = group, let member = member else { return }
        
        statusLabel.text = group.membersAndStatus[member.uid]?.description
        statusView.backgroundColor = getStatusViewBackgroundColor().withAlphaComponent(0.6)
        
        if member.uid == currentUser.uid {
            statusView.isUserInteractionEnabled = true
            statusView.layer.borderColor = getStatusViewBackgroundColor().cgColor
            statusView.layer.borderWidth = 3.5
        } else {
            statusView.layer.borderColor = .none
            statusView.layer.borderWidth = 0
            statusView.isUserInteractionEnabled = false
        }
    }
    
    private func getStatusViewBackgroundColor() -> UIColor {
        guard let group = group,
              let member = member,
              let acceptanceStatus = group.membersAndStatus[member.uid] else { return .clear }
        switch acceptanceStatus {
        case .accepted:
            return .systemGreen
        case .pending:
            return .systemYellow
        case .declined:
            return .systemRed
        }
    }
    
    @objc private func toggleStatus() {
        guard let member = member, let group = group else { return }
        
        switch group.getStatus(for: member.uid) {
        case .accepted:
            //Toggle to Pending
            FirebaseManager.shared.updateGroup(for: group.jointID, fields: [
                "\(VKConstants.membersAndStatus).\(member.uid)": VKGroupAcceptanceStatus.pending.description
            ]) { error in
                if let error = error, let cellActionHandler = self.cellActionHandler {
                    cellActionHandler(error)
                }
            }
        case .pending:
            //Toggle to Declined
            FirebaseManager.shared.updateGroup(for: group.jointID, fields: [
                "\(VKConstants.membersAndStatus).\(member.uid)": VKGroupAcceptanceStatus.declined.description
            ]) { error in
                if let error = error, let cellActionHandler = self.cellActionHandler {
                    cellActionHandler(error)
                }
            }
        case .declined:
            //Toggle to Accepted
            FirebaseManager.shared.updateGroup(for: group.jointID, fields: [
                "\(VKConstants.membersAndStatus).\(member.uid)": VKGroupAcceptanceStatus.accepted.description
            ]) { error in
                if let error = error, let cellActionHandler = self.cellActionHandler {
                    cellActionHandler(error)
                }
            }
        }
    }
}

