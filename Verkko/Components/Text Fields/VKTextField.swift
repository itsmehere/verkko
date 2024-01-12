//
//  VKTextField.swift
//  Verkko
//
//  Created by Justin Wong on 6/1/23.
//

import UIKit

class VKTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray2.cgColor
        
        //black on light mode and white on dark mode
        textColor = .label
        tintColor = .systemGreen
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: frame.height))
        leftViewMode = .always
        font = .systemFont(ofSize: 15, weight: .regular)
        
        //font will shrink appropriately for long text
        adjustsFontSizeToFitWidth = true
        minimumFontSize = 12
        autocapitalizationType = .none
        
        backgroundColor = .tertiarySystemBackground
        autocorrectionType = .no
        returnKeyType = .go
    }
    
    func setBorderColor(color: CGColor) {
        layer.borderColor = color
    }
}

