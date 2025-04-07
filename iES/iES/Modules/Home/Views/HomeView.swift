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
    @Environment(\.modelContext) var modelContext
    @State private var profile: ProfileModel = ProfileModel(name: "")
    
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
                                    ConsoleView(game: game, profile: profile)
                                        .ignoresSafeArea()
                                } label: {
                                    HomeViewIcon(text: game.title, icon: UIElements.gameImage(imageData: game.imageData))
                                }
                            }
                            NavigationLink {
                                LibraryView()
                            } label: {
                                HomeViewIcon(localizedText: "library", icon: Image(systemName: "books.vertical"))
                            }
                            NavigationLink {
                                ProfileView()
                            } label: {
                                HomeViewIcon(localizedText: "profile", icon: Image(systemName: "person"))
                            }
                            NavigationLink {
                                SettingsView()
                            } label: {
                                HomeViewIcon(localizedText: "settings", icon: Image(systemName: "slider.horizontal.3"))
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
                .onAppear {
                    self.profile = ProfileService.getProfile(context: modelContext)
                    Task {
                        guard let data = await CloudService.load() else { return }
                        do {
                            let model = try CloudServiceConverter.getCodableStruct(data: data)
                            CloudServiceConverter.saveFromCodableStruct(model, context: modelContext)
                        } catch {
                            print(error)
                        }
                    }
                }
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
