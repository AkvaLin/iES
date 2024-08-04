//
//  HomeView.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import SwiftUI

struct HomeView: View {
    
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 40) {
                        Group {
                            HomeViewIcon()
                            ForEach(0..<3) { _ in
                                HomeViewIcon(localizedText: "Game", color: .game, icon: Image(systemName: "gamecontroller"))
                            }
                            NavigationLink {
                                LibraryView()
                            } label: {//00CED1
                                HomeViewIcon(localizedText: "Library", color: .library, icon: Image(systemName: "books.vertical"))
                            }
                            NavigationLink {
                                ProfileView()
                            } label: {
                                HomeViewIcon(localizedText: "Profile", color: .profile, icon: Image(systemName: "person"))
                            }
                            NavigationLink {
                                
                            } label: {
                                HomeViewIcon(localizedText: "Settings", color: .settings, icon: Image(systemName: "slider.horizontal.3"))
                            }
                            HomeViewIcon()
                        }
                        .containerRelativeFrame(.horizontal, count: 3, spacing: 40.0)
                        .scrollTransition(.interactive.threshold(.centered)) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0)
                                .scaleEffect(x: phase.isIdentity ? 1 : 0.3, y: phase.isIdentity ? 1 : 0.3)
                        }
                        .foregroundStyle(.primary)
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(40, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            //            HomeView()
            //                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
            //                .previewDisplayName("iPhone")
            HomeView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro 13-inch (M4)"))
                .previewDisplayName("iPad")
            //            HomeView()
            //                .previewDevice(PreviewDevice(rawValue: "Apple TV 4K (3rd generation)"))
            //                .previewDisplayName("TV")
            //            HomeView()
            //                .previewDevice(PreviewDevice(rawValue: "Apple Vision Pro"))
            //                .previewDisplayName("Vision")
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
