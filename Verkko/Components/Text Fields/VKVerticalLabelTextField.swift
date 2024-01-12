//
//  VKVerticalLabelTextField.swift
//  Verkko
//
//  Created by Justin Wong on 6/1/23.
//

import UIKit

class VKVerticalLabelTextField: UIStackView {
    private let label = UILabel()
    private var placeholder: String!
    private var textField: VKTextField!
    private let errorLabel = UILabel()
    private var secure = Bool()
    private var iconView: UIImageView!
    
    private var hSpacing: CGFloat!
    private var returnCompletion: (() -> Void)?
    
    required init(labelText: String, placeholder: String? = "", isSecure: Bool? = false, spacing: CGFloat = 8, returnCompletion: (() -> Void)? = nil) {
        self.label.text = labelText
        self.placeholder = placeholder!
        self.textField = VKTextField()
        self.secure = isSecure!
        self.hSpacing = spacing
        self.returnCompletion = returnCompletion
        super.init(frame: .zero)
        
        configure()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        axis = .vertical
        spacing = hSpacing
        label.font = UIFont.systemFont(ofSize: 10, weight: .heavy)
        label.textColor = UIColor(white: 0.4, alpha: 1)
        addArrangedSubview(label)

        let attributes = [NSAttributedString.Key.foregroundColor : UIColor(white: 0.7, alpha: 1),
                          NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .regular)]
        let customPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)

        textField.attributedPlaceholder = customPlaceholder
        textField.isSecureTextEntry = secure
        textField.addTarget(self, action: #selector(enterPressed), for: .editingDidEndOnExit)
        textField.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 45),
        ])
        
        if (secure == true) {
            addShowSecuredTextIcon(UIImage(systemName: "lock")!, padding: 20, isLeftView: false)
        }
    }
    
    func addShowSecuredTextIcon(_ image: UIImage, padding: CGFloat,isLeftView: Bool) {
        let frame = CGRect(x: 0, y: 0, width: image.size.width + padding, height: image.size.height)
        
        let outerView = UIView(frame: frame)
        iconView  = UIImageView(frame: frame)

        let gesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showSecuredText))
        outerView.addGestureRecognizer(gesture)

        iconView.tintColor = .systemGray3
        iconView.image = image
        iconView.contentMode = .center
        outerView.addSubview(iconView)
        
        if isLeftView {
            textField.leftViewMode = .always
            textField.leftView = outerView
        } else {
            textField.rightViewMode = .always
            textField.rightView = outerView
        }
    }
    
    @objc private func showSecuredText() {
        textField.isSecureTextEntry.toggle()
        
        if (textField.isSecureTextEntry) {
            iconView.tintColor = .systemGray3
        } else {
            iconView.tintColor = .systemGreen
        }
    }
    
    func getTextField() -> VKTextField {
        return textField
    }
    
    func getLabelText() -> String {
        return textField.text ?? ""
    }
    
    func setLabelText(text: String) {
        textField.text = text
    }
    
    func setDelegate(vc: UITextFieldDelegate) {
        textField.delegate = vc
    }
    
    func setReturnHandler(with returnCompletion: (() -> Void)?) {
        self.returnCompletion = returnCompletion
    }
    
    @objc private func enterPressed() {
        if let returnCompletion = returnCompletion {
            returnCompletion()
        }
        textField.resignFirstResponder()
    }
    
    func showError(text errorText: String) {
        textField.setBorderColor(color: UIColor.systemRed.cgColor)
    
        errorLabel.text = errorText
        errorLabel.font = .systemFont(ofSize: 12, weight: .regular)
        errorLabel.textColor = .systemRed
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 5),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 20)
        ])
    }
    
    func removeError() {
        textField.setBorderColor(color: UIColor.systemGray2.cgColor)
        errorLabel.removeFromSuperview()
    }
}


