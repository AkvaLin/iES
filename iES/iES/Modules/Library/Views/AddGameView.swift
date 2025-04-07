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
    @State private var isLoading = false
    
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
                                if let imageData {
                                    HomeViewIcon(text: gameName, icon: UIElements.gameImage(imageData: imageData))
                                } else {
                                    HomeViewIcon(libraryText: gameName,
                                                 icon: UIElements.gameImage(imageData: imageData))
                                }
                                LibraryItemView(icon: Image(data: imageData), title: gameName)
                            }
                        }
                        .padding(.horizontal)
                        Button {
                            addGame()
                        } label: {
                            Text(Localization.save)
                        }
                        .disabled(gameName.isEmpty || selectedFile == nil)
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
            .allowsHitTesting(!isLoading)
            if isLoading {
                Thinking()
            }
        }
        .onChange(of: imageSelection) {
            guard let imageSelection else {
                imageData = nil
                return
            }
            Task {
                DispatchQueue.main.async {
                    isLoading = true
                }
                guard let imageData = try? await imageSelection.loadTransferable(type: Data.self) else {
                    DispatchQueue.main.async {
                        isLoading = false
                    }
                    return
                }
                self.imageData = imageData
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
    }
    
    private func addGame() {
        Task {
            DispatchQueue.main.async {
                isLoading = true
            }
            defer { selectedFile?.stopAccessingSecurityScopedResource() }
            guard
                let selectedFile,
                selectedFile.startAccessingSecurityScopedResource()
            else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }
            
            do {
                let gameData = try Data(contentsOf: selectedFile)
                
                let imageData: Data? =
                if let imageSelection {
                    try? await imageSelection.loadTransferable(type: Data.self)
                } else {
                    nil
                }
                
                let model = GameModel(
                    title: gameName,
                    imageData: imageData,
                    lastTimePlayed: .now,
                    gameData: gameData
                )
                
                SwiftDataManager.insert(model, context: modelContext) { _ in
                    DispatchQueue.main.async {
                        isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
            
            DispatchQueue.main.async {
                isLoading = false
            }
            dismiss()
        }
    }
}

#Preview {
    AddGameView()
}
