//
//  HeaderContentView.swift
//  Verkko
//
//  Created by Justin Wong on 5/24/23.
//

import UIKit

class HeaderContentView: UIView {
    
    private let headerView: UIView!
    private let contentView: UIView!
    
    required init(headerView: UIView, contentView: UIView) {
        self.headerView = headerView
        self.contentView = contentView
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(headerView)
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            headerView.heightAnchor.constraint(equalToConstant: 20),
            
            contentView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
