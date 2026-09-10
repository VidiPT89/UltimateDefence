import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void

    @State private var logoOpacity = 0.0
    @State private var logoScale = 0.82
    @State private var creditsOpacity = 0.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("PrimaryOrange"), Color("BurntYellow"), Color("Black")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 128, height: 128)
                    .overlay(
                        Text("UD")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(Color("Black"))
                    )
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("Ultimate Defence")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(logoOpacity)

                Spacer()

                VStack(spacing: 10) {
                    Text("Developed by David Arsénio Martins")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Link("https://ividi.dev/", destination: URL(string: "https://ividi.dev/")!)
                    Link("https://github.com/VidiPT89/", destination: URL(string: "https://github.com/VidiPT89/")!)
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .opacity(creditsOpacity)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.75)) {
                logoOpacity = 1
                logoScale = 1
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.45)) {
                creditsOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                onFinished()
            }
        }
    }
}
