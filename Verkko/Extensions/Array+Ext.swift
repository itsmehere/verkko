//
//  Array+Ext.swift
//  Verkko
//
//  Created by Justin Wong on 7/25/23.
//

import Foundation

//MARK: - VKUser
extension Array where Element == VKUser {
    mutating func sortAlphabeticallyAscendingByFullName() {
        self.sort(by: { $0.getFullName().trimmingCharacters(in: .whitespacesAndNewlines) < $1.getFullName().trimmingCharacters(in: .whitespacesAndNewlines)})
    }
    
    func getUIDs() -> [String] {
        return self.map { $0.uid }
    }
}

//MARK: - VKFriendInfo
extension Array where Element == VKFriendInfo {
    func getJointIDs() -> [String] {
        return self.map { $0.jointID }
    }
}

//MARK: - VKFriendAssociatedData
extension Array where Element == VKFriendAssociatedData {
    func getFriendUsers() -> [VKUser] {
        return self.map { $0.friend }
    }
    
    func getFriendInfos() -> [VKFriendInfo] {
        return self.map { $0.friendInfo }
    }
}


