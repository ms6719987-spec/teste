import SwiftUI

enum AppTheme {
    static let accent = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.95, green: 0.12, blue: 0.18, alpha: 1.00)
                : UIColor(red: 0.82, green: 0.04, blue: 0.10, alpha: 1.00)
        }
    )
    static let pageBackground = Color(uiColor: .systemBackground)
    static let consoleBackground = Color(uiColor: .secondarySystemBackground)
    static let pageInset: CGFloat = 16
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18
    static let contentCardCornerRadius: CGFloat = 20
    static let contentCardInset: CGFloat = 16
    static let contentCardPadding: CGFloat = 16
}

struct AppCardBorder: View {
    var body: some View {
        RoundedRectangle(
            cornerRadius: AppTheme.contentCardCornerRadius,
            style: .continuous
        )
        .strokeBorder(
            Color(uiColor: .separator).opacity(0.22),
            lineWidth: 0.5
        )
        .accessibilityHidden(true)
    }
}


// MARK: - Animated rain / glass UI

struct RainGlassBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black

                RadialGradient(
                    colors: [
                        AppTheme.accent.opacity(0.20),
                        .clear
                    ],
                    center: .topTrailing,
                    startRadius: 10,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.85
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.10, green: 0.16, blue: 0.22).opacity(0.70),
                        .clear
                    ],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.80
                )

                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        drawRain(in: &context, size: size, time: time)
                    }
                    .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea()
        }
        .accessibilityHidden(true)
    }

    private func drawRain(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let drops = 105
        let travel = size.height + 180

        for index in 0..<drops {
            let seed = Double(index)
            let x = pseudoRandom(seed * 13.17) * size.width
            let length = 8 + pseudoRandom(seed * 3.71) * 28
            let speed = 85 + pseudoRandom(seed * 9.23) * 150
            let phase = pseudoRandom(seed * 17.41) * travel
            let y = ((time * speed + phase).truncatingRemainder(dividingBy: travel)) - 90
            let alpha = 0.08 + pseudoRandom(seed * 5.11) * 0.20
            let width = 0.45 + pseudoRandom(seed * 2.17) * 0.75

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x - 2.0, y: y + length))
            context.stroke(
                path,
                with: .color(.white.opacity(alpha)),
                lineWidth: width
            )
        }

        // A few larger droplets give the background a wet-glass feel.
        for index in 0..<18 {
            let seed = Double(index + 200)
            let x = pseudoRandom(seed * 2.93) * size.width
            let baseY = pseudoRandom(seed * 7.31) * size.height
            let pulse = 0.65 + 0.35 * sin(time * 0.9 + seed)
            let radius = 1.2 + pseudoRandom(seed * 4.19) * 2.8

            context.fill(
                Path(ellipseIn: CGRect(
                    x: x,
                    y: baseY,
                    width: radius,
                    height: radius * 1.8
                )),
                with: .color(.white.opacity(0.07 * pulse))
            )
        }
    }

    private func pseudoRandom(_ value: Double) -> Double {
        let x = sin(value * 12.9898) * 43758.5453
        return x - floor(x)
    }
}

struct GlassPanel<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(cornerRadius: CGFloat = 18, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.025))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.26),
                                AppTheme.accent.opacity(0.28),
                                Color.white.opacity(0.07)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: AppTheme.accent.opacity(0.10), radius: 18, y: 8)
    }
}

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(tint.opacity(0.12))
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 36)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.28), lineWidth: 0.8)
        }
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon60x60")
                ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                ?? UIImage(named: "AppIcon") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}
