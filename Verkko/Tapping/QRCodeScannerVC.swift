//
//  QRCodeScannerVC.swift
//  Verkko
//
//  Created by Justin Wong on 8/12/23.
//

import AVFoundation
import UIKit
import CoreLocation

//https://www.hackingwithswift.com/example-code/media/how-to-scan-a-qr-code
class QRCodeScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var presentingController: UIViewController?
    
    private let locationManager = CLLocationManager()
    private var newFriendUID: String?
    private var locationCoordinate: CLLocationCoordinate2D? {
        //Necessary in order to make sure that initiateNewFriendship gets only called once 
        willSet {
            locationManager.stopUpdatingLocation()
            
            guard locationCoordinate == nil else { return }
            if let coordinate = newValue {
                tapWithQRCode(with: coordinate)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentingController = presentingViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        title = "Scan QR Code"
        addCloseButton()
        configureNavbarBlur()
        
        captureSession = AVCaptureSession()
        performScanning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }    
    
    private func performScanning() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }


    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(newFriendUID: stringValue)
        }

        dismiss(animated: true)
    }

    func found(newFriendUID: String) {
        self.newFriendUID = newFriendUID

        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }
    
    private func tapWithQRCode(with coordinate: CLLocationCoordinate2D) {
        guard let currentUser = FirebaseManager.shared.currentUser, let newFriendUID = newFriendUID else { return }
        
        if !currentUser.getFriendUIDs().contains(where: { $0 == newFriendUID }) {
            initiateNewFriendship(at: coordinate)
        } else {
            updateFriendship(at: coordinate)
        }
    }
    
    private func initiateNewFriendship(at coordinate: CLLocationCoordinate2D) {
        guard let currentUser = FirebaseManager.shared.currentUser, let newFriendUID = newFriendUID else { return }

        FirebaseManager.shared.getUsers(for: [newFriendUID]) { result in
            switch result {
            case .success(let users):
                if let newFriend = users.first {
                    //TODO: Show Take a Picture Camera View Controller
                    let mutualFriends = Array(Set(currentUser.friends.keys).intersection(Set(newFriend.friends.keys)))
                    FirebaseManager.shared.initializeFriendship(userUID: currentUser.uid, friend: newFriend, mutualFriends: mutualFriends, tapPhoto: nil, at: coordinate, viaQRCode: true) { error in
                        if let error = error {
                            self.presentVKAlert(title: "Cannot Initialize Friendship", message: error.localizedDescription, buttonTitle: "OK")
                        } else {
                            self.dismiss()
                        }
                    }
                }
            case .failure(let error):
                self.presentVKAlert(title: "Cannot Fetch Friend Info", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    private func updateFriendship(at coordinate: CLLocationCoordinate2D) {
        guard let currentUser = FirebaseManager.shared.currentUser, let friendUID = newFriendUID else { return }
        
        FirebaseManager.shared.fetchUserDocument(for: friendUID) { result in
            switch result {
            case .success(let friend):
                FirebaseManager.shared.updateFriendship(userUID: currentUser.uid, friend: friend, tapPhoto: nil, lastTappedTime: Date(), lastTappedLat: coordinate.latitude, lastTappedLon: coordinate.longitude, viaQRCode: true) { error in
                    if let error = error {
                        self.presentVKAlert(title: "Error Updating Friendship", message: error.localizedDescription, buttonTitle: "OK")
                    } else {
                        self.dismiss()
                    }
                }
            case .failure(let error):
                self.presentVKAlert(title: "Error Updating Friendship", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    private func dismiss() {
        self.dismiss(animated: false) {
            self.presentingController?.dismiss(animated: false)
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

//MARK: - CLLocationManagerDelegate
extension QRCodeScannerVC: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        locationCoordinate = coordinate
    }
}

