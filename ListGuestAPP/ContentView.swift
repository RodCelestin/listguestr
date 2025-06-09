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
    @State private var wishlistEventIDs: Set<String> = [] {
        didSet {
            saveWishlistEvents()
        }
    } // State to store wishlist event IDs
    @State private var isShowingToast: Bool = false
    @State private var toastMessage: String = ""
    
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
    
    private var registrationClosingSoonEvents: [Event] {
        filteredEvents.filter {
            guard let deadline = $0.registrationDeadline else { return false }
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: Date(), to: deadline)
            return (components.day ?? 0) >= 0 && (components.day ?? 0) <= 7
        }
    }
    
    // Helper function to load applied events from UserDefaults
    private func loadAppliedEvents() {
        let appliedEventIDs = UserDefaults.standard.stringArray(forKey: "appliedEventIDs") ?? []
        appliedEvents = events.filter { event in
            appliedEventIDs.contains(event.id.uuidString)
        }
        print("Loaded applied events: \(appliedEvents.count)")
    }
    
    // Helper function to load wishlist events from UserDefaults
    private func loadWishlistEvents() {
        let storedWishlistIDs = UserDefaults.standard.stringArray(forKey: "wishlistEventIDs") ?? []
        wishlistEventIDs = Set(storedWishlistIDs)
        print("Loaded wishlist events: \(wishlistEventIDs.count)")
    }
    
    // Helper function to save wishlist events to UserDefaults
    private func saveWishlistEvents() {
        UserDefaults.standard.set(Array(wishlistEventIDs), forKey: "wishlistEventIDs")
        print("Saved wishlist event IDs: \(wishlistEventIDs.count)")
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
        loadWishlistEvents() // Load wishlist events after events are fetched
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
                                            EventDetailView(event: event, selectedEvent: $selectedEvent, wishlistEventIDs: $wishlistEventIDs, isShowingToast: $isShowingToast, toastMessage: $toastMessage) // Pass selectedEvent binding
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
                            
                            // Section for Events Closing Soon
                            if !registrationClosingSoonEvents.isEmpty {
                                Section(header: Text("Registration Closing Soon")) {
                                    ForEach(registrationClosingSoonEvents) { event in
                                        NavigationLink(tag: event, selection: $selectedEvent) {
                                            EventDetailView(event: event, selectedEvent: $selectedEvent, wishlistEventIDs: $wishlistEventIDs, isShowingToast: $isShowingToast, toastMessage: $toastMessage)
                                        } label: {
                                            HStack(alignment: .top, spacing: 16) {
                                                if let imageUrl = event.artistImageUrl {
                                                    AsyncImage(url: imageUrl) { image in
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
                                                            .foregroundColor(.red)
                                                    }
                                                }
                                                .padding(.vertical, 4)
                                            }
                                        }
                                        .swipeActions(edge: .trailing) {
                                            if !wishlistEventIDs.contains(event.id.uuidString) {
                                                Button {
                                                    wishlistEventIDs.insert(event.id.uuidString)
                                                    toastMessage = "'\(event.title)' added to wishlist!"
                                                    isShowingToast = true
                                                } label: {
                                                    Label("Wishlist", systemImage: "heart")
                                                }
                                                .tint(.pink)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Section for Other Events (excluding applied ones)
                            Section(header: Text("All Events")) {
                                ForEach(filteredEvents.filter { event in
                                    !appliedEvents.contains(where: { $0.id == event.id }) && !registrationClosingSoonEvents.contains(where: { $0.id == event.id })
                                }) { event in
                                    // Use selection and tag for programmatic navigation control
                                    NavigationLink(tag: event, selection: $selectedEvent) {
                                        EventDetailView(event: event, selectedEvent: $selectedEvent, wishlistEventIDs: $wishlistEventIDs, isShowingToast: $isShowingToast, toastMessage: $toastMessage) // Pass selectedEvent binding
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
                                        .swipeActions(edge: .trailing) {
                                            if !wishlistEventIDs.contains(event.id.uuidString) {
                                                Button {
                                                    wishlistEventIDs.insert(event.id.uuidString)
                                                    toastMessage = "'\(event.title)' added to wishlist!"
                                                    isShowingToast = true
                                                } label: {
                                                    Label("Wishlist", systemImage: "heart")
                                                }
                                                .tint(.pink)
                                            }
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
                                                EventDetailView(event: event, selectedEvent: $selectedEvent, wishlistEventIDs: $wishlistEventIDs, isShowingToast: $isShowingToast, toastMessage: $toastMessage) // Pass selectedEvent binding
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
                                }
                                
                                // Section for Events Closing Soon in Grid
                                if !registrationClosingSoonEvents.isEmpty {
                                    Text("Registration Closing Soon")
                                        .font(.title2)
                                        .padding(.horizontal)
                                        .padding(.top, appliedEvents.isEmpty ? 0 : 16) // Add top padding only if Applied Events section is present

                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(registrationClosingSoonEvents) { event in
                                            NavigationLink(tag: event, selection: $selectedEvent) {
                                                EventDetailView(event: event, selectedEvent: $selectedEvent, wishlistEventIDs: $wishlistEventIDs, isShowingToast: $isShowingToast, toastMessage: $toastMessage) // Pass selectedEvent binding
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
                                                            .foregroundColor(.red)
                                                    }
                                                    
                                                    if let daysLeft = daysUntilClosing(for: event) {
                                                        Text(daysLeft)
                                                            .font(.caption)
                                                            .foregroundColor(.red)
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
                                }
                                
                                // Section for Other Events in Grid
                                Text("All Events")
                                    .font(.title2)
                                    .padding(.horizontal)
                                    .padding(.top, (appliedEvents.isEmpty && registrationClosingSoonEvents.isEmpty) ? 0 : 16) // Adjust top padding

                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(filteredEvents.filter { event in
                                        !appliedEvents.contains(where: { $0.id == event.id }) && !registrationClosingSoonEvents.contains(where: { $0.id == event.id })
                                    }) { event in
                                        // Use selection and tag for programmatic navigation control
                                        NavigationLink(tag: event, selection: $selectedEvent) {
                                            EventDetailView(event: event, selectedEvent: $selectedEvent, wishlistEventIDs: $wishlistEventIDs, isShowingToast: $isShowingToast, toastMessage: $toastMessage) // Pass selectedEvent binding
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
                                        .swipeActions(edge: .trailing) {
                                            if !wishlistEventIDs.contains(event.id.uuidString) {
                                                Button {
                                                    wishlistEventIDs.insert(event.id.uuidString)
                                                    toastMessage = "'\(event.title)' added to wishlist!"
                                                    isShowingToast = true
                                                } label: {
                                                    Label("Wishlist", systemImage: "heart")
                                                }
                                                .tint(.pink)
                                            }
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
                
                // Wishlist button
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        WishlistView(wishlistEventIDs: $wishlistEventIDs)
                    } label: {
                        Image(systemName: "heart.fill")
                    }
                }
            }
            .sheet(isPresented: $isShowingFilterModal) { // Present modal when isShowingFilterModal is true
                // Placeholder for the filter modal view
                FilterModalView(allEvents: events, initialSelectedGenres: appliedGenres) { selectedGenres in
                    appliedGenres = selectedGenres // Update appliedGenres when filters are applied
                }
                .presentationDetents([.medium, .large]) // Optional: customize modal size
            }
        }
        .task {
            print("ContentView: Task started for initial load.")
            await loadEvents()
        }
        .overlay(alignment: .bottom) {
            if isShowingToast {
                ToastView(message: toastMessage, isShowing: $isShowingToast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1) // Ensure the toast is on top of other content
            }
        }
    }
}

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
                .padding(.bottom, 20) // Adjust padding from bottom edge
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isShowing = false
                        }
                    }
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
