//
//  UIApplication+Ext.swift
//  Verkko
//
//  Created by Justin Wong on 6/3/23.
//

import UIKit

extension UIApplication {
    func topMostController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil 
    }
}
