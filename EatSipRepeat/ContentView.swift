import SwiftUI

// Helper struct to store carousel state per season
private struct SeasonCarouselState {
    var currentPage: Int = 0
    var visitedPages: Set<Int> = [0] // Start with page 0 visited
}

struct ContentView: View {
    // MARK: — UI State
    @State private var selectedSeason: String = "Spring"
    @State private var isSideMenuPresented = false
    
    // These will now reflect the state for the *current* selectedSeason
    @State private var currentPage: Int = 0 
    @State private var visitedPages: Set<Int> = [0]

    // Storage for carousel state across different seasons
    @State private var seasonCarouselStates: [String: SeasonCarouselState] = [:]

    @State private var showComingSoonSheet = false // New state for the sheet

    // MARK: — ViewModel
    @StateObject private var viewModel = MenuViewModel()

    // Computed property for the items to display in the TabView
    private var carouselPages: [CarouselPageItem] {
        var items: [CarouselPageItem] = viewModel.menus.map { .menu($0) }
        // Always add the "Add Action" card if there are any menus for the current season.
        if !viewModel.menus.isEmpty {
            items.append(.addAction)
        }
        return items
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // ─── Background
                Color.theme.cream
                    .ignoresSafeArea()

                // ─── Main content
                VStack(spacing: Spacing.lg) {
                    // Header
                    HStack {
                        Button {
                            withAnimation { isSideMenuPresented.toggle() }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(Color.theme.forestGreen)
                        }

                        Spacer()

                        Text("Menus")
                            .font(.custom("DrukWide-Bold", size: 34))
                            .foregroundColor(Color.theme.forestGreen)

                        Spacer()

                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 24, height: 24)
                    }
                    .padding(.horizontal, Spacing.md)

                    // Season picker
                    SeasonPicker(selected: $selectedSeason)

                    // Loading / Error
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                    if let err = viewModel.errorMessage {
                        Text(err)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Container for menu display area (TabView, Loading, Empty State)
                    ZStack {
                        TabView(selection: $currentPage) {
                            if viewModel.isLoading || viewModel.menus.isEmpty {
                                // Placeholder view (shown if loading OR if not loading & menus are empty)
                                VStack {
                                    Spacer()
                                    Text(viewModel.isLoading ? "Loading Menus..." : "No menus available for \(selectedSeason).")
                                        .font(.custom("Inter-Regular", size: 16))
                                        .foregroundColor(Color.theme.cream)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, Spacing.md)
                                .frame(height: 260)
                                .tag(-1) // Special tag for this placeholder page
                            } else {
                                // Iterate over the combined list of menus and the potential action card
                                ForEach(Array(carouselPages.enumerated()), id: \.element.id) { index, pageItem in
                                    switch pageItem {
                                    case .menu(let menu):
                                        MenuCard(menu: menu, isActive: index == currentPage)
                                            .padding(.horizontal, Spacing.md)
                                            .frame(height: 260)
                                            .frame(maxWidth: .infinity)
                                            .tag(index) // Tag with the index from carouselPages
                                    case .addAction:
                                        AddActionCardView {
                                            showComingSoonSheet = true
                                        }
                                        .padding(.horizontal, Spacing.md)
                                        .frame(height: 260)
                                        .frame(maxWidth: .infinity)
                                        .tag(index) // Tag with the index from carouselPages
                                    }
                                }
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hide default indicator
                        .id(viewModel.isLoading)

                        if viewModel.isLoading {
                            // Opaque Loading Overlay
                            Color.theme.cream
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.theme.cream))
                        }
                    }
                    .frame(height: 280)
                    .padding(.vertical, Spacing.md) // Apply vertical padding to the ZStack
                    .onChange(of: selectedSeason) { oldValue, newValue in
                        // Save state for the season we are leaving (oldValue)
                        if !oldValue.isEmpty {
                            seasonCarouselStates[oldValue] = SeasonCarouselState(currentPage: currentPage, visitedPages: visitedPages)
                        }
                        
                        // Trigger loading for the new season in an async Task
                        Task {
                            await viewModel.loadMenus(for: newValue)
                        }

                        // Load state for the new season (newValue) or initialize it
                        if let savedState = seasonCarouselStates[newValue] {
                            currentPage = savedState.currentPage
                            visitedPages = savedState.visitedPages
                        } else {
                            currentPage = 0
                            visitedPages = [0] // Default for a new/unvisited season
                        }
                    }
                    .onChange(of: currentPage) { oldValue, newPage in
                        // Add the new page to visitedPages if it's a valid menu item index
                        if newPage >= 0 && newPage < viewModel.menus.count { // Only track actual menu indices
                            visitedPages.insert(newPage)
                        }
                    }
                    .onAppear {
                        // Initial load for the default selected season in an async Task
                        if viewModel.menus.isEmpty {
                            Task {
                                await viewModel.loadMenus(for: selectedSeason)
                            }
                        }
                        // Initialize state for the first season if it's not already there
                        if seasonCarouselStates[selectedSeason] == nil {
                            seasonCarouselStates[selectedSeason] = SeasonCarouselState(currentPage: 0, visitedPages: [0])
                        }
                    }
                    
                    // Custom Page Indicator View
                    // Show only if not loading and there are pages to indicate
                    if !viewModel.isLoading && !carouselPages.isEmpty && carouselPages.count > 1 {
                        CustomPageIndicatorView(numberOfPages: carouselPages.count, currentPage: $currentPage)
                            .padding(.bottom, Spacing.sm) // Add some padding
                    }

                    Spacer()

                    // ─── Side menu overlay & panel
                    if isSideMenuPresented {
                        Color.theme.forestGreen
                            .opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { isSideMenuPresented = false }
                            }

                        SideMenuView(isShowing: $isSideMenuPresented)
                            .transition(.move(edge: .leading))
                            .zIndex(1)
                    }
                }
                .padding(.top, Spacing.xl)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showComingSoonSheet) {
                ComingSoonView()
            }
            .task(id: selectedSeason) {
                // The responsibility of setting currentPage and visitedPages is now handled by 
                // .onChange(of: selectedSeason). This task just loads data.
                await viewModel.loadMenus(for: selectedSeason)
            }
        }
    }
}

// MARK: - ComingSoonView (New View)

private struct ComingSoonView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView { // Optional: if you want a navigation bar for the Done button
            VStack(alignment: .center, spacing: Spacing.lg) {
                Spacer()

                Image("UnderConstruction") // Make sure this image exists in your Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170) // Adjust size as needed
                    .padding(.bottom, Spacing.md)

                Text("Feature Coming Soon!")
                    .font(.custom("DrukWide-Bold", size: 26)) // Example font, adjust as needed
                    .foregroundColor(Color.theme.forestGreen)
                    .multilineTextAlignment(.center)

                Text("We’re teaching the app to stir the pot — expect brand‑new menus to land in a future future!")
                    .font(.custom("Inter-Regular", size: 16)) // Example font
                    .foregroundColor(Color.theme.primaryCoral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                
                Spacer()
                Spacer()

            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.theme.cream.ignoresSafeArea()) // Match your app's theme
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Inter-Semibold", size: 16))
                    .foregroundColor(Color.theme.primaryCoral)
                }
            }
            // If not using NavigationView for the toolbar, you might place a button directly in the VStack:
            // Button("OK") { dismiss() }.buttonStyle(FilledCoralButton()).padding(.top)
        }
    }
}

// MARK: - Custom Page Indicator View
private struct CustomPageIndicatorView: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    
    let activeDotColor: Color = Color.theme.primaryCoral
    let inactiveDotColor: Color = Color.gray.opacity(0.5) // Or another subtle color
    let dotSize: CGFloat = 8
    let activeDotScale: CGFloat = 1.0 // Could make active dot larger if desired
    let spacing: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                if index == currentPage {
                    Circle()
                        .fill(activeDotColor)
                        .frame(width: dotSize * activeDotScale, height: dotSize * activeDotScale)
                } else {
                    Circle()
                        .strokeBorder(inactiveDotColor, lineWidth: 1)
                        .frame(width: dotSize, height: dotSize)
                }
            }
        }
    }
}

// MARK: – SeasonPicker (unchanged)
struct SeasonPicker: View {
    @Binding var selected: String
    private let seasons = ["Spring", "Summer", "Autumn", "Winter"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(seasons, id: \.self) { s in
                Button {
                    withAnimation(.spring()) { selected = s }
                } label: {
                    Text(s)
                        .font(.custom("Inter-Regular", size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(selected == s ? Color.theme.forestGreen : Color.clear)
                        .foregroundColor(
                            selected == s
                                ? Color.theme.cream
                                : Color.theme.forestGreen
                        )
                }
                .clipShape(Capsule())
            }
        }
        .padding(4)
        .overlay(
            Capsule().stroke(Color.theme.forestGreen, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.md)
        .frame(height: 44)
    }
}

// MARK: – MenuCard (for carousel, roomy & clear)
private struct MenuCard: View {
    let menu: Menu
    let isActive: Bool

    @State private var cardOpacity: Double = 0 

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) { // Main VStack for the card
            // Title
            Text(menu.title)
                .font(.custom("DrukWide-Bold", size: 24))
                .foregroundColor(Color.theme.forestGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading) // Ensure title area takes full width

            // Three rows, each with a bold label + wrapped body text
            VStack(alignment: .leading, spacing: Spacing.sm) {
                row(label: "Starter", text: menu.recipes.first { $0.course == "Starter" }?.title)
                row(label: "Main",    text: menu.recipes.first { $0.course == "Main" }?.title)
                row(label: "Dessert", text: menu.recipes.first { $0.course == "Dessert" }?.title)
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Ensure recipe rows area takes full width
            
            Spacer() // Pushes content above it to the top of the card's frame
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity) // Ensure the VStack itself tries to take max width *within the padding*
        .background(Color(hex: "#C7B89C")) // Darkened background for better contrast
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .opacity(cardOpacity) // Apply opacity to the whole card
        .onChange(of: isActive) { oldIsActive, newIsActive in
            if newIsActive {
                // Animate in card opacity
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                    cardOpacity = 1 
                }
            } else {
                // Reset card opacity (can be animated out or instant)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) { // Optional: animate out
                    cardOpacity = 0
                }
            }
        }
        // Trigger initial animation if card is already active on appear
        .onAppear {
            if isActive {
                // Using a slight delay to ensure the view is ready for animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        cardOpacity = 1
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(label: String, text: String?) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(label)
                .font(.custom("Inter-Semibold", size: 16))
                .foregroundColor(Color.theme.forestGreen)
                .frame(width: 75, alignment: .leading)

            Text(text ?? "")
                .font(.custom("Inter-Semibold", size: 18)) // Updated font size and weight
                .foregroundColor(Color.theme.forestGreen)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading) // Ensure recipe title takes available width in HStack
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure HStack row takes full width
    }
}

// MARK: – Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Enum to define the type of content for each carousel page
private enum CarouselPageItem: Identifiable, Hashable {
    case menu(Menu)
    case addAction
    
    var id: String {
        switch self {
        case .menu(let menu):
            return menu.id.uuidString // Convert UUID to String
        case .addAction:
            return "addActionCard"
        }
    }
}

// View for the "Add New Menu" card in the carousel
private struct AddActionCardView: View {
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "plus.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60) // Adjusted size
                .foregroundColor(Color.theme.primaryCoral)
            
            Text("Generate New Menus")
                .font(.custom("Inter-Semibold", size: 18))
                .foregroundColor(Color.theme.forestGreen)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it fills available space like MenuCard
        .background(Color(hex: "#C7B89C")) // Consistent background
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle()) // Make the whole area tappable
        .onTapGesture {
            onTap()
        }
    }
}
