//
//  VKFriendInfo.swift
//  Verkko
//
//  Created by Mihir Rao on 6/8/23.
//

import UIKit

struct VKFriendInfo: Hashable, Codable {
    var tappedLocations: [String: [Double]]
    var tappedTimes: [Date]
    var photoIDs: [String]
    var mutualFriends: [String]
    var jointID: String
    var friends: [String]
    //TODO: QR Code does not support sharing permission at the moment that's why the property is an optional
    var sharingPermissions: [String: VKSharingPermission]?
}
 
struct VKSharingPermission: Hashable, Codable {
    var isEmailVisible: Bool
    var areInterestsVisible: Bool
    var isBirthdayVisible: Bool
    var isPhoneNumberVisible: Bool
    
    var description: [String: Any] {
        return [
            "isEmailVisible": isEmailVisible,
            "areInterestsVisible": areInterestsVisible,
            "isBirthdayVisible": isBirthdayVisible,
            "isPhoneNumberVisible": isPhoneNumberVisible
        ]
    }
}
