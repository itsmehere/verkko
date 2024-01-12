//
//  VKGroup.swift
//  Verkko
//
//  Created by Justin Wong on 7/2/23.
//

import Foundation
import CoreLocation
import FirebaseFirestore

typealias VKGroupAcceptanceStatus = VKGroup.VKGroupAcceptanceStatus


struct VKGroup: Hashable, Codable, Equatable {
    enum VKGroupAcceptanceStatus: String {
        case accepted
        case declined
        case pending
        
        var description: String {
            get {
                switch self {
                case .accepted: return "Accepted"
                case .declined: return "Declined"
                case .pending: return "Pending"
                }
            }
        }
        
        static func getVKGroupAcceptanceStatus(status: String) -> VKGroupAcceptanceStatus {
            switch status {
            case "Accepted":
                return .accepted
            case "Declined":
                return .declined
            default:
                return .pending
            }
        }
    }
    
    var jointID: String
    var name: String
    var location: GeoPoint?
    var meetingDateTime: Date?
    var membersAndStatus: [String: VKGroupAcceptanceStatus]
    var createdBy: String 
    var dateCreated: Date
    
    //dictionary represenation that is suitable for Firebase
    var dictionary: [String: Any] {
        return [
            "jointID": jointID,
            "membersAndStatus": membersAndStatus.mapValues { value in
                return value.description
            },
            "name": name,
            "createdBy": createdBy,
            "dateCreated": dateCreated
        ]
    }
    
    func getStatus(for userID: String) -> VKGroupAcceptanceStatus {
        return membersAndStatus[userID] ?? .pending
    }
    
    func getLocationAsCLLocationCoordinate2D() -> CLLocationCoordinate2D? {
        guard let location = location else { return nil }
        return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
    
    func getLocationAddress(completed: @escaping(String?) -> Void) {
        guard let location = location else { return completed(nil) }
        Utils.getAddressFromLatLon(lat: location.latitude, lon: location.longitude, completed: { result in
            switch result {
            case .success(let address):
                completed(address)
            case .failure(_):
                completed(nil)
            }
        })
    }
    
    func getMembersUIDs() -> [String] {
        return Array(membersAndStatus.keys)
    }
    
    func addGroupToOtherMembers(completionHandler: @escaping (VKError?) -> Void) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        let groupMembersExcludingCurrentUser = Array(membersAndStatus.filter{ $0.key != currentUser.uid }.keys)
        for otherMember in groupMembersExcludingCurrentUser {
            FirebaseManager.shared.updateUserData(for: otherMember, with: [
                VKConstants.groups: FieldValue.arrayUnion([jointID])
            ]) { error in
                if let error = error {
                   completionHandler(error)
                }
                completionHandler(nil)
            }
        }
    }
}

extension VKGroupAcceptanceStatus: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = VKGroupAcceptanceStatus.getVKGroupAcceptanceStatus(status: rawValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}

