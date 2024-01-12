//
//  VKSwiftUIAlertView.swift
//  Verkko
//
//  Created by Justin Wong on 6/3/23.
//

import SwiftUI

struct VKSwiftUIAlertView: UIViewControllerRepresentable {
    typealias UIViewType = VKAlertView
    
    private var alertTitle: String!
    private var message: String!
    private var buttonTitle: String!

    init(alertTitle: String, message: String, buttonTitle: String) {
        self.alertTitle = alertTitle
        self.message = message
        self.buttonTitle = buttonTitle
    }
    
    func makeUIViewController(context: Context) -> VKAlertView {
        let vkAlertVC = VKAlertView(alertTitle: alertTitle, message: message, buttonTitle: buttonTitle)
        vkAlertVC.modalPresentationStyle = .overFullScreen
        vkAlertVC.modalTransitionStyle = .crossDissolve
        return vkAlertVC
    }
    
    func updateUIViewController(_ uiViewController: VKAlertView, context: Context) {}
}

