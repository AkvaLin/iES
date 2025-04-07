//
//  LibraryVoew.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    
    @Query(GamesService.getDescriptor()) private var games: [GameModel]
    @Environment(\.modelContext) var modelContext
    @StateObject private var viewModel = LibraryViewModel()
    @State private var presentConsole = false
    @State private var playButtonWasPressed = false
    @State private var isBackgroundBlured = false
    @State private var profile: ProfileModel = ProfileModel(name: "")
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            UIElements.background()
            contentView
                .allowsHitTesting(!isLoading)
            if isBackgroundBlured {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .opacity(0.9)
            }
            if isLoading {
                Thinking()
            }
        }
        .navigationTitle(Localization.library)
        .toolbarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button(Localization.sortByName) {
                        withAnimation {
                            viewModel.sortBy = .name
                        }
                    }
                    Button(Localization.sortByRecentPlayed) {
                        withAnimation {
                            viewModel.sortBy = .datePlayed
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }

            }
            ToolbarItem(placement: .automatic) {
                NavigationLink {
                    AddGameView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isDetailsPresented) {
            if playButtonWasPressed {
                presentConsole = true
            }
        } content: {
            LibraryItemDetailView(model: viewModel.modelToPresent, profile: profile, playButtonWasPressed: $playButtonWasPressed)
                .onDisappear {
                    withAnimation {
                        isBackgroundBlured = false
                    }
                }
        }
        .alert(Localization.deleteGameAlert, isPresented: $viewModel.showDeleteAlert) {
            Button(Localization.delete, role: .destructive) {
                if let model = viewModel.modelToDelete {
                    isLoading = true
                    SwiftDataManager.delete(model, context: modelContext) { _ in
                        isLoading = false
                    }
                }
            }
            Button(Localization.cancel, role: .cancel) {}
        }
        .navigationDestination(isPresented: $presentConsole) {
            if let model = viewModel.modelToPresent {
                ConsoleView(game: model, profile: profile)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            self.profile = ProfileService.getProfile(context: modelContext)
        }
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], content: {
                ForEach(games.sorted(by: { lhs, rhs in
                    switch viewModel.sortBy {
                    case .name:
                        lhs.title < rhs.title
                    case .datePlayed:
                        lhs.lastTimePlayed > rhs.lastTimePlayed
                    }
                }), id: \.id) { game in
                    Button {
                        viewModel.modelToPresent = game
                        viewModel.isDetailsPresented = true
                        withAnimation {
                            isBackgroundBlured = true
                        }
                    } label: {
                        LibraryItemView(icon: Image(data: game.imageData), title: game.title)
                    }
                    .contextMenu {
                        Button(Localization.delete, systemImage: "trash", role: .destructive) {
                            viewModel.modelToDelete = game
                            viewModel.showDeleteAlert = true
                        }
                    }
                    .padding(.horizontal)
                }
            })
        }
    }
}

#if DEBUG
struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            //            LibraryView()
            //                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
            //                .previewDisplayName("iPhone")
            LibraryView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro 13-inch (M4)"))
                .previewDisplayName("iPad")
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
