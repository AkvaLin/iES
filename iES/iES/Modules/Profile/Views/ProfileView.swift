//
//  ProfileView.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    
    @State private var selectedImage: PhotosPickerItem?
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        ZStack {
            UIElements.background()
            GeometryReader { proxy in
                if UIDevice.current.userInterfaceIdiom == .phone {
                    if !viewModel.nameTextFieldEnabled {
                        List {
                            Section {
                                mainStatistics(proxy: proxy)
                                    .listRowBackground(Color.clear)
                                    .padding(.vertical)
                            } header: {
                                profileInfoHorizontal
                                    .frame(height: proxy.size.height / 3)
                                    .padding(.bottom)
                            }
                            Section {
                                ForEach(viewModel.statistics) { stat in
                                    HStack {
                                        Text(stat.title)
                                        Spacer()
                                        Text(stat.value)
                                    }
                                    .listRowBackground(backgroundView())
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    } else {
                        VStack {
                            TextField(Localization.playerName, text: $viewModel.playerNameTextField)
                                .textFieldStyle(.roundedBorder)
                                .foregroundStyle(Colors.foregorundColor)
                            Button(Localization.save) {
                                viewModel.saveName(context: modelContext)
                                withAnimation {
                                    viewModel.nameTextFieldEnabled = false
                                }
                            }
                            .disabled(viewModel.playerNameTextField.isEmpty)
                            .padding(.vertical)
                            .buttonStyle(.borderedProminent)
                            Button(Localization.cancel, role: .cancel) {
                                withAnimation {
                                    viewModel.nameTextFieldEnabled = false
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    HStack {
                        VStack {
                            profileInfoVertical
                                .frame(width: proxy.size.width / 3)
                            Spacer()
                            mainStatistics(proxy: proxy)
                                .padding(.vertical)
                            Spacer()
                        }
                        .padding(.vertical)
                        List {
                            ForEach(viewModel.statistics) { stat in
                                HStack {
                                    Text(stat.title)
                                    Spacer()
                                    Text(stat.value)
                                }
                                .listRowBackground(backgroundView())
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .frame(width: proxy.size.width / 3 * 2)
                    }
                }
            }
            .padding(.horizontal)
            .allowsHitTesting(!viewModel.isLoading)
            if viewModel.isLoading {
                Thinking()
            }
        }
        .navigationTitle(Localization.profile)
        .onAppear {
            viewModel.model = ProfileService.getProfile(context: modelContext)
            viewModel.onAppear(context: modelContext)
        }
        .onChange(of: selectedImage) {
            guard let selectedImage else {
                viewModel.imageData = nil
                return
            }
            Task {
                DispatchQueue.main.async {
                    viewModel.isLoading = true
                }
                guard let imageData = try? await selectedImage.loadTransferable(type: Data.self) else {
                    DispatchQueue.main.async {
                        viewModel.isLoading = false
                    }
                    return
                }
                self.viewModel.imageData = imageData
                DispatchQueue.main.async {
                    viewModel.isLoading = false
                }
            }
        }
    }
    
    private var profileImage: some View {
        PhotosPicker(selection: $selectedImage, matching: .images) {
            UIElements.profileImage(imageData: viewModel.imageData)
                .resizable()
                .scaledToFit()
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.circle)
        }
    }
    
    private var playerNameTitle: some View {
        Text(viewModel.playerName)
            .font(.title)
            .foregroundStyle(Colors.foregorundColor)
            .onTapGesture {
                withAnimation {
                    viewModel.nameTextFieldEnabled = true
                }
            }
    }
    
    private var profileInfoVertical: some View {
        VStack(alignment: .center) {
            profileImage
            playerNameTitle
            Spacer()
            
        }
    }
    
    private var profileInfoHorizontal: some View {
        HStack(alignment: .center) {
            profileImage
            playerNameTitle
            Spacer()
        }
    }
    
    private func mainStatistics(proxy: GeometryProxy) -> some View {
        let cellHeight = proxy.size.height / 4
        return VStack {
            HStack {
                Group {
                    Text("playingTime \(viewModel.playingTime)")
                    Text("gamesPlayed \(viewModel.gamesPlayed)")
                }
                .frame(maxWidth: .infinity, minHeight: cellHeight, maxHeight: cellHeight)
                .background(backgroundView())
                .clipShape(RoundedRectangle(cornerRadius: Consts.buttonCornerRadius))
            }
            HStack {
                Group {
                    Text("accountAge \(viewModel.accountAge)")
                    Text("lastActivity \(viewModel.lastActivity)")
                }
                .frame(maxWidth: .infinity, minHeight: cellHeight, maxHeight: cellHeight)
                .background(backgroundView())
                .clipShape(RoundedRectangle(cornerRadius: Consts.buttonCornerRadius))
            }
        }
    }
    
    private func backgroundView() -> some View {
        return Rectangle().fill(.ultraThinMaterial)
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                .previewDisplayName("iPhone")
            ProfileView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro 13-inch (M4)"))
                .previewDisplayName("iPad")
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
