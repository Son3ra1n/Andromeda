//
//  JoystickView.swift
//  Andromeda
//
//  Developed by son3ra1n.
//

import SwiftUI
import CoreLocation

struct JoystickView: View {
    @Binding var isActive: Bool
    var onMove: (CLLocationCoordinate2D) -> Void
    @Binding var currentCoordinate: CLLocationCoordinate2D
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var selectedSpeed: SpeedMode = .walk
    @State private var moveTimer: Timer? = nil
    
    enum SpeedMode: String, CaseIterable {
        case walk = "🚶"
        case run = "🏃"
        case bike = "🚴"
        case car = "🚗"
        
        var label: String {
            switch self {
            case .walk: return "Walk"
            case .run: return "Run"
            case .bike: return "Bike"
            case .car: return "Car"
            }
        }
        
        var speed: Double {
            switch self {
            case .walk: return 1.4
            case .run: return 3.3
            case .bike: return 6.9
            case .car: return 16.7
            }
        }
    }
    
    private let joystickSize: CGFloat = 140
    private let knobSize: CGFloat = 55
    private let maxDrag: CGFloat = 42
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            HStack(alignment: .bottom) {
                // Speed Selector
                VStack(spacing: 6) {
                    ForEach(SpeedMode.allCases, id: \.self) { mode in
                        Button(action: { selectedSpeed = mode }) {
                            Text(mode.rawValue)
                                .font(.system(size: 20))
                                .frame(width: 40, height: 40)
                                .background(
                                    selectedSpeed == mode
                                        ? Color.indigo.opacity(0.9)
                                        : Color.black.opacity(0.3)
                                )
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedSpeed == mode ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                    
                    Text(selectedSpeed.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.leading, 20)
                .padding(.bottom, 30)
                
                Spacer()
                
                // Joystick
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.25))
                        .frame(width: joystickSize, height: joystickSize)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 2)
                        )
                    
                    // Direction indicators
                    ForEach(0..<8, id: \.self) { i in
                        let angle = Double(i) * 45.0
                        let radius = Double(joystickSize / 2 - 12)
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 6, height: 6)
                            .offset(
                                x: CGFloat(cos(angle * .pi / 180) * radius),
                                y: CGFloat(sin(angle * .pi / 180) * radius)
                            )
                    }
                    
                    // Knob
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.indigo.opacity(0.9), Color.indigo],
                                center: .center,
                                startRadius: 0,
                                endRadius: knobSize / 2
                            )
                        )
                        .frame(width: knobSize, height: knobSize)
                        .shadow(color: .indigo.opacity(0.5), radius: isDragging ? 15 : 8, x: 0, y: 0)
                        .overlay(
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(dragAngle))
                        )
                        .offset(dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                                    let clampedDistance = min(distance, maxDrag)
                                    let angle = atan2(value.translation.height, value.translation.width)
                                    
                                    dragOffset = CGSize(
                                        width: cos(angle) * clampedDistance,
                                        height: sin(angle) * clampedDistance
                                    )
                                    
                                    if !isDragging {
                                        isDragging = true
                                        startMoving()
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        dragOffset = .zero
                                    }
                                    isDragging = false
                                    stopMoving()
                                }
                        )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .onDisappear {
            stopMoving()
        }
    }
    
    private var dragAngle: Double {
        guard dragOffset != .zero else { return 0 }
        let angle = atan2(dragOffset.height, dragOffset.width)
        return (angle * 180 / .pi) + 90
    }
    
    private func startMoving() {
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            guard isDragging, dragOffset != .zero else { return }
            
            let distance = sqrt(pow(dragOffset.width, 2) + pow(dragOffset.height, 2))
            let normalizedDistance = min(distance / maxDrag, 1.0)
            let angle = atan2(dragOffset.height, dragOffset.width)
            
            let metersPerTick = selectedSpeed.speed * 0.3 * normalizedDistance
            
            // Screen coordinates: right=+x, down=+y
            // Map: right=+longitude, down=-latitude
            let latDelta = -(metersPerTick * Double(sin(angle))) / 111320.0
            let longDelta = (metersPerTick * Double(cos(angle))) / (111320.0 * cos(currentCoordinate.latitude * .pi / 180))
            
            let newCoordinate = CLLocationCoordinate2D(
                latitude: currentCoordinate.latitude + latDelta,
                longitude: currentCoordinate.longitude + longDelta
            )
            
            DispatchQueue.main.async {
                onMove(newCoordinate)
            }
        }
    }
    
    private func stopMoving() {
        moveTimer?.invalidate()
        moveTimer = nil
    }
}
