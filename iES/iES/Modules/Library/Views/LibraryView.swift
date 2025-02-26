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
    
    var body: some View {
        ZStack {
            UIElements.background()
            contentView
        }
        .navigationTitle("Library")
        .toolbarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button("Sort by Name") {
                        withAnimation {
                            viewModel.sortBy = .name
                        }
                    }
                    Button("Sort by Recently Played") {
                        withAnimation {
                            viewModel.sortBy = .datePlayed
                        }
                    }
                    Button("Sort by Date Added") {
                        withAnimation {
                            viewModel.sortBy = .dateAdded
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
            LibraryItemDetailView(model: viewModel.modelToPresent, playButtonWasPressed: $playButtonWasPressed)
        }
        .alert("The game and all data will be permanently deleted.\nAre you sure?", isPresented: $viewModel.showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let model = viewModel.modelToDelete {
                    modelContext.delete(model)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .navigationDestination(isPresented: $presentConsole) {
            if let model = viewModel.modelToPresent {
                ConsoleView(game: model)
                    .ignoresSafeArea()
            }
        }
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], content: {
                ForEach(games.sorted(by: { lhs, rhs in
                    switch viewModel.sortBy {
                    case .name:
                        lhs.title < rhs.title
                    case .dateAdded:
                        lhs.title < rhs.title
                    case .datePlayed:
                        lhs.lastTimePlayed > rhs.lastTimePlayed
                    }
                }), id: \.id) { game in
                    Button {
                        viewModel.modelToPresent = game
                        viewModel.isDetailsPresented = true
                    } label: {
                        LibraryItemView(icon: Image(data: game.imageData), title: game.title)
                    }
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
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
