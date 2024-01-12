//
//  QRCodeTapVC.swift
//  Verkko
//
//  Created by Justin Wong on 8/12/23.
//

import UIKit

//TODO: QR Code does not support sharing permission at the moment because that requires Multipeer Connectivity
class QRCodeTapVC: UIViewController {
    private var qrCodeImageView: UIImageView!
    private let qrCodeCameraButtonView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Tap Via QR Code"
        
        addFullScreenBlurBackground()
        addCloseButton()
        configureQRCodeImageView()
        configureQRCodeCameraButton()
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    
    //MARK: UI Configurations
    private func configureQRCodeImageView() {
        guard let currentUser = FirebaseManager.shared.currentUser, let generatedQRCode = generateQRCode(from: currentUser.uid) else { return }
        
        qrCodeImageView = UIImageView(image: generatedQRCode)
        qrCodeImageView.layer.shadowColor = UIColor.systemGreen.cgColor
        qrCodeImageView.layer.shadowOpacity = 0.55
        qrCodeImageView.layer.shadowRadius = 40
        qrCodeImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qrCodeImageView)
        
        let qrCodeImageWidthHeight: CGFloat = 300
        
        NSLayoutConstraint.activate([
            qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            qrCodeImageView.widthAnchor.constraint(equalToConstant: qrCodeImageWidthHeight),
            qrCodeImageView.heightAnchor.constraint(equalToConstant: qrCodeImageWidthHeight)
        ])
    }
    
    private func configureQRCodeCameraButton() {
        let cameraSymbolImageWidthHeight: CGFloat = 35
        
        let cameraSymbolImageView = UIImageView(image: UIImage(systemName: "camera.fill"))
        cameraSymbolImageView.tintColor = UIColor.white
        cameraSymbolImageView.contentMode = .scaleAspectFit
        cameraSymbolImageView.translatesAutoresizingMaskIntoConstraints = false
        qrCodeCameraButtonView.addSubview(cameraSymbolImageView)
        
        let scanQRCodeLabel = UILabel()
        scanQRCodeLabel.text = "Scan QR Code"
        scanQRCodeLabel.textColor = UIColor.white
        scanQRCodeLabel.font = UIFont.systemFont(ofSize: 20)
        scanQRCodeLabel.textAlignment = .center
        scanQRCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        qrCodeCameraButtonView.addSubview(scanQRCodeLabel)
        
        qrCodeCameraButtonView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        qrCodeCameraButtonView.layer.cornerRadius = 10
        qrCodeCameraButtonView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qrCodeCameraButtonView)
        
        let presentScanQRCodeModalTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentScanQRCodeModal))
        qrCodeCameraButtonView.addGestureRecognizer(presentScanQRCodeModalTapGestureRecognizer)
        
        let leftRightPadding: CGFloat = 5
        
        NSLayoutConstraint.activate([
            cameraSymbolImageView.centerYAnchor.constraint(equalTo: qrCodeCameraButtonView.centerYAnchor),
            cameraSymbolImageView.widthAnchor.constraint(equalToConstant: cameraSymbolImageWidthHeight),
            cameraSymbolImageView.heightAnchor.constraint(equalToConstant: cameraSymbolImageWidthHeight),
            cameraSymbolImageView.leadingAnchor.constraint(equalTo: qrCodeCameraButtonView.leadingAnchor, constant: leftRightPadding),
            
            scanQRCodeLabel.centerYAnchor.constraint(equalTo: qrCodeCameraButtonView.centerYAnchor),
            scanQRCodeLabel.leadingAnchor.constraint(equalTo: cameraSymbolImageView.trailingAnchor),
            scanQRCodeLabel.trailingAnchor.constraint(equalTo: qrCodeCameraButtonView.trailingAnchor, constant: -leftRightPadding),
            scanQRCodeLabel.heightAnchor.constraint(equalToConstant: 30),
            
            qrCodeCameraButtonView.topAnchor.constraint(equalTo: qrCodeImageView.bottomAnchor, constant: 50),
            qrCodeCameraButtonView.widthAnchor.constraint(equalToConstant: 200),
            qrCodeCameraButtonView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeCameraButtonView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func presentScanQRCodeModal() {
        let qrCodeScannerNC = UINavigationController(rootViewController: QRCodeScannerVC())
        present(qrCodeScannerNC, animated: true)
    }
}
