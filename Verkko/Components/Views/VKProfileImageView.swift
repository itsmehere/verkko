//
//  VKProfileImageView.swift
//  Verkko
//
//  Created by Justin Wong on 5/26/23.
//

import UIKit

class VKProfileImageView: UIView {
    private var profileImageOuterView = UIView()
    public var profileImageView = UIImageView()
    private var profileImageWidthHeight: CGFloat = 150
    private let initialLabel = UILabel()
    private let radialBackground = CAGradientLayer()
    private var user: VKUser?
    
    private var pfpData: Data?
    public var name: String?
    
    init(user: VKUser? = nil, widthHeight: CGFloat) {
        profileImageWidthHeight = widthHeight
        self.user = user
        super.init(frame: CGRect(x: 0, y: 0, width: widthHeight, height: widthHeight))
        
        setDefaultImage()
        configureProfileImageView()
        updateGradientColors()
    }
    
    init(pfpData: Data?, name: String, widthHeight: CGFloat) {
        profileImageWidthHeight = widthHeight
        self.pfpData = pfpData
        self.name = name
        super.init(frame: CGRect(x: 0, y: 0, width: widthHeight, height: widthHeight))

        setDefaultImage()
        configureProfileImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateGradientColors()
    }
    
    func setImage(for image: UIImage?) {
        if let image = image {
            profileImageView.image = image
        } else if let pfpData = pfpData {
            profileImageView.image = UIImage(data: pfpData)
        } else {
            return
        }
        
        radialBackground.isHidden = true
        initialLabel.isHidden = true
        profileImageView.isHidden = false
        addImageBorder()
    }

    func setToDefault(for user: VKUser?) {
        if let user = user {
            initialLabel.text = user.getInitials()
        } else {
            return
        }
        
        profileImageView.isHidden = true
        radialBackground.isHidden = false
        initialLabel.isHidden = false
        addImageBorder()
    }
    
    func update(with user: VKUser?) {
        guard let user = user else { return }
        
        if let profileImage = user.getProfileUIImage() {
            setImage(for: profileImage)
        } else {
            setToDefault(for: user)
        }
    }
    
    private func updateGradientColors() {
        radialBackground.colors = [UIColor.systemGreen.withAlphaComponent(1).cgColor, UIColor.systemGreen.withAlphaComponent(1).cgColor]
//        if traitCollection.userInterfaceStyle == .light {
//            radialBackground.colors = [UIColor.systemGreen.withAlphaComponent(0.5).cgColor, UIColor.systemGreen.withAlphaComponent(0.8).cgColor]
//        } else {
//            radialBackground.colors = [UIColor.systemGreen.withAlphaComponent(0.8).cgColor, UIColor.systemGreen.withAlphaComponent(0.5).cgColor]
//        }
    }
    
    private func configureProfileImageView() {
        translatesAutoresizingMaskIntoConstraints = false
        
        profileImageOuterView = UIView(frame: CGRect(x: 0, y: 0, width: profileImageWidthHeight, height: profileImageWidthHeight))
        profileImageOuterView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileImageOuterView)
        
        profileImageView = UIImageView(frame: profileImageOuterView.bounds)
        profileImageView.tintColor = .lightGray
        profileImageOuterView.addSubview(profileImageView)
    
        // add a round mask, inset by 1.0 so we don't see the anti-aliased edge
        // TODO: Check to see if necessary. Because with this, shadows don't work anymore
        // let msk = CAShapeLayer()
        // msk.path = UIBezierPath(ovalIn: bounds.insetBy(dx: 1.0, dy: 1.0)).cgPath
        // layer.mask = msk
        
        setImage(for: user?.getProfileUIImage())
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.masksToBounds = false
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        
        NSLayoutConstraint.activate([
            profileImageOuterView.widthAnchor.constraint(equalToConstant: profileImageWidthHeight),
            profileImageOuterView.heightAnchor.constraint(equalToConstant: profileImageWidthHeight),
            
            profileImageOuterView.topAnchor.constraint(equalTo: topAnchor),
            profileImageOuterView.leadingAnchor.constraint(equalTo: leadingAnchor),
            profileImageOuterView.trailingAnchor.constraint(equalTo: trailingAnchor),
            profileImageOuterView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: profileImageOuterView.topAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: profileImageOuterView.leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: profileImageOuterView.trailingAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: profileImageOuterView.bottomAnchor)
        ])
    }
    
    private func setDefaultImage() {
        let initialsScalingConstant: CGFloat = 2.3
        
        layer.masksToBounds = false
        layer.cornerRadius = profileImageWidthHeight / 2
        clipsToBounds = true
        
        radialBackground.type = .radial
        radialBackground.startPoint = CGPoint(x: 0.5, y: 0.5)
        radialBackground.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(radialBackground)
        radialBackground.frame = bounds
        
        initialLabel.textColor = .white
        initialLabel.font = UIFont.systemFont(ofSize: profileImageWidthHeight / initialsScalingConstant, weight: .bold)
        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(initialLabel)
        
        setToDefault(for: user)
        
        NSLayoutConstraint.activate([
            initialLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            initialLabel.heightAnchor.constraint(equalToConstant: profileImageWidthHeight / initialsScalingConstant),
            initialLabel.heightAnchor.constraint(equalToConstant: profileImageWidthHeight / initialsScalingConstant)
        ])
    }
    
    public func addImageBorder(borderColor: UIColor? = nil) {
        self.layer.cornerRadius = self.frame.size.width / 2
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1.0
        
        if let color = borderColor {
            self.layer.borderColor = color.cgColor
        } else {
            self.layer.borderColor = CGColor(gray: 3/4, alpha: 1)
        }
    }
    
    public func removeImageBorder() {
        self.layer.borderWidth = 0
    }
    
    func addShadow(color: CGColor, opacity: Float = 1, offset: CGSize = .zero, radius: CGFloat = 10) {
        profileImageOuterView.layer.shadowColor = color
        profileImageOuterView.layer.shadowOpacity = opacity
        profileImageOuterView.layer.shadowOffset = offset
        profileImageOuterView.layer.shadowRadius = radius
        profileImageOuterView.layer.shadowPath = UIBezierPath(roundedRect: profileImageOuterView.bounds, cornerRadius: profileImageView.frame.size.width / 2).cgPath
    }
}
