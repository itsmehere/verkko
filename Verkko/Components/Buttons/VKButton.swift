//
//  VKButton.swift
//  Verkko
//
//  Created by Justin Wong on 6/1/23.
//


import UIKit

class VKButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(title: String) {
        super.init(frame: .zero)
        self.setTitle(title, for: .normal)
        configure()
    }
    
    convenience init(backgroundColor: UIColor, title: String) {
        self.init(title: title)
        set(backgroundColor: backgroundColor, title: title)
    }
    
    private func configure() {
        layer.cornerRadius = 5
        setTitleColor(.white, for: .normal)
        //dynamic type text
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func set(backgroundColor: UIColor, title: String) {
        self.backgroundColor = backgroundColor
        setTitle(title, for: .normal)
    }
    
    func addShadow(color: CGColor, opacity: Float = 1, offset: CGSize = .zero, radius: CGFloat = 10) {
        layer.shadowColor = color
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowPath = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: frame.size)).cgPath
    }
}
