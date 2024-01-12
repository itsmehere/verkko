//
//  VKCache.swift
//  Verkko
//
//  Created by Justin Wong on 7/31/23.
//

import Foundation

class VKCache<Key: Hashable, Value> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let dateProvider: () -> Date
    private let entryLifetime: TimeInterval
    
    init(dateProvider: @escaping () -> Date = Date.init, entryLifetime: TimeInterval = 12 * 60 * 60) {
        self.dateProvider = dateProvider
        self.entryLifetime = entryLifetime
    }
    
    func insert(_ value: Value, forKey key: Key) {
        let expirationDate = dateProvider().addingTimeInterval(entryLifetime)
        let entry = Entry(value: value, expirationDate: expirationDate)
        wrapped.setObject(entry, forKey: WrappedKey(key))
    }
    
    func value(forKey key: Key) -> Value? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else { return nil }
        
        guard dateProvider() < entry.expirationDate else {
            //Discard values that have expired
            removeValue(forKey: key)
            return nil
        }
        
        return entry.value
    }
    
    func removeValue(forKey key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }
}

private extension VKCache {
    final class WrappedKey: NSObject {
        let key: Key
        init(_ key: Key) { self.key = key }
        
        override var hash: Int { return key.hashValue }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else { return false }
            return value.key == key
        }
    }
    
    final class Entry {
        let value: Value
        let expirationDate: Date
        
        init(value: Value, expirationDate: Date) {
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

extension VKCache {
    subscript(key: Key) -> Value? {
        get { return value(forKey: key) }
        set {
            guard let value = newValue else {
                //If nil was assigned, then we remove any value for that key
                removeValue(forKey: key)
                return
            }
            insert(value, forKey: key)
        }
    }
}

//MARK: VKGroupCache
final class VKGroupCache: VKCache<String, VKUser> {
    func fetchGroupMembers(for group: VKGroup, completed: @escaping([VKUser]?) -> Void) {
        var fetchedGroupMembers = [VKUser]()
        
        for memberUID in group.getMembersUIDs() {
            if let member = value(forKey: memberUID) {
                fetchedGroupMembers.append(member)
                
                if fetchedGroupMembers.count == group.membersAndStatus.count {
                    completed(fetchedGroupMembers)
                }
            } else {
                FirebaseManager.shared.getUsers(for: [memberUID]) { result in
                    switch result {
                    case .success(let users):
                        if let user = users.first {
                            fetchedGroupMembers.append(user)
                            self.insert(user, forKey: user.uid)
                            
                            if fetchedGroupMembers.count == group.membersAndStatus.count {
                                completed(fetchedGroupMembers)
                            }
                        } else {
                            completed(nil)
                        }
                    case .failure(_):
                        completed(nil)
                    }
                }
            }
        }
    }
}

//MARK: VKFriendCache
final class VKFriendCache: VKCache<String, VKFriendAssociatedData> {
    func fetchFriendsAndInfo(for user: VKUser, completed: @escaping(Result<[VKFriendAssociatedData], Error>) -> Void) {
        var associatedDatas = [VKFriendAssociatedData]()
        let userFriendUIDS = user.getFriendUIDs()
        
        guard !userFriendUIDS.isEmpty else {
            completed(.success(associatedDatas))
            return
        }
        
        for friendUID in user.getFriendUIDs() {
            if let friendAndInfo = value(forKey: friendUID) {
                associatedDatas.append(friendAndInfo)
                
                if associatedDatas.count == user.friends.count {
                    completed(.success(associatedDatas))
                }
            } else {
                FirebaseManager.shared.getFriendAssociatedData(for: friendUID) { result in
                    switch result {
                    case .success(let friendAssociatedData):
                        associatedDatas.append(friendAssociatedData)
                        self.insert(friendAssociatedData, forKey: friendUID)
                        
                        if associatedDatas.count == user.friends.count {
                            completed(.success(associatedDatas))
                        }
                    case .failure(let error):
                        completed(.failure(error))
                    }
                }
            }
        }
    }
}
