//
//  AndromedaApp.swift
//  Andromeda
//
//  Developed by son3ra1n.
//

import SwiftUI
@main
struct GeraniumApp: App {
    @StateObject private var appSettings = AppSettings()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if checkSandbox(), !appSettings.tsBypass, !appSettings.isFirstRun {
                        UIApplication.shared.alert(title:"Andromeda wasn't installed with TrollStore", body:"Unable to create test file. The app cannot work without the correct entitlements. Please use TrollStore to install it.", withButton:true)
                    }
                    _ = RootHelper.loadMCM()
                }
                .sheet(isPresented: $appSettings.isFirstRun) {
                    if #available(iOS 16.0, *) {
                        NavigationStack {
                            WelcomeView(loggingAllowed: $appSettings.loggingAllowed, updBypass: $appSettings.updBypass)
                        }
                    } else {
                        NavigationView {
                            WelcomeView(loggingAllowed: $appSettings.loggingAllowed, updBypass: $appSettings.updBypass)
                        }
                    }
                }
        }
    }
}

class AppSettings: ObservableObject {
    @AppStorage("TSBypass") var tsBypass: Bool = false
    @AppStorage("UPDBypass") var updBypass: Bool = false
    @AppStorage("isLoggingAllowed") var loggingAllowed: Bool = true
    @AppStorage("isFirstRun") var isFirstRun: Bool = true
    @AppStorage("minimSizeC") var minimSizeC: Double = 50.0
    @AppStorage("keepCheckBoxesC") var keepCheckBoxesC: Bool = true
    @AppStorage("LocSimAttempts") var locSimAttemptNB: Int = 1
    @AppStorage("locSimMultipleAttempts") var locSimMultipleAttempts: Bool = false
    @AppStorage("usrUUID") var usrUUID: String = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    @AppStorage("languageCode") var languageCode: String = ""
    @AppStorage("defaultTab") var defaultTab: Int = 1
    @AppStorage("firstCleanerTime") var firstCleanerTime: Bool = true
    @AppStorage("tmpClean") var tmpClean: Bool = true
    @AppStorage("getSizes") var getSizes: Bool = false
}

var langaugee: String = {
    if AppSettings().languageCode.isEmpty {
        return "\(Locale.current.languageCode ?? "en-US")"
    }
    else {
        return "\(Locale.current.languageCode ?? "en")-\(AppSettings().languageCode)"
    }
}()
