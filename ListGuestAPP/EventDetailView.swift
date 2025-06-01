//
//  EventDetailView.swift
//  ListGuestAPP
//
//  Created by Rodolphe on 28/05/2025.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            
            Spacer()
        }
        .padding()
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Create a sample Event with registrationDeadline and location for the preview
            EventDetailView(event: Event(id: UUID(), title: "Sample Event", description: "This is a sample event description.", date: Date(), location: "Sample Location", createdAt: Date(), artistImageUrlString: nil, registrationDeadline: Calendar.current.date(byAdding: .day, value: 7, to: Date())))
        }
    }
} 