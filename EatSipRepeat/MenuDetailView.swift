import SwiftUI

struct MenuDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let menuTitle: String
    let recipes: [Recipe]                       // already fetched for this menu
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.theme.cream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom nav bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.theme.primaryCoral)
                    }
                    Text(menuTitle)
                        .font(.custom("Druk Wide Bold", size: 32))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Recipe pages
                
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
    }
}

// Preview - You might want to add one later
// struct MenuDetailView_Previews: PreviewProvider {
//     static var previews: some View {
//         // Sample data for preview
//         let sampleRecipes = [
//             Recipe(id: "1", title: "Recipe 1", course: "Main", description: "Desc 1", imageAttachments: [Attachment(url: "https://via.placeholder.com/300?text=Recipe+1")], sourceUrlString: "https://example.com"),
//             Recipe(id: "2", title: "Recipe 2", course: "Dessert", description: "Desc 2", imageAttachments: [Attachment(url: "https://via.placeholder.com/300?text=Recipe+2")], sourceUrlString: "https://example.com"),
//             Recipe(id: "3", title: "Recipe 3", course: "Appetizer", description: "Desc 3", imageAttachments: [Attachment(url: "https://via.placeholder.com/300?text=Recipe+3")], sourceUrlString: "https://example.com")
//         ]
//         MenuDetailView(menuTitle: "Sample Menu", recipes: sampleRecipes)
//     }
// }
