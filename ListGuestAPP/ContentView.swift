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
    @State private var isShowingFilterModal = false // State to control filter modal presentation
    @State private var appliedGenres: Set<String> = [] // State to store applied filters
    @State private var appliedEvents: [Event] = [] // State to store events the user has applied to
    @State private var selectedEvent: Event? = nil // State to control navigation to EventDetailView
    
    // Define columns for the grid view
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Computed property to filter events based on search text
    private var filteredEvents: [Event] {
        var eventsToFilter = events
        
        // Apply search text filter
        if !searchText.isEmpty {
            eventsToFilter = eventsToFilter.filter {
                $0.title.localizedStandardContains(searchText) ||
                ($0.description?.localizedStandardContains(searchText) ?? false) ||
                ($0.location?.localizedStandardContains(searchText) ?? false)
            }
        }
        
        // Apply genre filter if any genres are selected
        if !appliedGenres.isEmpty {
            eventsToFilter = eventsToFilter.filter {
                // An event is included if it has at least one genre that is in the appliedGenres set
                guard let eventGenres = $0.genres else { return false }
                return !appliedGenres.intersection(eventGenres).isEmpty
            }
        }
        
        return eventsToFilter
    }
    
    // Helper function to load applied events from UserDefaults
    private func loadAppliedEvents() {
        let appliedEventIDs = UserDefaults.standard.stringArray(forKey: "appliedEventIDs") ?? []
        appliedEvents = events.filter { event in
            appliedEventIDs.contains(event.id.uuidString)
        }
        print("Loaded applied events: \(appliedEvents.count)")
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
        print("ContentView: Task finished")
        loadAppliedEvents() // Load applied events after events are fetched
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
                        List {
                            // Section for Applied Events
                            if !appliedEvents.isEmpty {
                                Section(header: Text("Applied Events")) {
                                    ForEach(appliedEvents) {
                                        event in
                                        // Use selection and tag for programmatic navigation control
                                        NavigationLink(tag: event, selection: $selectedEvent) {
                                            EventDetailView(event: event, selectedEvent: $selectedEvent) // Pass selectedEvent binding
                                        } label: {
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
                                                    
                                                    // Add genre tags to list item
                                                    genreTagsView(genres: event.genres)
                                                        .padding(.bottom, 4)
                                                    
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
                                }
                            }
                            
                            // Section for Other Events (excluding applied ones)
                            Section(header: Text("All Events")) {
                                ForEach(filteredEvents.filter { event in
                                    !appliedEvents.contains(where: { $0.id == event.id })
                                }) { event in
                                    // Use selection and tag for programmatic navigation control
                                    NavigationLink(tag: event, selection: $selectedEvent) {
                                        EventDetailView(event: event, selectedEvent: $selectedEvent) // Pass selectedEvent binding
                                    } label: {
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
                                                
                                                // Add genre tags to list item
                                                genreTagsView(genres: event.genres)
                                                    .padding(.bottom, 4)
                                                
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
                            }
                        }
                        .refreshable {
                            await loadEvents()
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading) { // Use VStack to arrange sections vertically
                                // Section for Applied Events in Grid
                                if !appliedEvents.isEmpty {
                                    Text("Applied Events")
                                        .font(.title2)
                                        .padding(.horizontal)
                                        .padding(.top)
                                    
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(appliedEvents) {
                                            event in
                                            // Use selection and tag for programmatic navigation control
                                            NavigationLink(tag: event, selection: $selectedEvent) {
                                                EventDetailView(event: event, selectedEvent: $selectedEvent) // Pass selectedEvent binding
                                            } label: {
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
                                                    
                                                    // Add genre tags to grid item
                                                    genreTagsView(genres: event.genres)
                                                    
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
                                                    Spacer() // Push content to the top
                                                }
                                                .padding()
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(12)
                                                .frame(maxWidth: .infinity, minHeight: 150) // Ensure cards expand and have a minimum height
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // Section for Other Events in Grid
                                Text("All Events")
                                    .font(.title2)
                                    .padding(.horizontal)
                                    .padding(.top, appliedEvents.isEmpty ? 0 : 16) // Add top padding only if Applied Events section is present

                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(filteredEvents.filter { event in
                                        !appliedEvents.contains(where: { $0.id == event.id })
                                    }) { event in
                                        // Use selection and tag for programmatic navigation control
                                        NavigationLink(tag: event, selection: $selectedEvent) {
                                            EventDetailView(event: event, selectedEvent: $selectedEvent) // Pass selectedEvent binding
                                        } label: {
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
                                                
                                                // Add genre tags to grid item
                                                genreTagsView(genres: event.genres)
                                                
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
                                                Spacer() // Push content to the top
                                            }
                                            .padding()
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(12)
                                            .frame(maxWidth: .infinity, minHeight: 150) // Ensure cards expand and have a minimum height
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingFilterModal.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .overlay(
                                // Show a dot overlay if filters are applied
                                ZStack {
                                    if !appliedGenres.isEmpty {
                                        Circle()
                                            .fill(Color.blue) // Or another color to indicate active filter
                                            .frame(width: 8, height: 8)
                                            .offset(x: 8, y: -8) // Adjust position as needed
                                    }
                                }
                            )
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingList.toggle()
                    } label: {
                        Image(systemName: isShowingList ? "square.grid.2x2" : "list.bullet")
                    }
                }
                
                // Settings button
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .task {
                print("ContentView: Task started")
                await loadEvents()
                print("ContentView: Task finished")
            }
            .sheet(isPresented: $isShowingFilterModal) { // Present modal when isShowingFilterModal is true
                // Placeholder for the filter modal view
                FilterModalView(allEvents: events, initialSelectedGenres: appliedGenres) { selectedGenres in
                    appliedGenres = selectedGenres // Update appliedGenres when filters are applied
                }
                .presentationDetents([.medium, .large]) // Optional: customize modal size
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(EventService())
    }
}
