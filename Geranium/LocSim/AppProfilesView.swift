//
//  AppProfilesView.swift
//  Andromeda
//
//  Developed by son3ra1n.
//

import SwiftUI
import CoreLocation
import AlertKit

struct AppProfile: Codable, Identifiable {
    var id = UUID()
    var appName: String
    var emoji: String
    var latitude: Double
    var longitude: Double
    var locationName: String
    var isActive: Bool = false
}

class AppProfileManager: ObservableObject {
    @Published var profiles: [AppProfile] = []
    
    private let key = "andromeda_app_profiles"
    
    init() {
        load()
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([AppProfile].self, from: data) else {
            return
        }
        profiles = decoded
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    func add(_ profile: AppProfile) {
        profiles.append(profile)
        save()
    }
    
    func delete(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        save()
    }
    
    func setActive(_ profile: AppProfile) {
        for i in profiles.indices {
            profiles[i].isActive = (profiles[i].id == profile.id)
        }
        save()
    }
    
    func clearActive() {
        for i in profiles.indices {
            profiles[i].isActive = false
        }
        save()
    }
}

struct AppProfilesView: View {
    @Binding var isPresented: Bool
    var currentLat: Double
    var currentLong: Double
    var onActivate: (Double, Double, String) -> Void
    
    @StateObject private var manager = AppProfileManager()
    @State private var showAddSheet = false
    @State private var newAppName = ""
    @State private var newEmoji = "📱"
    @State private var newLocationName = ""
    @State private var useCurrentLocation = true
    @State private var customLat = ""
    @State private var customLong = ""
    
    let emojiOptions = ["📱", "💬", "📸", "🎮", "❤️", "🗺️", "🚗", "🎵", "🛒", "💼", "🏦", "📧", "🎥", "🐦", "👻"]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color.indigo.opacity(0.08), Color.black.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                if manager.profiles.isEmpty {
                    emptyState
                } else {
                    profileList
                }
            }
            .navigationTitle("App Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                addProfileSheet
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "apps.iphone")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No App Profiles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Create profiles to quickly switch\nlocations for different apps")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Profile List
    private var profileList: some View {
        List {
            // Active Profile Banner
            if let active = manager.profiles.first(where: { $0.isActive }) {
                Section {
                    HStack(spacing: 12) {
                        Text(active.emoji)
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(active.appName)
                                .font(.system(size: 15, weight: .bold))
                            Text(active.locationName)
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("ACTIVE")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // All Profiles
            Section(header: Text("All Profiles")) {
                ForEach(manager.profiles) { profile in
                    profileRow(profile)
                }
                .onDelete { offsets in
                    manager.delete(at: offsets)
                }
            }
            
            // Stop Button
            Section {
                Button(action: {
                    manager.clearActive()
                    LocSimManager.stopLocSim()
                    AlertKitAPI.present(title: "All Stopped", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                }) {
                    HStack {
                        Image(systemName: "location.slash.fill")
                        Text("Stop All Simulations")
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Profile Row
    private func profileRow(_ profile: AppProfile) -> some View {
        Button(action: {
            activateProfile(profile)
        }) {
            HStack(spacing: 14) {
                // App Emoji
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(profile.isActive ? Color.green.opacity(0.15) : Color.indigo.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Text(profile.emoji)
                        .font(.system(size: 24))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.appName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(profile.locationName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if profile.isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.indigo)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Add Profile Sheet
    private var addProfileSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("App")) {
                    TextField("App name (e.g. Tinder, Instagram...)", text: $newAppName)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button(action: { newEmoji = emoji }) {
                                    Text(emoji)
                                        .font(.system(size: 28))
                                        .padding(6)
                                        .background(
                                            newEmoji == emoji
                                                ? Color.indigo.opacity(0.2)
                                                : Color.clear
                                        )
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(newEmoji == emoji ? Color.indigo : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Location")) {
                    TextField("Location name (e.g. Paris, Tokyo...)", text: $newLocationName)
                    
                    Toggle("Use Current Simulated Location", isOn: $useCurrentLocation)
                    
                    if useCurrentLocation {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.indigo)
                            Text("\(String(format: "%.4f", currentLat)), \(String(format: "%.4f", currentLong))")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        TextField("Latitude", text: $customLat)
                            .keyboardType(.decimalPad)
                        TextField("Longitude", text: $customLong)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section {
                    Button(action: saveProfile) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Profile")
                        }
                        .foregroundColor(.indigo)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(newAppName.isEmpty || newLocationName.isEmpty)
                }
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showAddSheet = false }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func saveProfile() {
        let lat: Double
        let long: Double
        
        if useCurrentLocation {
            lat = currentLat
            long = currentLong
        } else {
            guard let parsedLat = Double(customLat), let parsedLong = Double(customLong) else { return }
            lat = parsedLat
            long = parsedLong
        }
        
        let profile = AppProfile(
            appName: newAppName,
            emoji: newEmoji,
            latitude: lat,
            longitude: long,
            locationName: newLocationName
        )
        
        manager.add(profile)
        newAppName = ""
        newLocationName = ""
        customLat = ""
        customLong = ""
        showAddSheet = false
        AlertKitAPI.present(title: "Profile Created!", icon: .done, style: .iOS17AppleMusic, haptic: .success)
    }
    
    private func activateProfile(_ profile: AppProfile) {
        manager.setActive(profile)
        onActivate(profile.latitude, profile.longitude, "\(profile.emoji) \(profile.appName)")
    }
}
