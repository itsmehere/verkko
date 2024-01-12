//
//  InterestsDisplayTileView.swift
//  Verkko
//
//  Created by Mihir Rao on 5/31/23.
//

import UIKit

class InterestsDisplayTileView: UIView {
    private let interest: String!
    private let interestColor: UIColor!
    
    required init(interest: String, interestColor: UIColor) {
        self.interest = interest
        self.interestColor = interestColor

        super.init(frame: .zero)
        
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        backgroundColor = interestColor
        layer.cornerRadius = 22

        let minWidth = 60
        let maxWidth = 200
        
        let interestLabel = UILabel()
        interestLabel.text = Utils.getFormattedLengthyEllipseText(labelText: interest, maxLength: 20)
        interestLabel.textColor = .white
        interestLabel.numberOfLines = 2
        interestLabel.font = .systemFont(ofSize: 14, weight: .regular)
        interestLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(interestLabel)
        
        NSLayoutConstraint.activate([
            interestLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            interestLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            widthAnchor.constraint(equalToConstant: CGFloat(min(minWidth + interestLabel.text!.count * 5, maxWidth))),
            heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
