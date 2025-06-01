import Foundation
import Supabase

class EventService: ObservableObject {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseKey
        )
    }
    
    @MainActor
    func fetchEvents() async throws -> [Event] {
        print("EventService: fetchEvents() called")
        do {
            let response: [Event] = try await client
                .database
                .from("events")
                .select("*, venue")
                .order("date", ascending: true)
                .execute()
                .value
            
            print("EventService: Fetched Events:")
            for event in response {
                print("  Event Title: \(event.title), Location: \(event.location ?? "N/A")")
            }
            
            print("EventService: fetchEvents() succeeded")
            return response
        } catch {
            print("EventService: fetchEvents() failed with error: \(error.localizedDescription)")
            throw error
        }
    }
} 