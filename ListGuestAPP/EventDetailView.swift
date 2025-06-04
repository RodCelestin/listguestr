//
//  EventDetailView.swift
//  ListGuestAPP
//
//  Created by Rodolphe on 28/05/2025.
//

import SwiftUI
import UIKit // Import UIKit for keyboard dismissal

struct EventDetailView: View {
    let event: Event
    
    // Access EventService from the environment
    @EnvironmentObject private var eventService: EventService
    
    // Add state variables for form fields
    @State private var fullName: String = ""
    @State private var role: String = ""
    @State private var company: String = ""
    @State private var email: String = ""
    @State private var additionalRequest: String = ""
    
    @State private var showingSuccessMessage = false // State to show success message
    @State private var registrationErrorMessage: String? = nil // State to show registration error
    
    // Helper function to calculate days until registration closes
    private func daysUntilClosing(for event: Event) -> String? {
        guard let deadline = event.registrationDeadline else {
            return nil
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: deadline)
        
        if let days = components.day, days >= 0 {
            if days == 0 {
                return "Closing today"
            } else {
                return "Closing in \(days) days"
            }
        } else {
            return nil // Deadline has passed
        }
    }
    
    // Helper function to display genre tags
    @ViewBuilder
    private func genreTagsView(genres: [String]?) -> some View {
        if let genres = genres, !genres.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(genres, id: \.self) {
                        genre in
                        Text(genre)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.bottom, 4) // Add some space below the tags
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let imageUrlString = event.artistImageUrlString, let url = URL(string: imageUrlString) {
                        AsyncImage(url: url) {
                            phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                                    .clipped()
                                    .shadow(radius: 8)
                            case .failure:
                                Image(systemName: "person.circle") // Placeholder for error
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                                    .clipped()
                                    .shadow(radius: 8)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .padding(.bottom)
                    } else {
                        // Optional: Display a placeholder image or text if no image URL is available
                        Image(systemName: "person.circle") // Example placeholder
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                            .clipped()
                            .padding(.bottom)
                            .shadow(radius: 8)
                    }

                    // Add genre tags here
                    genreTagsView(genres: event.genres)
                    
                    Text(event.title)
                        .font(.largeTitle)
                        .padding(.bottom, 4)
                    
                    if let description = event.description {
                        Text(description)
                            .font(.body)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(event.date, style: .date)
                        Text(event.date, style: .time)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    if let location = event.location {
                        HStack {
                            Image(systemName: "location.fill")
                            Text(location)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    if let deadline = event.registrationDeadline {
                        HStack {
                            Image(systemName: "clock")
                            Text("Registration closes: \(deadline, style: .date)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    if let daysLeft = daysUntilClosing(for: event) {
                        Text(daysLeft)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    // Add a divider before the form
                    Divider()
                        .padding(.vertical)
                    
                    // Registration Form
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Register for Guest List")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            TextField("Full Name *", text: $fullName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                                .textContentType(.name)
                            
                            TextField("Role *", text: $role)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                            
                            TextField("Company *", text: $company)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                                .textContentType(.organizationName)
                            
                            TextField("Email *", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textContentType(.emailAddress)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Want to add request?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextEditor(text: $additionalRequest)
                                    .frame(height: 100)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            
                            Button(action: {
                                // Clear previous messages
                                showingSuccessMessage = false
                                registrationErrorMessage = nil
                                
                                // Validate required fields
                                guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                                      !role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                                      !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                                      !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                    registrationErrorMessage = "Please fill out all required fields (marked with *)."
                                    return
                                }
                                
                                // Create Guest object
                                let newGuest = Guest(
                                    id: nil, // Supabase will generate the ID
                                    event_id: event.id, // Use the current event's ID
                                    full_name: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                                    role: role.trimmingCharacters(in: .whitespacesAndNewlines),
                                    company: company.trimmingCharacters(in: .whitespacesAndNewlines),
                                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                    additional_request: additionalRequest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : additionalRequest.trimmingCharacters(in: .whitespacesAndNewlines),
                                    created_at: nil // Supabase will generate the timestamp
                                )
                                
                                // Submit registration
                                Task {
                                    do {
                                        try await eventService.registerGuest(newGuest)
                                        // On success
                                        fullName = ""
                                        role = ""
                                        company = ""
                                        email = ""
                                        additionalRequest = ""
                                        showingSuccessMessage = true
                                        
                                        // Save the applied event ID to UserDefaults
                                        var appliedEventIDs = UserDefaults.standard.stringArray(forKey: "appliedEventIDs") ?? []
                                        let eventIDString = event.id.uuidString
                                        if !appliedEventIDs.contains(eventIDString) {
                                            appliedEventIDs.append(eventIDString)
                                            UserDefaults.standard.set(appliedEventIDs, forKey: "appliedEventIDs")
                                            print("Saved applied event ID: \(event.id.uuidString)")
                                        }
                                        
                                    } catch {
                                        // On failure
                                        print("Error registering guest: \(error.localizedDescription)")
                                        registrationErrorMessage = "Failed to register: \(error.localizedDescription)"
                                    }
                                }
                            }) {
                                Text("Submit Registration")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.top)
                            
                            // Display registration error message if any
                            if let errorMessage = registrationErrorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.callout)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding()
            }
            .onTapGesture { // Add tap gesture to dismiss keyboard
                hideKeyboard()
            }
            .navigationTitle(event.title)
            .navigationBarTitleDisplayMode(.inline)
            
            // Success Message Overlay
            if showingSuccessMessage {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showingSuccessMessage = false // Dismiss on tap outside message
                    }
                
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 50))
                    Text("Successfully Registered!")
                        .font(.headline)
                        .padding(.top, 8)
                    Text("You have been added to the guest list.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(width: 250, height: 150)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .transition(.scale) // Optional: Add animation
            }
        }
    }
    
    // Helper function to hide the keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Create a sample Event with registrationDeadline and location for the preview
            EventDetailView(event: Event(id: UUID(), title: "Sample Event", description: "This is a sample event description.", date: Date(), location: "Sample Location", createdAt: Date(), artistImageUrlString: nil, registrationDeadline: Calendar.current.date(byAdding: .day, value: 7, to: Date()), genres: nil))
                .environmentObject(EventService()) // Provide EventService for preview
        }
    }
} 