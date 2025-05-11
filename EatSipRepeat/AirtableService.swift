import Foundation
import Combine

// MARK: - Airtable Response Models
struct AirtableResponse<T: Codable>: Codable {
    let records: [AirtableRecord<T>]
    let offset: String?
    
    enum CodingKeys: String, CodingKey {
        case records
        case offset
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        records = try container.decode([AirtableRecord<T>].self, forKey: .records)
        offset = try container.decodeIfPresent(String.self, forKey: .offset)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(records, forKey: .records)
        
        if let offset = offset {
            try container.encode(offset, forKey: .offset)
        }
    }
}

struct AirtableRecord<T: Codable>: Codable {
    let id: String
    let fields: T
    let createdTime: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case fields
        case createdTime
    }
}

// MARK: - Airtable Request Models
struct AirtableCreateRequest<T: Codable>: Codable {
    let records: [AirtableCreateRecord<T>]
}

struct AirtableCreateRecord<T: Codable>: Codable {
    let fields: T
}

// MARK: - AirtableService
class AirtableService {
    private let baseID: String
    private let apiKey: String
    private let session: URLSession
    
    init(
        baseID: String = ProcessInfo.processInfo.environment["AIRTABLE_BASE_ID"] ?? "",
        apiKey: String = ProcessInfo.processInfo.environment["AIRTABLE_API_KEY"] ?? "",
        session: URLSession = .shared
    ) {
        self.baseID = baseID
        self.apiKey = apiKey
        self.session = session
    }
    
    // Generic fetch method
    func fetchRecords<T: Codable>(
        tableName: String,
        type: T.Type,
        completion: @escaping (Result<[T], Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.airtable.com/v0/\(baseID)/\(tableName)") else {
            completion(.failure(NSError(domain: "AirtableService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AirtableService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let airtableResponse = try JSONDecoder().decode(AirtableResponse<T>.self, from: data)
                let records = airtableResponse.records.map { $0.fields }
                completion(.success(records))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // Generic create method
    func createRecord<T: Codable>(
        tableName: String,
        record: T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.airtable.com/v0/\(baseID)/\(tableName)") else {
            completion(.failure(NSError(domain: "AirtableService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let createRequest = AirtableCreateRequest(records: [AirtableCreateRecord(fields: record)])
        
        do {
            request.httpBody = try JSONEncoder().encode(createRequest)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AirtableService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let airtableResponse = try JSONDecoder().decode(AirtableResponse<T>.self, from: data)
                let createdRecord = airtableResponse.records.first?.fields
                
                if let createdRecord = createdRecord {
                    completion(.success(createdRecord))
                } else {
                    completion(.failure(NSError(domain: "AirtableService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No record created"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

// Example usage for Recipe
extension Recipe {
    struct AirtableFields: Codable {
        let title: String
        let course: String
        let imageURL: String?
        let sourceURL: String?
        
        enum CodingKeys: String, CodingKey {
            case title
            case course
            case imageURL
            case sourceURL
        }
        
        init(
            title: String,
            course: String,
            imageURL: String? = nil,
            sourceURL: String? = nil
        ) {
            self.title = title
            self.course = course
            self.imageURL = imageURL
            self.sourceURL = sourceURL
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            title = try container.decode(String.self, forKey: .title)
            course = try container.decode(String.self, forKey: .course)
            imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
            sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(title, forKey: .title)
            try container.encode(course, forKey: .course)
            
            if let imageURL = imageURL {
                try container.encode(imageURL, forKey: .imageURL)
            }
            
            if let sourceURL = sourceURL {
                try container.encode(sourceURL, forKey: .sourceURL)
            }
        }
    }
}
