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

    // MARK: – Reusable Styles
    private struct FilterButtonStyle: ViewModifier {
        let isSelected: Bool
        
        func body(content: Content) -> some View {
            content
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(isSelected ? .theme.cream : .theme.forestGreen)
                .padding(.vertical, Spacing.sm)
                .padding(.horizontal, Spacing.md)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.theme.forestGreen : .clear)
                        .overlay(Capsule().stroke(Color.theme.forestGreen, lineWidth: 1))
                )
        }
    }

    // MARK: – Nested Toggle and Chip views
    struct FilterToggle: View {
        @Binding var selected: FilterType
        private let height: CGFloat = 36
        
        var body: some View {
            ZStack {
                // Background capsule
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.theme.forestGreen, lineWidth: 1)
                    .background(Color.theme.cream)
                
                // Segments
                HStack(spacing: 0) {
                    ForEach(FilterType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.spring()) {
                                selected = type
                            }
                        } label: {
                            Text(type.rawValue)
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(selected == type ? .theme.cream : .theme.forestGreen)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                        }
                        .background(selected == type ? Color.theme.forestGreen.opacity(0.9) : .clear)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Spacing.md)
        }
    }

    struct ChipSelector: View {
        @Binding var selectedChip: String
        let chips: [String]
        
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(chips, id: \.self) { chip in
                            Button {
                                withAnimation(.spring()) {
                                    selectedChip = chip
                                }
                            } label: {
                                Text(chip)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .font(.custom("Inter-Regular", size: 14))
                                    .foregroundColor(selectedChip == chip ? .theme.cream : .theme.forestGreen)
                                    .padding(.horizontal, Spacing.md)
                                    .frame(height: 32)
                                    .frame(maxWidth: 120)
                                    .background(
                                        Capsule()
                                            .fill(selectedChip == chip ? Color.theme.forestGreen.opacity(0.9) : .clear)
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.theme.forestGreen, lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .background(Color.theme.cream)
                .onChange(of: selectedChip) { newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: – Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.cream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                        .padding(.top, Spacing.lg)
                    
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            VStack(spacing: 0) {
                                FilterToggle(selected: $selectedFilterType)
                                    .padding(.bottom, Spacing.md)
                                
                                ChipSelector(selectedChip: $selectedChip, chips: currentChips)
                                    .padding(.bottom, Spacing.lg)
                                
                                Group {
                                    if viewModel.isLoading {
                                        loadingView
                                    } else if let err = viewModel.errorMessage {
                                        errorView(message: err)
                                    } else {
                                        menuCarouselView
                                    }
                                }
                            }
                        }
                        .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .overlay(alignment: .leading) {
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
            .sheet(isPresented: $showComingSoonSheet) { ComingSoonView() }
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
    
    private var headerView: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Button {
                    isSideMenuPresented.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.theme.forestGreen)
                }
                
                Spacer()
                
                Text("What's cooking?")
                    .font(.custom("DrukWide-Bold", size: 20))
                    .foregroundColor(.theme.forestGreen)
                
                Spacer()
                
                Circle()
                    .fill(.clear)
                    .frame(width: 24)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.theme.cream)
    }
    
    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .theme.primaryCoral))
                .scaleEffect(1.2)
            Text("Finding perfect menus...")
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(.theme.forestGreen)
        }
        .frame(height: 400)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.red)
            Text(message)
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.md)
        .background(Color.theme.cream)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal, Spacing.md)
        .frame(height: 400)
    }
    
    private var menuCarouselView: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(Array(carouselPages.enumerated()), id: \.element.id) { index, page in
                    RecipeCarouselPageView(item: page)
                        .tag(index)
                }
            }
            .frame(height: 450)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.horizontal, Spacing.md)
            
            if carouselPages.count > 1 {
                pageIndicator
            }
        }
    }
    
    private var pageIndicator: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<carouselPages.count, id: \.self) { idx in
                Capsule()
                    .fill(idx == currentPage ? Color.theme.primaryCoral : Color.theme.forestGreen.opacity(0.2))
                    .frame(width: idx == currentPage ? 20 : 8, height: 8)
                    .animation(.spring(), value: currentPage)
            }
        }
        .padding(.top, -Spacing.lg)
    }

    // MARK: – Subviews
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
                    Text("We're teaching the app to stir the pot — expect brand‑new menus soon!")
                        .font(.custom("Inter-Regular", size: 16))
                        .foregroundColor(Color.theme.primaryCoral)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                    Spacer()
                }
                .padding(Spacing.xl)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

    private struct ModernMenuCard: View {
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
                .padding(.horizontal, Spacing.md)
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

    private struct RecipeCarouselPageView: View {
        let item: CarouselPageItem
        
        var body: some View {
            switch item {
            case .menu(let menu):
                ModernMenuCard(menu: menu, onSave: {}, onView: {})
            case .addAction:
                AddActionCardView(onTap: {})
            }
        }
    }
}