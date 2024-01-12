//
//  CaptureTheMomentVC.swift
//  Verkko
//
//  Created by Justin Wong on 8/14/23.
//

import AVFoundation
import CoreLocation
import UIKit
import SwiftUI

//Inspired by: https://medium.com/@barbulescualex/making-a-custom-camera-in-ios-ea44e3087563
class CaptureTheMomentVC: UIViewController {
    private var captureSession : AVCaptureSession!
    private var previewLayer : AVCaptureVideoPreviewLayer!
    
    private let informationLabel = UILabel()
    private var switchCameraButton = UIButton(type: .custom)
    private var cameraButtonView = UIView()

    private var backCamera : AVCaptureDevice!
    private var frontCamera : AVCaptureDevice!
    private var backInput : AVCaptureInput!
    private var frontInput : AVCaptureInput!
    private var photoOutput: AVCapturePhotoOutput!

    private var takePicture = false
    private var backCameraOn = true
    
    private let capturedImageView = CapturedImageView()
    private var saveNavbarButton: UIBarButtonItem!
    
    private let switchCameraButtonWidthHeight: CGFloat = 50
    private let cameraButtonWidthHeight: CGFloat = 80
    private var capturedImageBottomAnchor: NSLayoutConstraint!
    
    private var peer: VKUser!
    private var currentUserSharingPermission: VKSharingPermission?
    private var peerSharingPermission: VKSharingPermission?
    private var informationText: String?
    private var locationManager = CLLocationManager()
    private var tapLocation = CLLocationCoordinate2D()
    private var presentedController: UIViewController?
    
    init(peer: VKUser,
         currentUserSharingPermission: VKSharingPermission? = nil,
         peerSharingPermission: VKSharingPermission? = nil,
         informationText: String? = nil) {
        self.peer = peer
        self.currentUserSharingPermission = currentUserSharingPermission
        self.peerSharingPermission = peerSharingPermission
        self.informationText = informationText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentedController = presentingViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // location manager setup
        locationManager.requestWhenInUseAuthorization()
        
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.startUpdatingLocation()
            }
        }

        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
        setupAndStartCaptureSession()
        performTap()
    }
    
    //MARK: - UI Components
    private func configureSwitchCameraButton() {
        let image = UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25))
        switchCameraButton.addBlurEffect(cornerRadius: switchCameraButtonWidthHeight / 2)
        switchCameraButton.layer.cornerRadius = 15
        switchCameraButton.setImage(image, for: .normal)
        switchCameraButton.tintColor = .white
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configureCameraButton() {
        cameraButtonView.translatesAutoresizingMaskIntoConstraints = false
        
        let centerSolidCircle = UIView()
        centerSolidCircle.backgroundColor = .white
        centerSolidCircle.layer.cornerRadius = (cameraButtonWidthHeight - 15) / 2
        centerSolidCircle.translatesAutoresizingMaskIntoConstraints = false
        cameraButtonView.addSubview(centerSolidCircle)
        
        let outerBorderRing = UIView()
        outerBorderRing.backgroundColor = .clear
        outerBorderRing.layer.borderColor = UIColor.white.cgColor
        outerBorderRing.layer.borderWidth = 2
        outerBorderRing.layer.cornerRadius = cameraButtonWidthHeight / 2
        outerBorderRing.translatesAutoresizingMaskIntoConstraints = false
        cameraButtonView.addSubview(outerBorderRing)
        
        NSLayoutConstraint.activate([
            centerSolidCircle.centerXAnchor.constraint(equalTo: cameraButtonView.centerXAnchor),
            centerSolidCircle.centerYAnchor.constraint(equalTo: cameraButtonView.centerYAnchor),
            centerSolidCircle.widthAnchor.constraint(equalToConstant: cameraButtonWidthHeight - 15),
            centerSolidCircle.heightAnchor.constraint(equalToConstant: cameraButtonWidthHeight - 15),
            
            outerBorderRing.centerXAnchor.constraint(equalTo: cameraButtonView.centerXAnchor),
            outerBorderRing.centerYAnchor.constraint(equalTo: cameraButtonView.centerYAnchor),
            outerBorderRing.widthAnchor.constraint(equalToConstant: cameraButtonWidthHeight),
            outerBorderRing.heightAnchor.constraint(equalToConstant: cameraButtonWidthHeight)
        ])
    }
    
    private func setupView() {
        title = "Capture This Moment"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeVCHandler))
        navigationItem.leftBarButtonItem = closeButton
        
        configureNavbarBlur()
        configureCameraButton()
        configureSwitchCameraButton()
        configureInformationLabel()
        
        view.backgroundColor = .black
        
        let controlsStackView = UIStackView()
        controlsStackView.axis = .horizontal
        controlsStackView.distribution = .equalSpacing
        controlsStackView.alignment = .center
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsStackView)
        
        controlsStackView.addArrangedSubview(switchCameraButton)
        controlsStackView.addArrangedSubview(cameraButtonView)
        controlsStackView.addArrangedSubview(capturedImageView)
    
        NSLayoutConstraint.activate([
            switchCameraButton.widthAnchor.constraint(equalToConstant: switchCameraButtonWidthHeight),
            switchCameraButton.heightAnchor.constraint(equalToConstant: switchCameraButtonWidthHeight),
            
            cameraButtonView.widthAnchor.constraint(equalToConstant: cameraButtonWidthHeight),
            cameraButtonView.heightAnchor.constraint(equalToConstant: cameraButtonWidthHeight),

            capturedImageView.heightAnchor.constraint(equalToConstant: 50),
            capturedImageView.widthAnchor.constraint(equalToConstant: 50),
            
            controlsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            controlsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            controlsStackView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        switchCameraButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        
        let cameraButtonViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(captureImage))
        cameraButtonView.addGestureRecognizer(cameraButtonViewTapGestureRecognizer)
        
        let capturedImageViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showImagePreview))
        capturedImageView.addGestureRecognizer(capturedImageViewTapGestureRecognizer)
    }
    
    @objc private func closeVCHandler() {
        dismiss(animated: true) {
            self.presentedController?.dismiss(animated: true)
        }
    }
    
    //Perform Tap when user closes the window or when user decides to take photos
    //TODO: Show UI Success Notification or feedback
    @objc private func performTap() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        if currentUser.isFriend(with: peer.uid) {
            self.updateFriendshipViaTap(at: tapLocation)
        } else {
            self.initiateFriendshipViaTap(at: tapLocation, currentUserSharingPermission: currentUserSharingPermission, peerSharingPermission: peerSharingPermission)
        }
    }
    
    private func initiateFriendshipViaTap(at coordinate: CLLocationCoordinate2D, currentUserSharingPermission: VKSharingPermission?, peerSharingPermission: VKSharingPermission?) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        let mutualFriends = Array(Set(currentUser.friends.keys).intersection(Set(self.peer.friends.keys)))
        locationManager.stopUpdatingLocation()
    
        FirebaseManager.shared.initializeFriendship(userUID: currentUser.uid, friend: self.peer, mutualFriends: mutualFriends, tapPhoto: self.capturedImageView.image, at: tapLocation, currentUserSharingPermission: currentUserSharingPermission, peerSharingPermission: peerSharingPermission, viaQRCode: false) { error in
            if let error = error {
                self.presentVKAlert(title: "Error Adding Friend", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    private func updateFriendshipViaTap(at coordinate: CLLocationCoordinate2D) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        locationManager.stopUpdatingLocation()
    
        FirebaseManager.shared.updateFriendship(userUID: currentUser.uid, friend: self.peer, tapPhoto: self.capturedImageView.image, lastTappedTime: Date(), lastTappedLat: coordinate.latitude, lastTappedLon: coordinate.longitude, viaQRCode: false) { error in
            if let error = error {
                self.presentVKAlert(title: "Error Updating Friendship", message: error.localizedDescription, buttonTitle: "OK")
            }
        }
    }
    
    @objc private func showImagePreview() {
        guard let capturedImage = capturedImageView.image else { return }
        let imagePreviewVC = ImageSavePreviewVC(image: capturedImage) {
            self.performTap()
        }
        imagePreviewVC.modalPresentationStyle = .overCurrentContext
        imagePreviewVC.modalTransitionStyle = .crossDissolve
        present(imagePreviewVC, animated: true)
    }
    
    private func configureInformationLabel() {
        guard informationText != nil else { return }
        
        informationLabel.text = informationText
        informationLabel.backgroundColor = .clear
        informationLabel.textColor = .white
        informationLabel.font = UIFont.systemFont(ofSize: 14)
        informationLabel.numberOfLines = 2
        informationLabel.textAlignment = .center
        informationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(informationLabel)
        
        NSLayoutConstraint.activate([
            informationLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            informationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            informationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            informationLabel.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    //MARK: - Permissions
    private func checkPermissions() {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthStatus {
          case .authorized:
            return
          case .denied:
            //TODO: - Do somethin
            abort()
          case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
            { (authorized) in
              if(!authorized){
                abort()
              }
            })
          case .restricted:
            abort()
          @unknown default:
            fatalError()
        }
    }
   
   //MARK: - Camera Setup
   private func setupAndStartCaptureSession(){
       DispatchQueue.global(qos: .userInitiated).async{
           //init session
           self.captureSession = AVCaptureSession()
           //start configuration
           self.captureSession.beginConfiguration()
           
           //session specific configuration
           if self.captureSession.canSetSessionPreset(.photo) {
               self.captureSession.sessionPreset = .photo
           }
           self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
           
           //setup inputs
           self.setupInputs()
           
           DispatchQueue.main.async {
               //setup preview layer
               self.setupPreviewLayer()
           }
           
           //setup output
           self.setupOutput()
           
           //commit configuration
           self.captureSession.commitConfiguration()
           //start running it
           self.captureSession.startRunning()
       }
   }
   
   private func setupInputs(){
       //get back camera
       if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
           backCamera = device
       } else {
           //handle this appropriately for production purposes
           fatalError("no back camera")
       }
       
       //get front camera
       if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
           frontCamera = device
       } else {
           fatalError("no front camera")
       }
       
       //now we need to create an input objects from our devices
       guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
           fatalError("could not create input device from back camera")
       }
       backInput = bInput
       if !captureSession.canAddInput(backInput) {
           fatalError("could not add back camera input to capture session")
       }
       
       guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
           fatalError("could not create input device from front camera")
       }
       frontInput = fInput
       if !captureSession.canAddInput(frontInput) {
           fatalError("could not add front camera input to capture session")
       }
       
       //connect back camera input to session
       captureSession.addInput(backInput)
   }
   
   private func setupOutput(){
       photoOutput = AVCapturePhotoOutput()
       
       if captureSession.canAddOutput(photoOutput) {
           captureSession.addOutput(photoOutput)
       } else {
           fatalError("could not add video output")
       }
       
       photoOutput.connections.first?.videoOrientation = .portrait
   }
   
   private func setupPreviewLayer(){
       previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
       view.layer.insertSublayer(previewLayer, below: switchCameraButton.layer)
       previewLayer.frame = view.layer.frame
   }
   
   private func switchCameraInput(){
       //don't let user spam the button, fun for the user, not fun for performance
       switchCameraButton.isUserInteractionEnabled = false
       
       //reconfigure the input
       captureSession.beginConfiguration()
       if backCameraOn {
           captureSession.removeInput(backInput)
           captureSession.addInput(frontInput)
           backCameraOn = false
       } else {
           captureSession.removeInput(frontInput)
           captureSession.addInput(backInput)
           backCameraOn = true
       }
       
       //deal with the connection again for portrait mode
       photoOutput.connections.first?.videoOrientation = .portrait
       
       //mirror the video stream for front camera
       photoOutput.connections.first?.isVideoMirrored = !backCameraOn
       
       //commit config
       captureSession.commitConfiguration()
       
       //acitvate the camera button again
       switchCameraButton.isUserInteractionEnabled = true
   }
   
   //MARK:- Actions
   @objc private func captureImage(_ sender: UIButton?){
       let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
       impactGenerator.impactOccurred()
       takePicture = true
       
       let photoSettings = AVCapturePhotoSettings()
       photoOutput.capturePhoto(with: photoSettings, delegate: self)
   }
   
   @objc private func switchCamera(_ sender: UIButton?){
       switchCameraInput()
   }
}

//MARK: - AVCapturePhotoCaptureDelegate
extension CaptureTheMomentVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            presentVKAlert(title: "Cannot Capture Photo", message: error.localizedDescription.lowercased(), buttonTitle: "OK")
        } else {
            guard let imageData = photo.fileDataRepresentation(), let capturedImage = UIImage(data: imageData) else { return }
            DispatchQueue.main.async {
                self.capturedImageView.image = capturedImage
                self.takePicture = false
                self.showImagePreview()
            }
        }
    }
}

extension CaptureTheMomentVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        tapLocation = locValue
    }
}

//MARK: - CapturedImageView
class CapturedImageView : UIView {
    //MARK:- Vars
    var image : UIImage? {
        didSet {
            guard let image = image else {return}
            imageView.image = image
        }
    }
    
    //MARK:- View Components
    let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    //MARK:- Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Setup
    private func setupView(){
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 10
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
        ])
    }
}

//MARK: - ImagePreviewVC
class ImageSavePreviewVC: UIViewController {
    private let imagePreview = UIImageView()
    private let buttonsStackView = UIStackView()
    
    private var image: UIImage!
    private var presentController: UIViewController?
    
    private var performTapHandler: (() -> Void)?
    
    init(image: UIImage, performTapHandler: (() -> Void)?) {
        self.image = image
        self.performTapHandler = performTapHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentController = presentingViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black.withAlphaComponent(0.9)
        createDismissKeyboardTapGesture()
        
        let dismissTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeVC))
        view.addGestureRecognizer(dismissTapGestureRecognizer)
        
        configureImagePreview()
        configureButtonsStackView()
    }
    
    private func configureImagePreview() {
        imagePreview.image = image
        imagePreview.contentMode = .scaleAspectFit
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imagePreview)
        
        NSLayoutConstraint.activate([
            imagePreview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imagePreview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imagePreview.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            imagePreview.heightAnchor.constraint(equalTo: imagePreview.widthAnchor, multiplier: image.size.height / image.size.width)
            
        ])
    }
    
    private func configureButtonsStackView() {
        buttonsStackView.axis = .horizontal
        buttonsStackView.backgroundColor = .clear
        buttonsStackView.distribution = .equalSpacing
        buttonsStackView.spacing = 10
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsStackView)
        
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 25
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(cancelButton)
        
        let saveButton = UIButton(type: .custom)
        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = .systemGreen
        saveButton.layer.cornerRadius = 25
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        buttonsStackView.addArrangedSubview(saveButton)
        
        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            
            saveButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            saveButton.heightAnchor.constraint(equalToConstant: 60),
            
            buttonsStackView.topAnchor.constraint(equalTo: imagePreview.bottomAnchor, constant: 20),
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func cancel() {
        dismiss(animated: true)
    }
    
    @objc private func save() {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
        performTapHandler?()
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            presentVKAlert(title: "Cannot Save To Photo Library", message: error.localizedDescription, buttonTitle: "OK")
        } else {
            dismiss(animated: false) {
                self.presentController?.dismiss(animated: true)
            }
        }
    }
}
