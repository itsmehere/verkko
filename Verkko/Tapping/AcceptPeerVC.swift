//
//  AcceptPeerVC.swift
//  Verkko
//
//  Created by Justin Wong on 6/11/23.
//

import UIKit
import CoreLocation

//MARK: - AcceptPeerVC
class AcceptPeerVC: UIViewController, CLLocationManagerDelegate {
    private var acceptStatusHandler: ((VKPeerStatus, VKSharingPermission?) -> Void)?
    private var stopCommunicating: (() -> Void)?
    
    private var peer: VKUser!
    private var profilePictureView: VKProfileImageView!
    private let nameStack = UIStackView()
    private var buttonStackView = UIStackView()
    private var shareAndAcceptButton: UIButton!
    private var dontShareAndAcceptButton: UIButton!
    private var statusLabel: UILabel!
    private let profilePictureWidthAndHeight: CGFloat = 220
    private let networkManager = NetworkManager()
    private var tapPhoto: UIImage?
    private var shareAll = false
    private var currentUserSharingPermission: VKSharingPermission?
    private var oldCurrentUser: VKUser?
    
    required init(peer: VKUser,
                  acceptStatusHandler: ((VKPeerStatus, VKSharingPermission?) -> Void)?,
                  stopCommunicating: (() -> Void)?) {
        self.peer = peer
        self.acceptStatusHandler = acceptStatusHandler
        self.stopCommunicating = stopCommunicating
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        oldCurrentUser = FirebaseManager.shared.currentUser
        currentUserSharingPermission = SettingsManager.getCurrentUserSharingPermission()
        configureVC()
        configureStatusLabel()
        configureButtonStackView()
        configureProfilePictureView()
        configureNameStack()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismiss(animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureVC() {
        view.backgroundColor = .systemBackground
        navigationItem.setHidesBackButton(true, animated: true)
    }
    
    private func configureStatusLabel() {
        statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 14, weight: .regular)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5),
        ])
    }
    
    private func configureButtonStackView() {
        buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 10
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStackView)
        
        configureAcceptButton()
        configureDeclineButton()
        
        NSLayoutConstraint.activate([
            buttonStackView.heightAnchor.constraint(equalToConstant: 50),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func configureAcceptButton() {
        shareAndAcceptButton = UIButton(type: .custom)
        shareAndAcceptButton.setTitle("Share Info", for: .normal)
        shareAndAcceptButton.backgroundColor = .white
        shareAndAcceptButton.layer.borderColor = UIColor.black.cgColor
        shareAndAcceptButton.layer.borderWidth = 1
        shareAndAcceptButton.layer.cornerRadius = 25
        shareAndAcceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        shareAndAcceptButton.setTitleColor(.black, for: .normal)
        shareAndAcceptButton.addTarget(self, action: #selector(tappedAcceptButton), for: .touchUpInside)
        shareAndAcceptButton.translatesAutoresizingMaskIntoConstraints = false
        shareAndAcceptButton.layer.shadowColor = UIColor.black.cgColor
        shareAndAcceptButton.layer.shadowOpacity = 0.1
        shareAndAcceptButton.layer.shadowOffset = .zero
        shareAndAcceptButton.layer.shadowRadius = 15
        buttonStackView.addArrangedSubview(shareAndAcceptButton)
    }
    
    private func configureDeclineButton() {
        dontShareAndAcceptButton = UIButton(type: .custom)
        dontShareAndAcceptButton.setTitle("Edit Permissions", for: .normal)
        dontShareAndAcceptButton.backgroundColor = .white
        dontShareAndAcceptButton.layer.borderColor = UIColor.black.cgColor
        dontShareAndAcceptButton.layer.borderWidth = 1
        dontShareAndAcceptButton.layer.cornerRadius = 25
        dontShareAndAcceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        dontShareAndAcceptButton.setTitleColor(.black, for: .normal)
        dontShareAndAcceptButton.addTarget(self, action: #selector(tappedEditPermissions), for: .touchUpInside)
        dontShareAndAcceptButton.translatesAutoresizingMaskIntoConstraints = false
        dontShareAndAcceptButton.layer.shadowColor = UIColor.black.cgColor
        dontShareAndAcceptButton.layer.shadowOpacity = 0.1
        dontShareAndAcceptButton.layer.shadowOffset = .zero
        dontShareAndAcceptButton.layer.shadowRadius = 15
        buttonStackView.addArrangedSubview(dontShareAndAcceptButton)
    }
    
    private func configureNameStack() {
        //Name Stack
        nameStack.axis = .vertical
        nameStack.alignment = .center
        nameStack.distribution = .fillEqually
        nameStack.translatesAutoresizingMaskIntoConstraints = false
        nameStack.layer.shadowColor = UIColor.black.cgColor
        nameStack.layer.shadowOpacity = 0.25
        nameStack.layer.shadowOffset = .zero
        nameStack.layer.shadowRadius = 15
        view.addSubview(nameStack)
        
        let firstNameLabel = UILabel()
        firstNameLabel.text = peer.firstName
        firstNameLabel.font = .systemFont(ofSize: 50, weight: .heavy)
        
        let lastNameLabel = UILabel()
        lastNameLabel.text = peer.lastName
        lastNameLabel.font = .systemFont(ofSize: 50, weight: .heavy)
        
        nameStack.addArrangedSubview(firstNameLabel)
        nameStack.addArrangedSubview(lastNameLabel)
        
        NSLayoutConstraint.activate([
            nameStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameStack.topAnchor.constraint(equalTo: profilePictureView.bottomAnchor, constant: 20)
        ])
    }
    
    private func configureProfilePictureView() {
        profilePictureView = VKProfileImageView(user: peer, widthHeight: profilePictureWidthAndHeight)
        profilePictureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profilePictureView)
        
        NSLayoutConstraint.activate([
            profilePictureView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profilePictureView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
            profilePictureView.widthAnchor.constraint(equalToConstant: profilePictureWidthAndHeight),
            profilePictureView.heightAnchor.constraint(equalToConstant: profilePictureWidthAndHeight)
        ])
    }
    
    @objc private func tappedAcceptButton() {
        //Add peer as friend in Firestore and vice versa
        if let acceptStatusHandler = acceptStatusHandler {
            statusLabel.text = "Waiting For \(peer.firstName) To Accept"
            
            buttonStackView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.5) {
                self.buttonStackView.layer.opacity = 0.2
            }
            acceptStatusHandler(.approved, currentUserSharingPermission)
        }
    }
    
    @objc private func tappedEditPermissions() {
        let sharePersonalInfoNC = UINavigationController(rootViewController: SharePersonalInfoVC() { sharingPermission in
            self.currentUserSharingPermission = sharingPermission
            self.tappedAcceptButton()
        })
        sharePersonalInfoNC.modalPresentationStyle = .overFullScreen
        sharePersonalInfoNC.modalTransitionStyle = .crossDissolve
        present(sharePersonalInfoNC, animated: true)
    }
    
    func performBothAcceptedAction(peerSharingPermission: VKSharingPermission? = nil) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
                    
            //TODO: - Very Messy to get reference to HomeVC. Improve
            if let navigationController = UIApplication.shared.topMostController()?.children.first as? UINavigationController, let homeVC = navigationController.viewControllers.first {
                let captureTheMomentNC = UINavigationController(rootViewController: CaptureTheMomentVC(peer: self.peer, currentUserSharingPermission: currentUserSharingPermission, peerSharingPermission: peerSharingPermission))
                homeVC.present(captureTheMomentNC, animated: true)
            }
        }
    }
    
    func updateUIForDisconnectedPeer() {
        let disconnectedPeerOverlayVC = VKStatusOverlayVC(statusMessage: "Peer has been disconnected") {
            self.stopCommunicating?()
            self.dismiss(animated: true)
        }
        disconnectedPeerOverlayVC.modalTransitionStyle = .crossDissolve
        disconnectedPeerOverlayVC.modalPresentationStyle = .overFullScreen
        present(disconnectedPeerOverlayVC, animated: true)
    }
}
