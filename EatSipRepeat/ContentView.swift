import SwiftUI

struct ContentView: View {
    // MARK: — UI State
    @State private var selectedSeason: String = "Spring"
    @State private var isSideMenuPresented = false
    @State private var currentPage = 0
    @State private var visitedPages: Set<Int> = []

    // MARK: — ViewModel
    @StateObject private var viewModel = MenuViewModel()

    // Unlock the button once every page has been seen
    private var canGenerate: Bool {
        visitedPages.count >= viewModel.menus.count
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

                    // ─── Menu carousel (one card at a time)
                    TabView(selection: $currentPage) {
                        ForEach(Array(viewModel.menus.enumerated()), id: \.element.id) { index, menu in
                            MenuCard(menu: menu)
                                .padding(.horizontal, Spacing.md)
                                .frame(height: 260)
                                .frame(maxWidth: .infinity)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 280)
                    .padding(.vertical, Spacing.md)
                    .onAppear {
                        // mark the first page as visited
                        visitedPages.insert(0)
                    }
                    .onChange(of: currentPage) { newPage in
                        visitedPages.insert(newPage)
                    }

                    // ─── Action button
                    Button(canGenerate ? "Generate New Menus" : "Swipe to view all") {
                        Task { await viewModel.loadMenus(for: selectedSeason) }
                    }
                    .font(.custom("DrukWide-Bold", size: 33))
                    .frame(maxWidth: .infinity, minHeight: 75)
                    .buttonStyle(FilledCoralButton())
                    .padding(.bottom, Spacing.lg)
                    .disabled(!canGenerate)
                    .opacity(canGenerate ? 1 : 0.5)

                    Spacer()
                }
                .padding(.top, Spacing.xl)

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
            .navigationBarHidden(true)
            .task(id: selectedSeason) {
                await viewModel.loadMenus(for: selectedSeason)
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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Title
            Text(menu.title)
                .font(.custom("DrukWide-Bold", size: 24))
                .foregroundColor(Color.theme.forestGreen)

            // Three rows, each with a bold label + wrapped body text
            VStack(alignment: .leading, spacing: Spacing.sm) {
                row(label: "Starter", text: menu.recipes.first { $0.course == "Starter" }?.title)
                row(label: "Main",    text: menu.recipes.first { $0.course == "Main" }?.title)
                row(label: "Dessert", text: menu.recipes.first { $0.course == "Dessert" }?.title)
            }
        }
        .padding(Spacing.lg)
        .background(Color(hex: "#D1BFA3"))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func row(label: String, text: String?) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(label)
                .font(.custom("Inter-Semibold", size: 16))
                .foregroundColor(Color.theme.forestGreen)

            Text(text ?? "")
                .font(.custom("Inter-Regular", size: 16))
                .foregroundColor(Color.theme.forestGreen)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: – Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
