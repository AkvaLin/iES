//
//  AddGameView.swift
//  iES
//
//  Created by Никита Пивоваров on 03.08.2024.
//

import SwiftUI
import PhotosUI

// TODO: logic
/*
 https://developer.apple.com/documentation/photokit/bringing_photos_picker_to_your_swiftui_app
 */

struct AddGameView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var isImporting = false
    @State private var isFileSelected = false
    @State private var gameName = ""
    @State var imageSelection: PhotosPickerItem? = nil
    
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
            
            VStack {
                Button {
                    //                    isImporting = true
                    isFileSelected = true
                } label: {
                    Label("Import from Files", systemImage: "folder")
                }
                .padding()
                if isFileSelected {
                    VStack {
                        HStack(spacing: 40) {
                            VStack(spacing: 40) {
                                Spacer()
                                TextField("Enter the name of the game", text: $gameName)
                                    .padding()
                                    .background {
                                        RoundedRectangle(cornerRadius: 25.0)
                                            .fill(.thinMaterial)
                                    }
                                PhotosPicker(selection: $imageSelection) {
                                    Label("Choose an artwork", systemImage: "photo")
                                }
                                Spacer()
                            }
                            HStack {
                                HomeViewIcon(text: gameName, color: .game, icon: Image(systemName: "gamecontroller"))
                                LibraryItemView(icon: Image(systemName: "gamecontroller"), title: gameName)
                            }
                        }
                        .padding(.horizontal)
                        Button {
                            
                        } label: {
                            Text("Save")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.init(filenameExtension: "nes")!], onCompletion: { result in
                switch result {
                case .success(let success):
                    print(success)
                case .failure(let failure):
                    print(failure)
                }
            })
        }
    }
}

#Preview {
    AddGameView()
}
