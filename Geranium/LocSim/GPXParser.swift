//
//  GPXParser.swift
//  Andromeda
//
//  Developed by son3ra1n.
//

import Foundation
import CoreLocation

class GPXParser: NSObject, XMLParserDelegate {
    private var waypoints: [GPXWaypoint] = []
    private var trackPoints: [CLLocationCoordinate2D] = []
    private var currentElement = ""
    private var currentName = ""
    private var currentDesc = ""
    private var currentLat: Double?
    private var currentLon: Double?
    
    struct GPXWaypoint {
        let name: String
        let description: String
        let coordinate: CLLocationCoordinate2D
    }
    
    struct GPXResult {
        let waypoints: [GPXWaypoint]
        let trackPoints: [CLLocationCoordinate2D]
        let name: String
        
        var allCoordinates: [CLLocationCoordinate2D] {
            if !trackPoints.isEmpty { return trackPoints }
            return waypoints.map { $0.coordinate }
        }
        
        var isEmpty: Bool {
            return waypoints.isEmpty && trackPoints.isEmpty
        }
    }
    
    static func parse(data: Data) -> GPXResult? {
        let parser = GPXParser()
        return parser.parseData(data)
    }
    
    static func parse(url: URL) -> GPXResult? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return parse(data: data)
    }
    
    private func parseData(_ data: Data) -> GPXResult? {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        
        guard xmlParser.parse() else { return nil }
        
        return GPXResult(
            waypoints: waypoints,
            trackPoints: trackPoints,
            name: "GPX Route"
        )
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        switch elementName {
        case "wpt", "trkpt", "rtept":
            if let latStr = attributeDict["lat"], let lonStr = attributeDict["lon"],
               let lat = Double(latStr), let lon = Double(lonStr) {
                currentLat = lat
                currentLon = lon
            }
            currentName = ""
            currentDesc = ""
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        switch currentElement {
        case "name": currentName += trimmed
        case "desc": currentDesc += trimmed
        default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard let lat = currentLat, let lon = currentLon else { return }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        switch elementName {
        case "wpt":
            waypoints.append(GPXWaypoint(
                name: currentName.isEmpty ? "Waypoint \(waypoints.count + 1)" : currentName,
                description: currentDesc,
                coordinate: coordinate
            ))
            currentLat = nil
            currentLon = nil
            
        case "trkpt", "rtept":
            trackPoints.append(coordinate)
            currentLat = nil
            currentLon = nil
            
        default:
            break
        }
        
        currentElement = ""
    }
}

// MARK: - Document Picker for GPX Files
import SwiftUI
import UniformTypeIdentifiers

struct GPXDocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType(filenameExtension: "gpx") ?? .xml,
            .xml
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            onPick(url)
        }
    }
}
