import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false
    @State private var tabNavigation: AppTabNavigationState
    @State private var showSettings = false
    @State private var showLogs = false

    init() {
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Int
        if arguments.contains("--simulate-new-tab") {
            initialTab = 1
        } else if arguments.contains("--simulate-sources-tab") {
            initialTab = 2
        } else if arguments.contains("--simulate-installed-tab")
                    || arguments.contains("--simulate-patch-tab")
                    || arguments.contains("--simulate-wallpaper-tab") {
            initialTab = 3
        } else if arguments.contains("--simulate-files-tab") {
            initialTab = 4
        } else if arguments.contains("--simulate-search-tab") {
            initialTab = 5
        } else {
            initialTab = 0
        }
        _tabNavigation = State(initialValue: AppTabNavigationState(selectedTab: initialTab))
        _showSettings = State(
            initialValue: arguments.contains("--simulate-settings")
        )
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
#endif
    }

    var body: some View {
        HSVIPSDashboard(installedContent: AnyView(sectionContent(.installed)))
        .tint(AppTheme.accent)
        .imageScale(.small)
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.installed.rawValue) }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.installed.rawValue) }
        }
        .onChange(of: developerModeEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
        .patchStorePresentation(patchStore)
        .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
    }

    private var compactLayout: some View {
        TabView(selection: tabSelection) {
            ForEach(featureVisibility.visibleSections) { section in
                sectionContent(section)
                    .tabItem {
                        CompactTabLabel(
                            title: language.text(section.titleKey),
                            systemImage: section.systemImage
                        )
                    }
                    .tag(section.rawValue)
            }
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(featureVisibility.visibleSections) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            tabNavigation.select(section.rawValue)
                        }
                    } label: {
                        Label(language.text(section.titleKey), systemImage: section.systemImage)
                            .fontWeight(section.rawValue == tabNavigation.selectedTab ? .semibold : .regular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        section.rawValue == tabNavigation.selectedTab
                            ? AppTheme.accent.opacity(0.14)
                            : Color.clear
                    )
                    .accessibilityAddTraits(
                        section.rawValue == tabNavigation.selectedTab ? .isSelected : []
                    )
                }
            }
            .navigationTitle("3105")
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            sectionContent(selectedVisibleSection)
                .id(selectedVisibleSection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            RepositoryHomeView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .new:
            RepositoryNewView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .sources:
            RepositorySourcesView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .installed:
            PatchProjectsView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .files:
            AppDataBrowserView(
                tabSession: filesTabSession,
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .search:
            RepositorySearchView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
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
        FeatureVisibility(developerModeEnabled: developerModeActive)
    }

    private var developerModeActive: Bool {
#if targetEnvironment(simulator)
        developerModeEnabled
            || ProcessInfo.processInfo.arguments.contains("--simulate-developer-mode")
            || ProcessInfo.processInfo.arguments.contains("--simulate-files-tab")
#else
        developerModeEnabled
#endif
    }

    private var selectedVisibleSection: AppSection {
        let selected = AppSection(rawValue: tabNavigation.selectedTab)
        return selected.flatMap {
            featureVisibility.isVisible($0) ? $0 : nil
        } ?? .home
    }

    private func openSettings() {
        showSettings = true
    }

    private func openLogs() {
        showLogs = true
    }
}

private struct CompactTabLabel: View {
    let title: String
    let systemImage: String

    @ViewBuilder
    var body: some View {
        if let image = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        )?.withRenderingMode(.alwaysTemplate) {
            Image(uiImage: image)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
        }
        Text(title)
    }
}

private extension AppSection {
    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .new: return "tab.new"
        case .sources: return "tab.sources"
        case .installed: return "tab.installed"
        case .files: return "tab.files"
        case .search: return "tab.search"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .new: return "clock.fill"
        case .sources: return "shippingbox.fill"
        case .installed: return "tray.full.fill"
        case .files: return "folder.fill"
        case .search: return "magnifyingglass"
        }
    }
}


// HS VIPS visual dashboard. Existing Installed functionality remains available.
private struct HSVIPSDashboard: View {
    let installedContent: AnyView
    @State private var selectedCategory = "FF NORMAL"
    @State private var showInstalled = false
    @State private var showLaunchNotice = false
    private let red = Color(red: 1, green: 0.22, blue: 0.27)
    private let categories: [(String, String)] = [
        ("FF NORMAL", "flame.fill"), ("FF MAX", "flame"), ("AP", "shield.lefthalf.filled"),
        ("SKINS / TEXTURAS", "square.grid.2x2.fill"), ("HOLOGRAMAS", "wand.and.stars"), ("OUTROS", "shippingbox.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 22) {
                    infoRow("Device", value: "iPhone", icon: "iphone", color: red)
                    infoRow("Support", value: "SUPPORTED", icon: "checkmark.seal.fill", color: .green)
                    infoRow("Licença", value: "—", icon: "lock.shield.fill", color: .yellow)
                }
                .padding(22)
                .background(panel)

                VStack(spacing: 25) {
                    sectionHeader("CATEGORIAS ONLINE", icon: "bolt.fill")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(categories, id: \.0) { category in
                            Button {
                                selectedCategory = category.0
                            } label: {
                                VStack(spacing: 13) {
                                    Image(systemName: category.1).font(.system(size: 29, weight: .bold))
                                    Text(category.0).font(.system(size: 10, weight: .heavy, design: .rounded))
                                        .lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .foregroundStyle(selectedCategory == category.0 ? .white : .gray)
                                .frame(maxWidth: .infinity).frame(height: 112)
                                .background(selectedCategory == category.0 ? red : Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 21))
                                .overlay(RoundedRectangle(cornerRadius: 21).stroke(red.opacity(0.5)))
                            }.buttonStyle(.plain)
                        }
                    }
                    Text("Nenhum patch nesta categoria.").foregroundStyle(.gray).padding(.vertical, 22)
                    Button { showInstalled = true } label: {
                        Label("Abrir Installed", systemImage: "square.stack.3d.up.fill")
                            .font(.system(size: 16, weight: .bold)).foregroundStyle(red)
                    }
                    Button { showInstalled = true } label: {
                        Label("Atualizar catálogo", systemImage: "arrow.clockwise")
                            .font(.system(size: 15, weight: .bold)).foregroundStyle(red)
                    }
                }.padding(20).background(panel)

                VStack(spacing: 23) {
                    sectionHeader("LAUNCH GAME", icon: "arrow.up.right.square.fill")
                    HStack(spacing: 12) {
                        launchButton("FF NORMAL")
                        launchButton("FF MAX")
                    }
                }.padding(20).background(panel)

                Button { showInstalled = true } label: {
                    VStack(spacing: 5) {
                        Image(systemName: "flame.fill").font(.system(size: 32))
                        Text("HS VIPS").font(.system(size: 15, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(red).padding(.horizontal, 40).padding(.vertical, 15)
                    .background(Color(white: 0.18), in: Capsule())
                    .overlay(Capsule().stroke(red.opacity(0.7)))
                }.padding(.vertical, 25)
            }.padding(16)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showInstalled) { installedContent }
        .alert("Launch Game", isPresented: $showLaunchNotice) {
            Button("OK", role: .cancel) { }
        } message: { Text("Abertura do jogo ainda não configurada.") }
    }

    private var panel: some View {
        RoundedRectangle(cornerRadius: 28).fill(Color(red: 0.045, green: 0.008, blue: 0.012))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(red.opacity(0.32), lineWidth: 1))
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).foregroundStyle(red).font(.system(size: 23))
                .frame(width: 48, height: 48)
                .background(red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            Text(title).font(.system(size: 19, weight: .black, design: .rounded))
                .tracking(2).minimumScaleFactor(0.75).lineLimit(1)
            Spacer(minLength: 0)
            Circle().fill(red).frame(width: 7, height: 7)
        }
    }

    private func infoRow(_ title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon).foregroundStyle(color).font(.system(size: 23))
                .frame(width: 48, height: 48)
                .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            Text(title).foregroundStyle(.gray)
            Spacer()
            Text(value).fontWeight(.heavy).lineLimit(1)
        }
    }

    private func launchButton(_ title: String) -> some View {
        Button { showLaunchNotice = true } label: {
            Label(title, systemImage: "play.fill")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 68)
                .background(red.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(red.opacity(0.55)))
        }
    }
}
