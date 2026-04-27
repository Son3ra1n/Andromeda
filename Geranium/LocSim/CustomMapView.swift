//
//  CustomMapView.swift
//  Andromeda
//
//  Developed by son3ra1n.
//

import SwiftUI
import MapKit

struct CustomMapView: UIViewRepresentable {
    @Binding var tappedCoordinate: EquatableCoordinate?
    @Binding var moveToRegion: MKCoordinateRegion?
    var routePolyline: MKPolyline?
    var allRoutePolylines: [MKPolyline]
    var selectedRouteIndex: Int
    var movingPosition: CLLocationCoordinate2D?
    
    init(tappedCoordinate: Binding<EquatableCoordinate?>,
         moveToRegion: Binding<MKCoordinateRegion?>,
         routePolyline: MKPolyline? = nil,
         allRoutePolylines: [MKPolyline] = [],
         selectedRouteIndex: Int = 0,
         movingPosition: CLLocationCoordinate2D? = nil) {
        self._tappedCoordinate = tappedCoordinate
        self._moveToRegion = moveToRegion
        self.routePolyline = routePolyline
        self.allRoutePolylines = allRoutePolylines
        self.selectedRouteIndex = selectedRouteIndex
        self.movingPosition = movingPosition
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.layer.cornerRadius = 15
        mapView.layer.masksToBounds = true

        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapRecognizer)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Move to region if requested
        if let region = moveToRegion {
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                self.moveToRegion = nil
            }
        }
        
        // Update route polylines
        let existingOverlays = uiView.overlays
        
        if !allRoutePolylines.isEmpty {
            // Multiple routes available - show all
            let currentOverlayCount = existingOverlays.filter { $0 is MKPolyline }.count
            
            if currentOverlayCount != allRoutePolylines.count || context.coordinator.selectedIndex != selectedRouteIndex {
                // Remove old polylines
                uiView.removeOverlays(existingOverlays.filter { $0 is MKPolyline })
                
                // Add non-selected routes first (they render below)
                for (idx, polyline) in allRoutePolylines.enumerated() {
                    if idx != selectedRouteIndex {
                        uiView.addOverlay(polyline, level: .aboveRoads)
                    }
                }
                
                // Add selected route last (renders on top)
                if selectedRouteIndex < allRoutePolylines.count {
                    uiView.addOverlay(allRoutePolylines[selectedRouteIndex], level: .aboveRoads)
                }
                
                context.coordinator.currentPolylines = allRoutePolylines
                context.coordinator.selectedIndex = selectedRouteIndex
            }
        } else if let polyline = routePolyline {
            // Single route
            let hasExisting = existingOverlays.contains(where: { $0 is MKPolyline })
            if !hasExisting {
                uiView.addOverlay(polyline, level: .aboveRoads)
                context.coordinator.currentPolylines = [polyline]
                context.coordinator.selectedIndex = 0
            }
        } else {
            // No routes - clear
            uiView.removeOverlays(existingOverlays.filter { $0 is MKPolyline })
            context.coordinator.currentPolylines = []
        }
        
        // Update moving position annotation
        if let position = movingPosition {
            if let movingAnnotation = context.coordinator.movingAnnotation {
                UIView.animate(withDuration: 0.8) {
                    movingAnnotation.coordinate = position
                }
            } else {
                let annotation = MovingAnnotation()
                annotation.coordinate = position
                annotation.title = "Current Position"
                uiView.addAnnotation(annotation)
                context.coordinator.movingAnnotation = annotation
            }
        } else {
            if let movingAnnotation = context.coordinator.movingAnnotation {
                uiView.removeAnnotation(movingAnnotation)
                context.coordinator.movingAnnotation = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        var currentPolylines: [MKPolyline] = []
        var selectedIndex: Int = 0
        var movingAnnotation: MovingAnnotation? = nil

        init(_ parent: CustomMapView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            parent.tappedCoordinate = EquatableCoordinate(coordinate: coordinate)
        }
        
        // MARK: - Route colors
        private let routeColors: [UIColor] = [
            .systemBlue,
            .systemOrange, 
            .systemPurple,
            .systemPink
        ]
        
        // MARK: - MKMapViewDelegate
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                // Find index of this polyline
                if let idx = currentPolylines.firstIndex(where: { $0 === polyline }) {
                    if idx == selectedIndex {
                        // Selected route: solid, thick, bright
                        renderer.strokeColor = routeColors[idx % routeColors.count]
                        renderer.lineWidth = 6
                        renderer.alpha = 1.0
                    } else {
                        // Alternative route: thinner, semi-transparent, dashed
                        renderer.strokeColor = routeColors[idx % routeColors.count]
                        renderer.lineWidth = 4
                        renderer.alpha = 0.4
                        renderer.lineDashPattern = [8, 6]
                    }
                } else {
                    // Default style
                    renderer.strokeColor = .systemBlue
                    renderer.lineWidth = 5
                    renderer.alpha = 0.8
                }
                
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            
            if annotation is MovingAnnotation {
                let identifier = "MovingPosition"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                if view == nil {
                    view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    view?.canShowCallout = false
                    
                    let dotSize: CGFloat = 20
                    let outerSize: CGFloat = 30
                    
                    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: outerSize, height: outerSize))
                    
                    let outerCircle = UIView(frame: CGRect(x: 0, y: 0, width: outerSize, height: outerSize))
                    outerCircle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
                    outerCircle.layer.cornerRadius = outerSize / 2
                    containerView.addSubview(outerCircle)
                    
                    let innerCircle = UIView(frame: CGRect(
                        x: (outerSize - dotSize) / 2,
                        y: (outerSize - dotSize) / 2,
                        width: dotSize,
                        height: dotSize
                    ))
                    innerCircle.backgroundColor = UIColor.systemBlue
                    innerCircle.layer.cornerRadius = dotSize / 2
                    innerCircle.layer.borderWidth = 3
                    innerCircle.layer.borderColor = UIColor.white.cgColor
                    innerCircle.layer.shadowColor = UIColor.black.cgColor
                    innerCircle.layer.shadowOffset = CGSize(width: 0, height: 1)
                    innerCircle.layer.shadowRadius = 3
                    innerCircle.layer.shadowOpacity = 0.3
                    containerView.addSubview(innerCircle)
                    
                    let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
                    pulseAnimation.duration = 1.5
                    pulseAnimation.fromValue = 1.0
                    pulseAnimation.toValue = 1.5
                    pulseAnimation.autoreverses = true
                    pulseAnimation.repeatCount = .infinity
                    outerCircle.layer.add(pulseAnimation, forKey: "pulse")
                    
                    let fadeAnimation = CABasicAnimation(keyPath: "opacity")
                    fadeAnimation.duration = 1.5
                    fadeAnimation.fromValue = 0.5
                    fadeAnimation.toValue = 0.1
                    fadeAnimation.autoreverses = true
                    fadeAnimation.repeatCount = .infinity
                    outerCircle.layer.add(fadeAnimation, forKey: "fade")
                    
                    view?.addSubview(containerView)
                    view?.frame = containerView.frame
                    view?.centerOffset = CGPoint(x: 0, y: 0)
                } else {
                    view?.annotation = annotation
                }
                return view
            }
            
            return nil
        }
    }
}

class MovingAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
}
