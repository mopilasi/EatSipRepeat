import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @State private var showAboutSheet = false
    @Environment(\.openURL) private var openURL

    private let feedbackURL = URL(string: "https://form.typeform.com/to/oQcMvxHG")!

    var body: some View {
        ZStack {
            Color.theme.cream.ignoresSafeArea()
            VStack(alignment: .leading, spacing: Spacing.xl) {
                HStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                    Text("Eat Sip Repeat")
                        .font(.custom("DrukWide-Bold", size: 24))
                        .foregroundColor(Color.theme.forestGreen)
                }

                Group {
                    Button(action: { withAnimation { isShowing = false } }) {
                        SideMenuRow(icon: "house.fill", title: "Home")
                    }
                    NavigationLink(destination: FavouritesView().onAppear { isShowing = false }) {
                        SideMenuRow(icon: "heart.fill", title: "Favourites")
                    }
                    Button(action: { showAboutSheet = true }) {
                        SideMenuRow(icon: "info.circle", title: "About Us")
                    }
                    Button(action: { openURL(feedbackURL) }) {
                        SideMenuRow(icon: "bubble.left", title: "Feedback")
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("v1.0.0")
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundColor(.secondary)
                    Button("Terms & Privacy") {}
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundColor(Color.theme.forestGreen)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.xl)
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutUsView()
        }
    }
}

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

struct FavouritesView: View {
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutUsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let instagramURL = URL(string: "https://instagram.com/p_polina")!

    var body: some View {
            ZStack {
                Color.theme.cream
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // 1) Portrait
                        Image("AboutUs")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 160)
                        
                    // Title
                    Text("Meet the Maker")
                        .font(.custom("DrukWide-Bold", size: 25))
                        .foregroundColor(Color.theme.forestGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.md)

                    // Body paragraphs
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("Polina is a product manager on sabbatical, a dinner party enthusiast, and a bit too familiar with the chaos of recipe overload.")

                        Text("Eat Sip Repeat started as a “what if I just made this easier for myself?” side project, and after many iterations and more than one “how do I undo this” moment, Eat Sip Repeat was born.")

                        Text("She hopes it helps you skip the scroll and get to the good part: cooking, sipping, and sharing these moments with your loved ones.")
                    }
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color.theme.forestGreen)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, Spacing.md)

                    // Call‑to‑action
                    VStack(spacing: Spacing.sm) {
                        Text("Say hi on Instagram:")
                            .font(.custom("Inter-Medium", size: 16))
                            .foregroundColor(Color.theme.forestGreen)
                            .multilineTextAlignment(.center)

                        Button(action: { openURL(instagramURL) }) {
                            Text("@p_polina")
                                .font(.custom("Inter-Semibold", size: 18))
                                .foregroundColor(Color.theme.forestGreen)
                                .underline()
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    // Dismiss button
                    Button(action: { dismiss() }) {
                        Text("Got it!")
                            .font(.custom("Inter-Semibold", size: 16))
                            .foregroundColor(Color.theme.cream)
                            .padding(.vertical, Spacing.sm)
                            .padding(.horizontal, Spacing.lg)
                            .background(Color.theme.forestGreen)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, Spacing.xl)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
