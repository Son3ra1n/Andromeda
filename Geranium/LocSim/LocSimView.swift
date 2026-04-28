//  Andromeda LocSim
//  Created by son3ra1n.
//  Enhanced version of Geranium.
//  Developed by son3ra1n.
//

import SwiftUI
import CoreLocation
import MapKit
import AlertKit

struct LocSimView: View {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var routeSimulator = RouteSimulator()
    
    @State private var locationManager = CLLocationManager()
    @State private var lat: Double = 0.0
    @State private var long: Double = 0.0
    @State private var altitude: String = "0.0"
    @State private var tappedCoordinate: EquatableCoordinate? = nil
    @State private var bookmarkSheetTggle: Bool = false
    @State private var showRouteSheet: Bool = false
    @State private var showSearchBar: Bool = false
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching: Bool = false
    @State private var mapRegion: MKCoordinateRegion? = nil
    var body: some View {
        LocSimMainView()
    }
    @ViewBuilder
        private func LocSimMainView() -> some View {
            ZStack(alignment: .topTrailing) {
                // MARK: - Main Map
                CustomMapView(tappedCoordinate: $tappedCoordinate, moveToRegion: $mapRegion, routePolyline: routeSimulator.routePolyline, allRoutePolylines: routeSimulator.allRoutePolylines, selectedRouteIndex: routeSimulator.selectedRouteIndex, movingPosition: routeSimulator.currentPosition)
                    .onAppear {
                        CLLocationManager().requestAlwaysAuthorization()
                    }
                    .onChange(of: tappedCoordinate) { newCoord in
                        guard let coord = newCoord else { return }
                        let altitudeValue = Double(altitude) ?? 0.0
                        startSimulation(at: coord.coordinate, altitude: altitudeValue)
                    }
                    .ignoresSafeArea(.all, edges: [.top, .leading, .trailing])
                
                // MARK: - Address Search Overlay (Top)
                if showSearchBar {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search address...", text: $searchText, onCommit: {
                                searchAddress()
                            })
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            
                            if isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {
                                withAnimation {
                                    showSearchBar = false
                                    searchText = ""
                                    searchResults = []
                                }
                            }) {
                                Text("Cancel")
                                    .font(.subheadline)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        
                        // Search Results List
                        if !searchResults.isEmpty {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(searchResults, id: \.self) { item in
                                        Button(action: {
                                            selectSearchResult(item)
                                        }) {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.title3)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(item.name ?? "Unknown")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.primary)
                                                    if let address = item.placemark.title {
                                                        Text(address)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                Spacer()
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                        }
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }
                            .frame(maxHeight: 250)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                            )
                            .padding(.horizontal, 12)
                            .padding(.top, 4)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }

            
            // MARK: - Floating Controls (Replaces unstable Toolbar)
            VStack(spacing: 12) {
                // Address Search Button
                Button(action: {
                    showSearchBar.toggle()
                }) {
                    controlIcon(systemName: "magnifyingglass")
                }
                
                // Route Simulation Button
                Button(action: {
                    showRouteSheet.toggle()
                }) {
                    controlIcon(systemName: "car.fill")
                }
                
                // Altitude Button
                Button(action: {
                    UIApplication.shared.TextFieldAlert(
                        title: "Set Altitude",
                        message: "Enter the altitude in meters.",
                        textFieldPlaceHolder: "Altitude (m)"
                    ) { altitudeText, _ in
                        if let altText = altitudeText, !altText.isEmpty {
                            self.altitude = altText
                            AlertKitAPI.present(
                                title: "Altitude Set!",
                                icon: .done,
                                style: .iOS17AppleMusic,
                                haptic: .success
                            )
                        }
                    }
                }) {
                    controlIcon(systemName: "mountain.2.fill")
                }
                
                // Stop Sim Button
                Button(action: {
                    LocSimManager.stopLocSim()
                    AlertKitAPI.present(
                        title: "Stopped !",
                        icon: .done,
                        style: .iOS17AppleMusic,
                        haptic: .success
                    )
                }) {
                    controlIcon(systemName: "location.slash.fill", color: .red)
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 60)
        }
        .sheet(isPresented: $bookmarkSheetTggle) {
            BookMarkSlider(lat: $lat, long: $long)
        }
        .sheet(isPresented: $showRouteSheet) {
            RouteSimSheet(routeSimulator: routeSimulator, mapRegion: $mapRegion, isPresented: $showRouteSheet)
        }
    }
    
    private func startSimulation(at gcjCoordinate: CLLocationCoordinate2D, altitude: Double) {
        let wgsCoordinate = CoordTransform.gcj02ToWgs84(gcjCoordinate)
        
        self.lat = wgsCoordinate.latitude
        self.long = wgsCoordinate.longitude
        
        let location = CLLocation(coordinate: wgsCoordinate, altitude: altitude,horizontalAccuracy:5,verticalAccuracy: 5,timestamp: Date())
        LocSimManager.startLocSim(location: location)
        
        AlertKitAPI.present(
            title: "Started!",
            icon: .done,
            style: .iOS17AppleMusic,
            haptic: .success
        )
    }
    
    // MARK: - Address Search
    private func searchAddress() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        searchResults = []
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let response = response {
                    searchResults = response.mapItems
                } else {
                    UIApplication.shared.alert(body: "No results found for '\(searchText)'")
                }
            }
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        let altitudeValue = Double(altitude) ?? 0.0
        
        // Move the map to the selected location
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapRegion = region
        
        // Start simulation at the selected location
        startSimulation(at: coordinate, altitude: altitudeValue)
        
        // Close search UI
        showSearchBar = false
        searchText = ""
        searchResults = []
    }
    
    // MARK: - Modern UI Helpers
    private func controlIcon(systemName: String, color: Color = .indigo) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(color.opacity(0.9))
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    LocSimView()
}
