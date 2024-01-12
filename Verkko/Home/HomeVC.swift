//
//  HomeVC.swift
//  Verkko
//
//  Created by Justin Wong on 5/24/23.
//

import UIKit
import DeviceKit
import MapKit

class HomeVC: UIViewController {
    private var homeScrollView: UIScrollView!
    
    private var suggestedFriendsView: HeaderContentView!
    private var noSuggestedFriendsView: UIView!
    private let suggestedFriendsActivityIndicator = UIActivityIndicatorView(style: .medium)
    private let suggestedFriendsStackView = UIStackView()
    private var suggestedFriends = [VKUser]()
    private let suggestedFriendsViewHeight: CGFloat = 130
    
    private var photoFeedTableView: UITableView!
    private var noPhotosView: UIView!
    private var photoFeed = [(UIImage, VKPhotoData)]() {
        didSet {
            self.reloadPhotoTableView()
        }
    }
    
    private var tapButton = UIButton(type: .custom)
    
    private var lineView: UIView!
    private var loadingPhotosIndicator: UIActivityIndicatorView!
    private let headerLabelFontSize: CGFloat = 18
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setConfigurationForMainVC()
        
        configureHomeScrollView()
        configureLoadingView()
        configureSuggestedFriendsView()
        configurePhotoFeedView()
        configureNoPhotoFeedView()
        configureTapButton()
        
        refreshSuggestedFriendsUI()
        fetchSuggestedFriends()
        
        if let currentUser = FirebaseManager.shared.currentUser {
            getFeed(for: currentUser)
        }
    }
    
    //MARK: Home Scroll View Setup
    private func configureHomeScrollView() {
        homeScrollView = UIScrollView()
        homeScrollView.contentSize = CGSize(width: view.frame.size.width, height: view.frame.size.height * 1.25)
        homeScrollView.showsVerticalScrollIndicator = false
        homeScrollView.showsHorizontalScrollIndicator = false
        homeScrollView.bounces = true
        homeScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(homeScrollView)
        
        NSLayoutConstraint.activate([
            homeScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            homeScrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            homeScrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            homeScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    private func configureLoadingView() {
        loadingPhotosIndicator = UIActivityIndicatorView()
        loadingPhotosIndicator.center = view.center
        loadingPhotosIndicator.hidesWhenStopped = true
        loadingPhotosIndicator.style = .medium
        view.addSubview(loadingPhotosIndicator)
        
        NSLayoutConstraint.activate([
            loadingPhotosIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingPhotosIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    //MARK: - Sugggested Friends 
    private func configureSuggestedFriendsView() {
        suggestedFriendsView = HeaderContentView(headerView: createSuggestedFriendsHeader(), contentView: createSuggestedFriendsHorizontalScrollView())
        suggestedFriendsView.translatesAutoresizingMaskIntoConstraints = false
        homeScrollView.addSubview(suggestedFriendsView)
        
        createNoSuggestedFriendsView()
                
        NSLayoutConstraint.activate([
            suggestedFriendsView.topAnchor.constraint(equalTo: homeScrollView.topAnchor),
            suggestedFriendsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            suggestedFriendsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            suggestedFriendsView.heightAnchor.constraint(equalToConstant: suggestedFriendsViewHeight),
        ])
    }
    
    private func createSuggestedFriendsHeader() -> UIView {
        let suggestedFriendsHeader = UIView()
        suggestedFriendsHeader.translatesAutoresizingMaskIntoConstraints = false
        
        let suggestedFriendsHeaderLabel = UILabel()
        suggestedFriendsHeaderLabel.text = "Suggested Friends"
        suggestedFriendsHeaderLabel.font = UIFont.systemFont(ofSize: VKConstants.headerLabelFontSize, weight: .bold)
        suggestedFriendsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        suggestedFriendsHeader.addSubview(suggestedFriendsHeaderLabel)
        
        suggestedFriendsActivityIndicator.color = .lightGray
        suggestedFriendsActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        suggestedFriendsHeader.addSubview(suggestedFriendsActivityIndicator)
        
        let sortButton = UIButton(type: .custom)
        sortButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        sortButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        sortButton.tintColor = .systemGreen
        sortButton.translatesAutoresizingMaskIntoConstraints = false
        suggestedFriendsHeader.addSubview(sortButton)
        
        let sortSuggestedFriendsMenu = UIMenu(title: "", children: [
            UIAction(title: "Sort Ascending", image: UIImage(systemName: "chevron.up")) { _ in
                self.suggestedFriends.sort(by: { $0.getFullName() < $1.getFullName() })
                self.refreshSuggestedFriendsUI()
            },
            UIAction(title: "Sort Descending", image: UIImage(systemName: "chevron.down")) { _ in
                self.suggestedFriends.sort(by: { $0.getFullName() > $1.getFullName() })
                self.refreshSuggestedFriendsUI()
            },
//            UIAction(title: "View Recent Taps", image: UIImage(systemName: "clock")) { _ in
//                let recentTapsVC = UINavigationController(rootViewController: RecentTapsVC())
//                self.present(recentTapsVC, animated: true)
//            }
        ])
        
        sortButton.menu = sortSuggestedFriendsMenu
        sortButton.showsMenuAsPrimaryAction = true
        
        NSLayoutConstraint.activate([
            suggestedFriendsHeaderLabel.leadingAnchor.constraint(equalTo: suggestedFriendsHeader.leadingAnchor, constant: 6.5),
            suggestedFriendsHeaderLabel.topAnchor.constraint(equalTo: suggestedFriendsHeader.topAnchor),
            suggestedFriendsHeaderLabel.bottomAnchor.constraint(equalTo: suggestedFriendsHeader.bottomAnchor),
            suggestedFriendsHeaderLabel.heightAnchor.constraint(equalToConstant: 20),
            
            suggestedFriendsActivityIndicator.leadingAnchor.constraint(equalTo: suggestedFriendsHeaderLabel.trailingAnchor, constant: 5),
            suggestedFriendsActivityIndicator.topAnchor.constraint(equalTo: suggestedFriendsHeader.topAnchor),
            suggestedFriendsActivityIndicator.bottomAnchor.constraint(equalTo: suggestedFriendsHeader.bottomAnchor),
            suggestedFriendsActivityIndicator.heightAnchor.constraint(equalToConstant: 20),
            
            sortButton.trailingAnchor.constraint(equalTo: suggestedFriendsHeader.trailingAnchor),
            sortButton.centerYAnchor.constraint(equalTo: suggestedFriendsHeader.centerYAnchor),
            sortButton.heightAnchor.constraint(equalToConstant: 40),
            sortButton.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        return suggestedFriendsHeader
    }
    
    private func createSuggestedFriendsHorizontalScrollView() -> UIScrollView {
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.contentSize = CGSize(width: 1000, height: 150)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
         
        suggestedFriendsStackView.axis = .horizontal
        suggestedFriendsStackView.spacing = 20
        suggestedFriendsStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(suggestedFriendsStackView)
        
        NSLayoutConstraint.activate([
            suggestedFriendsStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            suggestedFriendsStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            suggestedFriendsStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            suggestedFriendsStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        return scrollView
    }
    
    private func createNoSuggestedFriendsView() {
        noSuggestedFriendsView = UIView()
        noSuggestedFriendsView.translatesAutoresizingMaskIntoConstraints = false
        noSuggestedFriendsView.isHidden = true
        homeScrollView.addSubview(noSuggestedFriendsView)

        let noSuggestedFriendsLabel = UILabel()
        noSuggestedFriendsLabel.text = "No Suggested Friends Yet"
        noSuggestedFriendsLabel.font = .systemFont(ofSize: 18, weight: .bold)
        noSuggestedFriendsLabel.textColor = .systemGray
        noSuggestedFriendsLabel.translatesAutoresizingMaskIntoConstraints = false
        noSuggestedFriendsView.addSubview(noSuggestedFriendsLabel)
        
        NSLayoutConstraint.activate([
            noSuggestedFriendsLabel.centerXAnchor.constraint(equalTo: noSuggestedFriendsView.centerXAnchor),
            noSuggestedFriendsLabel.topAnchor.constraint(equalTo: suggestedFriendsView.centerYAnchor),
            
            noSuggestedFriendsView.topAnchor.constraint(equalTo: homeScrollView.topAnchor),
            noSuggestedFriendsView.centerXAnchor.constraint(equalTo: homeScrollView.centerXAnchor),
            noSuggestedFriendsView.heightAnchor.constraint(equalToConstant: 100),
        ])
    }
    
    private func fetchSuggestedFriends() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        let currentUserFriendsUIDs = Array(currentUser.friends.keys)
        self.suggestedFriendsActivityIndicator.startAnimating()

        GroupMatchingManager.getNestedConnectedFriends(for: 10, current: currentUser.uid, connectedFriends: [], goneThroughFriends: currentUserFriendsUIDs) { friends in
            self.suggestedFriendsActivityIndicator.stopAnimating()
            FirebaseManager.shared.getUsers(for: friends) { result in
                switch result {
                case .success(let suggestedFriends):
                    self.suggestedFriends = suggestedFriends
                    self.suggestedFriends.sortAlphabeticallyAscendingByFullName()
                    self.refreshSuggestedFriendsUI()
                case .failure(let error):
                    self.presentVKAlert(title: "Error Fetching Friends", message: error.localizedDescription, buttonTitle: "OK")
                }
            }
        }
    }
    
    private func refreshSuggestedFriendsUI() {
        if !suggestedFriends.isEmpty {
            suggestedFriendsStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
            DispatchQueue.main.async {
                self.suggestedFriendsView.isHidden = false
                self.noSuggestedFriendsView.isHidden = true
                for i in 0..<min(self.suggestedFriends.count, 10) {
                    let suggestedFriend = self.suggestedFriends[i]
                    let suggestedFriendView = SuggestedFriendView(name: suggestedFriend.firstName)
                    suggestedFriendView.translatesAutoresizingMaskIntoConstraints = false
                    suggestedFriendView.updateProfileImage(with: suggestedFriend.getProfileUIImage())
                    self.suggestedFriendsStackView.addArrangedSubview(suggestedFriendView)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.suggestedFriendsView.isHidden = true
                self.noSuggestedFriendsView.isHidden = false
                self.homeScrollView.bringSubviewToFront(self.noSuggestedFriendsView)
            }
        }
    }
    
    //MARK: Photo Feed View
    private func configurePhotoFeedView() {
        photoFeedTableView = UITableView()
        photoFeedTableView.delegate = self
        photoFeedTableView.dataSource = self
        photoFeedTableView.register(PhotoFeedCell.self, forCellReuseIdentifier: PhotoFeedCell.reuseID)
        photoFeedTableView.translatesAutoresizingMaskIntoConstraints = false
        photoFeedTableView.separatorStyle = .none
        photoFeedTableView.isScrollEnabled = false
        photoFeedTableView.showsVerticalScrollIndicator = false
        photoFeedTableView.showsHorizontalScrollIndicator = false
        homeScrollView.addSubview(photoFeedTableView)

        NSLayoutConstraint.activate([
            photoFeedTableView.topAnchor.constraint(equalTo: suggestedFriendsView.bottomAnchor),
            photoFeedTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            photoFeedTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            photoFeedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        lineView = UIView(frame: CGRect(x: 0, y: suggestedFriendsViewHeight, width: view.bounds.width, height: 1.0))
        lineView.layer.borderWidth = 1.0
        lineView.layer.borderColor = UIColor(white: 0.92, alpha: 1).cgColor
        lineView.isHidden = true
        homeScrollView.addSubview(lineView)
    }
    
    private func getFeed(for user: VKUser) {
        loadingPhotosIndicator.startAnimating()
        
        FirebaseManager.shared.getFeed(photoIDs: user.feed) { result in
            switch result {
            case .success(let photoFeed):
                self.photoFeed = photoFeed
                self.loadingPhotosIndicator.stopAnimating()
                self.lineView.isHidden = false
            case .failure(let error):
                self.presentVKAlert(title: "Failed to Fetch Feed", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    private func configureNoPhotoFeedView() {
        noPhotosView = UIView()
        noPhotosView.translatesAutoresizingMaskIntoConstraints = false
        noPhotosView.isHidden = true
        photoFeedTableView.backgroundView = noPhotosView
        
        let config = UIImage.SymbolConfiguration(pointSize: 70, weight: .ultraLight)
        let noPhotosIcon = UIImageView(image: UIImage(systemName: "checkmark.circle", withConfiguration: config))
        noPhotosIcon.tintColor = .systemGray
        noPhotosIcon.translatesAutoresizingMaskIntoConstraints = false
        noPhotosView.addSubview(noPhotosIcon)

        let noPhotosLabel = UILabel()
        noPhotosLabel.text = "You're all caught up!"
        noPhotosLabel.font = .systemFont(ofSize: 20, weight: .bold)
        noPhotosLabel.textColor = .systemGray
        noPhotosLabel.translatesAutoresizingMaskIntoConstraints = false
        noPhotosView.addSubview(noPhotosLabel)
        
        NSLayoutConstraint.activate([
            noPhotosIcon.topAnchor.constraint(equalTo: noPhotosView.topAnchor, constant: 80),
            noPhotosIcon.centerXAnchor.constraint(equalTo: noPhotosView.centerXAnchor),
            noPhotosLabel.centerXAnchor.constraint(equalTo: noPhotosView.centerXAnchor),
            noPhotosLabel.topAnchor.constraint(equalTo: noPhotosIcon.bottomAnchor, constant: 10),
            
            noPhotosView.topAnchor.constraint(equalTo: suggestedFriendsView.bottomAnchor, constant: 50),
            noPhotosView.centerXAnchor.constraint(equalTo: photoFeedTableView.centerXAnchor),
            noPhotosView.heightAnchor.constraint(equalToConstant: 100),
        ])
    }
    
    private func reloadPhotoTableView() {
        if photoFeed.count == 0 {
            noPhotosView.isHidden = false
            homeScrollView.isScrollEnabled = false
        } else {
            noPhotosView.isHidden = true
            homeScrollView.isScrollEnabled = true
            photoFeedTableView.reloadData()
        }
    }
    
    //MARK: Tap Button
    private func configureTapButton() {
        view.addSubview(tapButton)
        tapButton.translatesAutoresizingMaskIntoConstraints = false
        tapButton.setTitle("Discover  🔭", for: .normal)
        tapButton.backgroundColor = .systemGreen
        tapButton.tintColor = .white
        tapButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 25)
        tapButton.layer.cornerRadius = 15
        tapButton.layer.shadowColor = UIColor.black.cgColor
        tapButton.layer.shadowOpacity = 0.25
        tapButton.layer.shadowOffset = .zero
        tapButton.layer.shadowRadius = 10
        tapButton.addTarget(self, action: #selector(clickedTapButton), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            tapButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            tapButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            tapButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            tapButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    @objc private func clickedTapButton() {
        let device = Device.current
        let unsupportedDevices: [Device] = [.iPhone8, .iPhone8Plus, .iPhoneX, .iPhoneXR, .iPhoneXS, .iPhoneXSMax]

        if unsupportedDevices.contains(device) {
            let qrCodeTapVC = UINavigationController(rootViewController: QRCodeTapVC())
            present(qrCodeTapVC, animated: true)
        } else  {
            let discoveringPeersVC = UINavigationController(rootViewController: DiscoveringPeersVC())
            present(discoveringPeersVC, animated: true)
        }
    }
}

//MARK: - Delegates
extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photoFeed.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let photoData = photoFeed[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotoFeedCell.reuseID) as! PhotoFeedCell
        cell.selectionStyle = .none

        // Configure cell info for given friend
        cell.set(for: photoData)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 420
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let photoData = photoFeed[indexPath.row]
        let coordinate = CLLocationCoordinate2DMake(photoData.1.lat, photoData.1.lon)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))

        Utils.getAddressFromLatLon(lat: photoData.1.lat, lon: photoData.1.lon) { result in
            switch result {
            case .success(let address):
                mapItem.name = address
                mapItem.openInMaps()
            case .failure(_):
                mapItem.openInMaps()
            }
        }
    }
}
