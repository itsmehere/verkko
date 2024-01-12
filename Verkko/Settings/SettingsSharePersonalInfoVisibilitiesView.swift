//
//  SettingsSharePersonalInfoVisibilitiesView.swift
//  Verkko
//
//  Created by Justin Wong on 6/19/23.
//

import SwiftUI

struct SettingsSharePersonalInfoVisibilitiesView: View {
    @ObservedObject var model: SettingsViewModel
    
    var currentUser: VKUser? = FirebaseManager.shared.currentUser
    
    var body: some View {
        VStack {
            SettingsSharePersonalInfoVisbilityView(infoNameText: "Email", isVisible: $model.isEmailVisible)
            Divider()
            SettingsSharePersonalInfoVisbilityView(infoNameText: "Phone Number", isVisible: $model.isPhoneNumberVisible)
            Divider()
            SettingsSharePersonalInfoVisbilityView(infoNameText: "Birthday", isVisible: $model.isBirthdayVisible)
            Divider()
            SettingsSharePersonalInfoVisbilityView(infoNameText: "Interests", isVisible: $model.areInterestsVisible)
        }
    }
}

//MARK: - SettingsSharePersonalInfoVisibilityView
struct SettingsSharePersonalInfoVisbilityView: View {
    var infoNameText: String
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack {
            Text(infoNameText)
                .bold()
            Spacer()
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .soft)
                generator.impactOccurred()
                isVisible.toggle()
            }) {
                Group {
                    if isVisible {
                        Image(systemName: "checkmark.circle.fill")
                    } else {
                        Image(systemName: "circle")
                    }
                }
                .font(.system(size: 30))
                .foregroundColor(Color(uiColor: .systemGreen))
            }
        }
    }
}

struct SettingsSharePersonalInfoVisibilitesPreview_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSharePersonalInfoVisibilitiesView(model: SettingsViewModel())
    }
}
