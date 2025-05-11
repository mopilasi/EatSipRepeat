import SwiftUI

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Data Models
// Font extensions removed, use .custom() or add fonts to project.
// Color extensions removed, use Color.theme from Color+Theme.swift.

/// Data model for menu information (see `MenuCard` and `ContentView`).
/// Driven by your Airtable data and manually conformed to `Identifiable` and `Decodable`.
struct Menu: Identifiable {
    let id: UUID // Keep UUID for Menu, or change to String if also from Airtable with String ID
    let season: String
    let title: String
    let recipes: [Recipe] // This will now use the new Recipe struct
    
    enum CodingKeys: String, CodingKey {
        case id
        case season
        case title
        case recipes
    }
    
    init(
        id: UUID = UUID(),
        season: String,
        title: String,
        recipes: [Recipe]
    ) {
        self.id = id
        self.season = season
        self.title = title
        self.recipes = recipes
    }
    
    // Decoder init might need adjustment if Menu IDs also become strings from Airtable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID() // Or String if changed
        season = try container.decode(String.self, forKey: .season)
        title = try container.decode(String.self, forKey: .title)
        // Recipes will be decoded using the new Recipe.CodingKeys
        recipes = try container.decodeIfPresent([Recipe].self, forKey: .recipes) ?? [] 
    }
}

// MARK: - Sample Data
// Updated to reflect new Recipe structure. 
// Note: imageAttachments would typically come from a valid URL.
let sampleMenus: [Menu] = [
    Menu(
        season: "Spring", 
        title: "Spring Menu 1", 
        recipes: [
            Recipe(
                id: "spring_soup_01",
                title: "Pea & Mint Soup",
                course: "Starter",
                description: "A refreshing start to your spring meal.",
                imageAttachments: [Attachment(url: "placeholder_pea_soup_url")], // Replace with actual URLs
                sourceUrlString: "https://example.com/pea-soup",
                isSaved: false
            ),
            Recipe(
                id: "spring_chicken_02",
                title: "Lemon‑Herb Chicken",
                course: "Main",
                description: "Tender chicken with spring herbs and lemon.",
                imageAttachments: [Attachment(url: "placeholder_lemon_chicken_url")],
                sourceUrlString: "https://example.com/lemon-herb-chicken",
                isSaved: false
            ),
            Recipe(
                id: "spring_dessert_03",
                title: "Panna Cotta",
                course: "Dessert",
                description: "Creamy panna cotta with a berry coulis.",
                imageAttachments: [Attachment(url: "placeholder_panna_cotta_url")],
                sourceUrlString: "https://example.com/panna-cotta",
                isSaved: false
            )
        ]
    )
]

// MARK: - Button Styles
struct FilledCoralButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Druk Wide Bold", size: 16)) // Using .custom directly
            .foregroundColor(Color.theme.cream)       // Updated to Color.theme
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.lg)
            .background(Color.theme.primaryCoral.opacity(configuration.isPressed ? 0.85 : 1)) // Updated
            .clipShape(Capsule())
    }
}
