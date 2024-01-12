//
//  SuggestedFriendView.swift
//  Verkko
//
//  Created by Justin Wong on 5/26/23.
//

import UIKit

class SuggestedFriendView: UIView {
    
    private let profileImageWidthAndHeight: CGFloat = 60
    private var profileImageView: VKProfileImageView!
    private let profileImage: UIImage?
    private let name: String!
    
    required init(profileImage: UIImage? = nil, name: String) {
        self.profileImage = profileImage
        self.name = name
        super.init(frame: .zero)
        
        configureView()
        updateProfileImage(with: profileImage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        backgroundColor = .none
    
        profileImageView = VKProfileImageView(user: currentUser, widthHeight: profileImageWidthAndHeight)
        addSubview(profileImageView)
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.textColor = UIColor(white: 0.5, alpha: 1)
        nameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
            
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 5),
            nameLabel.widthAnchor.constraint(equalToConstant: 100),
            
            widthAnchor.constraint(equalToConstant: 90),
            heightAnchor.constraint(equalToConstant: 90)
        ])
    }
    
    func updateProfileImage(with image: UIImage?) {
        profileImageView.setImage(for: image)
    }
}
