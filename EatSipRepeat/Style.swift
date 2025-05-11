//// Style.swift
//import SwiftUI
//
//// MARK: – Color Tokens
//extension Color {
//    static let primary    = Color("PrimaryCoral")    // #E45A30
//    static let cream      = Color("Cream")           // #F7E3CF
//    static let accent     = Color("ForestGreen")     // #3B4A36
//    static let background = Color("SoftGray")        // #F2F2F2
//    static let sand       = Color("WarmSand")        // #D1BFA3
//}
//
//// MARK: – Spacing Scale
//struct Spacing {
//    static let xs: CGFloat = 4
//    static let sm: CGFloat = 8
//    static let md: CGFloat = 16
//    static let lg: CGFloat = 24
//    static let xl: CGFloat = 32
//}
//
//// MARK: – Typography
//extension Font {
//    // Headlines
//    static func h1() -> Font { .custom("DrukWide-Bold", size: 32) }
//    static func h2() -> Font { .custom("DrukWide-Bold", size: 24) }
//    // Body
//    static func bodyText() -> Font { .custom("Lora-Regular", size: 16) }
//    // UI / Labels
//    static func label() -> Font { .custom("Inter-Medium", size: 14) }
//}
//
//// MARK: – View Modifiers
//
///// Primary button style
//struct PrimaryButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//          .font(.label())
//          .foregroundColor(.cream)
//          .padding(.vertical, Spacing.sm)
//          .padding(.horizontal, Spacing.md)
//          .background(Color.primary)
//          .cornerRadius(8)
//          .opacity(configuration.isPressed ? 0.8 : 1)
//    }
//}
//
///// Card container
//struct CardModifier: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//          .padding(Spacing.md)
//          .background(Color.sand)
//          .cornerRadius(12)
//          .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
//    }
//}
//
///// Header bar
//struct HeaderBar<Title: View>: View {
//    let title: Title
//    let onBack: () -> Void
//
//    var body: some View {
//        HStack(spacing: Spacing.md) {
//            Button(action: onBack) {
//                Image(systemName: "chevron.left")
//                  .font(.label())
//                  .foregroundColor(.accent)
//            }
//            title
//              .font(.h2())
//              .foregroundColor(.accent)
//            Spacer()
//        }
//        .padding(.horizontal, Spacing.md)
//        .padding(.vertical, Spacing.sm)
//        .background(Color.white)
//    }
//}
//
///// Segmented control pill style
//struct PillSegmentedStyle: ViewModifier {
//    var isSelected: Bool
//
//    func body(content: Content) -> some View {
//        content
//          .font(.label())
//          .padding(.vertical, Spacing.xs)
//          .padding(.horizontal, Spacing.lg / 2)
//          .background(isSelected ? Color.primary : Color.clear)
//          .foregroundColor(isSelected ? .cream : .accent)
//          .overlay(
//            Capsule().stroke(Color.accent, lineWidth: 2)
//          )
//          .clipShape(Capsule())
//    }
//}
//
//// MARK: – Usage Examples
//
///*
//
// // 1) Primary Button:
// Button("Shuffle") { … }
//   .buttonStyle(PrimaryButtonStyle())
//
// // 2) Card:
// VStack { … }
//   .modifier(CardModifier())
//
// // 3) Header Bar:
// HeaderBar(title: Text("Menus")) {
//   // back action
// }
//
// // 4) Season Picker:
// HStack {
//   ForEach(["Spring","Summer"], id: \.self) { season in
//     Text(season)
//       .modifier(PillSegmentedStyle(isSelected: selectedSeason == season))
//       .onTapGesture { selectedSeason = season }
//   }
// }
//
// // 5) Loader:
// ProgressView()
//   .progressViewStyle(.circular)
//   .tint(Color.accent)
//
//*/
////
////  Style.swift
////  EatSipRepeat
////
////  Created by Polina Kirillova on 29.04.2025.
////
//

