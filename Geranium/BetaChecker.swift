//
//  BetaChecker.swift
//  Andromeda
//
//  Developed by son3ra1n.
//  Beta enrollment system disabled for public release.
//

import Foundation
import SwiftUI

struct BetaView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            Image(uiImage: Bundle.main.icon!)
                .cornerRadius(10)
            Text("Andromeda Pro Edition")
                .font(.title2)
                .bold()
                .foregroundColor(.indigo)
                .multilineTextAlignment(.center)
            Text("by son3ra1n")
                .padding()
                .foregroundColor(.secondary)
        }
        .onAppear {
            // Auto-dismiss — beta system not active
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
}

func isDeviceEnrolled() -> Bool {
    // Beta enrollment disabled for public release
    return true
}
