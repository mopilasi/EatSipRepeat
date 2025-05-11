import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool

    // MARK: – Menu data
    private let menuItems: [(icon: String, title: String, action: ()->Void)] = [
        ("person.crop.circle", "My Profile",  { /* TODO */ }),
        ("bookmark",            "Favourites",  { /* TODO */ }),
        ("info.circle",         "About Us",    { /* TODO */ })
    ]

    var body: some View {
        ZStack {
            // Dimmed backdrop
            if isShowing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { isShowing = false } }
            }

            HStack(spacing: 0) {
                // ─── Drawer ───────────────────────
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Close button
                    HStack {
                        Button {
                            withAnimation { isShowing = false }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                         
                        }
                        .padding(.leading, Spacing.md)
                        .padding(.top, Spacing.xl)

                        Spacer()
                    }

   
                    Spacer()
                }
                .frame(width: 280)
           
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 2, y: 0)
                .offset(x: isShowing ? 0 : -300)
                .animation(.easeOut(duration: 0.25), value: isShowing)

                Spacer()
            }
        }
    }
}
