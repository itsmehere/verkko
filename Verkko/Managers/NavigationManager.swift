//
//  NavigationManager.swift
//  Verkko
//
//  Created by Justin Wong on 6/3/23.
//

import UIKit

struct NavigationManager {
    func createTabBar() -> UITabBarController {
        let tabBar = UITabBarController()
        UITabBar.appearance().tintColor = .systemGreen
        tabBar.viewControllers = [createHomeNC(), createFriendsNC(), createGroupMatchingNC(), createSettingsNC()]
        
        tabBar.tabBar.isTranslucent = true
        tabBar.tabBar.backgroundImage = UIImage()
        tabBar.tabBar.barTintColor = .clear
        tabBar.tabBar.backgroundColor = .black
        tabBar.tabBar.layer.backgroundColor = UIColor.clear.cgColor
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = tabBar.view.bounds
        blurView.autoresizingMask = .flexibleWidth
        tabBar.tabBar.insertSubview(blurView, at: 0)
        
        return tabBar
    }
    
    func createHomeNC() -> UINavigationController {
        let homeVC = HomeVC()
        homeVC.title = "Home"
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        return UINavigationController(rootViewController: homeVC)
    }
    
    func createFriendsNC() -> UINavigationController {
        let friendsNC = FriendsVC()
        friendsNC.title = "Friends"
        friendsNC.tabBarItem = UITabBarItem(title: "Friends", image: UIImage(systemName: "person.3"), tag: 1)
        return UINavigationController(rootViewController: friendsNC)
    }
    
    func createGroupMatchingNC() -> UINavigationController {
        let groupMatchingVC = GroupMatchingVC()
        groupMatchingVC.title = "Groups"
        groupMatchingVC.tabBarItem = UITabBarItem(title: "Groups", image: UIImage(systemName: "magnifyingglass"), tag: 2)
        return UINavigationController(rootViewController: groupMatchingVC)
    }
    
    func createSettingsNC() -> UINavigationController {
//        guard let topUIViewController = UIApplication.shared.topMostController() else { return UINavigationController() }
//        let configuration = VKConfiguration(uiViewController: topUIViewController)
        let settingsVC = VKHostingController(rootView: SettingsView())
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 3)
        return UINavigationController(rootViewController: settingsVC)
    }
}

struct VKConfiguration {
    var uiViewController: UIViewController
}
