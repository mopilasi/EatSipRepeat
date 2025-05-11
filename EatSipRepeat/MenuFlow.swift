// MenuFlow.swift
// Models & services for fetching and generating 3 proposed menus

import Foundation
import SwiftUI

// MARK: — Airtable DTOs (private)
private struct AirtableResponse: Decodable {
    let records: [AirtableRecord]
}

private struct AirtableRecord: Decodable {
    let id: String
    let fields: Fields
}

private struct Fields: Decodable {
    let Title: String?
    let Season: String?
    let Course: String?
    let sourceURL: String?           // maps to "Source URL"
    let Image: [AirtableAttachment]? // maps to Image attachments

    private enum CodingKeys: String, CodingKey {
        case Title, Season, Course, Image
        case sourceURL = "Source URL"
    }
}

private struct AirtableAttachment: Decodable {
    let url: String
}

// MARK: — RecipeService

/// Fetches Recipe models from your Airtable base by season tag
final class RecipeService {
    static let shared = RecipeService()
    private init() {}

    private let apiKey = "patnKF1hl3tiA3ohM.f400040c37d715cb1ca8ccbfc627a0f12e0a746a21dad296d99059384b238685"
    private let baseID = "appkaRHmM4gTj9E4m"
    private let tableName = "Recipes"

    /// Returns all recipes matching the given season (e.g. "Spring").
    func fetchRecipes(for season: String) async throws -> [Recipe] {
        var components = URLComponents(string: "https://api.airtable.com/v0/\(baseID)/\(tableName)")!
        components.queryItems = [
            URLQueryItem(name: "filterByFormula", value: "Season='\(season)'" )
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(AirtableResponse.self, from: data)
        return result.records.compactMap { rec in
            guard
                let title = rec.fields.Title,
                let course = rec.fields.Course,
                let src = rec.fields.sourceURL
            else { return nil }

            let attachments = rec.fields.Image?
                .compactMap { Attachment(url: $0.url) } ?? []

            return Recipe(
                id: rec.id,
                title: title,
                course: course,
                description: "",
                imageAttachments: attachments,
                sourceUrlString: src
            )
        }
    }
}

// MARK: — MenuService

/// Generates `count` random menus (one Starter, Main, Dessert each) from a flat recipe list.
struct MenuService {
    static func generateMenus(from recipes: [Recipe], season: String, count: Int = 3) -> [Menu] {
        let starters = recipes.filter { $0.course == "Starter" }
        let mains    = recipes.filter { $0.course == "Main" }
        let desserts = recipes.filter { $0.course == "Dessert" }

        guard !starters.isEmpty, !mains.isEmpty, !desserts.isEmpty else {
            return []
        }

        return (1...count).map { idx in
            let s = starters.randomElement()!
            let m = mains.randomElement()!
            let d = desserts.randomElement()!
            return Menu(
                id: UUID(),
                season: season,
                title: "\(season) Menu \(idx)",
                recipes: [s, m, d]
            )
        }
    }
}

// MARK: — ViewModel

@MainActor
class MenuViewModel: ObservableObject {
    @Published var menus: [Menu] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Load three menus for the given season
    func loadMenus(for season: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let all = try await RecipeService.shared.fetchRecipes(for: season)
            menus = MenuService.generateMenus(from: all, season: season)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
