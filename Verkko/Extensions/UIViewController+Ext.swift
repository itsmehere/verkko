//
//  UIViewController+Ext.swift
//  Verkko
//
//  Created by Justin Wong on 5/24/23.
//

import UIKit

extension UIViewController {
    func configureNavbarBlur() {
        guard let bounds = navigationController?.navigationBar.bounds else { return }
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        visualEffectView.isUserInteractionEnabled = false
        visualEffectView.frame = bounds
        visualEffectView.layer.zPosition = -1
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationController?.navigationBar.addSubview(visualEffectView)
        navigationController?.navigationBar.sendSubviewToBack(visualEffectView)
    }
    
    
    func addFullScreenBlurBackground() {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = .flexibleWidth
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func add(childVC: UIViewController, to containerView: UIView) {
        addChild(childVC)
        containerView.addSubview(childVC.view)
        childVC.view.frame = containerView.bounds
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        childVC.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            childVC.view.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            childVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    func setConfigurationForMainVC() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.systemGreen]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemGreen]
        navigationItem.standardAppearance = appearance
    }
    
    func presentVKAlert(title: String, message: String, buttonTitle: String, completionHandler: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertVC = VKAlertView(alertTitle: title, message: message, buttonTitle: buttonTitle, completionHandler: completionHandler)
            alertVC.modalPresentationStyle = .overFullScreen
            alertVC.modalTransitionStyle = .crossDissolve
            self.present(alertVC, animated: true)
        }
    }
    
    func createDismissKeyboardTapGesture() {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }
    
    func getTabbarHeight() -> CGFloat {
        return tabBarController?.tabBar.frame.size.height ?? 50
    }
    
    func addCloseButton() {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeVC))
        navigationItem.leftBarButtonItem = closeButton
    }
    
    @objc func closeVC() {
        dismiss(animated: true)
    }
}
