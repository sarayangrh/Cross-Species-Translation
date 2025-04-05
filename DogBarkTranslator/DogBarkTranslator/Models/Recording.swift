import Foundation

struct Recording: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let audioURL: URL
    let predictions: [String]
    let title: String
    var notes: String
    let photoURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case audioURL
        case predictions
        case title
        case notes
        case photoURL
    }
} 