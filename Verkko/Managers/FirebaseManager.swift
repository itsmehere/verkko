//
//  FirebaseManager.swift
//  Verkko
//
//  Created by Justin Wong on 6/1/23.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseFirestoreSwift
import CoreLocation

class FirebaseManager {
    static let shared = FirebaseManager()
    public let storageRef = Storage.storage().reference()
    private let db = Firestore.firestore()
    private var handle: AuthStateDidChangeListenerHandle?
    private let navigationManager = NavigationManager()
    private let sceneWindow = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window
    
    var currentUser: VKUser?
    private var groupListeners = [String: ListenerRegistration]()
    private var friendListeners = [String: ListenerRegistration]()
    private var friendInfoListeners = [String: ListenerRegistration]()
    
    // Variables used to store data for secondary photo upload when initializing friendship
    private var secondaryPhoto: UIImage?
    private var secondaryFriend: VKUser?
    private var secondaryVKPhotoData: VKPhotoData?
    
    // Image size:
    private let imageSizeMB: Int64 = 5
    
    init() {
        listenForAuthDidChange()
    }
    
    func listenForAuthDidChange() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            if let user = user {
                self?.fetchUserDocument(for: user.uid) { result in
                    switch result {
                    case .success(let currentUser):
                        print("current user \(currentUser)")
                        self?.currentUser = currentUser
                        self?.addCurrentUserListener()
                        self?.goToTabbar()
                    case .failure(_):
                        print("Failure in fetching user document")
                        self?.goToLoginScreen()
                    }
                }
            } else {
                //user has logged out
                self?.currentUser = nil
                self?.goToLoginScreen()
            }
        }
    }
    
//    func stopListeningForAuthDidChange() {
//        Auth.auth().removeStateDidChangeListener(handle!)
//    }
    
    private func goToTabbar() {
        sceneWindow?.rootViewController = navigationManager.createTabBar()
        sceneWindow?.makeKeyAndVisible()
    }
    
    private func goToLoginScreen() {
        sceneWindow?.rootViewController = UINavigationController(rootViewController: LandingVC())
        sceneWindow?.makeKeyAndVisible()
    }
    
    //MARK: - Firebase Authentication
    func loginInUser(email: String, password: String, completed: @escaping(Result<Void, VKError>) -> Void) {
        if email.isEmpty {
            let missingEmailErrorMessage = AuthErrorCode(.missingEmail).code.getErrorMessage()
            completed(.failure(VKError.custom(string: missingEmailErrorMessage)))
            return
        }
        
        if password.isEmpty {
            completed(.failure(VKError.passwordIsEmpty))
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let maybeError = error {
                let err = maybeError as NSError
                completed(.failure(VKError.custom(string: AuthErrorCode(_nsError: err).code.getErrorMessage())))
            } else {
                completed(.success(()))
            }
        }
    }
    
    func registerUser(firstName: String, lastName: String, interests: [String], email: String, phoneNumber: String, password: String, confirmPassword: String, birthday: Date, completed: @escaping(VKError?) -> Void) {
        guard password == confirmPassword else {
            completed(VKError.passwordsMismatch)
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                let customErrorString = AuthErrorCode(_nsError: error as NSError).code.getErrorMessage()
                completed(VKError.custom(string: customErrorString))
            } else {
                if let newUser = authResult?.user {
                    self.createUserDocument(firstName: firstName, lastName: lastName, interests: interests, email: email, phoneNumber: phoneNumber, feed: [String](), uid: newUser.uid, birthday: birthday) { error in
                        if let error = error {
                            completed(error)
                        }
                    }
                }
            }
        }
    }
    
    func logoutCurrentUser(completed: @escaping(VKError?) -> Void) {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            completed(VKError.custom(string: signOutError.localizedDescription))
        }
    }
    
    //MARK: - Firebase User
    func createUserDocument(firstName: String, lastName: String, interests: [String], email: String, phoneNumber: String, feed: [String], uid: String, birthday: Date, completed: @escaping(VKError?) -> Void) {
        db.collection("users").document(uid).setData([
            VKConstants.userFirstName: firstName,
            VKConstants.userLastName: lastName,
            VKConstants.userEmail: email,
            VKConstants.userPhoneNumber: phoneNumber,
            VKConstants.userUID: uid,
            VKConstants.feed: feed,
            VKConstants.interests: interests,
            VKConstants.friends: [String : String](),
            VKConstants.userBirthday: birthday,
            VKConstants.blockedFriends: [String]()
        ]) { error in
            if let error = error {
                completed(VKError.custom(string: error.localizedDescription))
            }
        }
    }
    
    func fetchUserDocument(for uid: String, completed: @escaping(Result<VKUser, Error>) -> Void) {
        db.collection("users").document(uid).getDocument(as: VKUser.self) { result in
            switch result {
            case .success(let user):
                completed(.success(user))
            case .failure(_):
                completed(.failure(VKError.unableToFetchUser))
            }
        }
    }
    
    func updateUserData(for uid: String, with fields: [String: Any], completed: @escaping(VKError?) -> Void) {
        db.collection("users").document(uid).updateData(fields) { error in
            if let _ = error {
                completed(VKError.unableToUpdateUser)
            } else {
                completed(nil)
            }
        }
    }

    private func addCurrentUserListener() {
        let currentUserID = self.currentUser!.uid
        
        db.collection("users").document(currentUserID).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            do {
                let updatedCurrentUser = try document.data(as: VKUser.self)
                self.currentUser = updatedCurrentUser
                self.uploadOtherTapPhoto()
                NotificationCenter.default.post(name: .updatedCurrentUser, object: self.currentUser)
            } catch {
                print("failed to listen to current user")
            }
        }
    }
    
    //MARK: Friend Management Methods

    // Update friendship if friendship already exists
    public func updateFriendship(userUID: String, friend: VKUser, tapPhoto: UIImage?, lastTappedTime: Date, lastTappedLat: Double, lastTappedLon: Double, viaQRCode isViaQRCode: Bool, completed: @escaping(VKError?) -> Void) {
        let jointID = self.currentUser!.friends[friend.uid]!
        
        var uidArr = [userUID, friend.uid]
        uidArr.sort()
        
        if uidArr[0] == userUID || isViaQRCode {
            let roundedLatitude = Utils.roundToTheFifthDecimalPlace(for: lastTappedLat)
            let roundedLongitude = Utils.roundToTheFifthDecimalPlace(for: lastTappedLon)
            
            getFriendInfo(for: jointID) { result in
                switch result {
                case .success(let friendInfo):
                    var newTappedLocations = friendInfo.tappedLocations
                    var latitudeCoords = [Double]()
                    var longitudeCoords = [Double]()
                    
                    if var latitudeArray = friendInfo.tappedLocations["lat"] {
                        latitudeCoords = latitudeArray + [roundedLatitude]
                    }
                    
                    if var longitudeArray = friendInfo.tappedLocations["lon"] {
                        longitudeCoords = longitudeArray + [roundedLongitude]
                    }
                    
                    newTappedLocations["lat"] = latitudeCoords
                    newTappedLocations["lon"] = longitudeCoords
                    
                    self.db.collection("friendInfo").document(jointID).updateData([
                        VKConstants.tappedTimes: FieldValue.arrayUnion([lastTappedTime]),
                        VKConstants.tappedLocations: newTappedLocations
                    ]) { error in
                        if let error = error {
                            completed(VKError.custom(string: error.localizedDescription))
                            return
                        }
                    }
                case .failure(let error):
                    completed(VKError.custom(string: error.localizedDescription))
                    return
                }
            }
        }
        
        if let tapPhoto = tapPhoto {
            let photoID = UUID().uuidString
            
            self.uploadTapPhoto(photoID: photoID, image: tapPhoto) { error in
                if let error = error {
                    completed(VKError.custom(string: error.localizedDescription))
                } else {
                    self.db.collection("friendInfo").document(jointID).updateData([
                        VKConstants.photoIDs: FieldValue.arrayUnion([photoID]),
                    ]) { error in
                        if let error = error {
                            print("Update Friendship Error: \(error.localizedDescription)")
                            completed(VKError.custom(string: error.localizedDescription))
                        } else {
                            var fields = [VKConstants.photoID: photoID, VKConstants.name1: self.currentUser!.firstName + " " + self.currentUser!.lastName, VKConstants.name2: friend.firstName + " " + friend.lastName, VKConstants.date: lastTappedTime, VKConstants.lat: lastTappedLat, VKConstants.lon: lastTappedLon] as [String : Any]
                            
                            if let pfp1 = self.currentUser?.profilePictureData {
                                fields[VKConstants.pfp1] = pfp1
                            }
                            
                            if let pfp2 = friend.profilePictureData {
                                fields[VKConstants.pfp2] = pfp2
                            }
                            
                            self.db.collection("photos").document(photoID).setData(fields) { error in
                                if let error = error {
                                    completed(VKError.custom(string: error.localizedDescription))
                                } else {
                                    self.updateFeed(friend: friend, photoID: photoID) { error in
                                        if let error = error {
                                            completed(VKError.custom(string: error.localizedDescription))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        completed(nil)
    }
    
    // Initialize friendship if people are meeting for the first time
    public func initializeFriendship(userUID: String, friend: VKUser, mutualFriends: [String], tapPhoto: UIImage?, at coordinate: CLLocationCoordinate2D, currentUserSharingPermission: VKSharingPermission? = nil, peerSharingPermission: VKSharingPermission? = nil, viaQRCode: Bool, completed: @escaping(Error?) -> Void) {
        
        let roundedLatitude = Utils.roundToTheFifthDecimalPlace(for: coordinate.latitude)
        let roundedLongitude = Utils.roundToTheFifthDecimalPlace(for: coordinate.longitude)
        let tappedLocation = ["lat": [roundedLatitude], "lon": [roundedLongitude]]
        let tappedTime = Date()
        
        var sharingPermissions = [String: Any]()
        
        if let currentUserSharingPermission = currentUserSharingPermission,
           let peerSharingPermission = peerSharingPermission {
            sharingPermissions = [userUID: currentUserSharingPermission.description, friend.uid: peerSharingPermission.description]
        }
        
        var fields = [VKConstants.photoIDs: [String](), VKConstants.tappedTimes: [tappedTime], VKConstants.tappedLocations: tappedLocation, VKConstants.mutualFriends: mutualFriends, VKConstants.friends: [userUID, friend.uid], VKConstants.sharingPermissions: sharingPermissions] as [String : Any]
        
        var uidArr = [userUID, friend.uid]
        uidArr.sort()
        
        if uidArr[0] == userUID || viaQRCode {
            let jointID = UUID().uuidString
            fields["jointID"] = jointID
            
            // Begin upload
            let batch = self.db.batch()
            
            if let tapPhoto = tapPhoto {
                let photoID = UUID().uuidString
                fields[VKConstants.photoIDs] = [photoID]

                self.uploadTapPhoto(photoID: photoID, image: tapPhoto) { error in
                    if let error = error {
                        completed(VKError.custom(string: error.localizedDescription))
                    } else {
                        var photoFields = [VKConstants.photoID: photoID, VKConstants.name1: self.currentUser!.firstName + " " + self.currentUser!.lastName, VKConstants.name2: friend.firstName + " " + friend.lastName, VKConstants.date: tappedTime, VKConstants.lat: coordinate.latitude, VKConstants.lon: coordinate.longitude] as [String : Any]
                        
                        if let pfp1 = self.currentUser?.profilePictureData {
                            photoFields[VKConstants.pfp1] = pfp1
                        }
                        
                        if let pfp2 = friend.profilePictureData {
                            photoFields[VKConstants.pfp2] = pfp2
                        }
                        
                        self.db.collection("photos").document(photoID).setData(photoFields) { error in
                            if let error = error {
                                completed(VKError.custom(string: error.localizedDescription))
                            } else {
                                self.updateFeed(friend: friend, photoID: photoID) { error in
                                    if let error = error {
                                        completed(VKError.custom(string: error.localizedDescription))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            let friendInfoRef = self.db.collection("friendInfo").document(jointID)
            batch.setData(fields, forDocument: friendInfoRef)
            
            let userAddFriendRef = self.db.collection("users").document(userUID)
            batch.updateData([
                VKConstants.friends + "." + friend.uid: jointID
            ], forDocument: userAddFriendRef)
            
            let friendAddUserRef = self.db.collection("users").document(friend.uid)
            batch.updateData([
                VKConstants.friends + "." + userUID: jointID
            ], forDocument: friendAddUserRef)
            
            batch.commit() { error in
                if let error = error {
                    completed(VKError.custom(string: error.localizedDescription))
                }
            }
        } else {
            secondaryPhoto = tapPhoto
            secondaryFriend = friend
            secondaryVKPhotoData = VKPhotoData(photoID: UUID().uuidString, name1: self.currentUser!.firstName + " " + self.currentUser!.lastName, name2: friend.firstName + " " + friend.lastName, date: Date(), lat: coordinate.latitude, lon: coordinate.longitude)
            completed(nil)
        }
    }
    
    // Uploads the second user's tap photo when initialization of the friendship is done
    private func uploadOtherTapPhoto() {
        guard let secondaryFriend = secondaryFriend else { return }
        
        if let secPhoto = self.secondaryPhoto {
            let secFriend = secondaryFriend
            let secVKPhotoData = self.secondaryVKPhotoData!.copy() as! VKPhotoData
            
            let jointID = (currentUser?.friends[secFriend.uid])!

            self.uploadTapPhoto(photoID: secVKPhotoData.photoID, image: secPhoto) { error in
                if error == nil {
                    self.db.collection("friendInfo").document(jointID).updateData([
                        VKConstants.photoIDs: FieldValue.arrayUnion([secVKPhotoData.photoID]),
                    ]) { error in
                        if error == nil {
                            var photoFields = [VKConstants.photoID: secVKPhotoData.photoID, VKConstants.name1: self.currentUser!.firstName + " " + self.currentUser!.lastName, VKConstants.name2: secFriend.firstName + " " + secFriend.lastName, VKConstants.date: secVKPhotoData.date, VKConstants.lat: secVKPhotoData.lat, VKConstants.lon: secVKPhotoData.lon] as [String : Any]
                            
                            if let pfp1 = self.currentUser?.profilePictureData {
                                photoFields[VKConstants.pfp1] = pfp1
                            }
                            
                            if let pfp2 = secFriend.profilePictureData {
                                photoFields[VKConstants.pfp2] = pfp2
                            }
                            
                            self.db.collection("photos").document(secVKPhotoData.photoID).setData(photoFields) { error in
                                if error == nil {
                                    self.updateFeed(friend: secFriend, photoID: secVKPhotoData.photoID) { error in }
                                }
                            }
                        }
                    }
                }
            }

            self.secondaryPhoto = nil
            self.secondaryFriend = nil
            self.secondaryVKPhotoData = nil
        }
    }
    
    private func uploadTapPhoto(photoID: String, image: UIImage?, completed: @escaping(Error?) -> Void) {
        guard let image = image else {
            completed(nil)
            return
        }
        
        // location in storage
        let friendshipPhotoRef = storageRef.child(photoID)
        
        // image data
        let data = image.jpegData(compressionQuality: 0.75)!
        
        _ = friendshipPhotoRef.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                completed(VKError.custom(string: error.localizedDescription))
            } else {
                completed(nil)
            }
        }
    }
    
    // Updates the feed for currentUser's friends and currentUser's tap friend's friends with photoID
    private func updateFeed(friend: VKUser, photoID: String, completed: @escaping(Error?) -> Void) {
        let batch = self.db.batch()
        
        for currentUserFriendUID in Array(self.currentUser!.friends.keys) {
            if currentUserFriendUID != friend.uid {
                let currentUserFriendUIDRef = self.db.collection("users").document(currentUserFriendUID)
                
                batch.updateData([
                    VKConstants.feed: FieldValue.arrayUnion([photoID])
                ], forDocument: currentUserFriendUIDRef)
            }
        }
        
        for friendsFriendUID in Array(friend.friends.keys) {
            if friendsFriendUID != self.currentUser!.uid {
                let friendsFriendUIDRef = self.db.collection("users").document(friendsFriendUID)
                
                batch.updateData([
                    VKConstants.feed: FieldValue.arrayUnion([photoID])
                ], forDocument: friendsFriendUIDRef)
            }
        }
        
        batch.commit() { error in
            if let error = error {
                completed(VKError.custom(string: error.localizedDescription))
            } else {
                completed(nil)
            }
        }
    }
    
    public func getFeed(photoIDs: [String], completed: @escaping(Result<[(UIImage, VKPhotoData)], Error>) -> Void) {
        var photosList = [(UIImage, VKPhotoData)]()
        
        if photoIDs.count == 0 {
            completed(.success(photosList))
            return
        }

        for photoID in photoIDs {
            // Create a reference to the file you want to download
            let photoRef = storageRef.child(photoID)

            // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
            photoRef.getData(maxSize: imageSizeMB * 1024 * 1024) { data, error in
                if let error = error {
                    completed(.failure(error))
                } else {
                    if let image = UIImage(data: data!) {
                        self.db.collection("photos").document(photoID).getDocument(as: VKPhotoData.self) { result in
                            switch result {
                            case .success(let photoData):
                                photosList.append((image, photoData))
                            case .failure(_):
                                completed(.failure(VKError.unableToFetchUser))
                            }
                            
                            if photosList.count == photoIDs.count {
                                completed(.success(photosList))
                            }
                        }
                    } else {
                        completed(.failure(VKError.custom(string: "Failed to retrieve photos")))
                    }
                }
            }
        }
    }
    
    public func getFriendPhotos(photoIDs: [String], completed: @escaping(Result<[(UIImage, Date?)], Error>) -> Void) {
        // Get list of photos for this friendship
        var photosList = [(UIImage, Date?)]()
        
        if photoIDs.count == 0 {
            completed(.success(photosList))
            return
        }
        
        for photoID in photoIDs {
            // Create a reference to the file you want to download
            let photoRef = storageRef.child(photoID)

            // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
            photoRef.getData(maxSize: imageSizeMB * 1024 * 1024) { data, error in
                if let error = error {
                    completed(.failure(error))
                } else {
                    if let image = UIImage(data: data!) {
                        photoRef.getMetadata { metadata, error in
                            if let _ = error {
                                completed(.failure(VKError.custom(string: "Failed to retrieve photos")))
                            } else {
                                photosList.append((image, metadata?.timeCreated))
                            }
                            
                            if photosList.count == photoIDs.count {
                                completed(.success(photosList))
                            }
                        }
                    } else {
                        completed(.failure(VKError.custom(string: "Failed to retrieve photos")))
                    }
                }
            }
        }
    }
    
    //MARK: - Friends
    // Update friendship if friendship already exists
    public func updateAndGetMutualFriends(userOne: VKUser, userTwo: VKUser, completed: @escaping(Result<[String], Error>) -> Void) {
        let mutualFriends = Array(Set(userOne.friends.keys).intersection(userTwo.friends.keys))
        let jointID = userOne.friends[userTwo.uid]!
        
        db.collection("friendInfo").document(jointID).updateData([
            VKConstants.mutualFriends: mutualFriends
        ]) { error in
            if let error = error {
                completed(.failure(VKError.custom(string: error.localizedDescription)))
            } else {
                completed(.success(mutualFriends))
            }
        }
    }
    
    // Get specified user's friends as VKUsers (defaults to current user)
    public func getFriends(completed: @escaping (Result<[VKFriendAssociatedData], Error>) -> Void) {
        guard let currentUser = currentUser else { return }
        
        let friendUIDs = currentUser.getFriendUIDs()
        var friendsAndInfos = [VKFriendAssociatedData]()
        
        if (friendUIDs.isEmpty) {
            completed(.success(friendsAndInfos))
        }
                
        for friendUID in friendUIDs {
            self.getFriendAssociatedData(for: friendUID) { result in
                switch result {
                case .success(let friendAssociatedData):
                    friendsAndInfos.append(friendAssociatedData)
                    if friendsAndInfos.count == friendUIDs.count {
                        completed(.success(friendsAndInfos))
                    }
                case .failure(let error):
                    completed(.failure(error))
                }
            }
        }
    }
    
    func getFriendAssociatedData(for friendUID: String, completed: @escaping(Result<VKFriendAssociatedData, Error>) -> Void) {
        guard let currentUser = currentUser else { return }
        //Get friend
        getUsers(for: [friendUID]) { result in
            switch result {
            case .success(let users):
                guard let user = users.first, let friendInfoID = currentUser.friends[friendUID] else { return }
                //Get VKFriendInfo
                self.getFriendInfo(for: friendInfoID) { result in
                    switch result {
                    case .success(let friendInfo):
                        //Get Mutual Friends
                        self.getUsers(for: friendInfo.mutualFriends) { result in
                            switch result {
                            case .success(let mutualFriends):
                                self.getLastTappedAddress(friendInfo: friendInfo) { result in
                                    switch result {
                                    case .success(let address):
                                        completed(.success(VKFriendAssociatedData(friend: user, friendInfo: friendInfo, mutualFriends: mutualFriends, lastTapAddress: address)))
                                    case .failure(let error):
                                        completed(.failure(error))
                                    }
                                }
                            case .failure(let error):
                                completed(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completed(.failure(error))
                    }
                }
            case .failure(let error):
                completed(.failure(error))
            }
        }
    }
    
    func getLastTappedAddress(friendInfo: VKFriendInfo, completed: @escaping(Result<String, Error>) -> Void) {
        let lastTappedIndex = friendInfo.tappedLocations["lat"]!.count - 1

        Utils.getAddressFromLatLon(lat: friendInfo.tappedLocations["lat"]![lastTappedIndex], lon: friendInfo.tappedLocations["lon"]![lastTappedIndex]) { result in
            switch result {
            case .success(let address):
                completed(.success(address))
            case .failure(let error):
                completed(.failure(error))
            }
        }
    }
    
    func getFriendInfo(for friendInfoID: String, completed:  @escaping(Result<VKFriendInfo, Error>) -> Void) {
        db.collection("friendInfo").document(friendInfoID).getDocument(as: VKFriendInfo.self) { result in
            switch result {
            case .success(let friendInfo):
                completed(.success(friendInfo))
            case .failure(let error):
                print(error)
                completed(.failure(error))
            }
        }
    }
    
    //VKFriendInfo Listeners
    func observeFriendInfos(for friendInfoIDs: [String], completed: @escaping(VKError?) -> Void) {
        for friendInfoID in friendInfoIDs {
            if !friendInfoListeners.contains(where: { $0.key == friendInfoID }) {
                let friendInfoListener = db.collection("friendInfo").whereField("jointID", isEqualTo: friendInfoID).addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents,
                          let friendInfoDoc = documents.first else { return }
                    do {
                        let friendInfoData = try friendInfoDoc.data(as: VKFriendInfo.self)
                        self.broadcastNewFriendInfo(for: friendInfoData)
                    } catch {
                        completed(VKError.unableToObserveFriendInfo)
                    }
                }
                
                friendInfoListeners[friendInfoID] = friendInfoListener
            }
        }
    }
    
    func broadcastNewFriendInfo(for friendInfo: VKFriendInfo) {
        NotificationCenter.default.post(name: .updatedFriendInfo, object: friendInfo)
    }
    
    func removeFriendInfoListeners(for friendInfoIDs: [String]) {
        for friendInfoID in friendInfoIDs {
            friendInfoListeners[friendInfoID]?.remove()
        }
    }
    
    func removeAllFriendInfoListeners() {
        friendInfoListeners.forEach({ $0.value.remove() })
    }
    
    //Friend VKUser Listeners
    func observeFriends(for friendUIDs: [String], completed: @escaping(VKError?) -> Void) {
        for friendUID in friendUIDs {
            if !friendListeners.contains(where: { $0.key == friendUID }) {
                let friendListener = db.collection("users").whereField(VKConstants.userUID, isEqualTo: friendUID).addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents,
                          let friendDoc = documents.first else { return }
                    do {
                        let friendData = try friendDoc.data(as: VKUser.self)
                        self.broadcastUpdatedFriend(for: friendData)
                    } catch {
                        completed(VKError.unableToObserveFriend)
                    }
                }
                
                friendListeners[friendUID] = friendListener
            }
        }
    }
    
    func broadcastUpdatedFriend(for updatedFriend: VKUser){
        NotificationCenter.default.post(name: .updatedFriend, object: updatedFriend)
    }
    
    func removeFriendListeners(for friendIDs: [String]) {
        for friendID in friendIDs {
            friendListeners[friendID]?.remove()
        }
    }
    
    func removeAllFriendListeners() {
        friendListeners.forEach({ $0.value.remove() })
    }
    
    func getUsers(for userIDs: [String], completed: @escaping(Result<[VKUser], Error>) -> Void) {
        var users = [VKUser]()
        
        if (userIDs.isEmpty) {
            completed(.success(users))
        }
        
        for userID in userIDs {
            db.collection("users").document(userID).getDocument(as: VKUser.self) { result in
                switch result {
                case .success(let user):
                    users.append(user)
                    if users.count - 1 == userIDs.count - 1 {
                        completed(.success(users))
                    }
                case .failure(let error):
                    completed(.failure(error))
                }
            }
        }
    }
    
    //MARK: - Groups
    func createGroups(for groups: [VKGroup], completed: @escaping(VKError?) -> Void) {
        guard let currentUser = currentUser else { return }
        let batch = db.batch()
        
        for group in groups {
            let groupRef = db.collection("groups").document(group.jointID)
            batch.setData(group.dictionary, forDocument: groupRef)
        }
        
        let currentUserRef = db.collection("users").document(currentUser.uid)
        batch.updateData([
            VKConstants.groups: FieldValue.arrayUnion(groups.map{ $0.jointID })
        ], forDocument: currentUserRef)
        
        batch.commit() { error in
            if let error = error {
                completed(VKError.custom(string: error.localizedDescription))
            } else {
                completed(nil)
            }
        }
    }
    
    func fetchGroups(for groupIDs: [String], completed: @escaping(Result<[VKGroup], VKError>) -> Void) {
        if groupIDs.isEmpty {
            completed(.success([VKGroup]()))
        }
        
        var fetchedGroups = [VKGroup]()
        
        for groupID in groupIDs {
            db.collection("groups").document(groupID).getDocument(as: VKGroup.self) { result in
                switch result {
                case .success(let group):
                    fetchedGroups.append(group)
                    
                    if fetchedGroups.count == groupIDs.count {
                        print("Fetched Groups: \(fetchedGroups)")
                        completed(.success(fetchedGroups))
                    }
                case .failure(let error):
                    completed(.failure(VKError.custom(string: error.localizedDescription)))
                }
            }
        }
    }
    
    func deleteGroups(for groups: [VKGroup], completed: @escaping(VKError?) -> Void) {
        let batch = db.batch()
        
        for group in groups {
            let groupRef = db.collection("groups").document(group.jointID)
            batch.deleteDocument(groupRef)
            
            for memberUID in group.membersAndStatus.keys {
                let memberRef = db.collection("users").document(memberUID)
                batch.updateData([
                    VKConstants.groups: FieldValue.arrayRemove([group.jointID])
                ], forDocument: memberRef)
            }
            
            groupListeners.removeValue(forKey: group.jointID)
        }

        batch.commit() { error in
            if let error = error {
                completed(VKError.custom(string: error.localizedDescription))
            } else {
                completed(nil)
            }
        }
    }
    
    func updateGroup(for groupID: String, fields: [String: Any], completed: @escaping(VKError?) -> Void) {
        db.collection("groups").document(groupID).updateData(fields) { error in
            if let error = error {
                completed(VKError.custom(string: error.localizedDescription))
            } else {
                completed(nil)
            }
        }
    }
    
    func observeGroups(for groupIDs: [String], completed: @escaping(VKError?) -> Void) {
        for groupID in groupIDs {
            if !groupListeners.contains(where: { $0.key == groupID}) {
                let groupListener = db.collection("groups").whereField(VKConstants.jointID, isEqualTo: groupID).addSnapshotListener { querySnapshot, error in
                    print("Group Update")
                    guard let documents = querySnapshot?.documents,
                          let groupDocument = documents.first else { return }
                    do {
                        let groupData = try groupDocument.data(as: VKGroup.self)
                        self.broadcastUpdatedGroup(for: groupData)
                    } catch {
                        completed(VKError.unableToObserveGroup)
                    }
                }
                
                groupListeners[groupID] = groupListener
            }
        }
    }
    
    func broadcastUpdatedGroup(for group: VKGroup) {
        NotificationCenter.default.post(name: .updatedGroup, object: group)
    }
    
    func removeGroupListeners(for groupIDs: [String]) {
        for groupID in groupIDs {
            groupListeners[groupID]?.remove()
        }
    }
    
    func removeFromGroup(from group: VKGroup, forUID userUID: String) {
        let currentUserRef = db.collection("users").document(userUID)
        currentUserRef.updateData([
            VKConstants.groups: FieldValue.arrayRemove([group.jointID])
        ])
        
        let groupRef = db.collection("groups").document(group.jointID)
        
        var newMembersAndStatus = group.membersAndStatus
        newMembersAndStatus.removeValue(forKey: userUID)
        
        groupRef.updateData([
            VKConstants.membersAndStatus: newMembersAndStatus
        ])
    }
    
    //MARK: - Public Helper Methods
    func getCurrentUser() -> VKUser? {
        return currentUser
    }
}

//MARK: - AuthErrorCode.Code Extension 
extension AuthErrorCode.Code {
    func getErrorMessage() -> String {
        switch self {
        case .emailAlreadyInUse:
            return "The email is already in use with another account."
        case .userNotFound:
            return "Account not found for the specified user. Please check and try again."
        case .userDisabled:
            return "Your account has been disabled. Please contact support."
        case .invalidEmail, .invalidSender, .invalidRecipientEmail:
            return "Please enter a valid email"
        case .missingEmail:
            return "Email field cannot be empty."
        case .networkError:
            return "Network error. Please try again."
        case .weakPassword:
            return "Your password is too weak. The password must be 6 characters long or more."
        case .wrongPassword:
            return "Your password is incorrect. Please try again or use 'Forgot password' to reset your password"
        default:
            return "Unknown error occurred"
        }
    }
}

