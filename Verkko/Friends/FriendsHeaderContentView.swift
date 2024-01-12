//
//  FriendsHeaderContentView.swift
//  Verkko
//
//  Created by Mihir Rao on 6/1/23.
//

import UIKit

class FriendsHeaderContentView: UIView {
    private let headerView: UIView!
    private var contentView: UIView!
    private let headerLeadPadding: CGFloat!
    private let contentLeadPadding: CGFloat!
    private let headerContentPadding: CGFloat!
    
    
    required init(headerView: UIView, contentView: UIView, headerLeadPadding: CGFloat, contentLeadPadding: CGFloat, headerContentPadding: CGFloat) {
        self.headerView = headerView
        self.contentView = contentView
        self.headerLeadPadding = headerLeadPadding
        self.contentLeadPadding = contentLeadPadding
        self.headerContentPadding = headerContentPadding
        
        super.init(frame: .zero)
        
        configureHeaderView()
        configureContentView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureHeaderView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: headerLeadPadding),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -headerLeadPadding),
            headerView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func configureContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: headerContentPadding),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentLeadPadding),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentLeadPadding),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func updateContentView(with newContentView: UIView) {
        print("update content view")
        contentView.removeFromSuperview()
        contentView = newContentView
        configureContentView()
    }
}
