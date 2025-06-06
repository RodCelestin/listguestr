//
//  EventDetailView.swift
//  ListGuestAPP
//
//  Created by Rodolphe on 28/05/2025.
//

import SwiftUI
import UIKit // Import UIKit for keyboard dismissal

// MARK: - Custom TextField

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.leading, 12) // internal padding for placeholder
            }

            TextField("", text: $text)
                .padding(.vertical, 12) // vertical padding inside text field
                .padding(.horizontal, 12) // horizontal padding inside text field
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray)
        )
        .frame(height: 56)
    }
}

// MARK: - Event Detail View

struct EventDetailView: View {
    @Environment(\.presentationMode) var presentationMode // Access presentation mode to dismiss view
    let event: Event
    
    // Binding for controlling navigation from the root view
    @Binding var selectedEvent: Event? // Binding to the selected event in ContentView
    
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
    
    @State private var navigateToConfirmation = false // State to trigger navigation to confirmation page
    @State private var registeredGuest: Guest? = nil // State to hold the registered guest data
    
    @State private var isAcknowledged = false // State to track acknowledgment checkbox
    
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
    
    private var hasAlreadyApplied: Bool {
        let appliedEventIDs = UserDefaults.standard.stringArray(forKey: "appliedEventIDs") ?? []
        return appliedEventIDs.contains(event.id.uuidString)
    }
    
    // MARK: - Subviews
    
    private var appliedBanner: some View {
        Group {
            if hasAlreadyApplied {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You've already requested access for this event")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Our team will review your request and get back to you soon.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.bottom, 8)
                .padding(.horizontal, -16)
            }
        }
    }

    private func artistImageSection(geometry: GeometryProxy) -> some View {
        Group {
            if let imageUrlString = event.artistImageUrlString, let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { phase in
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
                            .cornerRadius(12)
                    case .failure:
                        Image(systemName: "person.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                            .clipped()
                            .shadow(radius: 8)
                            .cornerRadius(12)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                    .clipped()
                    .shadow(radius: 8)
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)
            }
        }
    }

    private var eventInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            if let capacity = event.capacity {
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("Capacity: \(capacity)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray3), lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.vertical, 8)
    }

    private var registrationForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Full Name")
                    .font(.headline)
                CustomTextField(placeholder: "Full Name *", text: $fullName)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Role")
                    .font(.headline)
                CustomTextField(placeholder: "Role *", text: $role)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Company")
                    .font(.headline)
                CustomTextField(placeholder: "Company *", text: $company)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .font(.headline)
                CustomTextField(placeholder: "Email *", text: $email)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Want to add request?")
                    .font(.headline)
                Text("This will help our team to handle best your request.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                CustomTextField(placeholder: "Your request...", text: $additionalRequest)
            }
            if let errorMessage = registrationErrorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.callout)
            }
            Toggle(isOn: $isAcknowledged) {
                Text("I understand that my request can be refused, based on guest list spots available and band and/or artist manager policy for that show.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }
            .toggleStyle(.automatic)
            .padding(.vertical)
        }
    }

    private var stickyCTAButton: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 100)
            .edgesIgnoringSafeArea(.bottom)
            Button(action: {
                showingSuccessMessage = false
                registrationErrorMessage = nil
                guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    registrationErrorMessage = "Please fill out all required fields (marked with *)."
                    return
                }
                let newGuest = Guest(
                    id: nil,
                    event_id: event.id,
                    full_name: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                    role: role.trimmingCharacters(in: .whitespacesAndNewlines),
                    company: company.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    additional_request: additionalRequest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : additionalRequest.trimmingCharacters(in: .whitespacesAndNewlines),
                    created_at: nil
                )
                Task {
                    do {
                        try await eventService.registerGuest(newGuest)
                        fullName = ""
                        role = ""
                        company = ""
                        email = ""
                        additionalRequest = ""
                        showingSuccessMessage = true
                        var appliedEventIDs = UserDefaults.standard.stringArray(forKey: "appliedEventIDs") ?? []
                        let eventIDString = event.id.uuidString
                        if !appliedEventIDs.contains(eventIDString) {
                            appliedEventIDs.append(eventIDString)
                            UserDefaults.standard.set(appliedEventIDs, forKey: "appliedEventIDs")
                            print("Saved applied event ID: \(event.id.uuidString)")
                        }
                        registeredGuest = newGuest
                        navigateToConfirmation = true
                    } catch {
                        print("Error registering guest: \(error.localizedDescription)")
                        registrationErrorMessage = "Failed to register: \(error.localizedDescription)"
                    }
                }
            }) {
                Text("🤘 Send a request")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!isAcknowledged)
            .padding([.horizontal, .bottom])
        }
    }

    private var navigationLink: some View {
        NavigationLink(destination: RegistrationConfirmationView(guest: registeredGuest ?? Guest(id: UUID(), event_id: UUID(), full_name: "", role: nil, company: nil, email: "", additional_request: nil, created_at: Date()), selectedEvent: $selectedEvent), isActive: $navigateToConfirmation) {
            EmptyView()
        }
        .hidden()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            appliedBanner
                            artistImageSection(geometry: geometry)
                            Text(event.title)
                                .font(.largeTitle)
                                .padding(.bottom, 4)
                            genreTagsView(genres: event.genres)
                            eventInfoSection
                            Text("Registrate now for this event 🤘")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.bottom, 8)
                            registrationForm
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                }
                stickyCTAButton
                navigationLink
            }
        }
        .onTapGesture { hideKeyboard() }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
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
            EventDetailView(event: Event(id: UUID(), title: "Sample Event", description: "This is a sample event description.", date: Date(), location: "Sample Location", createdAt: Date(), artistImageUrlString: nil, registrationDeadline: Calendar.current.date(byAdding: .day, value: 7, to: Date()), genres: nil, capacity: nil), selectedEvent: .constant(nil)) // Pass a constant binding for preview
        }
    }
} 
