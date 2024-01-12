//
//  RecentTapsCell.swift
//  Verkko
//
//  Created by Justin Wong on 5/24/23.
//

import UIKit

class RecentTapsCell: UITableViewCell {
    static let reuseID = "RecentTapsCell"
    
    private var profileImageView: VKProfileImageView!
    private var vInfoStackView: UIStackView!
    private var streaksView: UIView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureCell() {
        let profileImageWidthAndHeight: CGFloat = 50
        
        selectionStyle = .none 
        
        profileImageView = VKProfileImageView(widthHeight: profileImageWidthAndHeight)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(profileImageView)
        
        configureVInfoStackView()
        configureStreaksView()
        
        let hPadding: CGFloat = 10
        let vPadding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: hPadding),
            profileImageView.widthAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
            profileImageView.heightAnchor.constraint(equalToConstant: profileImageWidthAndHeight),
            
            vInfoStackView.topAnchor.constraint(equalTo: topAnchor, constant: vPadding),
            vInfoStackView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            vInfoStackView.trailingAnchor.constraint(equalTo: streaksView.leadingAnchor),
            vInfoStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPadding),
            
            streaksView.centerYAnchor.constraint(equalTo: centerYAnchor),
            streaksView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -hPadding),
            streaksView.widthAnchor.constraint(equalToConstant: 65),
            streaksView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func configureVInfoStackView() {
        vInfoStackView = UIStackView()
        vInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        vInfoStackView.axis = .vertical
        vInfoStackView.spacing = 5
        vInfoStackView.distribution = .fillEqually
        addSubview(vInfoStackView)
        
        let nameAndLastSeenHourView = UIView()
        vInfoStackView.addArrangedSubview(nameAndLastSeenHourView)
        
        let nameLabel = UILabel()
        nameLabel.text = "Han Solo"
        nameLabel.textColor = .systemGreen
        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameAndLastSeenHourView.addSubview(nameLabel)
        
        let lastSeenLabel = UILabel()
        lastSeenLabel.text = "· 2hr"
        lastSeenLabel.translatesAutoresizingMaskIntoConstraints = false
        nameAndLastSeenHourView.addSubview(lastSeenLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: nameAndLastSeenHourView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: nameAndLastSeenHourView.leadingAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: 30),
            
            lastSeenLabel.centerYAnchor.constraint(equalTo: nameAndLastSeenHourView.centerYAnchor),
            lastSeenLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            lastSeenLabel.widthAnchor.constraint(equalToConstant: 100),
            lastSeenLabel.heightAnchor.constraint(equalToConstant: 30),
        ])
    
        let locationLabel = UILabel()
        locationLabel.text = "Brown's Cafe"
        locationLabel.textColor = .secondaryLabel
        vInfoStackView.addArrangedSubview(locationLabel)
    }
    
    private func configureStreaksView() {
        streaksView = UIView()
        streaksView.translatesAutoresizingMaskIntoConstraints = false
        streaksView.layer.cornerRadius = 15
        streaksView.backgroundColor = .systemGray5
        addSubview(streaksView)
        
        let flameImage = UIImage(systemName: "flame.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 16)))
        let fireImageView = UIImageView(image: flameImage)
        fireImageView.tintColor = .systemOrange
        fireImageView.translatesAutoresizingMaskIntoConstraints = false
        streaksView.addSubview(fireImageView)
        
        let streakNumberLabel = UILabel()
        streakNumberLabel.text = "214"
        streakNumberLabel.font = .systemFont(ofSize: 15, weight: .bold)
        streakNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        streaksView.addSubview(streakNumberLabel)
        
        NSLayoutConstraint.activate([
            fireImageView.centerYAnchor.constraint(equalTo: streaksView.centerYAnchor),
            fireImageView.leadingAnchor.constraint(equalTo: streaksView.leadingAnchor, constant: 5),
            fireImageView.widthAnchor.constraint(equalToConstant: 20),
            fireImageView.heightAnchor.constraint(equalToConstant: 20),
            
            streakNumberLabel.centerYAnchor.constraint(equalTo: streaksView.centerYAnchor),
            streakNumberLabel.leadingAnchor.constraint(equalTo: fireImageView.trailingAnchor, constant: 5),
            streakNumberLabel.widthAnchor.constraint(equalToConstant: 30),
            streakNumberLabel.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
}
