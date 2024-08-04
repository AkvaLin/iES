//
//  LibraryVoew.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import SwiftUI

struct LibraryView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
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
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], content: {
                    ForEach(viewModel.games) { game in
                        LibraryItemView(icon: game.icon, title: game.title)
                            .padding(20)
                    }
                })
                .padding([.horizontal, .top], 40)
            }
            .navigationTitle("Library")
            .toolbarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    NavigationLink {
                        AddGameView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
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
            //            LibraryView()
            //                .previewDevice(PreviewDevice(rawValue: "Apple TV 4K (3rd generation)"))
            //                .previewDisplayName("TV")
            //            LibraryView()
            //                .previewDevice(PreviewDevice(rawValue: "Apple Vision Pro"))
            //                .previewDisplayName("Vision")
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
