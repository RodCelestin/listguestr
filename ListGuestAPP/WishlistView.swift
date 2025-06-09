import SwiftUI

struct WishlistView: View {
    @EnvironmentObject private var eventService: EventService
    @Binding var wishlistEventIDs: Set<String>
    
    @State private var wishlistEvents: [Event] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading wishlist...")
            } else if let error = errorMessage {
                VStack {
                    Text("Error")
                        .font(.headline)
                    Text(error)
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await fetchWishlistEvents()
                        }
                    }
                }
            } else if wishlistEvents.isEmpty {
                ContentUnavailableView(
                    "Your Wishlist is Empty",
                    systemImage: "heart.slash",
                    description: Text("Swipe right on an event to add it to your wishlist.")
                )
            } else {
                List {
                    ForEach(wishlistEvents) { event in
                        // Similar row display as in ContentView, but simplified
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
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.headline)
                                Text(event.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                removeEventFromWishlist(event.id.uuidString)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Wishlist")
        .task {
            await fetchWishlistEvents()
        }
    }
    
    private func fetchWishlistEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            let allEvents = try await eventService.fetchEvents()
            wishlistEvents = allEvents.filter { event in
                wishlistEventIDs.contains(event.id.uuidString)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching wishlist events: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func removeEventFromWishlist(_ eventID: String) {
        if let index = wishlistEvents.firstIndex(where: { $0.id.uuidString == eventID }) {
            wishlistEvents.remove(at: index)
        }
        wishlistEventIDs.remove(eventID)
        UserDefaults.standard.set(Array(wishlistEventIDs), forKey: "wishlistEventIDs")
        print("Removed event \(eventID) from wishlist.")
    }
}

struct WishlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WishlistView(wishlistEventIDs: .constant(Set<String>()))
                .environmentObject(EventService()) // Provide EventService for preview
        }
    }
} 