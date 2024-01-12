//
//  VKLoadingVC.swift
//  Verkko
//
//  Created by Justin Wong on 6/18/23.
//

import UIKit
import SwiftUI

class VKLoadingVC: UIViewController {
    private let activityIndicatorView = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        
        configureLoadingView()
    }
    
    private func configureLoadingView() {
        let loadingView = UIView()
        loadingView.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        loadingView.layer.cornerRadius = 10
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        activityIndicatorView.color = .white
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(activityIndicatorView)
        
        activityIndicatorView.startAnimating()
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 75),
            loadingView.heightAnchor.constraint(equalToConstant: 75),
            
            activityIndicatorView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])
    }
    
    func startLoadingAnimation() {
        activityIndicatorView.startAnimating()
    }
    
    func stopLoadingAnimation() {
        activityIndicatorView.stopAnimating()
    }
}

//MARK: - VKSwiftUILoadingView
struct VKSwiftUILoadingView: UIViewControllerRepresentable {
    typealias UIViewType = VKLoadingVC
    
    @Binding private var isLoading: Bool
    private let vkLoadingVC = VKLoadingVC()
    
    init(isLoading: Binding<Bool>) {
        self._isLoading = isLoading
    }
    
    func makeUIViewController(context: Context) -> VKLoadingVC {
        vkLoadingVC.modalPresentationStyle = .overFullScreen
        vkLoadingVC.modalTransitionStyle = .crossDissolve
        return vkLoadingVC
    }
    
    func updateUIViewController(_ uiViewController: VKLoadingVC, context: Context) {
        if isLoading {
            vkLoadingVC.startLoadingAnimation()
        } else {
            vkLoadingVC.stopLoadingAnimation()
        }
    }
}

