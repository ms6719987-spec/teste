import SwiftUI

struct AnimatedTitleText: View {
    let text: String

    @State private var phase: CGFloat = -1.0

    var body: some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        .red,
                        .orange,
                        .yellow,
                        .green,
                        .cyan,
                        .blue,
                        .purple,
                        .red
                    ],
                    startPoint: UnitPoint(x: phase, y: 0.5),
                    endPoint: UnitPoint(x: phase + 1.2, y: 0.5)
                )
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 2.8)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.0
                }
            }
    }
}
