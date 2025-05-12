import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @State private var showFavourites = false
    @State private var showAbout = false
    @Environment(\.openURL) private var openURL

    private let feedbackURL = URL(string: "https://form.typeform.com/to/oQcMvxHG")!

    var body: some View {
        ZStack {
            Color.theme.cream
                .ignoresSafeArea()

            // Use medium spacing for the overall VStack
            VStack(alignment: .leading, spacing: Spacing.md) {
                // ─── Header ─────────────────────────────────
                HStack(spacing: Spacing.sm) {
               
                    Text("Eat Sip Repeat")
                        .font(.custom("DrukWide-Bold", size: 24))
                        .foregroundColor(Color.theme.forestGreen)
                }
                .padding(.top, Spacing.lg)
                .padding(.horizontal, Spacing.md)

                // ─── Menu Items ───────────────────────────────
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Button {
                        withAnimation { isShowing = false }
                    } label: {
                        SideMenuRow(icon: "house.fill", title: "Home")
                    }

                    Button {
                        showFavourites = true
                    } label: {
                        SideMenuRow(icon: "heart.fill", title: "Favourites")
                    }

                    Button {
                        showAbout = true
                    } label: {
                        SideMenuRow(icon: "info.circle", title: "About Us")
                    }

                    Button {
                        openURL(feedbackURL)
                    } label: {
                        SideMenuRow(icon: "bubble.left", title: "Feedback")
                    }
                }
                .padding(.top, Spacing.md)
                .padding(.horizontal, Spacing.md)

                Spacer()

                // ─── Footer ─────────────────────────────────
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("v1.0.0")
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundColor(.secondary)

                    Button("Terms & Privacy") {
                        // TODO: open your privacy URL
                    }
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundColor(Color.theme.forestGreen)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
        }
        // ─── Present Favourites as a sheet ─────────────
        .sheet(isPresented: $showFavourites) {
            NavigationStack {
                FavouritesView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showFavourites = false
                            } label: {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.custom("Inter-Semibold", size: 16))
                                .foregroundColor(Color.theme.forestGreen)
                            }
                        }
                    }
            }
        }
        // ─── Present About Us as a sheet ───────────────
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                AboutUsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showAbout = false
                            } label: {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.custom("Inter-Semibold", size: 16))
                                .foregroundColor(Color.theme.forestGreen)
                            }
                        }
                    }
            }
        }
    }
}

// MARK: – Row Helper

private struct SideMenuRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.theme.forestGreen)
                .frame(width: 24, height: 24)
            Text(title)
                .font(.custom("Inter-Semibold", size: 18))
                .foregroundColor(Color.theme.forestGreen)
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: – FavouritesView
struct FavouritesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.theme.cream.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Text("Favourites")
                    .font(.custom("DrukWide-Bold", size: 28))
                    .foregroundColor(Color.theme.forestGreen)
                    .padding(.top, Spacing.xl)

                Text("You haven't saved any recipes yet.")
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color.theme.forestGreen)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)

                Spacer()
            }
            .padding(.top, Spacing.md)
        }
        .navigationTitle("Favourites")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: – AboutUsView
struct AboutUsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    private let instagramURL = URL(string: "https://instagram.com/p_polina")!

    var body: some View {
        ZStack {
            Color.theme.cream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Hero
                    HStack(spacing: Spacing.md) {
                        Image("AboutUs")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                        Text("Meet the Maker")
                            .font(.custom("DrukWide-Bold", size: 26))
                            .foregroundColor(Color.theme.forestGreen)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.md)

                    // Body copy
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Polina is a product manager on sabbatical, a home cook with a soft spot for feeding friends, and someone who got a little too overwhelmed by the infinite scroll of recipe websites.")
                        Text("What started as a curiosity project turned into something real: an app to take the chaos out of menu planning and help people host with ease.")
                        Text("She built Eat Sip Repeat with help from ChatGPT and Windsurf. There were many, many iterations, some accidental deletions, and more than one “how do I undo this” moment—but also a lot of joy.")
                        Text("The hope is simple: that this little app helps you skip the scroll and get to the good part: cooking, sipping, and sharing these moments with your loved ones.")
                    }
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color.theme.forestGreen)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)

                    // Instagram CTA
                    VStack(spacing: Spacing.sm) {
                        Text("Say hi on Instagram:")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color.theme.forestGreen)
                            .multilineTextAlignment(.center)

                        Button {
                            openURL(instagramURL)
                        } label: {
                            Text("@p_polina")
                                .font(.custom("Inter-Semibold", size: 16))
                                .foregroundColor(Color.theme.forestGreen)
                                .underline()
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)

                    Spacer(minLength: Spacing.xl)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("About Us")
        .navigationBarTitleDisplayMode(.inline)
    }
}
