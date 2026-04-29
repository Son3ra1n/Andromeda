//
//  BookMarkSlider.swift
//  Andromeda
//
//  Developed by son3ra1n.
//

import SwiftUI
import AlertKit
import CoreLocation

struct Bookmark: Identifiable {
    var id = UUID()
    var name: String
    var lat: Double
    var long: Double
}

struct BookMarkSlider: View {
    @Environment(\.dismiss) var dismiss
    @Binding var lat: Double
    @Binding var long: Double
    @State private var name = ""
    @State private var result: Bool = false
    @AppStorage("isMika") var isMika: Bool = false
    @State private var bookmarks: [Bookmark] = BookMarkRetrieve().compactMap { dict in
        guard let name = dict["name"] as? String,
              let lat = dict["lat"] as? Double,
              let long = dict["long"] as? Double else { return nil }
        return Bookmark(name: name, lat: lat, long: long)
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(bookmarks) { bookmark in
                    Button(action: {
                        close()
                        LocSimManager.startLocSim(location: CLLocation(coordinate: CLLocationCoordinate2D(latitude: bookmark.lat, longitude: bookmark.long), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, timestamp: Date()))
                        AlertKitAPI.present(
                            title: "Started !",
                            icon: .done,
                            style: .iOS17AppleMusic,
                            haptic: .success
                        )
                    }) {
                        VStack(alignment: .leading) {
                            Text("\(bookmark.name)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Latitude: \(bookmark.lat) Longitude: \(bookmark.long)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .onDelete(perform: deleteBookmark)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Bookmarks")
                        .font(.title2)
                        .bold()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if lat != 0.00 && long != 0.00 {
                            UIApplication.shared.TextFieldAlert(
                                title: "Enter bookmark name",
                                textFieldPlaceHolder: "Example..."
                            ) { enteredText, _ in
                                let bookmarkName = enteredText ?? "Unknown"
                                result = BookMarkSave(lat: lat, long: long, name: bookmarkName)
                                bookmarks = BookMarkRetrieve().compactMap { dict in
                                    guard let name = dict["name"] as? String,
                                          let lat = dict["lat"] as? Double,
                                          let long = dict["long"] as? Double else { return nil }
                                    return Bookmark(name: name, lat: lat, long: long)
                                }
                            }

                        } else {
                            UIApplication.shared.confirmAlert(title: "Your position is set to 0", body: "Are you sure you want to continue? This might be a mistake; try picking somewhere on the map", onOK: {
                                UIApplication.shared.TextFieldAlert(title: "Enter bookmark name", textFieldPlaceHolder: "Example...", completion: { enteredText, _ in
                                    result = BookMarkSave(lat: lat, long: long, name: enteredText ?? "Unknown")
                                    bookmarks = BookMarkRetrieve().compactMap { dict in
                                        guard let name = dict["name"] as? String,
                                              let lat = dict["lat"] as? Double,
                                              let long = dict["long"] as? Double else { return nil }
                                        return Bookmark(name: name, lat: lat, long: long)
                                    }
                                    AlertKitAPI.present(
                                        title: "Added !",
                                        icon: .done,
                                        style: .iOS17AppleMusic,
                                        haptic: .success
                                    )
                                })
                            }, noCancel: false)
                        }
                    }) {
                        Image(systemName: "plus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .overlay(
                    Group {
                        if bookmarks.isEmpty {
                            VStack {
                                Text("No bookmarks saved.")
                                    .foregroundColor(.secondary)
                                    .font(.title)
                                    .padding()
                                    .multilineTextAlignment(.center)
                                Text("To add a bookmark, select a custom location then tap the + button.")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    , alignment: .center
                )
            .onAppear {
                if isThereAnyMika(), !isMika {
                    UIApplication.shared.confirmAlert(title:"Mika's LocSim bookmarks/records detected.", body: "Do you want to import them ?", onOK: {
                        importMika()
                        bookmarks = BookMarkRetrieve().compactMap { dict in
                            guard let name = dict["name"] as? String,
                                  let lat = dict["lat"] as? Double,
                                  let long = dict["long"] as? Double else { return nil }
                            return Bookmark(name: name, lat: lat, long: long)
                        }
                        isMika.toggle()
                    }, noCancel: false, yes: true)
                }
            }
        }
    }

    private func deleteBookmark(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        updateBookmarks()
        AlertKitAPI.present(
            title: "Deleted !",
            icon: .done,
            style: .iOS17AppleMusic,
            haptic: .success
        )
    }
    let sharedUserDefaultsSuiteName = "group.live.cclerc.geraniumBookmarks"
    private func updateBookmarks() {
        let sharedUserDefaults = UserDefaults(suiteName: sharedUserDefaultsSuiteName)
        sharedUserDefaults?.set(bookmarks.map { ["name": $0.name, "lat": $0.lat, "long": $0.long] }, forKey: "bookmarks")
        sharedUserDefaults?.synchronize()
    }
    
    func close() {
        dismiss()
    }
}
