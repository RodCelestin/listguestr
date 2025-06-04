//
//  SettingsView.swift
//  ListGuestAPP
//
//  Created by Rodolphe Celestin on 2025-06-13.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingResetConfirmation = false // State to control confirmation dialog
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Local Data")) {
                    Button("Reset Applied Events") {
                        showingResetConfirmation = true // Show confirmation dialog
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            // Add confirmation dialog
            .confirmationDialog("Reset Applied Events", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
                Button("Confirm", role: .destructive) {
                    UserDefaults.standard.removeObject(forKey: "appliedEventIDs")
                    print("Applied events local storage reset.")
                    // Optionally, provide visual feedback here, e.g., an alert
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove all applied events from this device?")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 