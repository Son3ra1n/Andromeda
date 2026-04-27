//
//  RouteSimulator.swift
//  Andromeda
//
//  Route simulation - moves location along a real route with background support
//

import Foundation
import CoreLocation
import MapKit
import UIKit

enum TravelMode: String, CaseIterable {
    case walking = "Walking"
    case cycling = "Cycling"
    case driving = "Driving"
    
    var speed: Double { // meters per second
        switch self {
        case .walking: return 1.4   // ~5 km/h
        case .cycling: return 5.5   // ~20 km/h
        case .driving: return 13.9  // ~50 km/h
        }
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .driving: return "car.fill"
        }
    }
    
    var transportType: MKDirectionsTransportType {
        switch self {
        case .walking: return .walking
        case .cycling: return .walking
        case .driving: return .automobile
        }
    }
}

class RouteOption: Identifiable, ObservableObject {
    let id = UUID()
    let route: MKRoute
    let index: Int
    
    var name: String {
        if index == 0 { return "Fastest Route" }
        return "Alternative \(index)"
    }
    
    var distanceText: String {
        if route.distance >= 1000 {
            return String(format: "%.1f km", route.distance / 1000)
        }
        return String(format: "%.0f m", route.distance)
    }
    
    var etaText: String {
        let minutes = Int(route.expectedTravelTime / 60)
        if minutes > 60 {
            let hours = minutes / 60
            let rem = minutes % 60
            return "\(hours)h \(rem)m"
        }
        return "\(minutes) min"
    }
    
    init(route: MKRoute, index: Int) {
        self.route = route
        self.index = index
    }
}

class RouteSimulator: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isSimulating: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentPointIndex: Int = 0
    @Published var totalPoints: Int = 0
    @Published var routePolyline: MKPolyline? = nil
    @Published var currentPosition: CLLocationCoordinate2D? = nil
    @Published var progress: Double = 0.0
    @Published var isCalculatingRoute: Bool = false
    @Published var estimatedTime: String = ""
    @Published var travelMode: TravelMode = .driving
    
    @Published var availableRoutes: [RouteOption] = []
    @Published var allRoutePolylines: [MKPolyline] = []
    @Published var selectedRouteIndex: Int = 0
    
    private var routePoints: [CLLocationCoordinate2D] = []
    private var timer: Timer? = nil
    private var altitude: Double = 0.0
    private var speedMultiplier: Double = 1.0
    private let updateInterval: TimeInterval = 1.0
    
    // Background handling
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    func calculateRoutes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, mode: TravelMode, speedMult: Double, completion: @escaping (Bool, String?) -> Void) {
        isCalculatingRoute = true
        travelMode = mode
        speedMultiplier = speedMult
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = mode.transportType
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isCalculatingRoute = false
                if let error = error {
                    completion(false, "Route error: \(error.localizedDescription)")
                    return
                }
                guard let routes = response?.routes, !routes.isEmpty else {
                    completion(false, "No route found")
                    return
                }
                self?.availableRoutes = routes.enumerated().map { RouteOption(route: $0.element, index: $0.offset) }
                self?.allRoutePolylines = routes.map { $0.polyline }
                self?.selectRoute(at: 0)
                completion(true, nil)
            }
        }
    }
    
    func selectRoute(at index: Int) {
        guard index < availableRoutes.count else { return }
        selectedRouteIndex = index
        let route = availableRoutes[index].route
        
        let pointCount = route.polyline.pointCount
        var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        
        let effectiveSpeed = travelMode.speed * speedMultiplier
        routePoints = interpolateRoute(coords: coords, speed: effectiveSpeed, interval: updateInterval)
        totalPoints = routePoints.count
        routePolyline = route.polyline
        
        let totalDistance = route.distance
        let timeSeconds = totalDistance / effectiveSpeed
        let minutes = Int(timeSeconds / 60)
        let seconds = Int(timeSeconds) % 60
        estimatedTime = minutes > 60 ? "\(minutes/60)h \(minutes%60)m" : "\(minutes)m \(seconds)s"
    }
    
    private func interpolateRoute(coords: [CLLocationCoordinate2D], speed: Double, interval: TimeInterval) -> [CLLocationCoordinate2D] {
        guard coords.count >= 2 else { return coords }
        let stepDistance = speed * interval
        var result: [CLLocationCoordinate2D] = [coords[0]]
        var remainingDistance: Double = 0.0
        
        for i in 1..<coords.count {
            let from = coords[i-1]; let to = coords[i]
            let segmentDistance = distanceBetween(from, to)
            guard segmentDistance > 0 else { continue }
            var coveredInSegment = remainingDistance > 0 ? -remainingDistance : 0.0
            
            while coveredInSegment + stepDistance <= segmentDistance {
                coveredInSegment += stepDistance
                let fraction = coveredInSegment / segmentDistance
                let lat = from.latitude + (to.latitude - from.latitude) * fraction
                let lng = from.longitude + (to.longitude - from.longitude) * fraction
                result.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
            }
            remainingDistance = segmentDistance - coveredInSegment
        }
        if let last = coords.last { result.append(last) }
        return result
    }
    
    private func distanceBetween(_ c1: CLLocationCoordinate2D, _ c2: CLLocationCoordinate2D) -> Double {
        return CLLocation(latitude: c1.latitude, longitude: c1.longitude).distance(from: CLLocation(latitude: c2.latitude, longitude: c2.longitude))
    }
    
    func startSimulation(altitude: Double = 0.0) {
        guard !routePoints.isEmpty else { return }
        self.altitude = altitude
        currentPointIndex = 0
        isSimulating = true
        isPaused = false
        progress = 0.0
        
        // Request "Always" authorization for background
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        startBackgroundTask()
        updateLocation(at: 0)
        
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.advanceToNextPoint()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    func togglePause() {
        if isPaused {
            isPaused = false
            startBackgroundTask()
            timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
                self?.advanceToNextPoint()
            }
            RunLoop.current.add(timer!, forMode: .common)
        } else {
            isPaused = true
            timer?.invalidate()
            timer = nil
            endBackgroundTask()
        }
    }
    
    func stopSimulation() {
        timer?.invalidate()
        timer = nil
        isSimulating = false
        isPaused = false
        currentPointIndex = 0
        progress = 0.0
        routePoints = []
        routePolyline = nil
        allRoutePolylines = []
        availableRoutes = []
        currentPosition = nil
        estimatedTime = ""
        locationManager.stopUpdatingLocation()
        endBackgroundTask()
        LocSimManager.stopLocSim()
    }
    
    private func advanceToNextPoint() {
        currentPointIndex += 1
        
        if currentPointIndex >= routePoints.count {
            // Route completed! 
            // We STOP the timer but do NOT call stopLocSim()
            // This keeps the user's location fixed at the destination.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.timer?.invalidate()
                self.timer = nil
                self.isSimulating = false // UI shows it's finished
                self.isPaused = false
                self.progress = 1.0
                self.endBackgroundTask()
                self.locationManager.stopUpdatingLocation()
                // IMPORTANT: We do NOT call LocSimManager.stopLocSim() here
                // so the fake location stays at the last point.
            }
            return
        }
        
        updateLocation(at: currentPointIndex)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progress = Double(self.currentPointIndex) / Double(max(self.totalPoints - 1, 1))
        }
    }
    
    private func updateLocation(at index: Int) {
        guard index < routePoints.count else { return }
        var coord = routePoints[index]
        
        // MARK: - Human-like Realism
        // Add tiny random jitter (0.5 - 1.5 meters) to look less "robotic"
        let latJitter = Double.random(in: -0.00001...0.00001)
        let lngJitter = Double.random(in: -0.00001...0.00001)
        coord.latitude += latJitter
        coord.longitude += lngJitter
        
        DispatchQueue.main.async { [weak self] in
            self?.currentPosition = coord
        }
        
        let wgsCoord = CoordTransform.gcj02ToWgs84(coord)
        let location = CLLocation(
            coordinate: wgsCoord,
            altitude: altitude + Double.random(in: -0.5...0.5), // Slight altitude jitter
            horizontalAccuracy: Double.random(in: 3.0...6.0),   // Varying accuracy
            verticalAccuracy: 5,
            timestamp: Date()
        )
        LocSimManager.startLocSim(location: location)
    }
    
    // MARK: - Background Task Management
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "RouteSimulation") { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
