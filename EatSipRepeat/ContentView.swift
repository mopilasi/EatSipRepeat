import SwiftUI

// MARK: – SeasonCarouselState
private struct SeasonCarouselState {
    var currentPage: Int = 0
    var visitedPages: Set<Int> = [0]
}

// MARK: – ContentView
struct ContentView: View {
    // UI State
    @State private var selectedSeason: String = "Spring"
    @State private var isSideMenuPresented = false
    @State private var currentPage: Int = 0
    @State private var visitedPages: Set<Int> = [0]
    @State private var seasonCarouselStates: [String: SeasonCarouselState] = [:]
    @State private var showComingSoonSheet = false

    // ViewModel
    @StateObject private var viewModel = MenuViewModel()

    // Build the pages of our deck
    private var carouselPages: [CarouselPageItem] {
        var items = viewModel.menus.map { CarouselPageItem.menu($0) }
        if !viewModel.menus.isEmpty {
            items.append(.addAction)
        }
        return items
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.cream.ignoresSafeArea()

                GeometryReader { geo in
                    VStack(spacing: Spacing.lg) {
                        // ─── Header
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

                            // Placeholder for symmetry
                            Rectangle().fill(Color.clear).frame(width:24, height:24)
                        }
                        .padding(.horizontal, Spacing.md)

                        // ─── Season Picker
                        SeasonPicker(selected: $selectedSeason)

                        // ─── Loading / Error
                        if viewModel.isLoading {
                            ProgressView().padding()
                        }
                        if let err = viewModel.errorMessage {
                            Text(err)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // ─── Swipe‑Deck Area (75% of height)
                        ZStack {
                            if viewModel.isLoading || viewModel.menus.isEmpty {
                                // Placeholder
                                VStack {
                                    Spacer()
                                    Text(viewModel.isLoading
                                         ? "Loading Menus..."
                                         : "No menus available for \(selectedSeason).")
                                        .font(.custom("Inter-Regular", size: 16))
                                        .foregroundColor(Color.theme.cream)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, Spacing.md)
                                .frame(height: geo.size.height * 0.75)
                            } else {
                                // Real Deck
                                ZStack {
                                    TabView(selection: $currentPage) {
                                        ForEach(Array(carouselPages.enumerated()), id: \.element.id) { idx, item in
                                            switch item {
                                            case .menu(let menu):
                                                ModernMenuCard(
                                                    menu: menu,
                                                    onSave: {
                                                        // TODO: Save action
                                                    },
                                                    onView: {
                                                        // TODO: Navigate to detail
                                                    }
                                                )
                                                .frame(
                                                    width: geo.size.width - Spacing.md*2,
                                                    height: geo.size.height * 0.70
                                                )
                                                .tag(idx)

                                            case .addAction:
                                                AddActionCardView {
                                                    showComingSoonSheet = true
                                                }
                                                .frame(
                                                    width: geo.size.width - Spacing.md*2,
                                                    height: geo.size.height * 0.70
                                                )
                                                .tag(idx)
                                            }
                                        }
                                    }
                                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                    .frame(
                                        width: geo.size.width,
                                        height: geo.size.height * 0.75
                                    )
                                    

                                    // ← single arrow overlay
                                    HStack {
                                        Button {
                                            withAnimation {
                                                currentPage = max(0, currentPage - 1)
                                            }
                                        } label: {
                                            Image(systemName: "chevron.left")
                                                .font(.title2)
                                                .foregroundColor(Color.theme.primaryCoral)
                                                .padding(12)
                                                .background(Circle().fill(Color.theme.primaryCoral.opacity(0.15)))
                                        }
                                        .opacity(currentPage > 0 ? 1 : 0.5)

                                        Spacer()

                                        Button {
                                            withAnimation {
                                                currentPage = min(carouselPages.count - 1, currentPage + 1)
                                            }
                                        } label: {
                                            Image(systemName: "chevron.right")
                                                .font(.title2)
                                                .foregroundColor(Color.theme.primaryCoral)
                                                .padding(12)
                                                .background(Circle().fill(Color.theme.primaryCoral.opacity(0.15)))
                                        }
                                        .opacity(currentPage < carouselPages.count - 1 ? 1 : 0.5)
                                    }
                                    .padding(.horizontal, Spacing.xl)
                                }
                            }
                        }
                        .padding(.vertical, Spacing.md)

                        // ─── Page Indicator
                        if !viewModel.isLoading && carouselPages.count > 1 {
                            CustomPageIndicatorView(
                                numberOfPages: carouselPages.count,
                                currentPage: $currentPage
                            )
                            .padding(.bottom, Spacing.sm)
                        }

                        Spacer()
                    }
                    .padding(.top, Spacing.xl)
                    .frame(width: geo.size.width, height: geo.size.height)
                }

                // ─── Side Menu Overlay
                if isSideMenuPresented {
                    Color.theme.forestGreen.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { isSideMenuPresented = false }
                        }
                    SideMenuView(isShowing: $isSideMenuPresented)
                        .transition(.move(edge: .leading))
                        .zIndex(2)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showComingSoonSheet) {
                ComingSoonView()
            }
            .task(id: selectedSeason) {
                await viewModel.loadMenus(for: selectedSeason)
            }
        }
    }
}


// MARK: – ComingSoonView
private struct ComingSoonView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Spacer()
                Image("UnderConstruction")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)
                Text("Feature Coming Soon!")
                    .font(.custom("DrukWide-Bold", size: 26))
                    .foregroundColor(Color.theme.forestGreen)
                    .multilineTextAlignment(.center)
                Text("We’re teaching the app to stir the pot — expect brand‑new menus to land soon!")
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color.theme.primaryCoral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                Spacer()
            }
            .padding(Spacing.xl)
            .background(Color.theme.cream.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Inter-Semibold", size: 16))
                        .foregroundColor(Color.theme.primaryCoral)
                }
            }
        }
    }
}

// MARK: – CustomPageIndicatorView
private struct CustomPageIndicatorView: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    let activeDotColor: Color   = Color.theme.primaryCoral
    let inactiveDotColor: Color = Color.gray.opacity(0.4)
    let dotSize: CGFloat        = 8
    let spacing: CGFloat        = 8

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<numberOfPages, id: \.self) { idx in
                if idx == currentPage {
                    Circle()
                        .fill(activeDotColor)
                        .frame(width: dotSize, height: dotSize)
                } else {
                    Circle()
                        .strokeBorder(inactiveDotColor, lineWidth: 1)
                        .frame(width: dotSize, height: dotSize)
                }
            }
        }
    }
}

// MARK: – SeasonPicker
struct SeasonPicker: View {
    @Binding var selected: String
    private let seasons = ["Spring","Summer","Autumn","Winter"]

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
                        .foregroundColor(selected == s ? Color.theme.cream : Color.theme.forestGreen)
                }
                .clipShape(Capsule())
            }
        }
        .padding(4)
        .overlay(Capsule().stroke(Color.theme.forestGreen, lineWidth: 1))
        .padding(.horizontal, Spacing.md)
        .frame(height: 44)
    }
}

// MARK: – ModernMenuCard
struct ModernMenuCard: View {
    let menu: Menu
    let onSave: () -> Void
    let onView: () -> Void

    @State private var imageIndex = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#C7B89C"))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)

            VStack(spacing: 0) {
                // Image carousel
                TabView(selection: $imageIndex) {
                    ForEach(menu.recipes.indices, id: \.self) { idx in
                        AsyncImage(url: menu.recipes[idx].imageURL) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                Color.theme.cream.opacity(0.1)
                            }
                        }
                        .tag(idx)
                        .frame(height: 180)
                        .clipped()
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Dots
                HStack(spacing: 6) {
                    ForEach(menu.recipes.indices, id: \.self) { idx in
                        Circle()
                            .fill(idx == imageIndex
                                  ? Color.theme.primaryCoral
                                  : Color.gray.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.vertical, 8)

                // Title + list
                VStack(alignment: .leading, spacing: 12) {
                    Text(menu.title)
                        .font(.custom("DrukWide-Bold", size: 20))
                        .foregroundColor(Color.theme.forestGreen)

                    ForEach(menu.recipes) { r in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(icon(for: r.course))
                            Text("\(r.course): \(r.title)")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(Color.theme.forestGreen)
                        }
                    }

                    // Buttons (outline + filled, matching your palette)
                    HStack(spacing: Spacing.lg) {
                        Button(action: onSave) {
                            Text("Save")
                                .font(.custom("Inter-Semibold", size: 18))
                                .foregroundColor(Color.theme.primaryCoral)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.theme.primaryCoral, lineWidth: 2)
                                )
                        }

                        Button(action: onView) {
                            Text("View Recipe")
                                .font(.custom("Inter-Semibold", size: 18))
                                .foregroundColor(Color.theme.cream)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.md)
                                .background(Color.theme.primaryCoral)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(16)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private func icon(for course: String) -> String {
        switch course {
        case "Starter": return "🥗"
        case "Main":    return "🍽️"
        case "Dessert": return "🍰"
        default:        return "•"
        }
    }
}

// MARK: – AddActionCardView
private struct AddActionCardView: View {
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "plus.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(Color.theme.primaryCoral)

            Text("Generate New Menus")
                .font(.custom("Inter-Semibold", size: 18))
                .foregroundColor(Color.theme.forestGreen)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(Spacing.lg)
        .background(Color(hex: "#C7B89C"))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: – CarouselPageItem
private enum CarouselPageItem: Identifiable, Hashable {
    case menu(Menu)
    case addAction

    var id: String {
        switch self {
        case .menu(let m):      return m.id.uuidString
        case .addAction:        return "addActionCard"
        }
    }
}

// MARK: – Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
