//
//  SharePersonalInfoVC.swift
//  Verkko
//
//  Created by Justin Wong on 6/19/23.
//

import UIKit

class SharePersonalInfoVC: UIViewController {
    
    private var firstNameVisibilityView: TogglePersonalInfoVisibilityView!
    private var lastNameVisibilityView: TogglePersonalInfoVisibilityView!
    private var emailVisibilityView: TogglePersonalInfoVisibilityView!
    private var interestsVisibilityView: TogglePersonalInfoVisibilityView!
    private var profilePictureVisibilitySection: TogglePersonalInfoVisibilityView!
    private var birthdayVisibilitySection: TogglePersonalInfoVisibilityView!
    private var phoneNumberVisibilitySection: TogglePersonalInfoVisibilityView!
    
    private let directionLabel = UILabel()
    private let sharePersonalInfoStackView = UIStackView()
    private var shareButton: UIButton!
    
    private var shareHandler: ((VKSharingPermission) -> Void)?
    
    init(shareHandler: ((VKSharingPermission) -> Void)?) {
        self.shareHandler = shareHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()
        addFullScreenBlurBackground()
        configureDirectionLabel()
        configureShareButton()
        configureStackView()
    }
    
    private func configureDirectionLabel() {
        directionLabel.text = "Share"
        directionLabel.font = UIFont.systemFont(ofSize: 50, weight: .heavy)
        directionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(directionLabel)
        
        NSLayoutConstraint.activate([
            directionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            directionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            directionLabel.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func configureStackView() {
        sharePersonalInfoStackView.axis = .vertical
        sharePersonalInfoStackView.distribution = .fillProportionally
        sharePersonalInfoStackView.spacing = 5
        sharePersonalInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sharePersonalInfoStackView)
        
        configureStackViewSections()
        
        NSLayoutConstraint.activate([
            sharePersonalInfoStackView.topAnchor.constraint(equalTo: directionLabel.bottomAnchor),
            sharePersonalInfoStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            sharePersonalInfoStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            sharePersonalInfoStackView.bottomAnchor.constraint(equalTo: shareButton.topAnchor)
        ])
    }
    
    private func configureStackViewSections() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        emailVisibilityView = TogglePersonalInfoVisibilityView(mainText: "Email:", contentText: currentUser.email, isVisible: SettingsManager.isEmailVisible())
        interestsVisibilityView = TogglePersonalInfoVisibilityView(mainText: "Interests", contentText: "", isVisible: SettingsManager.areInterestsVisible())
        birthdayVisibilitySection = TogglePersonalInfoVisibilityView(mainText: "Birthday", contentText: "", isVisible: SettingsManager.isBirthdayVisible())
        phoneNumberVisibilitySection = TogglePersonalInfoVisibilityView(mainText: "Phone Number", contentText: "", isVisible: SettingsManager.isPhoneNumberVisible())
        
        sharePersonalInfoStackView.addArrangedSubview(emailVisibilityView)
        sharePersonalInfoStackView.addArrangedSubview(phoneNumberVisibilitySection)
        sharePersonalInfoStackView.addArrangedSubview(birthdayVisibilitySection)
        sharePersonalInfoStackView.addArrangedSubview(interestsVisibilityView)
    }
    
    private func configureShareButton() {
        shareButton = VKButton(backgroundColor: UIColor.systemGreen.withAlphaComponent(0.8), title: "Share")
        shareButton.layer.cornerRadius = 25
        shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        shareButton.addTarget(self, action: #selector(tappedShareButton), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shareButton)
        
        NSLayoutConstraint.activate([
            shareButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 250),
            shareButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func tappedShareButton() {
        
        let viewingPermission = VKSharingPermission(
            isEmailVisible: emailVisibilityView.getVisibility(),
            areInterestsVisible: interestsVisibilityView.getVisibility(),
            isBirthdayVisible: birthdayVisibilitySection.getVisibility(),
            isPhoneNumberVisible: phoneNumberVisibilitySection.getVisibility())
        
        dismiss(animated: true) {
            self.shareHandler?(viewingPermission)
        }
    }
}

//MARK: - TogglePersonalInfoVisibilityView
class TogglePersonalInfoVisibilityView: UIView {
    
    private var mainText: String!
    private var contentText: String!
    private let selectionButton = UIButton(type: .custom)
    private var isVisible: Bool {
        didSet {
           updateSelectionButton()
        }
    }
    
    private let selectionButtonPointSize: CGFloat = 40

    required init(mainText: String, contentText: String, isVisible: Bool) {
        self.mainText = mainText
        self.contentText = contentText
        self.isVisible = isVisible
        super.init(frame: .zero)
    
        configurePersonalInfoVisibilityView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configurePersonalInfoVisibilityView() {
        let infoLabel = UILabel()
        infoLabel.text = mainText
        infoLabel.font = UIFont.boldSystemFont(ofSize: 25)
        infoLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        infoLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(infoLabel)
        
        let contentLabel = UILabel()
        contentLabel.text = contentText
        contentLabel.textColor = .secondaryLabel
        contentLabel.font = UIFont.boldSystemFont(ofSize: 18)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentLabel)
        
        updateSelectionButton()
        selectionButton.tintColor = .systemGreen
        selectionButton.addTarget(self, action: #selector(togglePersonalInfoVisibility), for: .touchUpInside)
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionButton)
        
        NSLayoutConstraint.activate([
            infoLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            infoLabel.topAnchor.constraint(equalTo: topAnchor),
            infoLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            contentLabel.leadingAnchor.constraint(equalTo: infoLabel.trailingAnchor, constant: 5),
            contentLabel.topAnchor.constraint(equalTo: topAnchor),
            contentLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            selectionButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    @objc private func togglePersonalInfoVisibility() {
        isVisible.toggle()
    }
    
    private func updateSelectionButton() {
        if isVisible {
            setSelectionButtonToChecked()
        } else {
            setSelectionButtonToEmpty()
        }
    }

    private func setSelectionButtonToEmpty() {
        selectionButton.setImage(UIImage(systemName: "circle")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: selectionButtonPointSize)), for: .normal)
    }
    
    private func setSelectionButtonToChecked() {
        selectionButton.setImage(UIImage(systemName: "checkmark.circle.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: selectionButtonPointSize)), for: .normal)
    }
    
    func getVisibility() -> Bool {
        return isVisible
    }
}
