// MenuFlow.swift
// Models & services for fetching and generating 3 proposed menus
// MODIFIED: Now fetches pre-defined menus from "Curated Menus" table.

import Foundation
import SwiftUI

// MARK: — Airtable DTOs (private)
private struct AirtableResponse: Decodable {
    let records: [AirtableRecord]
}

private struct AirtableRecord: Decodable {
    let id: String // Airtable record ID for the curated menu
    let fields: Fields
}

// MODIFIED: Fields struct to match "Curated Menus" table
private struct Fields: Decodable {
    let season: String?
    let menuName: String?
    let starterName: String?
    let starterURL: String?
    let starterDescription: String?
    let mainName: String?
    let mainURL: String?
    let mainDescription: String?
    let dessertName: String?
    let dessertURL: String?
    let dessertDescription: String?
    // Assuming no direct image attachment fields for individual recipes in "Curated Menus"

    private enum CodingKeys: String, CodingKey {
        case season = "Season"
        case menuName = "Menu Name"
        case starterName = "Starter Name"
        case starterURL = "Starter URL"
        case starterDescription = "Starter Description"
        case mainName = "Main Name"
        case mainURL = "Main URL"
        case mainDescription = "Main Description"
        case dessertName = "Dessert Name"
        case dessertURL = "Dessert URL"
        case dessertDescription = "Dessert Description"
    }
}

// MARK: — CuratedMenuService (MODIFIED from RecipeService)

/// Fetches Menu models from your "Curated Menus" Airtable base by season tag
final class CuratedMenuService { // RENAMED and MODIFIED
    static let shared = CuratedMenuService()
    private init() {}

    // MODIFIED: Load API Key from AirtableConfig.plist
    private var apiKey: String {
        guard let filePath = Bundle.main.path(forResource: "AirtableConfig", ofType: "plist") else {
            fatalError("Couldn't find file 'AirtableConfig.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "API_KEY") as? String else {
            fatalError("Couldn't find key 'API_KEY' in 'AirtableConfig.plist'.")
        }
        if value.starts(with: "YOUR_") {
            fatalError("Please replace 'YOUR_ACTUAL_AIRTABLE_API_KEY' in 'AirtableConfig.plist' with your actual Airtable API key.")
        }
        return value
    }
    private let baseID = "appkaRHmM4gTj9E4m"
    private let tableName = "Curated Menus" // MODIFIED: Table name

    /// Returns all menus matching the given season (e.g. "Spring").
    func fetchCuratedMenus(for season: String) async throws -> [Menu] { // MODIFIED: Return type and logic
        var components = URLComponents(string: "https://api.airtable.com/v0/\(baseID)/\(tableName)")!
        components.queryItems = [
            URLQueryItem(name: "filterByFormula", value: "Season='\(season)'" )
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            // Consider more detailed error handling, e.g., decoding Airtable error response
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(AirtableResponse.self, from: data)
        return result.records.compactMap { rec in
            guard
                let menuAirtableId = rec.id as String?, // Capture Airtable ID for the menu record
                let menuTitle = rec.fields.menuName,
                let menuSeason = rec.fields.season,
                // Starter fields
                let starterTitle = rec.fields.starterName,
                let starterUrl = rec.fields.starterURL,
                let starterDesc = rec.fields.starterDescription,
                // Main fields
                let mainTitle = rec.fields.mainName,
                let mainUrl = rec.fields.mainURL,
                let mainDesc = rec.fields.mainDescription,
                // Dessert fields
                let dessertTitle = rec.fields.dessertName,
                let dessertUrl = rec.fields.dessertURL,
                let dessertDesc = rec.fields.dessertDescription
            else {
                // Log an error or handle missing essential fields
                print("Skipping record due to missing fields: \(rec.id)")
                return nil
            }

            // Create Recipe objects for Starter, Main, and Dessert
            // Using menuAirtableId to create unique-enough IDs for child recipes
            let starterRecipe = Recipe(
                id: "\(menuAirtableId)-starter",
                title: starterTitle,
                course: "Starter",
                description: starterDesc,
                imageAttachments: [], // Assuming no specific image attachment fields in "Curated Menus"
                sourceUrlString: starterUrl
            )

            let mainRecipe = Recipe(
                id: "\(menuAirtableId)-main",
                title: mainTitle,
                course: "Main",
                description: mainDesc,
                imageAttachments: [],
                sourceUrlString: mainUrl
            )

            let dessertRecipe = Recipe(
                id: "\(menuAirtableId)-dessert",
                title: dessertTitle,
                course: "Dessert",
                description: dessertDesc,
                imageAttachments: [],
                sourceUrlString: dessertUrl
            )

            return Menu(
                id: UUID(), // Using UUID for Menu ID as per original Menu struct design
                season: menuSeason,
                title: menuTitle,
                recipes: [starterRecipe, mainRecipe, dessertRecipe]
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

    /// Load menus for the given season from "Curated Menus"
    func loadMenus(for season: String) async {
        isLoading = true
        errorMessage = nil
        do {
            // MODIFIED: Call the new service and assign directly
            menus = try await CuratedMenuService.shared.fetchCuratedMenus(for: season)
        } catch {
            self.errorMessage = error.localizedDescription // Provide more specific error if possible
        }
        isLoading = false
    }
}

// IMPORTANT: This code assumes the existence of `Recipe` and `Menu` structs
// defined elsewhere in your project, with at least the following properties:
//
// struct Recipe: Identifiable { // Identifiable if used in SwiftUI lists directly
//     let id: String // Or UUID, ensure consistency
//     let title: String
//     let course: String
//     let description: String
//     let imageAttachments: [Attachment] // Assuming Attachment struct { let url: String }
//     let sourceUrlString: String
// }
//
// struct Menu: Identifiable { // Identifiable if used in SwiftUI lists directly
//     let id: UUID
//     let season: String
//     let title: String
//     let recipes: [Recipe]
// }
//
// struct Attachment: Identifiable { // Example, if needed for imageAttachments
//     let id = UUID()
//     let url: String
// }
// Ensure these structs are defined and match the usage above.
