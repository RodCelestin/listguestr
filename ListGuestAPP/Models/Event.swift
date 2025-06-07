import Foundation

struct Event: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String?
    let date: Date
    let location: String?
    let createdAt: Date
    let artistImageUrlString: String?
    let registrationDeadline: Date?
    let genres: [String]?
    let capacity: Int?
    let note: String?
    
    var artistImageUrl: URL? {
        guard let urlString = artistImageUrlString, !urlString.isEmpty else {
            return nil
        }
        // Attempt to create a URL, handling potential failures
        return URL(string: urlString)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case date
        case location = "venue"
        case createdAt = "created_at"
        case artistImageUrlString = "spotify_artist_id"
        case registrationDeadline = "registration_deadline"
        case genres
        case capacity
        case note
    }
} 