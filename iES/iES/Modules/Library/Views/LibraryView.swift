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
            Group {
                backgroundView
                contentView
            }
            .allowsHitTesting(!viewModel.isDetailsPresented)
            .blur(radius: viewModel.isDetailsPresented ? 15 : 0)
            .onChange(of: viewModel.isDetailsPresented, { oldValue, newValue in
                withAnimation {
                    if newValue {
                        viewModel.detailsViewOffset.height = 0
                    }
                }
            })
            
            if viewModel.isDetailsPresented {
                detailsView
            }
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
    
    private var backgroundView: some View {
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
    
    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], content: {
                ForEach(viewModel.games) { game in
                    LibraryItemView(icon: game.icon, title: game.title)
                        .onTapGesture {
                            viewModel.modelToPresent = game
                            withAnimation {
                                viewModel.isDetailsPresented = true
                            }
                        }
                        .padding(20)
                }
            })
            .padding([.horizontal, .top], 40)
        }
    }
    
    private var detailsView: some View {
        LibraryItemDetailView(model: viewModel.modelToPresent ?? LibraryItemModel(title: "<Missing>", icon: Image(systemName: "externaldrive.badge.exclamationmark")))
            .padding(40)
            .aspectRatio(1, contentMode: .fit)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation {
                            if value.translation.height < 0 {
                                viewModel.detailsViewOffset.height = 0
                            } else {
                                viewModel.detailsViewOffset.height = value.translation.height
                            }
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 200 {
                            withAnimation {
                                viewModel.isDetailsPresented = false
                                viewModel.detailsViewOffset.height = 500
                            }
                        } else {
                            withAnimation {
                                viewModel.detailsViewOffset.height = 0
                            }
                        }
                    }
            )
            .offset(viewModel.detailsViewOffset)
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
