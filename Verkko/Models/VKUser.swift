//
//  VKUser.swift
//  Verkko
//
//  Created by Mihir Rao on 5/28/23.
//

import UIKit

struct VKUser: Hashable, Codable {
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var birthday: Date
    var uid: String
    var interests: [String]
    var friends: [String : String]
    var groups: [String]?
    var feed: [String]
    var profilePictureData: Data?
    var blockedFriends: [String]
    
    func getFullName() -> String {
        return "\(firstName) \(lastName)"
    }
    
    func getInitials() -> String {
        return "\(firstName.prefix(1))\(lastName.prefix(1))"
    }
    
    func getFriendUIDs() -> [String] {
        return Array(friends.keys)
    }

    func getProfileUIImage() -> UIImage? {
        if let imageData = profilePictureData, let image = UIImage(data: imageData) {
            return image
        }
        return nil
    }
    
    func isFriend(with friendUID: String) -> Bool {
        return friends[friendUID] != nil
    }
}

/**
 Primarly used for caching in cojunction with VKCache. VKFriendAssociatedData groups the relevant "fetched" properties under a friend and their VKFriendInfo together to avoid fetching and geodecoding properties like `mutualFriends` and `lastTapAddress`
 */
struct VKFriendAssociatedData: Codable {
    var friend: VKUser
    var friendInfo: VKFriendInfo
    var mutualFriends: [VKUser]
    var lastTapAddress: String?
    
    func getMutualFriendUIDS() -> [String] {
        return mutualFriends.map { $0.uid }
    }
}
