import SwiftUI
import UIKit

struct ContentView: View {
    let onReturnToNetflix: (() -> Void)?
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @State private var tabNavigation: AppTabNavigationState
    @AppStorage(FeatureVisibility.cleanerStorageKey) private var cleanerEnabled = true
    @AppStorage(FeatureVisibility.wallpapersStorageKey) private var wallpapersEnabled = true

    init(onReturnToNetflix: (() -> Void)? = nil) {
        self.onReturnToNetflix = onReturnToNetflix
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Int
        if arguments.contains("--simulate-files-tab") {
            initialTab = 1
        } else if arguments.contains("--simulate-patch-tab") {
            initialTab = 2
        } else if arguments.contains("--simulate-cleaner-tab") {
            initialTab = 3
        } else if arguments.contains("--simulate-wallpaper-tab") {
            initialTab = 4
        } else {
            initialTab = 0
        }
        _tabNavigation = State(initialValue: AppTabNavigationState(selectedTab: initialTab))
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
#endif
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if horizontalSizeClass == .regular {
                    regularLayout
                } else {
                    compactLayout
                }
            }
        }
        .tint(AppTheme.accent)
        .imageScale(.small)
        .simultaneousGesture(
            TapGesture(count: 3)
                .onEnded {
                    onReturnToNetflix?()
                }
        )
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
        }
        .onChange(of: cleanerEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onChange(of: wallpapersEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
    }

    private var compactLayout: some View {
        PatchProjectsView()
    }

    private var regularLayout: some View {
        PatchProjectsView()
    }

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            DashboardView(
                cleanerEnabled: $cleanerEnabled,
                wallpapersEnabled: $wallpapersEnabled,
                wallpapersSupported: wallpapersSupported,
                onOpenPatches: {
                    tabNavigation.select(AppSection.patches.rawValue)
                },
                onReturnToNetflix: onReturnToNetflix ?? {}
            )
        case .files:
            AppDataBrowserView(
                tabSession: filesTabSession
            )
        case .patches:
            PatchProjectsView()
        case .cleaner:
            CleanerView()
        case .wallpapers:
            WallpaperLabView()
        }
    }

    private var tabSelection: Binding<Int> {
        Binding(
            get: { tabNavigation.selectedTab },
            set: { tabNavigation.select($0) }
        )
    }

    private var filesTabSession: Binding<FilesTabSession> {
        Binding(
            get: { tabNavigation.filesTabs },
            set: { tabNavigation.setFilesTabs($0) }
        )
    }

    private var featureVisibility: FeatureVisibility {
        FeatureVisibility(
            cleanerEnabled: cleanerEnabled,
            wallpapersEnabled: wallpapersEnabled,
            wallpapersSupported: wallpapersSupported
        )
    }

    private var wallpapersSupported: Bool {
        WallpaperFeatureSupportPolicy.isSupported(major: AppInfo.versionTuple.major)
    }

    private var selectedVisibleSection: AppSection {
        guard let section = AppSection(rawValue: tabNavigation.selectedTab),
              featureVisibility.isVisible(section) else {
            return .patches
        }
        return section
    }
}

private struct CompactTabLabel: View {
    let title: String
    let systemImage: String

    @ViewBuilder
    var body: some View {
        if title == "Injetor" {
            Image(systemName: "scope")
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28, height: 28)
        } else if let image = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        )?.withRenderingMode(.alwaysTemplate) {
            Image(uiImage: image)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium, design: .rounded))
        }
        Text(title)
    }
}

private extension AppSection {
    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .files: return "tab.files"
        case .patches: return "tab.patches"
        case .cleaner: return "tab.cleaner"
        case .wallpapers: return "tab.wallpapers"
        }
    }

    var portugueseTitle: String {
        switch self {
        case .home: return "Início"
        case .files: return "Arquivos"
        case .patches: return "Injetor"
        case .cleaner: return "Limpeza"
        case .wallpapers: return "Papéis de parede"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .files: return "folder.fill"
        case .patches: return "xmark"
        case .cleaner: return "sparkles"
        case .wallpapers: return "photo.on.rectangle.angled"
        }
    }
}

private struct DashboardView: View {
    @EnvironmentObject private var appState: AppState

    @Binding var cleanerEnabled: Bool
    @Binding var wallpapersEnabled: Bool

    let wallpapersSupported: Bool
    let onOpenPatches: () -> Void
    let onReturnToNetflix: () -> Void

    private let accentRed = Color(red: 1.0, green: 0.10, blue: 0.14)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RedParticleBackground()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    mainCompatibilityCard
                    systemStatusCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 34)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("INJETOR")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Painel de controle")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()

            Image(systemName: "checkmark.shield")
                .font(.system(size: 36, weight: .medium, design: .rounded))
                .foregroundStyle(accentRed)
                .shadow(color: accentRed.opacity(0.55), radius: 10)
                .padding(.top, 4)
        }
    }

    private var mainCompatibilityCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(accentRed.opacity(0.30), lineWidth: 5)
                    .frame(width: 116, height: 116)
                    .shadow(color: accentRed.opacity(0.55), radius: 16)

                Circle()
                    .stroke(accentRed, lineWidth: 5)
                    .frame(width: 92, height: 92)

                Image(systemName: appState.isSupported ? "checkmark.shield" : "xmark.shield")
                    .font(.system(size: 42, weight: .medium, design: .rounded))
                    .foregroundStyle(accentRed)
            }
            .padding(.top, 24)

            HStack(spacing: 10) {
                Circle()
                    .fill(appState.isSupported ? Color.green : Color.red)
                    .frame(width: 14, height: 14)
                    .shadow(color: accentRed.opacity(0.7), radius: 6)

                Text(appState.isSupported ? "SUPORTADO" : "NÃO SUPORTADO")
                    .font(.system(size: 25, weight: .medium, design: .rounded))
                    .foregroundStyle(appState.isSupported ? Color.green : Color.red)
            }

            Text(
                appState.isSupported
                ? "Seu dispositivo e versão do iOS são suportados."
                : "Seu dispositivo ou versão do iOS não são suportados."
            )
            .font(.system(size: 15))
            .foregroundStyle(.white.opacity(0.72))
            .multilineTextAlignment(.center)

            Divider()
                .overlay(Color.white.opacity(0.12))

            HStack(spacing: 0) {
                deviceColumn

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 112)

                iosColumn
            }
            .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.075, green: 0.075, blue: 0.08).opacity(1.0),
                    Color(red: 0.035, green: 0.035, blue: 0.04).opacity(1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(
                        colors: [accentRed, Color.white.opacity(0.10), accentRed.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: accentRed.opacity(0.16), radius: 16)
    }

    private var deviceColumn: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone")
                .font(.system(size: 25, weight: .medium, design: .rounded))
                .foregroundStyle(accentRed)

            Text("DISPOSITIVO")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.60))

            Text(AppInfo.displayMachineName)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .frame(maxWidth: .infinity)
    }

    private var iosColumn: some View {
        VStack(spacing: 10) {
            Text("iOS")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(accentRed)
                .frame(width: 42, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(accentRed, lineWidth: 2)
                )

            Text("IOS ATUAL")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.60))

            Text(AppInfo.osVersion)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private var systemStatusCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(accentRed, lineWidth: 2.5)
                    .frame(width: 62, height: 62)
                    .shadow(color: accentRed.opacity(0.4), radius: 8)

                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 27, weight: .medium, design: .rounded))
                    .foregroundStyle(accentRed)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("STATUS DO SISTEMA")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))

                HStack(spacing: 9) {
                    Circle()
                        .fill(appState.isSupported ? Color.green : Color.red)
                        .frame(width: 13, height: 13)
                        .shadow(color: accentRed.opacity(0.7), radius: 5)

                    Text(appState.isSupported ? "SUPORTADO" : "NÃO SUPORTADO")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                }

                Text(appState.isSupported ? "Tudo funcionando corretamente." : "Sistema não suportado.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.075, green: 0.075, blue: 0.08).opacity(1.0),
                    Color(red: 0.035, green: 0.035, blue: 0.04).opacity(1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(accentRed.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: accentRed.opacity(0.14), radius: 14)
    }
}

private struct RedParticleBackground: View {
    private struct Particle {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let speed: Double
        let phase: Double
        let stretch: CGFloat
    }

    private let particles: [Particle] = [
        .init(x: 0.05, y: 0.12, size: 2.0, speed: 7.2, phase: 0.0, stretch: 8),
        .init(x: 0.18, y: 0.26, size: 1.5, speed: 8.0, phase: 1.1, stretch: 3),
        .init(x: 0.31, y: 0.08, size: 2.2, speed: 6.7, phase: 2.4, stretch: 10),
        .init(x: 0.44, y: 0.34, size: 1.8, speed: 9.1, phase: 3.2, stretch: 4),
        .init(x: 0.58, y: 0.18, size: 2.4, speed: 7.8, phase: 0.8, stretch: 9),
        .init(x: 0.72, y: 0.29, size: 1.6, speed: 8.7, phase: 4.0, stretch: 3),
        .init(x: 0.87, y: 0.11, size: 2.0, speed: 6.9, phase: 1.7, stretch: 7),
        .init(x: 0.95, y: 0.42, size: 1.7, speed: 9.4, phase: 2.9, stretch: 4),
        .init(x: 0.10, y: 0.54, size: 2.1, speed: 8.3, phase: 3.8, stretch: 8),
        .init(x: 0.25, y: 0.68, size: 1.5, speed: 7.0, phase: 2.0, stretch: 3),
        .init(x: 0.39, y: 0.57, size: 2.3, speed: 9.0, phase: 1.4, stretch: 10),
        .init(x: 0.53, y: 0.78, size: 1.6, speed: 7.5, phase: 4.5, stretch: 4),
        .init(x: 0.66, y: 0.63, size: 2.0, speed: 8.5, phase: 0.4, stretch: 8),
        .init(x: 0.79, y: 0.84, size: 1.8, speed: 6.8, phase: 3.1, stretch: 3),
        .init(x: 0.91, y: 0.71, size: 2.2, speed: 9.2, phase: 1.9, stretch: 9),
        .init(x: 0.14, y: 0.91, size: 1.7, speed: 7.7, phase: 2.6, stretch: 5)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            GeometryReader { geo in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate

                    for p in particles {
                        let progress = (t / p.speed + p.phase).truncatingRemainder(dividingBy: 1.0)
                        let y = (p.y + CGFloat(progress) * 0.22).truncatingRemainder(dividingBy: 1.08)
                        let drift = sin(t * 0.65 + p.phase) * 7.0
                        let x = p.x * size.width + drift
                        let py = y * size.height

                        let glowRect = CGRect(
                            x: x - p.size * 3.0,
                            y: py - p.stretch * 0.5,
                            width: p.size * 7.0,
                            height: p.stretch
                        )

                        context.addFilter(.blur(radius: 6.0))
                        context.fill(
                            Path(roundedRect: glowRect, cornerRadius: p.size),
                            with: .color(Color.red.opacity(0.42))
                        )
                        context.addFilter(.blur(radius: 0))

                        let coreRect = CGRect(
                            x: x - p.size * 0.5,
                            y: py - p.stretch * 0.5,
                            width: p.size,
                            height: p.stretch
                        )

                        context.fill(
                            Path(roundedRect: coreRect, cornerRadius: p.size * 0.5),
                            with: .color(Color.red.opacity(1.0))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}


private struct GlobalRedParticleBackground: View {
    private struct Particle {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let speed: Double
        let phase: Double
        let stretch: CGFloat
    }

    private let particles: [Particle] = [
        .init(x: 0.03, y: 0.08, size: 1.8, speed: 7.0, phase: 0.0, stretch: 8),
        .init(x: 0.10, y: 0.20, size: 1.2, speed: 8.4, phase: 1.2, stretch: 4),
        .init(x: 0.18, y: 0.35, size: 2.0, speed: 7.8, phase: 2.2, stretch: 10),
        .init(x: 0.27, y: 0.12, size: 1.5, speed: 9.0, phase: 3.3, stretch: 5),
        .init(x: 0.35, y: 0.48, size: 1.9, speed: 6.9, phase: 0.7, stretch: 8),
        .init(x: 0.44, y: 0.25, size: 1.3, speed: 8.8, phase: 4.0, stretch: 4),
        .init(x: 0.53, y: 0.62, size: 2.1, speed: 7.4, phase: 2.8, stretch: 10),
        .init(x: 0.61, y: 0.18, size: 1.4, speed: 9.2, phase: 1.6, stretch: 5),
        .init(x: 0.70, y: 0.42, size: 1.9, speed: 7.1, phase: 3.7, stretch: 8),
        .init(x: 0.78, y: 0.73, size: 1.2, speed: 8.6, phase: 0.9, stretch: 4),
        .init(x: 0.86, y: 0.29, size: 2.0, speed: 7.7, phase: 2.5, stretch: 9),
        .init(x: 0.94, y: 0.55, size: 1.5, speed: 9.1, phase: 4.4, stretch: 5),
        .init(x: 0.07, y: 0.80, size: 1.8, speed: 7.3, phase: 1.9, stretch: 8),
        .init(x: 0.22, y: 0.90, size: 1.3, speed: 8.9, phase: 3.0, stretch: 4),
        .init(x: 0.48, y: 0.86, size: 2.0, speed: 7.6, phase: 0.5, stretch: 9),
        .init(x: 0.66, y: 0.94, size: 1.5, speed: 8.2, phase: 2.1, stretch: 5),
        .init(x: 0.89, y: 0.88, size: 1.9, speed: 7.0, phase: 3.9, stretch: 8)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                for p in particles {
                    let progress = (t / p.speed + p.phase).truncatingRemainder(dividingBy: 1.0)
                    let py = ((p.y + CGFloat(progress) * 0.26).truncatingRemainder(dividingBy: 1.08)) * size.height
                    let px = p.x * size.width + sin(t * 0.55 + p.phase) * 6.0

                    let glowRect = CGRect(
                        x: px - p.size * 3.5,
                        y: py - p.stretch * 0.5,
                        width: p.size * 7.0,
                        height: p.stretch
                    )

                    context.addFilter(.blur(radius: 6.0))
                    context.fill(
                        Path(roundedRect: glowRect, cornerRadius: p.size),
                        with: .color(Color.red.opacity(0.58))
                    )
                    context.addFilter(.blur(radius: 0))

                    let coreRect = CGRect(
                        x: px - p.size * 0.5,
                        y: py - p.stretch * 0.5,
                        width: p.size,
                        height: p.stretch
                    )

                    context.fill(
                        Path(roundedRect: coreRect, cornerRadius: p.size * 0.5),
                        with: .color(Color.red.opacity(1.0))
                    )
                }
            }
        }
    }
}
