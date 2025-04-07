//
//  SettingsView.swift
//  iES
//
//  Created by Никита Пивоваров on 11.10.2024.
//

import SwiftUI
import GoogleDriveClient

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var csManager: ColorSchemeManager
    
    var body: some View {
        ZStack {
            UIElements.background()
            List {
                Group {
                    appSettings
                    videoSettings
                    audioSettings
                    cloudSettings
                }
                .listRowBackground(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                )
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Localization.settings)
    }
    
    private var colorSchemePicker: some View {
        Group {
            Picker(Localization.colorScheme, selection: $csManager.colorScheme) {
                Section {
                    Text(Localization.system).tag(AppService.UIColorScheme.device)
                    Text(Localization.light).tag(AppService.UIColorScheme.light)
                    Text(Localization.dark).tag(AppService.UIColorScheme.dark)
                } header: {
                    Text(Localization.defaultLoc)
                }
            }
        }
    }
    
    private var appSettings: some View {
        Section(Localization.appSettings) {
            colorSchemePicker
        }
    }
    
    private var videoSettings: some View {
        Section(Localization.videoSettings) {
            Toggle(Localization.enableFX, isOn: $viewModel.metalFxEnabled)
            if !viewModel.metalFxEnabled {
                Toggle(Localization.enableSharperEdges, isOn: $viewModel.nearestNeighborRendering)
                Toggle(Localization.integerScaling, isOn: $viewModel.integerScaling)
                VStack {
                    Text(Localization.scanlines)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("", selection: $viewModel.scanlines) {
                        Text(Localization.off).tag(Int(Scanlines.off.rawValue))
                        Text(Localization.low).tag(Int(Scanlines.low.rawValue))
                        Text(Localization.med).tag(Int(Scanlines.med.rawValue))
                        Text(Localization.hi).tag(Int(Scanlines.hi.rawValue))
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var audioSettings: some View {
        Section(Localization.audioSettings) {
            Toggle(Localization.enableAudio, isOn: $viewModel.enableAudio)
            Toggle(Localization.highPassFiltering, isOn: $viewModel.audioFilter)
            VStack {
                Text(Localization.sampleRate)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("", selection: $viewModel.sampleRate) {
                    Text("12").tag(SampleRate._12000Hz.rawValue)
                    Text("16").tag(SampleRate._16000Hz.rawValue)
                    Text("22").tag(SampleRate._22050Hz.rawValue)
                    Text("44").tag(SampleRate._44100Hz.rawValue)
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var cloudSettings: some View {
        Section("cloudSettings") {
            Toggle("yandexDisk", isOn: $viewModel.yandexDisk)
            Toggle("googleDrive", isOn: $viewModel.googleDrive)
        }
        .onChange(of: viewModel.yandexDisk) { oldValue, newValue in
            if !oldValue, newValue {
                viewModel.showYandexDiskAuth = true
            } else if !newValue, oldValue {
                do {
                    try KeychainManager.instance.saveToken("", forKey: Settings.Keys.yandexToken)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: viewModel.googleDrive) { oldValue, newValue in
            if !oldValue, newValue {
                Task {
                    await GoogleDriveService.signIn()
                }
            } else if !newValue, oldValue {
                Task {
                    await GoogleDriveService.signOut()
                }
            }
        }
        .onOpenURL { url in
            Task {
                await GoogleDriveService.handleRedirect(url: url)
            }
        }
        .sheet(isPresented: $viewModel.showYandexDiskAuth) {
            YandexAuthView()
                .onDisappear {
                    guard let token = KeychainManager.instance.getToken(forKey: Settings.Keys.yandexToken), !token.isEmpty else {
                        viewModel.yandexDisk = false
                        return
                    }
                }
        }
    }
}
