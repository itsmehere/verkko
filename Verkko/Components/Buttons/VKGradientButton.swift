//
//  VKGradientButton.swift
//  Verkko
//
//  Created by Justin Wong on 7/4/23.
//

import SwiftUI

struct VKGradientButton: View {
    var text: String
    var gradientColors: [Color]
    var completion: () -> Void
    
    var body: some View {
        Button(action: {
            completion()
        }) {
            Text(text)
                .padding()
                .foregroundColor(.white)
                .font(.system(size: 20).bold())
                .background(
                    RadialGradient(gradient: Gradient(colors: gradientColors), center: .center, startRadius: 1, endRadius: 150)
                )
                .cornerRadius(10.0)
                .shadow(color: gradientColors.first ?? .clear, radius: 10, x: 0, y: 0)
        }
    }
}
