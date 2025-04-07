//
//  LibraryItemDetailView.swift
//  iES
//
//  Created by Никита Пивоваров on 30.08.2024.
//

import SwiftUI

struct LibraryItemDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var showDeleteAlert = false
    let model: GameModel?
    let profile: ProfileModel?
    @Binding var playButtonWasPressed: Bool
    @State private var isViewFlipped = false
    @State private var isSettingsPresented = false
    @State private var showDeleteSaveDataAlert = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            UIElements.background()
            HStack {
                Spacer()
                contentView
                Spacer()
                divier
                rightMenuBar
            }
            .allowsTightening(!isLoading)
            .padding()
            if isLoading {
                Thinking()
            }
        }
        .alert(Localization.deleteGameAlert, isPresented: $showDeleteAlert) {
            Button(Localization.delete, role: .destructive) {
                isLoading = true
                if let model = model {
                    SwiftDataManager.delete(model, context: modelContext) { _ in
                        isLoading = false
                    }
                }
                dismiss()
            }
            Button(Localization.cancel, role: .cancel) {}
        }
        .alert(Localization.deleteGameSaveAlert, isPresented: $showDeleteSaveDataAlert) {
            Button(Localization.delete, role: .destructive) {
                isLoading = true
                model?.state = nil
                SwiftDataManager.performOnUpdate(context: modelContext) { _ in
                    isLoading = false
                }
            }
            Button(Localization.cancel, role: .cancel) {}
        }
    }
    
    private var contentView: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.compact.backward")
                }
                .font(.title)
                .foregroundStyle(Colors.primaryColor)
                .frame(minWidth: 44, minHeight: 44)
                Spacer()
                Text(model?.title ?? "<Unknown>")
                    .lineLimit(1)
                    .font(.title)
                Spacer()
            }
            Spacer()
            FlipView(
                frontView: FrontView(model: model, flipAction: { isViewFlipped.toggle() }),
                backView: BackView(isSettingsPresented: $isSettingsPresented, showDeleteAlert: $showDeleteAlert, showDeleteSaveDataAlert: $showDeleteSaveDataAlert, model: model, profile: profile, flipAction: { isViewFlipped.toggle() }),
                showBack: $isViewFlipped
            )
            .padding(.horizontal)
            Spacer()
        }
    }
    
    private var divier: some View {
        Rectangle()
            .fill(Colors.primaryColor)
            .frame(maxWidth: 1, maxHeight: .infinity)
    }
    
    private var rightMenuBar: some View {
        VStack {
            Group {
                Button {
                    withAnimation {
                        if isSettingsPresented, isViewFlipped {
                            isViewFlipped = false
                        } else {
                            isSettingsPresented = true
                            isViewFlipped = true
                        }
                    }
                } label: {
                    Image(systemName: "gear")
                }
                .frame(minWidth: 44, minHeight: 44)
                Spacer()
                Button {
                    withAnimation {
                        if !isSettingsPresented, isViewFlipped {
                            isViewFlipped = false
                        } else {
                            isSettingsPresented = false
                            isViewFlipped = true
                        }
                    }
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            .foregroundStyle(Colors.primaryColor)
            Spacer()
            playButton
                .frame(minWidth: 44, minHeight: 44)
        }
        .font(.title)
        .padding(.vertical)
    }
    
    private var playButton: some View {
        Button {
            playButtonWasPressed = true
            dismiss()
        } label: {
            Image(systemName: "play.fill")
        }
        .buttonStyle(.borderedProminent)
    }
}


fileprivate struct FrontView: View {
    
    let model: GameModel?
    let flipAction: () -> Void
    
    var body: some View {
        UIElements.gameImage(imageData: model?.imageData)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture {
                  withAnimation {
                        flipAction()
                  }
            }
    }
}

fileprivate struct BackView: View {
    @Binding var isSettingsPresented: Bool
    @Binding var showDeleteAlert: Bool
    @Binding var showDeleteSaveDataAlert: Bool
    @State var isAutoSaveEnabled: Bool = false
    @State private var isLoading: Bool = false
    @Environment(\.modelContext) var modelContext
    let model: GameModel?
    let profile: ProfileModel?
    let flipAction: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .onTapGesture {
                      withAnimation {
                            flipAction()
                      }
                }
                .allowsHitTesting(!isLoading)
            if isSettingsPresented {
                VStack {
                    Text(Localization.settings)
                        .font(.title3)
                        .padding(.vertical)
                    List {
                        Group {
                            Section {
                                Toggle(Localization.autoSaveEnabled, isOn: $isAutoSaveEnabled)
                            }
                            Section {
                                Button(Localization.deleteSaveData, role: .destructive) {
                                    showDeleteSaveDataAlert = true
                                }
                                Button(Localization.deleteGame, role: .destructive) {
                                    showDeleteAlert = true
                                }
                            }
                        }
                        .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                    }
                    .scrollContentBackground(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listStyle(.insetGrouped)
                }
                .padding(.horizontal)
                .onAppear {
                    isAutoSaveEnabled = model?.isAutoSaveEnabled ?? false
                }
                .onChange(of: isAutoSaveEnabled) { oldValue, newValue in
                    isLoading = true
                    model?.isAutoSaveEnabled = newValue
                    SwiftDataManager.performOnUpdate(context: modelContext) { _ in
                        isLoading = false
                    }
                }
                .allowsHitTesting(!isLoading)
            } else {
                VStack {
                    Text(Localization.stats)
                        .font(.title3)
                        .padding(.vertical)
                    List {
                        if let profile, let model {
                            Group {
                                HStack {
                                    Text("playingTime")
                                    Spacer()
                                    Text(Duration.seconds(profile.timePlayed[model.title] ?? 0).formatted(.time(pattern: .hourMinute)))
                                }
                                HStack {
                                    Text("lastTimePlayed")
                                    Spacer()
                                    Text(model.lastTimePlayed.formatted())
                                }
                            }
                            .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listStyle(.insetGrouped)
                }
                .allowsHitTesting(!isLoading)
            }
            if isLoading {
                Thinking()
            }
        }
    }
}
