//
//  SettingsManager.swift
//  Verkko
//
//  Created by Justin Wong on 6/6/23.
//

import Foundation

struct SettingsConstants {
    static let firstTimeLoaded = "FirstTimeLoaded"
    static let allowNotifications = "AllowNotifications"
    static let appearanceIndex = "AppearanceIndex"
    static let subscriptionPlanIsFree = "SubscriptionPlanIsFree"
    
    static let isEmailVisible = "IsEmailVisible"
    static let areInterestsVisible = "AreInterestsVisible"
    static let isBirthdayVisible = "IsBirthdayVisible"
    static let isPhoneNumberVisible = "IsPhoneNumberVisible"
}

class SettingsManager {
    private static let defaults = UserDefaults.standard
    
    static func setFirstTimeLoaded(to bool: Bool) {
        return defaults.set(bool, forKey: SettingsConstants.firstTimeLoaded)
    }
    
    static func getFirstTimeLoaded() -> Bool {
        return defaults.bool(forKey: SettingsConstants.firstTimeLoaded)
    }
    
    static func setAllowNotifications(to bool: Bool) {
        return defaults.set(bool, forKey: SettingsConstants.allowNotifications)
    }
    
    static func getAllowNotifications() -> Bool {
        return defaults.bool(forKey: SettingsConstants.allowNotifications)
    }
    
    static func setIsEmailVisible(to bool: Bool) {
        return defaults.set(bool, forKey: SettingsConstants.isEmailVisible)
    }
    
    static func isEmailVisible() -> Bool {
        return defaults.bool(forKey: SettingsConstants.isEmailVisible)
    }
    
    static func setAreInterestsVisible(to bool: Bool) {
        return defaults.set(bool, forKey: SettingsConstants.areInterestsVisible)
    }
    
    static func areInterestsVisible() -> Bool {
        return defaults.bool(forKey: SettingsConstants.areInterestsVisible)
    }
    
    static func setIsBirthdayVisible(to bool: Bool) {
        return defaults.set(bool, forKey: SettingsConstants.isBirthdayVisible)
    }
    
    static func isBirthdayVisible() -> Bool {
        return defaults.bool(forKey: SettingsConstants.isBirthdayVisible)
    }
    
    static func setIsPhoneNumberVisible(to bool: Bool) {
        return defaults.set(bool, forKey: SettingsConstants.isPhoneNumberVisible)
    }
    
    static func isPhoneNumberVisible() -> Bool {
        return defaults.bool(forKey: SettingsConstants.isPhoneNumberVisible)
    }
    
    static func getCurrentUserSharingPermission() -> VKSharingPermission {
        return VKSharingPermission(isEmailVisible: isEmailVisible(), areInterestsVisible: areInterestsVisible(), isBirthdayVisible: isBirthdayVisible(), isPhoneNumberVisible: isPhoneNumberVisible())
    }
}
