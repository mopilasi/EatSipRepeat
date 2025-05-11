import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var logoAppeared = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.theme.primaryCoral
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 100)

                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                    .scaleEffect(logoAppeared ? 1 : 0.5)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            logoAppeared = true
                        }
                    }

                Text("Take the guesswork out of hosting a dinner party")
                    .font(.custom("Lora-Regular", size: 18))
                    .foregroundColor(Color.theme.cream)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)

                Spacer()

                Button(action: {
                    hasSeenWelcome = true
                }) {
                    Text("Let’s go")
                        .font(.custom("DrukWide-Bold", size: 16))
                        .foregroundColor(Color.theme.cream)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .background(Color.theme.forestGreen)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
                .scaleEffect(pulse ? 1.05 : 1)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 1)
                            .repeatForever(autoreverses: true)
                    ) {
                        pulse = true
                    }
                }
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}

