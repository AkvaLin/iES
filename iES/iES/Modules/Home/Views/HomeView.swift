//
//  HomeView.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import Foundation
import SwiftUI
import SwiftData

struct HomeView: View {
    
    @Query(GamesService.getDescriptor(limit: 3)) private var games: [GameModel]
    
    var body: some View {
        NavigationStack {
            ZStack {
                UIElements.background()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 40) {
                        Group {
                            HomeViewIcon()
                            EmptyView()
                            ForEach(games, id: \.id) { game in
                                NavigationLink {
                                    ConsoleView(game: game)
                                        .ignoresSafeArea()
                                } label: {
                                    HomeViewIcon(text: game.title, icon: UIElements.gameImage(imageData: game.imageData))
                                }
                            }
                            NavigationLink {
                                LibraryView()
                            } label: {
                                HomeViewIcon(localizedText: "Library", icon: Image(systemName: "books.vertical"))
                            }
                            NavigationLink {
                                ProfileView()
                            } label: {
                                HomeViewIcon(localizedText: "Profile", icon: Image(systemName: "person"))
                            }
                            NavigationLink {
                                SettingsView()
                            } label: {
                                HomeViewIcon(localizedText: "Settings", icon: Image(systemName: "slider.horizontal.3"))
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
            HomeView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                .previewDisplayName("iPhone")
            HomeView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro 13-inch (M4)"))
                .previewDisplayName("iPad")
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
