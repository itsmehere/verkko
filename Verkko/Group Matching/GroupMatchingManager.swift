//
//  GroupMatchingManager.swift
//  Verkko
//
//  Created by Justin Wong on 7/22/23.
//

import Foundation

class GroupMatchingManager {
    static func generateSuggestedGroups(minMembersCount: Int, maxMembersCount: Int, allGroups: [VKGroup], completionHandler: @escaping([VKGroup]) -> Void) {
        var generatedSuggestedGroups = [VKGroup]()
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        for membersCount in minMembersCount...maxMembersCount {
            generateSuggestedGroup(for: membersCount, allGroups: allGroups, person: currentUser) { suggestedGroup in
                if let suggestedGroup = suggestedGroup {
                    generatedSuggestedGroups.append(suggestedGroup)
                }
                
                if membersCount == maxMembersCount {
                    completionHandler(generatedSuggestedGroups)
                }
            }
        }
    }
    
    static func generateSuggestedGroup(for membersCount: Int,
                                allGroups: [VKGroup],
                                person: VKUser,
                                completed: @escaping(VKGroup?) -> Void) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        getNestedConnectedFriends(for: membersCount, current: person.uid, connectedFriends: [currentUser.uid], goneThroughFriends: [currentUser.uid]) { foundFriends in
            
            let amount = min(membersCount, foundFriends.count)
            let numOfCombinationsPerAmount = Utils.numberOfCombinations(n: foundFriends.count, k: amount)
            var newGroupMembersUIDs = getRandomFoundFriends(of: foundFriends, for: amount)
            var totalCombinationOccurences = 1
            
            //Check to see if foundFriends already is in an existing group, if so try to generate a new one
            while !areGroupMembersValid(for: newGroupMembersUIDs, in: allGroups) {
                if totalCombinationOccurences >= numOfCombinationsPerAmount {
                    completed(nil)
                    return
                }
                newGroupMembersUIDs = getRandomFoundFriends(of: foundFriends, for: amount)
                totalCombinationOccurences += 1
            }
           
            let newSuggestedGroup = VKGroup(jointID: UUID().uuidString, name: "New Group", membersAndStatus: newGroupMembersUIDs.reduce(into: [String: VKGroupAcceptanceStatus]()) {
                $0[$1] = .pending
            }, createdBy: currentUser.uid, dateCreated: Date())

            completed(newSuggestedGroup)
        }
    }
    
    private static func areGroupMembersValid(for membersUIDs: [String], in allGroups: [VKGroup]) -> Bool {
        guard let currentUser = FirebaseManager.shared.currentUser else { return false }
        
        for group in allGroups {
            let groupMembersSet = Set(group.membersAndStatus.keys)
            let newGroupMembersSet = Set(membersUIDs)
            if groupMembersSet == newGroupMembersSet || !newGroupMembersSet.contains(currentUser.uid) {
                return false
            }
        }
        return true
    }
    
    private static func getRandomFoundFriends(of foundFriends: [String], for amount: Int) -> [String] {
        return Array(foundFriends.shuffled()[0..<amount])
    }
    
    /// Recursively picks a random friend of current and aggregates a list of connectedFriends from that random friend
    /// - Parameters:
    ///   - count: recursive counter for number of members in group
    ///   - current: recursive current person to get its friends
    ///   - connectedFriends: an aggregate list of all of the friends encountered
    ///   - goneThroughFriends: random friends that we looked at (and gotten their friends)
    ///   - completed: completion handler that returns connectedFriends once base case conditions satisfy
    static func getNestedConnectedFriends(for count: Int, current: String, connectedFriends: [String], goneThroughFriends: [String], completed: @escaping([String]) -> Void) {

        if count == 0 {
            completed(connectedFriends)
            return
        }
        
        var connectedFriends = connectedFriends
        var goneThroughFriends = goneThroughFriends
        
        FirebaseManager.shared.getUsers(for: [current]) { result in
            switch result {
            case .success(let users):
                if let user = users.first {
                    goneThroughFriends.append(user.uid)
                    
                    if user.friends.isEmpty {
                        let haventGoneThrough = GroupMatchingManager.getHaventGoneThroughElementSet(from: connectedFriends, subtractWith: goneThroughFriends)
                        
                        //Gone through all connectedFriends so we have to just to return even if we don't have enough
                        if haventGoneThrough.isEmpty {
                            completed(connectedFriends)
                            return
                        }
                        
                        let randomFriendIndex = Int.random(in: 0..<haventGoneThrough.count)
                        let randomChosenFriend = haventGoneThrough[randomFriendIndex]
                        
                        //Try again with new person in connectedFriends
                        self.getNestedConnectedFriends(for: count, current: randomChosenFriend, connectedFriends: connectedFriends, goneThroughFriends: goneThroughFriends, completed: completed)
                        return
                    }
                    
                    let randomFriendIndex = Int.random(in: 0..<user.friends.count)
                    let randomChosenFriend = Array(user.friends.keys)[randomFriendIndex]
                    let validFriends = GroupMatchingManager.getHaventGoneThroughElementSet(from: Array(user.friends.keys), subtractWith: connectedFriends + goneThroughFriends)
                    
                    connectedFriends.append(contentsOf: validFriends)
           
                    
                    self.getNestedConnectedFriends(for: count - 1, current: randomChosenFriend, connectedFriends: connectedFriends, goneThroughFriends: goneThroughFriends, completed: completed)
                }
                break
            case .failure(_):
                break
            }
        }
    }
    
    private static func getHaventGoneThroughElementSet(from mainArray: [String], subtractWith subtractingArray: [String]) -> [String] {
        let mainSet = Set(mainArray)
        let subtractingSet = Set(subtractingArray)
        let result = mainSet.subtracting(subtractingSet)
        return Array(result)
    }
}
