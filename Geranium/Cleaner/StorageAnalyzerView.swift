//
//  StorageAnalyzerView.swift
//  Andromeda
//
//  Developed by son3ra1n.
//

import SwiftUI

struct StorageAnalyzerView: View {
    @State private var isScanning = true
    @State private var storageItems: [StorageItem] = []
    @State private var totalSpace: Double = 0
    @State private var usedSpace: Double = 0
    @State private var freeSpace: Double = 0
    
    struct StorageItem: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let size: Double // bytes
        let color: Color
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color.indigo.opacity(0.08), Color.black.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Donut Chart
                        ZStack {
                            if !isScanning {
                                donutChart()
                                    .frame(width: 200, height: 200)
                                
                                VStack(spacing: 2) {
                                    Text(formatSize(freeSpace))
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                                        )
                                    Text("Free")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                ProgressView()
                                    .scaleEffect(2)
                                    .frame(width: 200, height: 200)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Total Bar
                        if !isScanning {
                            VStack(spacing: 6) {
                                HStack {
                                    Text("Total Storage")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatSize(totalSpace))
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                }
                                
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 10)
                                        .overlay(alignment: .leading) {
                                            let usedRatio = totalSpace > 0 ? usedSpace / totalSpace : 0
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(
                                                    LinearGradient(
                                                        colors: usedRatio > 0.9 ? [.red, .orange] : [.indigo, .purple],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: geo.size.width * usedRatio, height: 10)
                                        }
                                }
                                .frame(height: 10)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        
                        // Category List
                        if !isScanning {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("CATEGORIES")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                
                                ForEach(storageItems) { item in
                                    storageRow(item: item)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Storage")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                analyzeStorage()
            }
        }
    }
    
    @ViewBuilder
    private func donutChart() -> some View {
        let total = storageItems.reduce(0) { $0 + $1.size } + freeSpace
        
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 15
            let lineWidth: CGFloat = 28
            
            var startAngle: Angle = .degrees(-90)
            
            for item in storageItems {
                let proportion = total > 0 ? item.size / total : 0
                let endAngle = startAngle + .degrees(proportion * 360)
                
                let path = Path { p in
                    p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                }
                
                context.stroke(path, with: .color(item.color), lineWidth: lineWidth)
                startAngle = endAngle
            }
            
            // Free space arc
            let freeAngle = startAngle + .degrees((total > 0 ? freeSpace / total : 0) * 360)
            let freePath = Path { p in
                p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: freeAngle, clockwise: false)
            }
            context.stroke(freePath, with: .color(Color.gray.opacity(0.2)), lineWidth: lineWidth)
        }
    }
    
    private func storageRow(item: StorageItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.color)
                .frame(width: 12, height: 12)
            
            Image(systemName: item.icon)
                .font(.system(size: 15))
                .foregroundColor(item.color)
                .frame(width: 24)
            
            Text(item.name)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
            
            Text(formatSize(item.size))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
    
    private func formatSize(_ bytes: Double) -> String {
        if bytes >= 1_073_741_824 {
            return String(format: "%.1f GB", bytes / 1_073_741_824)
        } else if bytes >= 1_048_576 {
            return String(format: "%.1f MB", bytes / 1_048_576)
        } else {
            return String(format: "%.0f KB", bytes / 1024)
        }
    }
    
    private func analyzeStorage() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Get device storage info
            let fileManager = FileManager.default
            
            do {
                let attrs = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
                let total = (attrs[.systemSize] as? Double) ?? 0
                let free = (attrs[.systemFreeSize] as? Double) ?? 0
                let used = total - free
                
                // Estimate categories
                let systemSize = total * 0.15 // ~15% system
                let appsSize = used * 0.35
                let mediaSize = used * 0.25
                let cachesSize = used * 0.10
                let otherSize = used - systemSize - appsSize - mediaSize - cachesSize
                
                let items: [StorageItem] = [
                    StorageItem(name: "System", icon: "gearshape.fill", size: max(systemSize, 0), color: .gray),
                    StorageItem(name: "Apps", icon: "square.grid.2x2.fill", size: max(appsSize, 0), color: .blue),
                    StorageItem(name: "Media", icon: "photo.fill", size: max(mediaSize, 0), color: .orange),
                    StorageItem(name: "Caches", icon: "archivebox.fill", size: max(cachesSize, 0), color: .red),
                    StorageItem(name: "Other", icon: "ellipsis.circle.fill", size: max(otherSize, 0), color: .purple),
                ]
                
                DispatchQueue.main.async {
                    self.totalSpace = total
                    self.usedSpace = used
                    self.freeSpace = free
                    self.storageItems = items
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.isScanning = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isScanning = false
                }
            }
        }
    }
}
