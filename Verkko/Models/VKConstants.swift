//
//  VKConstants.swift
//  Verkko
//
//  Created by Justin Wong on 6/3/23.
//

import Foundation

struct VKConstants {
    // VKUser constants
    static let userFirstName = "firstName"
    static let userLastName = "lastName"
    static let userUID = "uid"
    static let userEmail = "email"
    static let userPhoneNumber = "phoneNumber"
    static let userProfilePictureData = "profilePictureData"
    static let userBirthday = "birthday"
    static let interests = "interests"
    static let friends = "friends"
    static let feed = "feed"
    static let groups = "groups"
    static let blockedFriends = "blockedFriends"
    
    // VKFriendInfo constants
    static let tappedLocations = "tappedLocations"
    static let tappedTimes = "tappedTimes"
    static let photoIDs = "photoIDs"
    static let mutualFriends = "mutualFriends"
    static let cachedLastTapAddress = "cachedLastTapAddress"
    static let sharingPermissions = "sharingPermissions"
    
    // VKPhotoData constants
    static let photoID = "photoID"
    static let name1 = "name1"
    static let name2 = "name2"
    static let pfp1 = "pfp1"
    static let pfp2 = "pfp2"
    static let date = "date"
    static let lat = "lat"
    static let lon = "lon"

    //VKGroup constants
    static let jointID = "jointID"
    static let membersAndStatus = "membersAndStatus"
    static let dateCreated = "dateCreated"
    static let meetingDateTime = "meetingDateTime"
    
    //UI element constants
    static let closeButtonWidthAndHeight: CGFloat = 25
    static let headerLabelFontSize: CGFloat = 15
    static let nextButtonHeight: CGFloat = 45
}
