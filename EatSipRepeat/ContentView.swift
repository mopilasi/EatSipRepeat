import SwiftUI

struct ContentView: View {
    @State private var selectedSeason: String = "Spring"
    @State private var isSideMenuPresented = false // Added for side menu

    /// Sample: three Spring menus so you can verify scrolling.
    /// Replace with your Airtable‑driven `[Menu]` later.
    private let sampleMenus: [Menu] = [
        Menu(season: "Spring", title: "Spring Menu 1", recipes: [
            Recipe(id: "s1r1", title: "Pea & Mint Soup", course: "Starter", description: "Refreshing green soup.", imageAttachments: [Attachment(url: "https://via.placeholder.com/300/90EE90/000000?Text=Pea+Soup")], sourceUrlString: "https://example.com/pea-soup"),
            Recipe(id: "s1r2", title: "Lemon‑Herb Chicken", course: "Main", description: "Zesty chicken dish.", imageAttachments: [Attachment(url: "https://via.placeholder.com/300/FFFFE0/000000?Text=Lemon+Chicken")], sourceUrlString: "https://example.com/lemon-chicken"),
            Recipe(id: "s1r3", title: "Panna Cotta", course: "Dessert", description: "Creamy Italian dessert.", imageAttachments: [Attachment(url: "https://via.placeholder.com/300/FFF8DC/000000?Text=Panna+Cotta")], sourceUrlString: "https://example.com/panna-cotta")
        ]),
        Menu(season: "Spring", title: "Spring Menu 2", recipes: [
            Recipe(id: "s2r1", title: "Tomato Tart", course: "Starter", description: "Savory tomato tart.", imageAttachments: [Attachment(url: "https://via.placeholder.com/300/FF6347/FFFFFF?Text=Tomato+Tart")], sourceUrlString: "https://example.com/tomato-tart"),
            Recipe(id: "s2r2", title: "Ricotta Gnocchi", course: "Main", description: "Soft ricotta dumplings.", imageAttachments: [Attachment(url: "https://via.placeholder.com/300/F5F5DC/000000?Text=Gnocchi")], sourceUrlString: "https://example.com/ricotta-gnocchi"),
            Recipe(id: "s2r3", title: "Strawberry Shortcake", course: "Dessert", description: "Classic summer dessert.", imageAttachments: [Attachment(url: "https://via.placeholder.com/300/FFB6C1/000000?Text=Shortcake")], sourceUrlString: "https://example.com/strawberry-shortcake")
        ]),
        Menu(season: "Spring", title: "Spring Menu 3", recipes: [
            Recipe(id: "s3r1", title: "Grilled Peach & Burrata Salad", course: "Starter", description: "Sweet and savory salad.", imageAttachments: [Attachment(url: "https://via.placeholder.com/300/FFDAB9/000000?Text=Peach+Salad")], sourceUrlString: "https://example.com/peach-salad"),
            Recipe(id: "s3r2", title: "Skirt Steak w/ Chimichurri", course: "Main", description: "Flavorful grilled steak.", imageAttachments: [Attachment(url: "https://via.placeholder.com/300/8B4513/FFFFFF?Text=Steak")], sourceUrlString: "https://example.com/skirt-steak"),
            Recipe(id: "s3r3", title: "Blueberry Galette", course: "Dessert", description: "Rustic blueberry tart.", imageAttachments: [Attachment(url: "https://via.placeholder.com/300/ADD8E6/000000?Text=Galette")], sourceUrlString: "https://example.com/blueberry-galette")
        ])
    ]

    /// Group by season for fast lookup
    private var menusBySeason: [String: [Menu]] {
        Dictionary(grouping: sampleMenus, by: \.season)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.cream.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    // ─── Title & Hamburger Button
                    HStack {
                        Button {
                            withAnimation {
                                isSideMenuPresented.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(Color.theme.forestGreen)
                        }
                        Spacer()
                        Text("Menus")
                            .font(.custom("Druk Wide Bold", size: 34))
                            .foregroundColor(Color.theme.forestGreen)
                        Spacer()
                        Rectangle().fill(Color.clear).frame(width: 24, height: 24)
                    }
                    .padding(.horizontal, Spacing.md)

                    SeasonPicker(selected: $selectedSeason)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Spacing.md) {
                            ForEach(menusBySeason[selectedSeason] ?? []) { menu in
                                NavigationLink(destination: MenuDetailView(menuTitle: menu.title, recipes: menu.recipes)) {
                                    MenuCard(menu: menu)
                                }
                            }
                        }
                        .padding(.vertical, Spacing.md)
                    }

                    Button("Shuffle") { /* TODO: shuffle logic */ }
                        .font(.custom("Druk Wide Bold", size: 33))
                        .frame(maxWidth: .infinity, minHeight: 75)
                        .buttonStyle(FilledCoralButton())
                        .padding(.bottom, Spacing.lg)
                }
                .padding(.top, Spacing.xl)
                
                if isSideMenuPresented {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                isSideMenuPresented = false
                            }
                        }
                    SideMenuView(isShowing: $isSideMenuPresented)
                        .transition(.move(edge: .leading))
                        .zIndex(1)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: – Season Picker (pill control)
struct SeasonPicker: View {
    let seasons = ["Spring", "Summer", "Autumn", "Winter"]
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(seasons, id: \.self) { s in
                Button {
                    withAnimation(.spring()) { selected = s }
                } label: {
                    Text(s)
                        .font(.custom("Inter-Medium", size: 14))
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

// MARK: – MenuCard
private struct MenuCard: View {
    let menu: Menu

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(menu.title)
                .font(.custom("Druk Wide Bold", size: 22))
                .foregroundColor(Color.theme.forestGreen)

            ForEach(menu.recipes) { r in
                Text("\(r.course): \(r.title)")
                    .font(.custom("Inter-Medium", size: 16))
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
