import SwiftUI

struct AnimatedPatchRowTitle: View {
    let text: String

    private let fixedRed = Color(red: 0.92, green: 0.035, blue: 0.055)

    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(fixedRed)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
}
