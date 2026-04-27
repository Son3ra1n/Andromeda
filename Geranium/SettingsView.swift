//
//  SettingsView.swift
//  Andromeda
//
//  Developed by son3ra1n.
//

import SwiftUI
import AlertKit

struct SettingsView: View {
    @State var defaultTab = AppSettings().defaultTab
    @State var DebugStuff: Bool = false
    @State var MinimCal: String = ""
    @State var LocSimTries: String = ""
    @State var localisation: String = {
        if langaugee != "" {
            return langaugee
        }
        else if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let firstLanguage = languages.first {
                return "\(Locale.current.languageCode ?? "en-GB")"
        } else {
            return "en-GB"
        }
    }()
    @StateObject private var appSettings = AppSettings()
    
    // Custom language
    @State var appCodeLanguage = langaugee
    let languageMapping: [String: String] = [
                "zh-Hans": "Chinese (Simplified)",
                "zh-Hant": "Chinese (Traditional)",
                "Base": "English",
                "en-GB": "English (GB)",
                "es": "Spanish",
                "es-419": "Spanish (Latin America)",
                "fr": "French",
                "it": "Italian",
                "ja": "Japanese",
                "ko": "Korean",
                "ru": "Russian",
                "sk": "Slovak",
                "sv": "Swedish",
                "tr": "Turkish",
                "vi": "Vietnamese",
    ]
    var sortedLocalisalist: [String] {
        languageMapping.keys.sorted()
    }
    
    // Open Tab
    let defaultTabList: [Int: String] = [
                1: "Home",
                2: "Daemons",
                3: "LocSim",
                4: "Cleaner",
                5: "Superviser",
    ]
    
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - ByeTime Settings
                Section(header: Label("ByeTime", systemImage: "hourglass"), footer: Text("ByeTime allows you to completely disable Screen Time, iCloud or not.")) {
                    NavigationLink(destination: ByeTimeView(DebugStuff: $DebugStuff)) {
                        HStack {
                            Text("ByeTime Settings")
                        }
                    }
                }
                
                // MARK: - Language
                Section(header: Label("App Language", systemImage: "magnifyingglass"), footer: Text("Choose your preferred language. The app will exit to apply changes.")) {
                    Picker("Language", selection: $localisation) {
                        ForEach(sortedLocalisalist, id: \.self) { abbreviation in
                            Text(languageMapping[abbreviation] ?? abbreviation)
                                .tag(abbreviation)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: localisation) { newValue in
                        if localisation.contains("en-GB") || localisation.contains("zh") || localisation.contains("es-419"){
                            let parts = localisation.components(separatedBy: "-")
                            if let appCodeLanguage = parts.last {
                                appSettings.languageCode = appCodeLanguage
                                UserDefaults.standard.set(["\(localisation)"], forKey: "AppleLanguages")
                            }
                        }
                        else {
                            appSettings.languageCode = ""
                            UserDefaults.standard.set(["\(newValue)"], forKey: "AppleLanguages")
                        }
                        UIApplication.shared.confirmAlert(title: "Restart Required", body: "The app needs to restart to apply language changes.", onOK: {
                            exitGracefully()
                        }, noCancel: true)
                    }
                    .onAppear {
                        appSettings.languageCode = ""
                    }
                }
                
                // MARK: - Debug
                Section(header: Label("Debug", systemImage: "chevron.left.forwardslash.chevron.right"), footer: Text("Show experimental debug values.")) {
                    Toggle(isOn: $DebugStuff) {
                        Text("Debug Info")
                    }
                    if DebugStuff {
                        Text("Language: \(localisation)")
                        Button("Reset Language") {
                            UserDefaults.standard.set(["Base"], forKey: "AppleLanguages")
                            UIApplication.shared.confirmAlert(title: "Restart Required", body: "The app needs to restart.", onOK: {
                                exitGracefully()
                            }, noCancel: true)
                        }
                        Text("UUID: \(appSettings.usrUUID)")
                        Text("RootHelper: \(RootHelper.whatsthePath())")
                    }
                }
                
                // MARK: - Cleaner Settings
                Section(header: Label("Cleaner", systemImage: "trash"), footer: Text("Configure cleaning options.")) {
                    Toggle(isOn: $appSettings.keepCheckBoxesC) {
                        Text("Keep selection after cleaning")
                    }
                    Toggle(isOn: $appSettings.getSizes) {
                        Text("Calculate Cleaning Size")
                    }
                    .onChange(of: appSettings.getSizes) { newValue in
                        UIApplication.shared.confirmAlert(title: "Restart Required", body: "The app needs to restart.", onOK: {
                            exitGracefully()
                        }, noCancel: true)
                    }
                    Toggle(isOn: Binding<Bool>(
                        get: { !appSettings.tmpClean },
                        set: { appSettings.tmpClean = !$0 }
                    )) {
                        Text("Safe Clean (Enable for iOS 15)")
                    }
                    .onChange(of: appSettings.tmpClean) { newValue in
                        UIApplication.shared.confirmAlert(title: "Restart Required", body: "The app needs to restart.", onOK: {
                            exitGracefully()
                        }, noCancel: true)
                    }
                    
                    if DebugStuff {
                        HStack {
                            Text("Minimum Size:")
                            Spacer()
                            TextField("50.0 MB", text: $MinimCal)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: MinimCal) { newValue in
                                    MinimCal = newValue.replacingOccurrences(of: ",", with: ".")
                                }
                        }
                        .onAppear {
                            MinimCal = "\(appSettings.minimSizeC)"
                        }
                        .onChange(of: MinimCal) { newValue in
                            appSettings.minimSizeC = Double(MinimCal) ?? 50.0
                        }
                    }
                }
                
                // MARK: - LocSim Settings
                Section(header: Label("LocSim", systemImage: "location.fill.viewfinder"), footer: Text("Configure location simulation settings.")) {
                    Toggle(isOn: $appSettings.locSimMultipleAttempts) {
                        Text("Try stopping LocSim multiple times")
                    }
                    if appSettings.locSimMultipleAttempts {
                        HStack {
                            Text("Attempts:")
                            Spacer()
                            TextField("3", text: $LocSimTries)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        .onAppear {
                            LocSimTries = "\(appSettings.locSimAttemptNB)"
                        }
                        .onChange(of: LocSimTries) { newValue in
                            appSettings.locSimAttemptNB = Int(LocSimTries) ?? 1
                        }
                    }
                }
                
                // MARK: - Startup
                Section(header: Label("Startup", systemImage: "play"), footer: Text("Customize startup behavior.")) {
                    Picker("Default Tab", selection: $defaultTab) {
                        ForEach(Array(defaultTabList.keys).sorted(), id: \.self) { key in
                            Text(defaultTabList[key] ?? "")
                                .tag(key)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: defaultTab) { newValue in
                        appSettings.defaultTab = defaultTab
                        UIApplication.shared.confirmAlert(title: "Restart Required", body: "The app needs to restart.", onOK: {
                            exitGracefully()
                        }, noCancel: true)
                    }
                    Toggle(isOn: $appSettings.tsBypass) {
                        Text("Bypass TrollStore Pop Up")
                    }
                    .onChange(of: appSettings.tsBypass) { newValue in
                        AlertKitAPI.present(title: "Saved!", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                    }
                }
                
                // MARK: - About
                Section(header: Label("About", systemImage: "info.circle")) {
                    HStack {
                        Text("App")
                        Spacer()
                        Text("Andromeda v2.5.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("son3ra1n")
                            .foregroundColor(.indigo)
                    }
                    Button(action: {
                        UIApplication.shared.open(URL(string: "https://github.com/son3ra1n/Andromeda")!)
                    }) {
                        HStack {
                            Text("Source Code")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.indigo)
                        }
                    }
                }
                
                // MARK: - Acknowledgments
                Section(header: Label("Acknowledgments", systemImage: "heart.fill"), footer: Text("Andromeda is inspired by and built upon the Geranium project by c22dev. Licensed under GPL-3.0.")) {
                    Button(action: {
                        UIApplication.shared.open(URL(string: "https://github.com/c22dev/Geranium")!)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Geranium by c22dev")
                                    .foregroundColor(.primary)
                                Text("Original project & core architecture")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    Button(action: {
                        UIApplication.shared.open(URL(string: "https://github.com/BomberFish/Geranium")!)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("BomberFish")
                                    .foregroundColor(.primary)
                                Text("Daemon listing contributions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
