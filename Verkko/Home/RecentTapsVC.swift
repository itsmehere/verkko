//
//  RecentTapsVC.swift
//  Verkko
//
//  Created by Mihir Rao on 8/27/23.
//

import UIKit

class RecentTapsVC: UIViewController {
    private var recentTapsTableView: UITableView!
    private var recentTapsHeaderContentView: HeaderContentView!
    private var recentTapsContentViewTopAnchor: NSLayoutConstraint!
    
    private var recentlyTappedFriends = [VKUser]() {
        didSet {
            //TODO if we decide to keep recent taps view
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setConfigurationForMainVC()
        addCloseButton()
        configureRecentTapsTableView()
    }
    
    private func configureRecentTapsTableView() {
        recentTapsTableView = UITableView()
        recentTapsTableView.backgroundColor = .systemBackground
        recentTapsTableView.delegate = self
        recentTapsTableView.dataSource = self
        recentTapsTableView.register(RecentTapsCell.self, forCellReuseIdentifier: RecentTapsCell.reuseID)
        recentTapsTableView.translatesAutoresizingMaskIntoConstraints = false
        
        let recentTapsLabel = UILabel()
        recentTapsLabel.text = "Recent Taps"
        recentTapsLabel.font = .systemFont(ofSize: 18, weight: .bold)
        recentTapsLabel.translatesAutoresizingMaskIntoConstraints = false
        recentTapsLabel.textColor = .black

        recentTapsHeaderContentView = HeaderContentView(headerView: recentTapsLabel, contentView: recentTapsTableView)
        recentTapsHeaderContentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recentTapsHeaderContentView)

        NSLayoutConstraint.activate([
            recentTapsHeaderContentView.topAnchor.constraint(equalTo: view.topAnchor, constant: 65),
            recentTapsHeaderContentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            recentTapsHeaderContentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            recentTapsHeaderContentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
}

//MARK: - Delegates
extension RecentTapsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecentTapsCell.reuseID) as! RecentTapsCell
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
