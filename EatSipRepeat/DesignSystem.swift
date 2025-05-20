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
struct Menu: Identifiable, Decodable, Equatable, Hashable {
    let id: UUID
    let season: String
    let title: String
    let recipes: [Recipe]
    
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        season = try container.decode(String.self, forKey: .season)
        title = try container.decode(String.self, forKey: .title)
        recipes = try container.decodeIfPresent([Recipe].self, forKey: .recipes) ?? []
    }
}

// MARK: - Sample Data
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
                imageAttachments: [Attachment(url: "placeholder_pea_soup_url")],
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
            .font(.custom("Druk Wide Bold", size: 16))
            .foregroundColor(Color.theme.cream)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.lg)
            .background(Color.theme.primaryCoral.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(Capsule())
    }
}