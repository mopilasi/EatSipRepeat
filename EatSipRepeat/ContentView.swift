import SwiftUI

// MARK: – Season helper
enum Season: String, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case autumn = "Autumn"
    case winter = "Winter"

    static func current() -> Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:   return .spring
        case 6...8:   return .summer
        case 9...11:  return .autumn
        default:      return .winter
        }
    }
}

// MARK: – SeasonCarouselState
private struct SeasonCarouselState {
    var currentPage: Int = 0
    var visitedPages: Set<Int> = [0]
}

// MARK: – ContentView
struct ContentView: View {
    // UI State
    @State private var selectedFilterType: FilterType = .season
    @State private var selectedChip: String = Season.current().rawValue
    @State private var isSideMenuPresented = false
    @State private var currentPage: Int = 0
    @State private var seasonCarouselStates: [String: SeasonCarouselState] = [:]
    @State private var showComingSoonSheet = false

    // ViewModel
    @StateObject private var viewModel = MenuViewModel()

    // Chips data
    private let seasonChips = Season.allCases.map(\.rawValue)
    private let occasionChips: [String] = [
        "Date Night",
        "The One With All The Friends",
        "When Grandma visits",
        "Anniversary splurge",
        "Movie night"
    ]
    private var currentChips: [String] {
        selectedFilterType == .season ? seasonChips : occasionChips
    }

    // MARK: – Filter types
    enum FilterType: String, CaseIterable {
        case season = "Season"
        case occasion = "Occasion"
    }

    // MARK: – Carousel pages
    private var carouselPages: [CarouselPageItem] {
        var items = viewModel.menus.map { CarouselPageItem.menu($0) }
        if !viewModel.menus.isEmpty {
            items.append(.addAction)
        }
        return items
    }

    // MARK: – Nested Toggle and Chip views
    struct FilterToggle: View {
        @Binding var selected: FilterType
        init(selected: Binding<FilterType>) {
            self._selected = selected
            // Style UISegmentedControl
            UISegmentedControl.appearance().selectedSegmentTintColor = .clear
            UISegmentedControl.appearance().setTitleTextAttributes([
                .foregroundColor: UIColor(Color.theme.primaryCoral),
                .font: UIFont(name: "Inter-Regular", size: 14) ?? .systemFont(ofSize: 14)
            ], for: .selected)
            UISegmentedControl.appearance().setTitleTextAttributes([
                .foregroundColor: UIColor(Color.theme.forestGreen),
                .font: UIFont(name: "Inter-Regular", size: 14) ?? .systemFont(ofSize: 14)
            ], for: .normal)
            UISegmentedControl.appearance().backgroundColor = UIColor(Color.theme.cream)
        }
        var body: some View {
            Picker("Filter", selection: $selected) {
                ForEach(FilterType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .background(Color.theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.theme.forestGreen, lineWidth: 1))
        }
    }

    struct ChipSelector: View {
        @Binding var selectedChip: String
        let chips: [String]
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    LazyHStack(spacing: 8) {
                        ForEach(chips, id: \.self) { chip in
                            Text(chip)
                                .font(.custom("Inter-Regular", size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .fixedSize()
                                .background(Capsule()
                                                .fill(selectedChip == chip ? Color.theme.forestGreen : .clear))
                                .overlay(Capsule()
                                            .stroke(Color.theme.forestGreen.opacity(selectedChip == chip ? 1 : 0.4), lineWidth: 1))
                                .foregroundColor(selectedChip == chip ? Color.theme.cream : Color.theme.forestGreen)
                                .id(chip)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedChip = chip
                                        proxy.scrollTo(chip, anchor: .center)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: – Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.cream.ignoresSafeArea()
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        // Header & Filters
                        VStack(spacing: Spacing.lg) {
                            headerView
                            filtersView
                        }
                        .padding(.top, Spacing.xl)
                        .frame(height: 180)

                        // Loading / Error
                        if viewModel.isLoading {
                            ProgressView().padding()
                        }
                        if let err = viewModel.errorMessage {
                            Text(err)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Carousel or placeholder
                        carouselSection(geo: geo)
                            .padding(.vertical, Spacing.md)

                        // Page indicator dots
                        if !viewModel.isLoading && carouselPages.count > 1 {
                            CustomPageIndicatorView(numberOfPages: carouselPages.count,
                                                     currentPage: $currentPage)
                                .padding(.bottom, Spacing.sm)
                        }
                        Spacer()
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                // Side menu
                if isSideMenuPresented {
                    Color.theme.forestGreen.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { isSideMenuPresented = false } }
                    SideMenuView(isShowing: $isSideMenuPresented)
                        .transition(.move(edge: .leading))
                        .zIndex(2)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showComingSoonSheet) { ComingSoonView() }
            // Load menus on appear & chip change
            .task(id: selectedChip) {
                await viewModel.loadMenus(for: selectedChip)
            }
            .onChange(of: selectedFilterType) { new in
                selectedChip = (new == .season)
                    ? Season.current().rawValue
                    : occasionChips.first ?? ""
            }
        }
    }

    // MARK: – Subviews
    private var headerView: some View {
        HStack {
            Button { withAnimation { isSideMenuPresented.toggle() } } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(Color.theme.forestGreen)
            }
            Spacer()
            Text("Menus")
                .font(.custom("DrukWide-Bold", size: 34))
                .foregroundColor(Color.theme.forestGreen)
            Spacer()
            Rectangle().fill(Color.clear).frame(width: 24, height: 24)
        }
        .padding(.horizontal, Spacing.md)
    }

    private var filtersView: some View {
        VStack(spacing: Spacing.md) {
            FilterToggle(selected: $selectedFilterType)
                .padding(.horizontal)
            ChipSelector(selectedChip: $selectedChip, chips: currentChips)
        }
    }

    private func carouselSection(geo: GeometryProxy) -> some View {
        ZStack {
            if viewModel.isLoading || viewModel.menus.isEmpty {
                VStack {
                    Spacer()
                    Text(viewModel.isLoading ? "Loading Menus…" : "No menus for \(selectedChip).")
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
                ZStack {
                    TabView(selection: $currentPage) {
                        ForEach(Array(carouselPages.enumerated()), id: \.offset) { idx, item in
                            switch item {
                            case .menu(let m):
                                ModernMenuCard(menu: m, onSave: {}, onView: {})
                                    .frame(width: geo.size.width - Spacing.md*2,
                                           height: geo.size.height * 0.70)
                                    .tag(idx)
                            case .addAction:
                                AddActionCardView { showComingSoonSheet = true }
                                    .frame(width: geo.size.width - Spacing.md*2,
                                           height: geo.size.height * 0.70)
                                    .tag(idx)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(width: geo.size.width, height: geo.size.height * 0.75)

                    HStack {
                        Button { withAnimation { currentPage = max(0, currentPage - 1) } } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(Color.theme.primaryCoral)
                                .padding(12)
                                .background(Circle().fill(Color.theme.primaryCoral.opacity(0.15)))
                        }
                        .opacity(currentPage > 0 ? 1 : 0.5)
                        Spacer()
                        Button { withAnimation { currentPage = min(carouselPages.count - 1, currentPage + 1) } } label: {
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

// MARK: – CustomPageIndicatorView
private struct CustomPageIndicatorView: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { idx in
                Circle()
                    .fill(idx == currentPage ? Color.theme.primaryCoral : Color.gray.opacity(0.4))
                    .frame(width: 8, height: 8)
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
                    .resizable().scaledToFit().frame(width: 170, height: 170)
                Text("Feature Coming Soon!")
                    .font(.custom("DrukWide-Bold", size: 26))
                    .foregroundColor(Color.theme.forestGreen)
                Text("We’re teaching the app to stir the pot — expect brand‑new menus soon!")
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color.theme.primaryCoral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                Spacer()
            }
            .padding(Spacing.xl)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
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
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            VStack(spacing: 0) {
                TabView(selection: $imageIndex) {
                    ForEach(menu.recipes.indices, id: \.self) { idx in
                        AsyncImage(url: menu.recipes[idx].imageURL) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            default: Color.theme.cream.opacity(0.1)
                            }
                        }
                        .frame(height: 180)
                        .clipped()
                        .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                HStack(spacing: 6) {
                    ForEach(menu.recipes.indices, id: \.self) { idx in
                        Circle()
                            .fill(idx == imageIndex ? Color.theme.primaryCoral : Color.gray.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.vertical, 8)
                VStack(alignment: .leading, spacing: 12) {
                    Text(menu.title)
                        .font(.custom("DrukWide-Bold", size: 20))
                        .foregroundColor(Color.theme.forestGreen)
                    ForEach(menu.recipes) { r in
                        HStack(spacing: 8) {
                            Text(icon(for: r.course))
                            Text("\(r.course): \(r.title)")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(Color.theme.forestGreen)
                        }
                    }
                    HStack(spacing: Spacing.lg) {
                        Button(action: onSave) {
                            Text("Save Menu")
                                .font(.custom("Inter-Semibold", size: 18))
                                .foregroundColor(Color.theme.primaryCoral)
                                .padding(.vertical, Spacing.md)
                                .padding(.horizontal, Spacing.xl)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.theme.primaryCoral, lineWidth: 2))
                        }
                        Button(action: onView) {
                            Text("Plan Menu")
                                .font(.custom("Inter-Semibold", size: 18))
                                .foregroundColor(Color.theme.cream)
                                .padding(.vertical, Spacing.md)
                                .padding(.horizontal, Spacing.xl)
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
        default:         return "•"
        }
    }
}

// MARK: – AddActionCardView
private struct AddActionCardView: View {
    let onTap: () -> Void
    var body: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "plus.circle.fill")
                .resizable().scaledToFit().frame(width: 60, height: 60)
                .foregroundColor(Color.theme.primaryCoral)
            Text("Generate New Menus")
                .font(.custom("Inter-Semibold", size: 18))
                .foregroundColor(Color.theme.forestGreen)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onTapGesture(perform: onTap)
    }
}
