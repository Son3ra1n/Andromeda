//
//  FloatingQuickMenu.swift
//  Andromeda
//
//  Developed by son3ra1n.
//

import SwiftUI

enum QuickMenuAction: String, CaseIterable {
    case search = "Search"
    case favorites = "Favorites"
    case appProfiles = "Apps"
    case joystick = "Joystick"
    case route = "Route"
    case altitude = "Altitude"
    case timer = "Timer"
    case stop = "Stop"
    
    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .favorites: return "star.fill"
        case .appProfiles: return "apps.iphone"
        case .joystick: return "gamecontroller.fill"
        case .route: return "car.fill"
        case .altitude: return "mountain.2.fill"
        case .timer: return "timer"
        case .stop: return "location.slash.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .search: return .indigo
        case .favorites: return .orange
        case .appProfiles: return .cyan
        case .joystick: return .green
        case .route: return .blue
        case .altitude: return .purple
        case .timer: return .orange
        case .stop: return .red
        }
    }
}

struct FloatingQuickMenu: View {
    let onAction: (QuickMenuAction) -> Void
    var joystickActive: Bool
    var timerActive: Bool
    
    private let actions = QuickMenuAction.allCases
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                ForEach(actions, id: \.self) { action in
                    let isActive = (action == .joystick && joystickActive) || (action == .timer && timerActive)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onAction(action)
                    }) {
                        HStack(spacing: 6) {
                            Text(action.rawValue)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                            
                            Image(systemName: action.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isActive ? action.color : action.color.opacity(0.75))
                                .shadow(color: action.color.opacity(isActive ? 0.5 : 0.25), radius: isActive ? 8 : 4, x: 0, y: 3)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(isActive ? 0.4 : 0.15), lineWidth: 1)
                        )
                        .scaleEffect(isActive ? 1.05 : 1.0)
                        .animation(.spring(response: 0.25), value: isActive)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}
