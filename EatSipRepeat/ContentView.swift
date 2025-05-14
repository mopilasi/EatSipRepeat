import SwiftUI

struct ContentView: View {
    // MARK: — UI State
    @State private var selectedSeason: String = "Spring"
    @State private var isSideMenuPresented = false
    @State private var currentPage: Int = 0
    
    // Keep track of carousel state per season if you switch seasons
    @State private var seasonCarouselStates: [String: (page: Int, visited: Set<Int>)] = [:]
    
    @State private var showComingSoonSheet = false

    // MARK: — ViewModel
    @StateObject private var viewModel = MenuViewModel()

    // Combine menus + “addAction” card
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
                Color.theme.cream
                    .ignoresSafeArea()
                
                GeometryReader { geo in
                    VStack(spacing: Spacing.lg) {
                        header
                        
                        SeasonPicker(selected: $selectedSeason)
                        
                        // Loading / Error
                        if viewModel.isLoading {
                            ProgressView().padding()
                        } else if let err = viewModel.errorMessage {
                            Text(err)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // ─── Swipe‑deck
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
                                .tag(-1)
                            } else {
                                TabView(selection: $currentPage) {
                                    ForEach(Array(carouselPages.enumerated()), id: \.offset) { idx, page in
                                        switch page {
                                        case .menu(let menu):
                                            ModernMenuCard(
                                                menu: menu,
                                                onPrev: {
                                                    withAnimation {
                                                        currentPage = max(0, currentPage - 1)
                                                    }
                                                },
                                                onNext: {
                                                    withAnimation {
                                                        currentPage = min(carouselPages.count - 1, currentPage + 1)
                                                    }
                                                },
                                                onSave: {
                                                    // TODO: implement save
                                                },
                                                onView: {
                                                    // TODO: navigate to detail
                                                }
                                            )
                                            .frame(
                                                width: geo.size.width,
                                                height: geo.size.height * 0.70
                                            )
                                            .tag(idx)
                                            
                                        case .addAction:
                                            AddActionCardView {
                                                showComingSoonSheet = true
                                            }
                                            .frame(
                                                width: geo.size.width,
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
                            }
                        }
                        .padding(.vertical, Spacing.md)
                        
                        // Page indicator
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
                
                // Side‑menu overlay
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
            .sheet(isPresented: $showComingSoonSheet) {
                ComingSoonView()
            }
            .task(id: selectedSeason) {
                // Save carousel state for previous season
                if let old = seasonCarouselStates[selectedSeason] {
                    currentPage = old.page
                } else {
                    currentPage = 0
                }
                await viewModel.loadMenus(for: selectedSeason)
            }
        }
    }
    
    // MARK: — Header
    private var header: some View {
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
    }
}

// MARK: — CarouselPageItem
private enum CarouselPageItem: Identifiable, Hashable {
    case menu(Menu)
    case addAction
    
    var id: String {
        switch self {
        case .menu(let m):      return m.id.uuidString
        case .addAction:        return "addAction"
        }
    }
}

// MARK: — SeasonPicker
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
                        .foregroundColor(selected == s
                                         ? Color.theme.cream
                                         : Color.theme.forestGreen)
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

// MARK: — CustomPageIndicatorView
private struct CustomPageIndicatorView: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    
    let activeDotColor: Color = Color.theme.primaryCoral
    let inactiveDotColor: Color = Color.gray.opacity(0.5)
    let dotSize: CGFloat = 8
    let spacing: CGFloat = 8
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<numberOfPages, id: \.self) { idx in
                Circle()
                    .fill(idx == currentPage ? activeDotColor : inactiveDotColor)
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
}

// MARK: — ModernMenuCard
struct ModernMenuCard: View {
    let menu: Menu
    let onPrev: () -> Void
    let onNext: () -> Void
    let onSave: () -> Void
    let onView: () -> Void
    
    @State private var imageIndex = 0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#C7B89C"))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            
            VStack(spacing: 0) {
                // Header images
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
                
                // Content
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
                    
                    HStack(spacing: 12) {
                        // Save
                        Button(action: onSave) {
                            Text("Save")
                                .font(.custom("Inter-Semibold", size: 14))
                                .foregroundColor(Color.theme.primaryCoral)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.theme.primaryCoral, lineWidth: 1)
                                )
                        }
                        
                        // View Recipe
                        Button(action: onView) {
                            Text("View Recipe")
                                .font(.custom("Inter-Semibold", size: 14))
                                .foregroundColor(Color.theme.cream)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.theme.primaryCoral)
                                )
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
            
            // Left arrow
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Color.theme.primaryCoral)
                    .padding(12)
                    .background(Circle().fill(Color.theme.primaryCoral.opacity(0.15)))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Spacing.md)
            
            // Right arrow
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(Color.theme.primaryCoral)
                    .padding(12)
                    .background(Circle().fill(Color.theme.primaryCoral.opacity(0.15)))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, Spacing.md)
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

// MARK: — AddActionCardView
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
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: — ComingSoonView
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
                Text("We’re teaching the app to stir the pot — expect brand‑new menus to land in a future future!")
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

// MARK: — Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
