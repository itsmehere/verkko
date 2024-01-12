//
//  VKError.swift
//  Verkko
//
//  Created by Justin Wong on 6/3/23.
//

import Foundation

enum VKError: Error {
    case passwordsMismatch
    case passwordIsEmpty
    case emailAlreadyInUse
    case unableToUpdateUser
    case unableToFetchUser
    case unableToFetchFriends
    case unableToFetchProfileImage
    case unableToUploadProfileImage
    case unableToObserveGroup
    case unableToObserveFriendInfo
    case unableToObserveFriend
    case unableToCreateSuggestedGroup
    case custom(string: String)
    
    func getMessage() -> String {
        switch self {
        case .passwordsMismatch:
            return "Password and Confirm Password needs to match. Please try again."
        case .passwordIsEmpty:
            return "Password cannot be empty."
        case .unableToFetchUser:
            return "Unable to fetch user."
        case .unableToFetchFriends:
            return "Unable to fetch friends."
        case .unableToUpdateUser:
            return "Unable to update user."
        case .unableToFetchProfileImage:
            return "Unable to fetch profile image."
        case .unableToUploadProfileImage:
            return "Unable to upload profile image."
        case .unableToObserveGroup:
            return "Unable to observe group."
        case .unableToObserveFriendInfo:
            return "Unable to observe friend info."
        case .unableToObserveFriend:
            return "Unable to observe friend."
        case .unableToCreateSuggestedGroup:
            return "All possible suggested groups have been created."
        case .custom(let string):
            return string
        default:
            return "Unknown error occurred"
        }
    }
}
