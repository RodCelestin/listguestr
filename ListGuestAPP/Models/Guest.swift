import Foundation

struct Guest: Identifiable, Codable {
    let id: UUID? // Supabase will generate this on insert
    let event_id: UUID
    let full_name: String
    let role: String?
    let company: String?
    let email: String
    let additional_request: String?
    let created_at: Date? // Supabase can auto-generate this
    
    // CodingKeys to map Swift property names to database column names
    enum CodingKeys: String, CodingKey {
        case id
        case event_id
        case full_name = "name"
        case role
        case company
        case email
        case additional_request = "request"
        case created_at
    }
} 