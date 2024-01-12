//
//  SettingsView.swift
//  Verkko
//
//  Created by Justin Wong on 6/3/23.
//

import SwiftUI
import Setting

//MARK: - SettingsViewModel
class SettingsViewModel: ObservableObject {
    @AppStorage(SettingsConstants.allowNotifications) var allowNotifications = true
    @AppStorage(SettingsConstants.appearanceIndex) var appearanceIndex = 0
    @AppStorage(SettingsConstants.subscriptionPlanIsFree) var subscriptionPlanIsFree = true
    @AppStorage(SettingsConstants.isEmailVisible) var isEmailVisible = true 
    @AppStorage(SettingsConstants.areInterestsVisible) var areInterestsVisible = true
    @AppStorage(SettingsConstants.isBirthdayVisible) var isBirthdayVisible = true
    @AppStorage(SettingsConstants.isPhoneNumberVisible) var isPhoneNumberVisible = true
}

struct SettingsView: View {
    @ObservedObject private var model = SettingsViewModel()
    @State private var error: VKError?
    @State private var showLogoutConfirmationAlert = false 
    @State private var isPresentingError = false
    @State private var isLoading = false
    
    private var hello: CGFloat = 15
    
    var body: some View {
        ZStack {
            SettingStack {
                SettingPage(title: "Settings") {
                    settingsProfileHeaderView
                    SettingGroup(id: "MainSection") {
                        generalSection
                        appearanceSection
                        
                        //When in @SettingBuilder, I couldn't access model for some reason 
                        SettingPage(title: "Privacy") {
                            SettingGroup(header: "Share Visibility") {
                                SettingCustomView {
                                    SettingsSharePersonalInfoVisibilitiesView(model: model)
                                        .padding(15)
                                }
                            }
                        }
                        .previewIcon("lock.fill", foregroundColor: .white, backgroundColor: .gray.opacity(0.7))
                        
                        subscriptionSection
                        helpSection
                        aboutSection
                    }
                    
                    //Don't know why I can't refactor into a SettingBuilder
                    SettingGroup(id: "LogoutGroup") {
                        SettingCustomView(id: "LogoutButton") {
                            SettingButton(title: "Logout") {
                                showLogoutConfirmationAlert.toggle()
                            }
                            .foregroundColor(.red)
                            .presentScreen(isPresented: $isPresentingError, modalPresentationStyle: .overFullScreen) {
                                VKSwiftUIAlertView(alertTitle: "Error", message: error?.getMessage() ?? "", buttonTitle: "OK")
                            }
                            .confirmationDialog("Confirm Logout", isPresented: $showLogoutConfirmationAlert) {
                                Button("OK", action: {
                                    isLoading = true
                                    
                                    //Add an additional 1 sec so prevent any "flashing" when logoutCurrentUser resolves very quickly
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        FirebaseManager.shared.logoutCurrentUser { error in
                                            isLoading = false
                                            if let error = error {
                                                self.error = error
                                                isPresentingError = true
                                            }
                                        }
                                    }
                                    
                                })
                                Button("Cancel", role: .cancel) {
                                    showLogoutConfirmationAlert.toggle()
                                }
                            } message: {
                                Text("Are you sure you want to logout?")
                            }
                        }
                    }
                }
            }
            if isLoading {
                VKSwiftUILoadingView(isLoading: $isLoading)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    //MARK: - SettingsProfileHeaderView
    @SettingBuilder private var settingsProfileHeaderView: some Setting {
        SettingGroup(id: "SettingsProfileHeaderView") {
            SettingCustomView(id: "SettingsProfileHeaderView") {
                SettingsProfileHeaderView()
            }
        }
    }
    
    //MARK: - General Section
    @SettingBuilder private var generalSection: some Setting {
        SettingPage(title: "General") {
//            SettingGroup {
//                SettingToggle(title: "Enable Notifications", isOn: $model.allowNotifications)
//            }
            
            SettingGroup {
                SettingCustomView(id: "ForgotPassword") {
                    Button("Forgot Password") {
                        //Reset Password
                    }
                    .foregroundColor(.red)
                    .padding(15)
                }
                SettingCustomView(id: "DeleteAccount") {
                    Button("Delete Account") {
                        //Delete Account From Firestore
                    }
                    .foregroundColor(.red)
                    .padding(15)
                }
            }
        }
        .previewIcon("gear", foregroundColor: .white, backgroundColor: .gray)
    }
    
    //MARK: - Appearance Section
    @SettingBuilder private var appearanceSection: some Setting {
        SettingPage(title: "Appearance") {
            SettingGroup {
                SettingCustomView(id: "SettingAppearanceSectionHeader") {
                    HStack {
                        Text("Choose an appearance for TimeTangle. \"Auto\" will match TimeTangle to the system-wide appearance")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                        Image(systemName: "sun.max.fill")
                            .frame(width: 70, height: 70)
                            .background(.black)
                            .foregroundColor(.yellow)
                            .cornerRadius(10)
                            .font(.system(.largeTitle))
                    }
                    .padding(15)
                }
            }
            
            SettingGroup {
                SettingPicker(title: "Appearance", choices: [
                "Auto",
                "Light",
                "Dark"
                ], selectedIndex: $model.appearanceIndex, choicesConfiguration: .init(pickerDisplayMode: .inline))
            }
        }
        .previewIcon("sun.max.fill", foregroundColor: .yellow, backgroundColor: .black)
    }
}

//MARK: - Subscription Section
@SettingBuilder private var subscriptionSection: some Setting {
    SettingPage(title: "Subscription") {
        
    }
    .previewIcon("bubbles.and.sparkles", foregroundColor: .white, backgroundColor: .purple)
}

//MARK: - Help Section
@SettingBuilder private var helpSection: some Setting {
    SettingPage(title: "Help") {}
        .previewIcon("questionmark.circle.fill", foregroundColor: .white, backgroundColor: .blue)
}

//MARK: - About Section
@SettingBuilder private var aboutSection: some Setting {
    SettingPage(title: "About") {
        SettingCustomView(id: "AppIcon") {
            Image(systemName: "app.fill")
                .font(.system(size: 100))
                .frame(width: 100, height: 100)
                .foregroundColor(Color(uiColor: .lightGray))
                .centered()
        }
        
        SettingCustomView(id: "AppInfo") {
            VStack(spacing: 10) {
                if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Verkko \(appVersion)")
                }
                
                if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Build \(buildNumber)")
                }
                
                Text("iOS \(UIDevice.current.systemVersion)")
            }
            .foregroundColor(.gray)
            .centered()
        }
        
        SettingCustomView(id: "About Me") {
            Text("Verkko is built by Mihir Rao & Justin Wong. 2 students at UC Berkeley studying Electrical Engineering and Computer Sciences.")
                .foregroundColor(.gray)
                .centered()
                .padding(15)
        }
        
        SettingGroup {
            SettingCustomView(id: "PrivacyPolicy") {
                Group {
                    Button(action: {}) {
                        Text("Personal Website")
                            .foregroundColor(.blue)
                            .leftAligned()
                    }
                    Button(action: {}) {
                        Text("Privacy Policy")
                            .foregroundColor(.blue)
                            .leftAligned()
                    }
                }
                .foregroundColor(.blue)
                .padding(15)
                .frame(maxWidth: .infinity)
            }
        }
    }
    .previewIcon("info.circle.fill", foregroundColor: .white, backgroundColor: .green)
}

//MARK: - SettingsProfileHeaderView
struct SettingsProfileHeaderView: View {
    
    @State private var profileImage: UIImage?
    @State private var name: String = ""
    @State private var username: String = ""
    
    var body: some View {
        NavigationLink(destination: SettingsMyProfileView()) {
            HStack(spacing: 20) {
                VKSwiftUIProfileImageView(image: profileImage, size: 70)
                    .frame(width: 70, height: 70)
                VStack(alignment: .leading) {
                    Text(name)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .font(.title2.bold())
                    Text(username)
                        .foregroundColor(.secondary)
                    Text("Free Plan")
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(15)
        }
        .onAppear {
            guard let currentUser = FirebaseManager.shared.currentUser else { return }
            if let imageData = currentUser.profilePictureData, let image = UIImage(data: imageData) {
                profileImage = image
            }
            name = currentUser.getFullName()
        }
    }
}

//MARK: - VKSwiftUIProfileImageView
struct VKSwiftUIProfileImageView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var image: UIImage?
    var size: CGFloat
    
    var body: some View {
        Group {
            if let profileImage = image {
                Image(uiImage: profileImage)
                    .resizable()
                    .frame(width: size, height: size)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 1))
            } else {
                Image(systemName: "person.crop.circle")
            }
        }
        .foregroundColor(.gray)
        .font(.system(size: size))
    }
}


//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
