import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @State private var logoAppeared = false
    @State private var buttonPulsing = false

    var body: some View {
        ZStack {
            // Coral background matching logo

            VStack(spacing: Spacing.lg) {
                Spacer()

                // Logo animation: larger size
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                    .padding(.horizontal, Spacing.md)
                    .scaleEffect(logoAppeared ? 1 : 0.8)
                    .opacity(logoAppeared ? 1 : 0)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            logoAppeared = true
                        }
                    }

                // Tagline appears together with logo (no delay), bold Lora
                Text("Take the guesswork out of hosting a dinner party")

                    .fontWeight(.bold)

                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                    .opacity(logoAppeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: logoAppeared)

                Spacer()

                // “Let’s Go” using accent (green) button
                Button(action: {
                    hasSeenWelcome = true
                }) {
                    Text("Let’s Go")
                    
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                }
                .buttonStyle(FilledAccentButton())
                .padding(.horizontal, Spacing.md)
                .scaleEffect(buttonPulsing ? 1.05 : 1)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 1)
                            .repeatForever(autoreverses: true)
                    ) {
                        buttonPulsing = true
                    }
                }
                .padding(.bottom, Spacing.xl)
            }
        }
    }
}

// MARK: – Accent button style for welcome screen
struct FilledAccentButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    
            .background(

                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
            .clipShape(Capsule())
    }
}
