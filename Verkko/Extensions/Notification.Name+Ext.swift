//
//  Notification.Name+Ext.swift
//  Verkko
//
//  Created by Justin Wong on 7/24/23.
//

import Foundation

extension Notification.Name {
    static var updatedGroup: Notification.Name {
        return .init(rawValue: "Firebase.updatedGroup")
    }
    
    static var updatedCurrentUser: Notification.Name {
        return .init(rawValue: "vk.currentUserUpdated")
    }
    
    static var updatedFriendInfo: Notification.Name {
        return .init(rawValue: "vk.updatedFriendInfo")
    }
    
    static var updatedFriend: Notification.Name {
        return .init(rawValue: "vk.updatedFriendUser")
    }
}
