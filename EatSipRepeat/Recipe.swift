import Foundation

/// 1 attachment in Airtable’s “Image” field → `url` string
struct Attachment: Decodable, Equatable, Hashable { let url: String }

struct Recipe: Decodable, Identifiable, Equatable, Hashable {
    let id: String                           // Airtable “id”
    let title: String                        // “Title”
    let course: String                       // “Course”
    let description: String                  // “Description”
    let imageAttachments: [Attachment]?      // “Image”
    let sourceUrlString: String?             // “Source URL”
    var isSaved: Bool = false                // local state

    enum CodingKeys: String, CodingKey {
        case id
        case title        = "Title"
        case course       = "Course"
        case description  = "Description"
        case imageAttachments = "Image"
        case sourceUrlString  = "Source URL"
    }

    /// Convenience helpers
    var imageURL: URL?   { URL(string: imageAttachments?.first?.url ?? "") }
    var sourceURL: URL?  { URL(string: sourceUrlString ?? "") }
}
