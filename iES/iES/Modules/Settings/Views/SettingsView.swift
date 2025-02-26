//
//  SettingsView.swift
//  iES
//
//  Created by Никита Пивоваров on 11.10.2024.
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @Namespace private var colorPickersNamespace
    
    var body: some View {
        NavigationStack {
            ZStack {
                UIElements.background()
                List {
                    appSettings
                    videoSettings
                    audioSettings
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
        }
    }
    
    private var colorSchemePicker: some View {
        Group {
            Picker("Color Scheme", selection: $viewModel.selectedColorScheme) {
                Section {
                    Text("System").tag(SettingsConstants.AppSettings.Theme.system)
                    Text("Dark").tag(SettingsConstants.AppSettings.Theme.dark)
                    Text("Light").tag(SettingsConstants.AppSettings.Theme.light)
                } header: {
                    Text("Default")
                }
                Section {
                    Text("Custom").tag(SettingsConstants.AppSettings.Theme.custom(viewModel.customBackgroundColor, viewModel.customAccentColor))
                } header: {
                    Text("Select colors below")
                }
            }
            if viewModel.isColorPickersShown {
                Group {
                    ColorPicker("Accent Color", selection: $viewModel.customAccentColor)
                    ColorPicker("Background Color", selection: $viewModel.customBackgroundColor)
                }
            }
        }
    }
    
    private var languagePicker: some View {
        Picker("Language", selection: $viewModel.selectedLanguage) {
            Text("English").tag(SettingsConstants.AppSettings.Language.en)
            Text("Russian").tag(SettingsConstants.AppSettings.Language.ru)
        }
    }
    
    private var appSettings: some View {
        Section("App Settings") {
            colorSchemePicker
            languagePicker
        }
    }
    
    private var videoSettings: some View {
        Section("Video settings") {
            Toggle("Enable MetalFX", isOn: $viewModel.metalFxEnabled)
            if !viewModel.metalFxEnabled {
                Toggle("Enable sharper edges", isOn: $viewModel.nearestNeighborRendering)
                Toggle("Integer scaling", isOn: $viewModel.integerScaling)
                VStack {
                    Text("Scanlines")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("", selection: $viewModel.scanlines) {
                        Text("off").tag(Int(Scanlines.off.rawValue))
                        Text("low").tag(Int(Scanlines.low.rawValue))
                        Text("med").tag(Int(Scanlines.med.rawValue))
                        Text("hi").tag(Int(Scanlines.hi.rawValue))
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var audioSettings: some View {
        Section("Audio settings") {
            Toggle("Enable Audio", isOn: $viewModel.enableAudio)
            Toggle("High pass filtering", isOn: $viewModel.audioFilter)
            VStack {
                Text("Sample rate (kHz)")
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
}
