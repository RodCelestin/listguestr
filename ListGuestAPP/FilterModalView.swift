//
//  FilterModalView.swift
//  ListGuestAPP
//
//  Created by Rodolphe Celestin on 2025-06-13.
//

import SwiftUI

struct FilterModalView: View {
    @Environment(\.dismiss) var dismiss
    let allEvents: [Event]
    @State private var selectedGenres: Set<String>
    let applyFilters: (Set<String>) -> Void // Completion handler to pass selected genres back
    
    // Initializer to accept initial selected genres
    init(allEvents: [Event], initialSelectedGenres: Set<String>, applyFilters: @escaping (Set<String>) -> Void) {
        self.allEvents = allEvents
        _selectedGenres = State(initialValue: initialSelectedGenres)
        self.applyFilters = applyFilters
    }
    
    // Computed property to get all unique genres
    private var uniqueGenres: [String] {
        Array(Set(allEvents.compactMap { $0.genres }.flatMap { $0 })).sorted()
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Filter by Genre")) {
                    ForEach(uniqueGenres, id: \.self) {
                        genre in
                        HStack {
                            Text(genre)
                            Spacer()
                            if selectedGenres.contains(genre) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle()) // Make the whole row tappable
                        .onTapGesture {
                            if selectedGenres.contains(genre) {
                                selectedGenres.remove(genre)
                            } else {
                                selectedGenres.insert(genre)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedGenres = [] // Clear all selected genres
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters(selectedGenres) // Call the completion handler
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterModalView_Previews: PreviewProvider {
    static var previews: some View {
        // Create some dummy events for the preview
        let dummyEvents = [
            Event(id: UUID(), title: "Concert", description: nil, date: Date(), location: "Venue A", createdAt: Date(), artistImageUrlString: nil, registrationDeadline: nil, genres: ["Rock", "Pop"]),
            Event(id: UUID(), title: "Art Exhibit", description: nil, date: Date(), location: "Gallery B", createdAt: Date(), artistImageUrlString: nil, registrationDeadline: nil, genres: ["Art"]),
            Event(id: UUID(), title: "Workshop", description: nil, date: Date(), location: "Online", createdAt: Date(), artistImageUrlString: nil, registrationDeadline: nil, genres: ["Tech", "Coding", "Design"]),
             Event(id: UUID(), title: "Festival", description: nil, date: Date(), location: "Park C", createdAt: Date(), artistImageUrlString: nil, registrationDeadline: nil, genres: ["Rock", "Outdoor"])
        ]
        // Pass a dummy set of selected genres for the preview
        FilterModalView(allEvents: dummyEvents, initialSelectedGenres: ["Rock", "Art"], applyFilters: { _ in })
    }
} 