//
//  DesignSystem.swift
//  iES
//
//  Created by Никита Пивоваров on 24.01.2025.
//

import SwiftUI

enum Colors {
    static let foregorundColor: Color = .iESForeground
    static let backgroundColor: Color = .iESBackground
    static let primaryColor: Color = .iESPrimary
    static let secondaryColor: Color = .iESSecondary
    static let accentColor: Color = .accent
}

enum Gradients {
    static let background: AnyGradient = Colors.backgroundColor.gradient
    static let primaryGradient: AnyGradient = Colors.primaryColor.gradient
}

enum Consts {
    static let padding: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 10
}

enum UIElements {
    enum Buttons {
        @ViewBuilder
        static func primaryButton(text: LocalizedStringKey, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Text(text)
                    .foregroundColor(Colors.primaryColor)
                    .padding()
                    .background(Colors.secondaryColor)
                    .cornerRadius(Consts.buttonCornerRadius)
            }
        }
        
        @ViewBuilder
        static func secondaryButton(text: LocalizedStringKey, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Text(text)
                    .foregroundColor(Colors.secondaryColor)
                    .padding()
                    .background(Colors.primaryColor)
                    .cornerRadius(Consts.buttonCornerRadius)
            }
        }
    }
    
    @ViewBuilder
    static func background() -> some View {
        Rectangle()
            .fill(Gradients.background)
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    static func gameImage(imageData data: Data?) -> Image {
        Image(data: data) ?? Image(systemName: "gamecontroller")
    }
}
