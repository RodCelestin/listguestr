//
//  RegistrationConfirmationView.swift
//  ListGuestAPP
//
//  Created by Rodolphe Celestin on 2025-06-13.
//

import SwiftUI

struct RegistrationConfirmationView: View {
    @Environment(\.presentationMode) var presentationMode // Access presentation mode to dismiss view
    let guest: Guest
    // Removed: @Binding var shouldPopToRoot: Bool
    
    // Binding for controlling navigation from the root view
    @Binding var selectedEvent: Event? // Binding to the selected event in ContentView
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Registration Successful!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("Thank you for registering. Here are the details you provided:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Full Name: \(guest.full_name)")
                    
                    if let role = guest.role, !role.isEmpty {
                        Text("Role: \(role)")
                    }
                    
                    if let company = guest.company, !company.isEmpty {
                        Text("Company: \(company)")
                    }
                    
                    Text("Email: \(guest.email)")
                    
                    if let request = guest.additional_request, !request.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Additional Request:")
                                .fontWeight(.semibold)
                            Text(request)
                        }
                    }
                }
                .font(.body)
                
                Spacer()
                
                Button("Back to all events") {
                    selectedEvent = nil // Set selectedEvent to nil to pop to root
                }
                .buttonStyle(.plain) // Change to .plain to apply custom styling
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top) // Add some padding at the top if needed
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack takes full space
        }
        .navigationTitle("Confirmation")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // Hide the default back button
    }
}

struct RegistrationConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Pass a constant binding for preview purposes
            RegistrationConfirmationView(guest: Guest(id: UUID(), event_id: UUID(), full_name: "John Doe", role: "Developer", company: "Apple Inc.", email: "john.doe@example.com", additional_request: "Please provide a vegetarian meal.", created_at: Date()), selectedEvent: .constant(nil)) // Pass a constant binding for preview
        }
    }
} 