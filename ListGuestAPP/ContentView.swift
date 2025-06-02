//
//  ContentView.swift
//  ListGuestAPP
//
//  Created by Rodolphe Celestin on 2025-06-01.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var eventService = EventService()
    @State private var events: [Event] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isShowingList = true // State to toggle between list and grid
    @State private var searchText = "" // State for the search bar text
    
    // Define columns for the grid view
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Computed property to filter events based on search text
    private var filteredEvents: [Event] {
        if searchText.isEmpty {
            return events
        } else {
            return events.filter {
                $0.title.localizedStandardContains(searchText) ||
                ($0.description?.localizedStandardContains(searchText) ?? false) ||
                ($0.location?.localizedStandardContains(searchText) ?? false)
            }
        }
    }
    
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
    
    // Add loadEvents function
    private func loadEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            events = try await eventService.fetchEvents()
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading events: \(error)")
        }
        
        isLoading = false
    }
    
    var body: some View {
        NavigationView {
            Group { // Content that will have the large title and searchable bar
                if isLoading {
                    ProgressView("Loading events...")
                } else if let error = errorMessage {
                    VStack {
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await loadEvents()
                            }
                        }
                    }
                } else {
                    if isShowingList {
                        List(filteredEvents) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                HStack(alignment: .top, spacing: 16) {
                                    if let imageUrl = event.artistImageUrl {
                                        AsyncImage(url: imageUrl) {
                                            image in
                                            image.resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                        } placeholder: {
                                            ProgressView()
                                                .frame(width: 50, height: 50)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(event.title)
                                            .font(.headline)
                                        if let description = event.description {
                                            Text(description)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        HStack {
                                            Image(systemName: "calendar")
                                            Text(event.date, style: .date)
                                            Text(event.date, style: .time)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        
                                        if let location = event.location {
                                            HStack {
                                                Image(systemName: "location")
                                                Text(location)
                                            }
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        }
                                        
                                        if let deadline = event.registrationDeadline {
                                            HStack {
                                                Image(systemName: "clock")
                                                Text("Registration closes: \(deadline, style: .date)")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        }
                                        
                                        if let daysLeft = daysUntilClosing(for: event) {
                                            Text(daysLeft)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .refreshable {
                            await loadEvents()
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredEvents) { event in
                                    NavigationLink(destination: EventDetailView(event: event)) {
                                        VStack(spacing: 8) {
                                            if let imageUrl = event.artistImageUrl {
                                                AsyncImage(url: imageUrl) {
                                                    image in
                                                    image.resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(height: 100)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                    
                                                } placeholder: {
                                                    ProgressView()
                                                        .frame(height: 100)
                                                }
                                            }
                                            Text(event.title)
                                                .font(.headline)
                                                .lineLimit(1)
                                            
                                            if let location = event.location {
                                                Text(location)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                            
                                            if let deadline = event.registrationDeadline {
                                                Text("Closes: \(deadline, style: .date)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            if let daysLeft = daysUntilClosing(for: event) {
                                                Text(daysLeft)
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .refreshable {
                            await loadEvents()
                        }
                    }
                }
            }
            .navigationTitle("Events")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                Button {
                    isShowingList.toggle()
                } label: {
                    Image(systemName: isShowingList ? "square.grid.2x2" : "list.bullet")
                }
            }
            .task {
                print("ContentView: Task started")
                await loadEvents()
                print("ContentView: Task finished")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
