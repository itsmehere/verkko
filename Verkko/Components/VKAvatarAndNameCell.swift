//
//  VKAvatarAndNameCell.swift
//  Verkko
//
//  Created by Justin Wong on 7/21/23.
//

import UIKit

class VKAvatarAndNameCell: UITableViewCell {
    static let reuseID = "VKAvatarAndNameCell"
    
    private var avatarImageView: VKProfileImageView?
    private let nameLabel = UILabel()
    
    private var widthHeight: CGFloat = 45
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(for user: VKUser, widthHeight: CGFloat = 45) {
        self.widthHeight = widthHeight
        avatarImageView = VKProfileImageView(user: user, widthHeight: widthHeight)
        avatarImageView?.setImage(for: user.getProfileUIImage())
        nameLabel.text = user.getFullName()
        
        configureCell()
    }
    
    private func configureCell() {
        guard let avatarImageView = avatarImageView else { return }
        
        selectionStyle = .none
        isUserInteractionEnabled = true
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarImageView)
        
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.heightAnchor.constraint(equalToConstant: widthHeight),
            avatarImageView.widthAnchor.constraint(equalToConstant: widthHeight),
            avatarImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10)
        ])
    }
}
