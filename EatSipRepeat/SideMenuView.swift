// SideMenuView.swift

import SwiftUI

struct SideMenuView: View {
  @Binding var isShowing: Bool

  var body: some View {
    ZStack(alignment: .leading) {
      // 1. Semi‑opaque overlay
      if isShowing {
        Color.theme.forestGreen
          .opacity(0.5)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation { isShowing = false }
          }
      }

      // 2. Slide‑out panel
      HStack {
        VStack(alignment: .leading, spacing: 24) {
          // Header
          HStack(spacing: 12) {
            Image("AppLogo")
              .resizable()
              .scaledToFit()
              .frame(width: 60, height: 60)
            Text("Eat Sip Repeat")
              .font(.custom("DrukWide-Bold", size: 24))
              .foregroundColor(Color.theme.forestGreen)
          }
          .padding(.bottom, 32)

          // Menu items
          Group {
            SideMenuRow(icon: "house.fill", title: "Home") {
              // navigate to home
              withAnimation { isShowing = false }
            }
            SideMenuRow(icon: "heart.fill", title: "Favourites") {
              // navigate to favourites view
            }
            SideMenuRow(icon: "info.circle", title: "About Us") {
              // show about sheet
            }
            SideMenuRow(icon: "bubble.left", title: "Feedback") {
              // open mail composer
            }
          }

          Spacer()

          // Footer
          VStack(alignment: .leading, spacing: 4) {
            Text("v1.0.0")
              .font(.custom("Inter-Regular", size: 12))
              .foregroundColor(.secondary)
            Button("Terms & Privacy") {
              // open link
            }
            .font(.custom("Inter-Regular", size: 12))
            .foregroundColor(Color.theme.forestGreen)
          }
        }
        .padding(.top, 60)
        .padding(.horizontal, 24)
        .frame(width: UIScreen.main.bounds.width * 0.8)
        .background(Color.theme.cream)
        .offset(x: isShowing ? 0 : -UIScreen.main.bounds.width * 0.8)
        .animation(.easeInOut, value: isShowing)

        Spacer()
      }
    }
  }
}

struct SideMenuRow: View {
  let icon: String
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Image(systemName: icon)
          .frame(width: 24, height: 24)
        Text(title)
          .font(.custom("Inter-Bold", size: 18))
        Spacer()
      }
      .foregroundColor(Color.theme.forestGreen)
    }
  }
}
