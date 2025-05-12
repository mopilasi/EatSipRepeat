import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @State private var showAboutSheet = false
    @Environment(\.openURL) private var openURL

    // Replace with your actual Typeform feedback URL
    private let feedbackURL = URL(string: "https://form.typeform.com/to/oQcMvxHG")!

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // MARK: – Header
            HStack(spacing: 12) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                Text("Eat Sip Repeat")
                    .font(.custom("DrukWide-Bold", size: 24))
                    .foregroundColor(Color.theme.forestGreen)
            }

            // MARK: – Menu Items
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

            // MARK: – Footer
            VStack(alignment: .leading, spacing: 4) {
                Text("v1.0.0")
                    .font(.custom("Inter-Regular", size: 12))
                    .foregroundColor(.secondary)
                Button("Terms & Privacy") {
                    // open your terms URL
                }
                .font(.custom("Inter-Regular", size: 12))
                .foregroundColor(Color.theme.forestGreen)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .background(Color.theme.cream)
        .edgesIgnoringSafeArea(.vertical)
        .sheet(isPresented: $showAboutSheet) {
            AboutUsView()
        }
    }
}

// MARK: – Helper Row View
private struct SideMenuRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 16) {
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
        .padding(.vertical, 8)
    }
}

// MARK: – Stub Views for Navigation & About Sheet
struct FavouritesView: View {
    var body: some View {
        Text("Your saved favourites will appear here.")
            .padding()
            .navigationTitle("Favourites")
    }
}

struct AboutUsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("About Eat Sip Repeat")
                .font(.title)
            Text("We’re on a mission to make your dinner parties stress-free and fun!")
                .multilineTextAlignment(.center)
                .padding()

            Button("Dismiss") {
                dismiss()
            }
            .font(.custom("Inter-Semibold", size: 16))
            .padding(.top, 16)
        }
        .padding()
    }
}
