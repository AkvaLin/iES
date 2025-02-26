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
    @Binding var playButtonWasPressed: Bool
    @State private var isViewFlipped = false
    @State private var isSettingsPresented = false
    @State private var showDeleteSaveDataAlert = false
    
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
            .padding()
        }
        .alert(Localization.deleteGameAlert, isPresented: $showDeleteAlert) {
            Button(Localization.delete, role: .destructive) {
                if let model = model {
                    modelContext.delete(model)
                }
                dismiss()
            }
            Button(Localization.cancel, role: .cancel) {}
        }
        .alert(Localization.deleteGameSaveAlert, isPresented: $showDeleteSaveDataAlert) {
            Button(Localization.delete, role: .destructive) {
                model?.state = nil
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
                backView: BackView(isSettingsPresented: $isSettingsPresented, showDeleteAlert: $showDeleteAlert, showDeleteSaveDataAlert: $showDeleteSaveDataAlert, model: model, flipAction: { isViewFlipped.toggle() }),
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
    let model: GameModel?
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
            if isSettingsPresented {
                VStack {
                    Text(Localization.settings)
                        .font(.title3)
                        .padding(.vertical)
                    List {
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
                    .scrollBounceBehavior(.basedOnSize)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listStyle(.insetGrouped)
                }
                .padding(.horizontal)
                .onAppear {
                    isAutoSaveEnabled = model?.isAutoSaveEnabled ?? false
                }
                .onChange(of: isAutoSaveEnabled) { oldValue, newValue in
                    model?.isAutoSaveEnabled = newValue
                }
            } else {
                Text(Localization.stats)
            }
        }
    }
}
