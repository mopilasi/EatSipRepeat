import SwiftUI

struct ContentView: View {
    @State private var selectedSeason: String = "Spring"
    @State private var isSideMenuPresented = false

    /// Sample menus for “Spring”
    private let sampleMenus: [Menu] = [
        // … your existing sampleMenus here …
    ]

    /// Group by season for fast lookup
    private var menusBySeason: [String: [Menu]] {
        Dictionary(grouping: sampleMenus, by: \.season)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // ─── Background
                Color.theme.cream
                    .ignoresSafeArea()

                // ─── Main content
                VStack(spacing: Spacing.lg) {
                    HStack {
                        // Hamburger
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

                        // Balancing spacer
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 24, height: 24)
                    }
                    .padding(.horizontal, Spacing.md)

                    // Season pill picker
                    SeasonPicker(selected: $selectedSeason)

                    // Menu cards
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Spacing.md) {
                            ForEach(menusBySeason[selectedSeason] ?? []) { menu in
                                NavigationLink(
                                    destination: MenuDetailView(
                                        menuTitle: menu.title,
                                        recipes: menu.recipes
                                    )
                                ) {
                                    MenuCard(menu: menu)
                                }
                            }
                        }
                        .padding(.vertical, Spacing.md)
                    }

                    // Shuffle
                    Button("Shuffle") {
                        // TODO: shuffle logic
                    }
                    .font(.custom("DrukWide-Bold", size: 33))
                    .frame(maxWidth: .infinity, minHeight: 75)
                    .buttonStyle(FilledCoralButton())
                    .padding(.bottom, Spacing.lg)
                }
                .padding(.top, Spacing.xl)

                // ─── Side menu overlay & panel
                if isSideMenuPresented {
                    // Dimmed forest‑green overlay
                    Color.theme.forestGreen
                        .opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { isSideMenuPresented = false }
                        }

                    // Slide‑out menu
                    SideMenuView(isShowing: $isSideMenuPresented)
                        .transition(.move(edge: .leading))
                        .zIndex(1)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: – SeasonPicker
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
            Capsule()
                .stroke(Color.theme.forestGreen, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.md)
        .frame(height: 44)
    }
}

// MARK: – MenuCard
private struct MenuCard: View {
    let menu: Menu

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(menu.title)
                .font(.custom("DrukWide-Bold", size: 22))
                .foregroundColor(Color.theme.forestGreen)

            ForEach(menu.recipes) { r in
                Text("\(r.course): \(r.title)")
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color.theme.forestGreen)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color(hex: "#D1BFA3"))
        .cornerRadius(20)
        .padding(.horizontal, Spacing.md)
    }
}



// MARK: – Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
