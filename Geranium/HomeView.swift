//
//  HomeView.swift
//  Andromeda
//
//  Created by son3ra1n.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var isDebugSheetOn = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(colors: [Color.indigo.opacity(0.1), Color.black.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // MARK: - Hero Header
                        VStack(spacing: 15) {
                            Image(uiImage: Bundle.main.icon ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .cornerRadius(22)
                                .shadow(color: .indigo.opacity(0.5), radius: 15, x: 0, y: 10)
                            
                            VStack(spacing: 4) {
                                Text("ANDROMEDA")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .tracking(2)
                                    .foregroundStyle(
                                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                                    )
                                
                                Text("PRO EDITION BY SON3RA1N")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(1)
                            }
                        }
                        .padding(.top, 40)
                        
                        // MARK: - Feature Stats Card
                        HStack(spacing: 15) {
                            statItem(title: "Status", value: "Verified", icon: "checkmark.shield.fill", color: .green)
                            statItem(title: "Version", value: "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")-Pro", icon: "cpu", color: .indigo)
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Main Actions
                        VStack(spacing: 12) {
                            Text("CREDITS & CONTRIBUTORS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 10)
                            
                            VStack(spacing: 1) {
                                creditRow(name: "son3ra1n", role: "Main Developer", image: "https://github.com/son3ra1n.png")
                            }
                            .glassCard()
                        }
                        .padding(.horizontal)
                        
                        // Respring Button
                        Button(action: { respring() }) {
                            HStack {
                                Image(systemName: "restart.circle.fill")
                                Text("Respring Device")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(16)
                            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isDebugSheetOn.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.indigo)
                    }
                }
            }
            .sheet(isPresented: $isDebugSheetOn) {
                SettingsView()
            }
        }
    }
    
    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
    
    private func creditRow(name: String, role: String, image: String) -> some View {
        HStack(spacing: 15) {
            AsyncImageView(url: URL(string: image)!)
                .frame(width: 40, height: 40)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(role)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}
//
//  AndromedaTheme.swift
//  Andromeda
//
//  Premium design tokens for son3ra1n Edition
//

import SwiftUI

struct AndromedaTheme {
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [Color(red: 0.3, green: 0.2, blue: 0.8), Color(red: 0.5, green: 0.1, blue: 0.7)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glassBackground = Color(UIColor.systemBackground).opacity(0.7)
    
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [Color.indigo.opacity(0.2), Color.purple.opacity(0.1)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(colors: [.white.opacity(0.4), .clear, .indigo.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
}
