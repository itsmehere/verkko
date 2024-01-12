//
//  VKEmptyStateView.swift
//  Verkko
//
//  Created by Justin Wong on 6/8/23.
//

import UIKit

class VKEmptyStateView: UIView {
    
    private let messageLabel: VKTitleLabel!
    
    required init(message: String,
                  fontSize: CGFloat = 20,
                  textAlignment: NSTextAlignment = .center) {
        messageLabel = VKTitleLabel(textAlignment: .center, fontSize: fontSize)
        super.init(frame: .zero)
        
        messageLabel.text = message
        messageLabel.textAlignment = textAlignment
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        addSubview(messageLabel)
        
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 3
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageLabel.heightAnchor.constraint(equalToConstant: 200),
        ])
    }
}
