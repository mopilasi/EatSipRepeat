import SwiftUI

struct RecipeCarouselPageView: View {
    @Environment(\.dismiss) private var dismiss
    let menuTitle: String
    let recipes: [Recipe]
    @Binding var savedRecipes: [Recipe]
    @State private var currentPage = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Custom Back Button
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Menus")
                    }
                }
                .padding([.leading, .top], Spacing.md)

                Text(menuTitle)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.lg)

                if recipes.isEmpty {
                    VStack {
                        Spacer()
                        Text("No recipes found in this menu.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    TabView(selection: $currentPage) {
                        ForEach(recipes.indices, id: \.self) { index in
                            let recipe = recipes[index]
                            let isSaved = savedRecipes.contains(where: { $0.id == recipe.id })
                            
                          
                   
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 500) // Adjust height as needed
                    .padding(.horizontal, Spacing.md)
                }

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

// Preview (optional, but helpful)
struct RecipeCarouselPageView_Previews: PreviewProvider {
    @State static var sampleSavedRecipes: [Recipe] = []
    // Simplified sample recipes for the preview, using the correct Recipe initializer
    static var sampleRecipesForPreview: [Recipe] = [
    ]

    static var previews: some View {
        RecipeCarouselPageView(
            menuTitle: "Preview Menu Title",
            recipes: sampleRecipesForPreview, // Use the well-defined array
            savedRecipes: $sampleSavedRecipes
        )
    }
}
