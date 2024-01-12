//
//  DiscoveringPeersVC.swift
//  Verkko
//
//  Created by Justin Wong on 6/12/23.
//

import UIKit
import NearbyInteraction
import MultipeerConnectivity

typealias VKPeerStatus = VKPeer.VKPeerStatus

//MARK: - VKPeer
struct VKPeer: Codable {
    enum VKPeerStatus: Codable {
        case none
        case approved
        case denied
        case close
        case terminated
    }
    var userData: VKUser
    var token: DiscoveryTokenWrapper
    var status: VKPeerStatus
    var sharingPermission: VKSharingPermission?
}

//MARK: - DiscoveryTokenWrapper
struct DiscoveryTokenWrapper: Codable {
    let discoveryTokenData: Data

    init(token: NIDiscoveryToken) throws {
        self.discoveryTokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
    }

    func getDiscoveryToken() throws -> NIDiscoveryToken {
        guard let token = try NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: discoveryTokenData) else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to unarchive discovery token"])
        }
        return token
    }

    private enum CodingKeys: String, CodingKey {
        case discoveryTokenData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.discoveryTokenData = try container.decode(Data.self, forKey: .discoveryTokenData)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(discoveryTokenData, forKey: .discoveryTokenData)
    }
}

//MARK: - DiscoveringPeersVC
class DiscoveringPeersVC: UIViewController {
    private var acceptPeerUIView: AcceptPeerVC?
    private var isDiscovering = true
    
    private let discoveringLabel = UILabel()
    private let helpInfoLabel = UILabel()
    private let informationLabel = UILabel()
    private var showHelpInfoTimer: Timer?
    
    //Nearby Interaction and Mutlipeer Connectivity variables
    private let nearbyDistanceThreshold: Float = 0.2
    
    enum DistanceDirectionState {
        case closeUpInFOV, notCloseUpInFOV, outOfFOV, unknown
    }
    
    private var session: NISession?
    private var peerDiscoveryToken: NIDiscoveryToken?
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private var currentDistanceDirectionState: DistanceDirectionState = .unknown
    private var mpc: MPCSession?
    private var connectedPeer: MCPeerID?
    private var sharedTokenWithPeer = false
    private var acceptPeerVC: AcceptPeerVC?
    
    private var peerVKPeer: VKPeer?
    private var currentUserVKPeer: VKPeer?
    
    required init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        addFullScreenBlurBackground()
        addCloseButton()
        configureQRCodeScannerVCNavbarButton()
        configureDiscoveringLabel()
        animateShrinkAndGrowForDiscoveringLabel()
        configureHelpInfoLabel()
        configureInformationLabel()
        startShowHelpTimer()
        configureLabelsTextColor()
        
        startup()
    }
    
    deinit {
        print("DiscoveringPeersVC deinitalized")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureLabelsTextColor()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    private func configureLabelsTextColor() {
        let userInterfaceStyle = traitCollection.userInterfaceStyle
        switch userInterfaceStyle {
        case .light, .unspecified:
            discoveringLabel.textColor = .lightGray
        case .dark:
            discoveringLabel.textColor = .lightText
        @unknown default:
            discoveringLabel.textColor = .label
        }
    }
    
    private func configureQRCodeScannerVCNavbarButton() {
        let qrCodeScannerNavbarButton = UIBarButtonItem(image: UIImage(systemName: "qrcode.viewfinder"), style: .plain, target: self, action: #selector(showQRCodeScannerVC))
        qrCodeScannerNavbarButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItem = qrCodeScannerNavbarButton
    }
    
    @objc private func showQRCodeScannerVC() {
        if let tabBarController = presentingViewController as? UITabBarController,
        let navigationController = tabBarController.viewControllers?.first as? UINavigationController,
           let homeVC = navigationController.viewControllers.first as? HomeVC {
            dismiss(animated: true) {
                let qrCodeScannerNC = UINavigationController(rootViewController: QRCodeScannerVC())
                homeVC.present(qrCodeScannerNC, animated: true) {
                    self.stopCommunicating()
                }
            }
        }
    }
    
    func stopCommunicating() {
        print("stopCommunicating")
        mpc?.invalidate()
        session?.invalidate()
        mpc = nil
        connectedPeer = nil
        sharedTokenWithPeer = false
        peerVKPeer = nil
        currentUserVKPeer = nil
    }
    
    //MARK: - Startup
    func startup() {
        // Create the NISession.
        session = NISession()
        
        // Set the delegate.
        session?.delegate = self
        
        // Because the session is new, reset the token-shared flag.
        sharedTokenWithPeer = false
        
        // If `connectedPeer` exists, share the discovery token, if needed.
        if connectedPeer != nil && mpc != nil {
            if let myToken = session?.discoveryToken {
                updateInformationLabel(description: "Initializing ...")
                if !sharedTokenWithPeer {
                    shareCurrentUserAsVKPeer(token: myToken)
                }
                guard let peerToken = peerDiscoveryToken else {
                    return
                }
                let config = NINearbyPeerConfiguration(peerToken: peerToken)
                session?.run(config)
            } else {
                fatalError("Unable to get self discovery token, is this session invalidated?")
            }
        } else {
            startupMPC()
            
            // Set the display state.
            currentDistanceDirectionState = .unknown
        }
    }
    
    // MARK: - Discovery token sharing and receiving using MPC.
    func startupMPC() {
        if mpc == nil {
            
            // Prevent Simulator from finding devices.
#if targetEnvironment(simulator)
            mpc = MPCSession(service: "nisample", identity: "com.example.apple-samplecode.simulator.peekaboo-nearbyinteraction", maxPeers: 1)
#else
            mpc = MPCSession(service: "nisample", identity: "com.example.apple-samplecode.peekaboo-nearbyinteraction", maxPeers: 1)
#endif
            mpc?.peerConnectedHandler = connectedToPeer
            mpc?.peerDataHandler = dataReceivedHandler
            mpc?.peerDisconnectedHandler = disconnectedFromPeer
        }
        mpc?.invalidate()
        mpc?.start()
    }
    
    func connectedToPeer(peer: MCPeerID) {
        guard let myToken = session?.discoveryToken else {
            fatalError("Unexpectedly failed to initialize nearby interaction session.")
        }
        
        if connectedPeer != nil {
            fatalError("Already connected to a peer.")
        }
        
        if !sharedTokenWithPeer {
            shareCurrentUserAsVKPeer(token: myToken)
        }
        
        connectedPeer = peer
        showHelpInfoTimer?.invalidate()
    }
    
    func disconnectedFromPeer(peer: MCPeerID) {
        impactGenerator.impactOccurred(intensity: 1)
  
        sharedTokenWithPeer = false
        stopCommunicating()
    
        acceptPeerVC?.updateUIForDisconnectedPeer()
    }
    
    func dataReceivedHandler(data: Data, peer: MCPeerID) {
        guard let vkPeer = try? JSONDecoder().decode(VKPeer.self, from: data) else {
            fatalError("Unexpectedly failed to decode discovery token.")
        }
        guard let token = try? vkPeer.token.getDiscoveryToken() else { return }
        print("VKPeer: \(vkPeer)")
        peerVKPeer = vkPeer
        switch vkPeer.status {
        case .approved:
            if currentUserVKPeer?.status == .approved {
                print("Both Users have Approved")
                acceptPeerVC?.performBothAcceptedAction(peerSharingPermission: vkPeer.sharingPermission)
            }
            break
        default:
            if isDiscovering  {
                isDiscovering = false
                pushToAcceptPeersVCOrCaptureMoment()
            }
            break
        }
        
        if peerDiscoveryToken == nil {
            peerDidShareDiscoveryToken(peer: peer, token: token)
        }
    }
    
    //Called in startup
    func shareCurrentUserAsVKPeer(token: NIDiscoveryToken, status: VKPeerStatus = .none, currentUserSharingPermission: VKSharingPermission? = nil) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        guard let discoveryTokenWrapper = try? DiscoveryTokenWrapper(token: token) else { return }
        currentUserVKPeer = VKPeer(userData: currentUser, token: discoveryTokenWrapper, status: status, sharingPermission: currentUserSharingPermission)
        guard let encodedData = try? JSONEncoder().encode(currentUserVKPeer!) else {
            fatalError("Unexpectedly failed to encode discovery token.")
        }
        
        mpc?.sendDataToAllPeers(data: encodedData)
        sharedTokenWithPeer = true
    }
    
    func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {
        if connectedPeer != peer {
            fatalError("Received token from unexpected peer.")
        }
        // Create a configuration.
        peerDiscoveryToken = token
        
        let config = NINearbyPeerConfiguration(peerToken: token)
        
        // Run the session.
        session?.run(config)
    }
    //MARK: - UI Configuration and Logic
    private func configureDiscoveringLabel() {
        discoveringLabel.text = "Discovering..."
        discoveringLabel.font = .systemFont(ofSize: 25, weight: .bold)
        discoveringLabel.textColor = .darkGray.withAlphaComponent(0.8)
        discoveringLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(discoveringLabel)
        
        NSLayoutConstraint.activate([
            discoveringLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            discoveringLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func configureHelpInfoLabel() {
        helpInfoLabel.text = "Please make sure both users are in Discover Mode and in nearby proximity"
        helpInfoLabel.font = .systemFont(ofSize: 15)
        helpInfoLabel.textColor = .gray
        helpInfoLabel.layer.opacity = 0
        helpInfoLabel.numberOfLines = 0
        helpInfoLabel.lineBreakMode = .byWordWrapping
        helpInfoLabel.sizeToFit()
        helpInfoLabel.textAlignment = .center
        helpInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(helpInfoLabel)
        
        let hPadding: CGFloat = 30
        
        NSLayoutConstraint.activate([
            helpInfoLabel.heightAnchor.constraint(equalToConstant: 100),
            helpInfoLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            helpInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: hPadding),
            helpInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hPadding)
        ])
    }
    
    private func configureInformationLabel() {
        informationLabel.font = .systemFont(ofSize: 18, weight: .bold)
        informationLabel.textColor = .systemRed.withAlphaComponent(0.8)
        informationLabel.layer.opacity = 0
        informationLabel.numberOfLines = 0
        informationLabel.lineBreakMode = .byWordWrapping
        informationLabel.sizeToFit()
        informationLabel.textAlignment = .center
        informationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(informationLabel)
        
        NSLayoutConstraint.activate([
            informationLabel.topAnchor.constraint(equalTo: helpInfoLabel.bottomAnchor, constant: 40),
            informationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func updateInformationLabel(description: String) {
        informationLabel.text = description
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut) {
            self.informationLabel.layer.opacity = 1
        }
    }
    
    private func animateShrinkAndGrowForDiscoveringLabel() {
        UIView.animate(withDuration: 2.0, animations: {
            // Increase the size of the label
            self.discoveringLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }, completion: { _ in
            UIView.animate(withDuration: 2.0, animations: {
                // Shrink the size of the label back to its original size
                self.discoveringLabel.transform = .identity
            }, completion: { _ in
                // Call the animateLabel() method again to create a loop
                self.animateShrinkAndGrowForDiscoveringLabel()
            })
        })
    }
    
    private func startShowHelpTimer() {
        showHelpInfoTimer?.invalidate()
        showHelpInfoTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { timer in
            if self.connectedPeer == nil {
                UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseOut) {
                    self.helpInfoLabel.layer.opacity = 1
                }
            }

            self.showHelpInfoTimer?.invalidate()
            self.showHelpInfoTimer = nil
        }
    }
    
    //MARK: - Nearby Interaction Visualization
    private func isNearby(_ distance: Float) -> Bool {
        return distance < nearbyDistanceThreshold
    }
    
    private func getDistanceDirectionState(from nearbyObject: NINearbyObject) -> DistanceDirectionState {
        if nearbyObject.distance == nil && nearbyObject.direction == nil {
            return .unknown
        }

        let isNearby = nearbyObject.distance.map(isNearby(_:)) ?? false
        let directionAvailable = nearbyObject.direction != nil

        if isNearby && directionAvailable {
            return .closeUpInFOV
        }

        if !isNearby && directionAvailable {
            return .notCloseUpInFOV
        }

        return .outOfFOV
    }
    
    private func updateVisualization(from currentState: DistanceDirectionState, to nextState: DistanceDirectionState, with peer: NINearbyObject) {
        // Invoke haptics on "peekaboo" or on the first measurement.
        if currentState == .notCloseUpInFOV && nextState == .closeUpInFOV || currentState == .unknown {
            impactGenerator.impactOccurred(intensity: 0.6)
        }

        // Animate into the next visuals.
        UIView.animate(withDuration: 0.3, animations: {
            self.animate(from: currentState, to: nextState, with: peer)
        })
    }
    
    private func animate(from currentState: DistanceDirectionState, to nextState: DistanceDirectionState, with peer: NINearbyObject) {
        
        // If the app transitions from unavailable, present the app's display
        // and hide the user instructions.
        if currentState == .unknown && nextState != .unknown {
            informationLabel.alpha = 0.0
        }

        if nextState == .unknown {
            informationLabel.alpha = 1.0
        }
        
        // Set the app's display based on peer state.
        switch nextState {
        case .closeUpInFOV:
            print("Close up IN Fov")
            isDiscovering = false
            break
        case .notCloseUpInFOV:
            print("no close up in fov")
            discoveringLabel.text = "Closer..."
            break
        case .outOfFOV:
            print("out of fov")
            discoveringLabel.text = "Out of view"
            break
        case .unknown:
            break
        }
        
        // Don't update visuals if the peer device is unavailable or out of the
        // U1 chip's field of view.
        if nextState == .outOfFOV || nextState == .unknown {
            return
        }
    }
    
    private func actOnCurrentUserAcceptanceStatus(for status: VKPeerStatus, currentUserSharingPermission: VKSharingPermission?, token: NIDiscoveryToken) {
        currentUserVKPeer?.status = status
        switch status {
        case .approved:
            shareCurrentUserAsVKPeer(token: token, status: .approved, currentUserSharingPermission: currentUserSharingPermission)
            
            if peerVKPeer?.status == .approved {
                acceptPeerVC?.performBothAcceptedAction(peerSharingPermission: peerVKPeer?.sharingPermission)
            }
            break
        case .denied:
            shareCurrentUserAsVKPeer(token: token, status: .denied)
            break
        default:
            break
        }
    }
    
    private func pushToAcceptPeersVCOrCaptureMoment() {
        guard let token = session?.discoveryToken else { return }
        guard let peerVKPeer = peerVKPeer,
        let currentUser = FirebaseManager.shared.currentUser else { return }
        
        self.shareCurrentUserAsVKPeer(token: token, status: .close)
        impactGenerator.impactOccurred()

        let peerUID = peerVKPeer.userData.uid
        if currentUser.isFriend(with: peerUID) {
            //Check if lastTappedTime is valid (not in the same day as current time)
            getLastTappedDate(peerUID: peerUID) { date in
                guard let date = date else { return }
                if !date.isSameDay(as: Date()) {
                    self.goToCaptureTheMomentVC(peerData: peerVKPeer.userData)
                } else {
                    let cannotTapOnSameDayStatusOverlayVC = VKStatusOverlayVC(statusMessage: "Already Tapped With \(peerVKPeer.userData.firstName). You can only tap once per day") {
                        self.dismiss(animated: true)
                    }
                    cannotTapOnSameDayStatusOverlayVC.modalTransitionStyle = .crossDissolve
                    cannotTapOnSameDayStatusOverlayVC.modalPresentationStyle = .overFullScreen
                    self.present(cannotTapOnSameDayStatusOverlayVC, animated: true)
                }
            }
        } else {
            acceptPeerVC = AcceptPeerVC(peer: peerVKPeer.userData,
                                        acceptStatusHandler: { currentUserStatus, currentUserSharingPermission in
                self.actOnCurrentUserAcceptanceStatus(for: currentUserStatus, currentUserSharingPermission: currentUserSharingPermission, token: token)
            }) { [weak self] in
                self?.stopCommunicating()
            }
            navigationController?.pushViewController(acceptPeerVC!, animated: true)
        }
    
        session?.pause()
    }
    
    private func getLastTappedDate(peerUID: String, completed: @escaping(Date?) -> Void) {
        guard let currentUser = FirebaseManager.shared.currentUser else {
            completed(nil)
            return
        }
        
        if let friendInfoJointID = currentUser.friends[peerUID] {
            FirebaseManager.shared.getFriendInfo(for: friendInfoJointID) { result in
                switch result {
                case .success(let friendInfo):
                    completed(friendInfo.tappedTimes.last)
                case .failure(let error):
                    self.presentVKAlert(title: "Cannot Get Shared Friend Info", message: error.localizedDescription, buttonTitle: "OK")
                }
            }
        }
    }
    
    private func goToCaptureTheMomentVC(peerData: VKUser) {
        if let tabBarController = presentingViewController as? UITabBarController,
        let navigationController = tabBarController.viewControllers?.first as? UINavigationController,
           let homeVC = navigationController.viewControllers.first as? HomeVC {
            dismiss(animated: true) {
                let captureTheMomentNC = UINavigationController(rootViewController: CaptureTheMomentVC(peer: peerData, informationText: "You and \(peerData.firstName) are already friends. Choose to take a Moment."))
                homeVC.present(captureTheMomentNC, animated: true) {
                    self.stopCommunicating()
                }
            }
        }
    }
}

// MARK: - `NISessionDelegate`.
extension DiscoveringPeersVC: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peerToken = peerDiscoveryToken else {
            fatalError("don't have peer token")
        }

        // Find the right peer.
        let peerObj = nearbyObjects.first { (obj) -> Bool in
            return obj.discoveryToken == peerToken
        }

        guard let nearbyObjectUpdate = peerObj else {
            return
        }

        // Update the the state and visualizations.
        if isDiscovering {
            let nextState = getDistanceDirectionState(from: nearbyObjectUpdate)
            updateVisualization(from: currentDistanceDirectionState, to: nextState, with: nearbyObjectUpdate)
            currentDistanceDirectionState = nextState
        }
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        guard let peerToken = peerDiscoveryToken else {
            fatalError("don't have peer token")
        }
        // Find the right peer.
        let peerObj = nearbyObjects.first { (obj) -> Bool in
            return obj.discoveryToken == peerToken
        }

        if peerObj == nil {
            return
        }

        currentDistanceDirectionState = .unknown

        switch reason {
        case .peerEnded:
            print("Peer Ended")
            // The peer token is no longer valid.
            peerDiscoveryToken = nil
            
            // The peer stopped communicating, so invalidate the session because
            // it's finished.
            session.invalidate()
            
            // Restart the sequence to see if the peer comes back.
            startup()
            startShowHelpTimer()
            
            // Update the app's display.
            updateInformationLabel(description: "Peer Ended")
        case .timeout:
            // The peer timed out, but the session is valid.
            print("peer timedout")
            discoveringLabel.text = "Discovering..."
            if let config = session.configuration {
                session.run(config)
            }
            startShowHelpTimer()
            updateInformationLabel(description: "")
        default:
            fatalError("Unknown and unhandled NINearbyObject.RemovalReason")
        }
    }

    func sessionWasSuspended(_ session: NISession) {
        print("session suspended")
        currentDistanceDirectionState = .unknown
        updateInformationLabel(description: "Session suspended")
        connectedPeer = nil
    }

    func sessionSuspensionEnded(_ session: NISession) {
        print("session suspension")
        // Session suspension ended. The session can now be run again.
//        if let config = self.session?.configuration {
//            session.run(config)
//        } else {
            // Create a valid configuration.
//            startup()
//        }

    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        print("didinvalidatewith")
        currentDistanceDirectionState = .unknown

        // If the app lacks user approval for Nearby Interaction, present
        // an option to go to Settings where the user can update the access.
        if case NIError.userDidNotAllow = error {
            if #available(iOS 15.0, *) {
                // In iOS 15.0, Settings persists Nearby Interaction access.
                updateInformationLabel(description: "Nearby Interactions access required. You can change access for NIPeekaboo in Settings.")
                // Create an alert that directs the user to Settings.
                let accessAlert = UIAlertController(title: "Access Required",
                                                    message: """
                                                    NIPeekaboo requires access to Nearby Interactions for this sample app.
                                                    Use this string to explain to users which functionality will be enabled if they change
                                                    Nearby Interactions access in Settings.
                                                    """,
                                                    preferredStyle: .alert)
                accessAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                accessAlert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: {_ in
                    // Send the user to the app's Settings to update Nearby Interactions access.
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    }
                }))

                //TODO: Display the alert.
//                present(accessAlert, animated: true, completion: nil)
            } else {
                // Before iOS 15.0, ask the user to restart the app so the
                // framework can ask for Nearby Interaction access again.
                updateInformationLabel(description: "Nearby Interactions access required. Restart NIPeekaboo to allow access.")
            }

            return
        }

        // Recreate a valid session.
//        startup()
    }
}
