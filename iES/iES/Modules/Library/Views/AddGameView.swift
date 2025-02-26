//
//  AddGameView.swift
//  iES
//
//  Created by Никита Пивоваров on 03.08.2024.
//

import SwiftUI
import PhotosUI

struct AddGameView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var isImporting = false
    @State private var isFileSelected = false
    @State private var gameName = ""
    @State var imageSelection: PhotosPickerItem? = nil
    @State private var selectedFile: URL?
    @MainActor
    @State private var imageData: Data? = nil
    
    var body: some View {
        ZStack {
            UIElements.background()
            VStack {
                Button {
                    isImporting = true
                } label: {
                    Label(Localization.importFromFiles, systemImage: "folder")
                }
                .padding()
                if isFileSelected {
                    VStack {
                        HStack(spacing: 40) {
                            VStack(spacing: 40) {
                                Spacer()
                                TextField(Localization.gameTextFieldPrompt, text: $gameName)
                                    .padding()
                                    .background {
                                        RoundedRectangle(cornerRadius: 25.0)
                                            .fill(.thinMaterial)
                                    }
                                PhotosPicker(selection: $imageSelection, matching: .images) {
                                    Label(Localization.libraryPhotoPickerLabel, systemImage: "photo")
                                }
                                Spacer()
                            }
                            HStack {
                                HomeViewIcon(text: gameName, icon: UIElements.gameImage(imageData: imageData))
                                LibraryItemView(icon: Image(data: imageData), title: gameName)
                            }
                        }
                        .padding(.horizontal)
                        Button {
                            addGame()
                        } label: {
                            Text(Localization.save)
                        }
                        .disabled(gameName.isEmpty || imageSelection == nil || selectedFile == nil)
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.init(filenameExtension: "nes")!], onCompletion: { result in
                switch result {
                case .success(let success):
                    selectedFile = success
                    isFileSelected = true
                case .failure(let failure):
                    print(failure)
                }
            })
        }
        .onChange(of: imageSelection) {
            guard let imageSelection else {
                imageData = nil
                return
            }
            Task {
                guard let imageData = try? await imageSelection.loadTransferable(type: Data.self) else { return }
                self.imageData = imageData
            }
        }
    }
    
    private func addGame() {
        Task {
            defer { selectedFile?.stopAccessingSecurityScopedResource() }
            guard
                let imageData = try? await imageSelection?.loadTransferable(type: Data.self),
                let selectedFile,
                selectedFile.startAccessingSecurityScopedResource()
            else { return }
            
            do {
                let gameData = try Data(contentsOf: selectedFile)
                
                let model = GameModel(
                    title: gameName,
                    imageData: imageData,
                    lastTimePlayed: .now,
                    gameData: gameData
                )
                
                modelContext.insert(model)
            } catch {
                
            }
            
            dismiss()
        }
    }
}

#Preview {
    AddGameView()
}
