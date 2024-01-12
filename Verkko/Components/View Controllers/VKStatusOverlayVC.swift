//
//  VKStatusOverlayVC.swift
//  Verkko
//
//  Created by Justin Wong on 8/17/23.
//

import UIKit

class VKStatusOverlayVC: UIViewController {
    private var statusMessage: String!
    private let containerStackView = UIStackView()
    
    private var dismissHandler: (() -> Void)?
    private var presentingController: UIViewController?
    
    init(statusMessage: String, dismissHandler: (() -> Void)? = nil) {
        self.statusMessage = statusMessage
        self.dismissHandler = dismissHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.8)
        
        addFullScreenBlurBackground()
        configureContainerStackView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentingController = presentingViewController
    }
    
    private func configureContainerStackView() {
        containerStackView.axis = .vertical
        containerStackView.distribution = .fill
        containerStackView.alignment = .center
        containerStackView.spacing = 50
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerStackView)
        
        containerStackView.addArrangedSubview(createStatusMessageLabel())
        containerStackView.addArrangedSubview(createDismissButton())
        
        let padding: CGFloat = 20
        
        NSLayoutConstraint.activate([
            containerStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            containerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
    }
    
    private func createStatusMessageLabel() -> UILabel {
        let statusMessageLabel = UILabel()
        statusMessageLabel.text = statusMessage
        statusMessageLabel.textColor = .systemRed
        statusMessageLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        statusMessageLabel.numberOfLines = 2
        statusMessageLabel.textAlignment = .center
        statusMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        return statusMessageLabel
    }
    
    private func createDismissButton() -> UIButton {
        let dismissButton = VKButton(backgroundColor: .white, title: "OK")
        dismissButton.setTitleColor(.black, for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissCompletion), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dismissButton.widthAnchor.constraint(equalToConstant: 200),
            dismissButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return dismissButton
    }
    
    @objc private func dismissCompletion() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
        
        dismiss(animated: false)
        dismissHandler?()
    }
}

