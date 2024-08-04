//
//  MainView.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import SwiftUI

struct MainView: View {
    
    @StateObject private var settings = AppSettings()
    
    var body: some View {
        TabView {
            Group {
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "gamecontroller")
                    }
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
            }
            .environmentObject(settings)
        }
    }
}

#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                .previewDisplayName("iPhone")
            MainView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro 13-inch (M4)"))
                .previewDisplayName("iPad")
            MainView()
                .previewDevice(PreviewDevice(rawValue: "Apple TV 4K (3rd generation)"))
                .previewDisplayName("TV")
            MainView()
                .previewDevice(PreviewDevice(rawValue: "Apple Vision Pro"))
                .previewDisplayName("Vision")
            MainView()
                .previewDevice(PreviewDevice(rawValue: "Mac"))
                .previewDisplayName("Mac")
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
