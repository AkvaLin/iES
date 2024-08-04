//
//  ProfileView.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import SwiftUI

struct ProfileView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                if colorScheme == .dark {
                    Rectangle()
                        .fill(.black.gradient)
                        .ignoresSafeArea()
                } else {
                    Rectangle()
                        .fill(.white.gradient)
                        .ignoresSafeArea()
                }
            }
        }
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                .previewDisplayName("iPhone")
            ProfileView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro 13-inch (M4)"))
                .previewDisplayName("iPad")
            ProfileView()
                .previewDevice(PreviewDevice(rawValue: "Apple TV 4K (3rd generation)"))
                .previewDisplayName("TV")
            ProfileView()
                .previewDevice(PreviewDevice(rawValue: "Apple Vision Pro"))
                .previewDisplayName("Vision")
        }
        .previewInterfaceOrientation(.landscapeLeft)
        .environmentObject(AppSettings())
    }
}
#endif
