//
//  ContentView.swift
//  Andromeda
//
//  Developed by son3ra1n.
//

import SwiftUI

struct ContentView: View {
    @State var defaultTab = AppSettings().defaultTab
    var body: some View {
        TabView(selection: $defaultTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(1)
            DaemonView()
                .tabItem {
                    Label("Daemons", systemImage: "flag.fill")
                }
                .tag(2)
                .onAppear {
                    RootHelper.removeItem(at: URL(fileURLWithPath: "/var/mobile/Documents/disabled.plist"))
                }
            LocSimView()
                .tabItem {
                    Label("LocSim", systemImage: "mappin")
                }
                .tag(3)
            CleanerView()
                .tabItem {
                    Label("Cleaner", systemImage: "trash.fill")
                }
                .tag(4)
            SuperviseView()
                .tabItem {
                    Label("Supervise", systemImage: "checkmark.seal.fill")
                }
                .tag(5)
        }
        .tint(.indigo)
    }
}
