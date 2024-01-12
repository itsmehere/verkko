//
//  PhotoFeedCell.swift
//  Verkko
//
//  Created by Mihir Rao on 8/22/23.
//

import UIKit
import MapKit

class PhotoFeedCell: UITableViewCell {
    static let reuseID = "PhotoFeedCell"
    
    private var photoTile: UIView!
    private var topSectionView: UIView!
    private var profileImageView1: VKProfileImageView!
    private var profileImageView2: VKProfileImageView!
    private var nameLabel: UILabel!
    private var locationLabel: UILabel!
    private var photoView: UIImageView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureCell() {
        photoTile = UIView()
        photoTile.backgroundColor = .white
        photoTile.layer.shadowColor = UIColor.black.cgColor
        photoTile.layer.shadowOpacity = 0.08
        photoTile.layer.shadowOffset = .zero
        photoTile.layer.shadowRadius = 12
        photoTile.translatesAutoresizingMaskIntoConstraints = false
        addSubview(photoTile)
        
        topSectionView = createUserLabelView()
        topSectionView.translatesAutoresizingMaskIntoConstraints = false
        photoTile.addSubview(topSectionView)
                
        NSLayoutConstraint.activate([
            photoTile.heightAnchor.constraint(equalToConstant: 420),
            photoTile.leadingAnchor.constraint(equalTo: leadingAnchor),
            photoTile.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            topSectionView.topAnchor.constraint(equalTo: photoTile.topAnchor, constant: 12),
            topSectionView.leadingAnchor.constraint(equalTo: photoTile.leadingAnchor, constant: 15),
            topSectionView.trailingAnchor.constraint(equalTo: photoTile.trailingAnchor),
        ])
        
        photoView = UIImageView()
        photoView.translatesAutoresizingMaskIntoConstraints = false
        photoTile.addSubview(photoView)

        NSLayoutConstraint.activate([
            photoView.topAnchor.constraint(equalTo: topSectionView.bottomAnchor, constant: 12),
            photoView.leadingAnchor.constraint(equalTo: photoTile.leadingAnchor),
            photoView.trailingAnchor.constraint(equalTo: photoTile.trailingAnchor),
            photoView.bottomAnchor.constraint(equalTo: photoTile.bottomAnchor)
        ])
    }
    
    private func createUserLabelView() -> UIStackView {
        let userLabelHStack = UIStackView()
        userLabelHStack.translatesAutoresizingMaskIntoConstraints = false
        userLabelHStack.axis = .horizontal
        userLabelHStack.spacing = 10
        userLabelHStack.alignment = .center
        userLabelHStack.distribution = .fill
        
        let photoStack = UIStackView()
        photoStack.translatesAutoresizingMaskIntoConstraints = false
        photoStack.axis = .horizontal
        photoStack.spacing = -15
        photoStack.alignment = .center
        photoStack.distribution = .fill
        userLabelHStack.addArrangedSubview(photoStack)
        
        let profileImageWidthAndHeight: CGFloat = 35
        profileImageView1 = VKProfileImageView(pfpData: Data(), name: "User 1", widthHeight: profileImageWidthAndHeight)
        profileImageView1.translatesAutoresizingMaskIntoConstraints = false
        photoStack.addArrangedSubview(profileImageView1)
        
        profileImageView2 = VKProfileImageView(pfpData: Data(), name: "User 2", widthHeight: profileImageWidthAndHeight)
        profileImageView2.translatesAutoresizingMaskIntoConstraints = false
        photoStack.addArrangedSubview(profileImageView2)
        
        // Stack view for name and mutuals
        let vInfoStackView = UIStackView()
        vInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        vInfoStackView.axis = .vertical
        vInfoStackView.spacing = 0
        userLabelHStack.addArrangedSubview(vInfoStackView)
        
        nameLabel = UILabel()
        nameLabel.text = ""
        nameLabel.textColor = .black
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        vInfoStackView.addArrangedSubview(nameLabel)
        
        locationLabel = UILabel()
        locationLabel.textColor = .systemGray
        locationLabel.text = "Unknown Location"
        locationLabel.font = .systemFont(ofSize: 12, weight: .regular)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        vInfoStackView.addArrangedSubview(locationLabel)
        
        NSLayoutConstraint.activate([
            profileImageView1.widthAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
            profileImageView1.heightAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
            
            profileImageView2.widthAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
            profileImageView2.heightAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
        ])
        
        return userLabelHStack
    }
    
    private func formatLocationLabelText(address: String) -> String {
        let displayLength = 35
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
    
    func set(for photoData: (UIImage, VKPhotoData)) {
        profileImageView1.profileImageView.image = UIImage(data: photoData.1.pfp1!)
        profileImageView1.name = photoData.1.name1

        profileImageView2.profileImageView.image = UIImage(data: photoData.1.pfp2!)
        profileImageView2.name = photoData.1.name2
        
        nameLabel.text = photoData.1.name1 + " and " + photoData.1.name2
        
        photoView.image = photoData.0
        
        Utils.getAddressFromLatLon(lat: photoData.1.lat, lon: photoData.1.lon) { result in
            switch result {
            case .success(let address):
                self.locationLabel.text = self.formatLocationLabelText(address: address) + " • " + Utils.getLastSeenTime(dateStamp: photoData.1.date)
            case .failure(_):
                self.locationLabel.text = "Unknown Location" + " • " + Utils.getLastSeenTime(dateStamp: photoData.1.date)
            }
        }
    }
}
