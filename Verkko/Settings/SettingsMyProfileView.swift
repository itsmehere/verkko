//
//  SettingsMyProfileView.swift
//  Verkko
//
//  Created by Justin Wong on 6/6/23.
//

import SwiftUI
import Setting
import PhotosUI

struct SettingsMyProfileView: View {
    
    @State private var profileImage: UIImage?
    @State private var showChangeNameAlert = false
    @State private var showChangeUsernameAlert = false
    @State private var showLogoutConfirmationAlert = false
    
    @State private var firstname = ""
    @State private var lastname = ""
    @State private var username = ""
    
    @State private var imageSelection = [PhotosPickerItem]()
    
    @State private var vkError: VKError? = nil
    @State private var showErrorAlert = false
    
    var body: some View {
        SettingStack(isSearchable: false) {
            SettingPage(title: "My Profile", navigationTitleDisplayMode: .inline) {
                profilePictureSection
                
                //Change Name Section
                SettingGroup(id: "Name", header: "Name") {
                    SettingText(title: "\(firstname) \(lastname)")
                    SettingCustomView(id: "ChangeName") {
                        Button(action: {
                            showChangeNameAlert.toggle()
                        }) {
                            Text("Change Name")
                                .leftAligned()
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                            
                        }
                        .padding(15)
                        .alert("Change Name", isPresented: $showChangeNameAlert) {
                            TextField("First Name", text: $firstname)
                            TextField("Last Name", text: $lastname)
                            Button("OK", action: {
                                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                                FirebaseManager.shared.updateUserData(for: currentUser.uid, with: [
                                    VKConstants.userFirstName: firstname.trimmingCharacters(in: .whitespacesAndNewlines),
                                    VKConstants.userLastName: lastname.trimmingCharacters(in: .whitespacesAndNewlines)
                                ]) { error in
                                    guard let error = error else { return }
                                    vkError = error
                                    showErrorAlert = true
                                }
                            })
                            Button("Cancel", role: .cancel) {
                                showChangeNameAlert.toggle()
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: imageSelection) { _ in
            Task {
                if let data = try? await imageSelection.first?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        uploadProfileImageDataToFirestore(for: uiImage)
                        profileImage = uiImage
                        return
                    }
                }
                vkError = VKError.unableToFetchProfileImage
                showErrorAlert = true
            }
        }
        .presentScreen(isPresented: $showErrorAlert, modalPresentationStyle: .fullScreen) {
            VKSwiftUIAlertView(alertTitle: "Error", message: vkError?.getMessage() ?? "No Message", buttonTitle: "OK")
                .ignoresSafeArea(.all)
        }
    }
    
    //MARK: - Profile Picture Section
    @SettingBuilder private var profilePictureSection: some Setting {
        SettingCustomView(id: "ProfilePicture") {
            VStack(spacing: 10) {
                profileImageView
                PhotosPicker(selection: $imageSelection, maxSelectionCount: 1, matching: .images, photoLibrary: .shared()) {
                    Text("Edit Picture")
                        .font(.system(size: 15).bold())
                        .foregroundColor(.white)
                }
                .padding(10)
                .background(Color(.systemGray3))
                .cornerRadius(10)
            }
            .onAppear {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                print(currentUser)
                if let imageData = currentUser.profilePictureData, let image = UIImage(data: imageData) {
                    profileImage = image
                }
                firstname = currentUser.firstName
                lastname = currentUser.lastName
            }
        }
    }
    
    private var profileImageView: some View {
        HStack {
            Spacer()
            VKSwiftUIProfileImageView(image: profileImage, size: 120)
            Spacer()
        }
    }
    
    //MARK: - Username Section
    @SettingBuilder private var usernameSection: some Setting {
        SettingGroup(id: "Username", header: "Username") {
            SettingText(title: username)
            SettingCustomView(id: "ChangeUsername") {
                HStack {
                    Button(action: {
                        showChangeUsernameAlert.toggle()
                    }) {
                        Text("Change Username")
                            .leftAligned()
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                    }
                    Spacer()
                }
                .padding(15)
                .alert("Change Username", isPresented: $showChangeUsernameAlert) {
                    TextField("Username", text: $username)
                    Button("OK", action: {
                        guard let currentUser = FirebaseManager.shared.currentUser else { return }
                        FirebaseManager.shared.updateUserData(for: currentUser.uid, with: [
                            VKConstants.userFirstName: firstname,
                            VKConstants.userLastName: lastname
                        ]) { error in
                            guard error == nil else { return }
                        }
                    })
                    Button("Cancel", role: .cancel) {
                        showChangeUsernameAlert.toggle()
                    }
                }
            }
        }
    }
    
    private func uploadProfileImageDataToFirestore(for image: UIImage) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }

        guard let compressedImageData = image.jpegData(compressionQuality: 0.1) else { return }

        FirebaseManager.shared.updateUserData(for: currentUser.uid, with: [
            VKConstants.userProfilePictureData: compressedImageData
        ]) { error in
            if let _ = error {
                vkError = VKError.unableToUploadProfileImage
            }
        }
    }
}

struct SettingsMyProfilePreviewProvider_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMyProfileView()
    }
}

