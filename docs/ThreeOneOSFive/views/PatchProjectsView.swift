import SwiftUI
import UIKit
import UniformTypeIdentifiers

private enum PatchPackagePickerPolicy {
    static let packageType = UTType(filenameExtension: "3105") ?? .data
    static let allowedContentTypes: [UTType] = [packageType, .data]
    static let copiesSelectedDocument = true
}

struct PatchProjectsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var draftCoordinator: PatchDraftCoordinator
    @StateObject private var store = PatchProjectStore()

    @State private var showCreate = false
    @State private var showImporter = false
    @State private var searchText = ""
    @State private var showSkins = false

    @AppStorage("selectedFreeFireVariant") private var selectedGameRaw = "normal"
    @AppStorage(AppTheme.themeStorageKey) private var selectedThemeRaw = "purple"

    private enum FreeFireVariant: String {
        case normal
        case max
    }

    private var selectedGame: FreeFireVariant {
        get { FreeFireVariant(rawValue: selectedGameRaw) ?? .normal }
        nonmutating set { selectedGameRaw = newValue.rawValue }
    }

    private var categoryItems: [PatchLibraryItem] {
        store.items.filter { $0.project != nil }
    }

    private var filteredItems: [PatchLibraryItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return categoryItems }

        return categoryItems.filter { item in
            if item.packageURL.lastPathComponent.localizedCaseInsensitiveContains(query) {
                return true
            }

            guard let project = item.project else { return false }
            return project.name.localizedCaseInsensitiveContains(query)
                || project.allBundleIdentifiers.contains {
                    $0.localizedCaseInsensitiveContains(query)
                }
                || project.directories.contains {
                    $0.relativePath.localizedCaseInsensitiveContains(query)
                }
                || project.rules.contains {
                    $0.relativePath.localizedCaseInsensitiveContains(query)
                        || $0.replacementFilename.localizedCaseInsensitiveContains(query)
                }
        }
    }

    init() {
#if targetEnvironment(simulator)
        _showCreate = State(
            initialValue: ProcessInfo.processInfo.arguments.contains("--simulate-patch-editor")
        )
#endif
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WarRedBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        heroHeader
                        supportStatusCard
                        gameSelector

                        if !gameFilteredItems.isEmpty {
                            projectSection
                        }

                        CleanerView(compactMode: true)
                            .padding(.top, 4)

                        footer
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)

            .sheet(isPresented: $showSkins) {
                SkinsView(
                    items: skinsFilteredItems,
                    selectedGameRaw: selectedGameRaw,
                    store: store
                )
                .preferredColorScheme(.dark)
            }

            .sheet(isPresented: $showImporter) {
                FileDocumentPicker(
                    allowedContentTypes: PatchPackagePickerPolicy.allowedContentTypes,
                    copiesSelectedDocument: PatchPackagePickerPolicy.copiesSelectedDocument,
                    allowsMultipleSelection: false,
                    onSelection: { result in
                        showImporter = false
                        if case .success(let urls) = result, let url = urls.first {
                            store.importPackage(at: url)
                        }
                    },
                    onCancel: {
                        showImporter = false
                    }
                )
                .ignoresSafeArea()
            }

            .sheet(isPresented: $showCreate) {
                PatchProjectEditorView(
                    existingProject: nil,
                    passwordIsProtected: false
                ) { project, password in
                    store.create(project: project, password: password)
                }
            }

            .sheet(item: $draftCoordinator.request) { request in
                PatchProjectEditorView(
                    existingProject: nil,
                    passwordIsProtected: false,
                    initialDraft: request.draft
                ) { project, password in
                    store.create(project: project, password: password)
                    draftCoordinator.clear()
                }
            }

            .sheet(item: $store.passwordRequest, onDismiss: store.cancelUnlock) { _ in
                PatchUnlockView(store: store)
            }

            .alert(item: $store.alert) { alert in
                Alert(
                    title: Text(language.text(alert.titleKey)),
                    message: Text(alert.message(language: language)),
                    dismissButton: .default(Text(language.text("common.ok")))
                )
            }

            .onAppear {
                store.reload()
                consumeExternalImport()
            }
            .onChange(of: draftCoordinator.importRequest?.id) { _ in
                consumeExternalImport()
            }
        }
    }

    private var heroHeader: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(AppTheme.accent)
                        .rotationEffect(.degrees(-8))

                    Text("INJETOR IOS")
                        .foregroundStyle(AppTheme.accent)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .italic()

                    Text("O MELHOR INJETOR FEITO PARA IOS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .tracking(1.0)
                        .padding(.top, 2)



                }

                Spacer()
            }

            HStack(alignment: .top, spacing: 10) {
                Menu {
                    Button {
                        selectedThemeRaw = "purple"
                    } label: {
                        Label(
                            "Roxo",
                            systemImage: selectedThemeRaw == "purple"
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                    }

                    Button {
                        selectedThemeRaw = "white"
                    } label: {
                        Label(
                            "Branco",
                            systemImage: selectedThemeRaw == "white"
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                    }

                    Button {
                        selectedThemeRaw = "red"
                    } label: {
                        Label(
                            "Vermelho",
                            systemImage: selectedThemeRaw == "red"
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(.white)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(minHeight: 180)
    }

    private var gameSelector: some View {
        HStack(spacing: 8) {
            gameTab(
                title: "FF NORMAL",
                imageName: "FreeFireNormalIcon",
                selected: selectedGame == .normal
            ) {
                selectedGame = .normal
            }

            gameTab(
                title: "FF MAX",
                imageName: "FreeFireMaxIcon",
                selected: selectedGame == .max
            ) {
                selectedGame = .max
            }

            Menu {
                Button {
                    showSkins = true
                } label: {
                    Label("SKINS", systemImage: "tshirt.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(Color.clear)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var gameFilteredItems: [PatchLibraryItem] {
        let isMax = selectedGame == .max
        let targetPath = isMax
            ? "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar/assetindexer.YJ~2FW7EkU5pRkVg51NrKyx4LXid8~3D"
            : "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar/assetindexer.U6Zffc4YIR3DslNj3cXvYGAqz58~3D"
        let targetBundleID = isMax ? "com.dts.freefiremax" : "com.dts.freefireth"

        return filteredItems.filter { item in
            guard let project = item.project else { return false }
            return project.rules.contains { rule in
                rule.bundleID == targetBundleID
                    && rule.relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/")) == targetPath
            }
        }
    }

    private var skinsFilteredItems: [PatchLibraryItem] {
        gameFilteredItems.filter { item in
            let projectName = item.project?.name ?? ""
            let packageName = item.packageURL.lastPathComponent
            return !projectName.localizedCaseInsensitiveContains("HS")
                && !packageName.localizedCaseInsensitiveContains("HS")
        }
    }

    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONFIGURAÇÕES")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(3.4)
                .foregroundStyle(.white.opacity(0.52))

            ForEach(gameFilteredItems) { item in
                itemRow(item)
            }
        }
    }

    private var supportStatusCard: some View {
        let supported = appState.isSupported
        let statusColor = supported
            ? Color(red: 0.18, green: 0.86, blue: 0.40)
            : Color(red: 1.00, green: 0.12, blue: 0.16)

        return HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
                .shadow(color: statusColor.opacity(0.65), radius: 5)

            VStack(alignment: .leading, spacing: 2) {
                Text("iOS \(AppInfo.osVersion)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))

                Text(supported ? "VERSÃO SUPORTADA" : "VERSÃO NÃO SUPORTADA")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
            }

            Spacer()

            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.035))
        )
    }

    private var footer: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text("INJETOR IOS")
                Text("SEMPRE UM PASSO À FRENTE")
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {

            }
        }
        .font(.system(size: 8, weight: .medium, design: .rounded))
        .tracking(2.6)
        .foregroundStyle(.white.opacity(0.44))
        .padding(.top, 8)
    }

    private func gameTab(
        title: String,
        imageName: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(imageName)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                    )

                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        selected ? AppTheme.accent.opacity(0.95) : Color.white.opacity(0.08),
                        lineWidth: selected ? 1.2 : 0.7
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func itemRow(_ item: PatchLibraryItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 50, height: 50)

                Image(systemName: "scope")
                    .font(.system(size: 23, weight: .black))
                    .foregroundStyle(AppTheme.accent)
            }

            Group {
                if item.isLocked {
                    Button {
                        store.requestUnlock(for: item)
                    } label: {
                        projectText(item)
                    }
                    .buttonStyle(.plain)
                } else {
                    projectText(item)
                }
            }

            Toggle(
                "",
                isOn: Binding(
                    get: { store.isApplied(projectID: item.id) },
                    set: { enabled in
                        store.setApplied(
                            enabled,
                            for: item,
                            freeFireVariant: selectedGameRaw
                        )
                    }
                )
            )
            .labelsHidden()
            .tint(AppTheme.accent)
            .disabled(item.isLocked || store.isBusy)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func projectText(_ item: PatchLibraryItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.project?.name ?? language.text("patch.locked_project"))
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(
                item.isLocked
                ? language.text("patch.tap_to_unlock")
                : language.text("patch.project")
            )
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.50))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func consumeExternalImport() {
        guard let request = draftCoordinator.importRequest else { return }
        draftCoordinator.clearImport()
        store.importPackage(from: request.source)
    }
}

private struct SkinsView: View {
    let items: [PatchLibraryItem]
    let selectedGameRaw: String
    @ObservedObject var store: PatchProjectStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                WarRedBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if items.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "tshirt")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(AppTheme.accent)

                                Text("NENHUMA SKIN DISPONÍVEL")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Os arquivos HS ficam fora desta aba.")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 80)
                        } else {
                            ForEach(items) { item in
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(AppTheme.accent.opacity(0.12))
                                            .frame(width: 50, height: 50)

                                        Image(systemName: "tshirt.fill")
                                            .font(.system(size: 22, weight: .black))
                                            .foregroundStyle(AppTheme.accent)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.project?.name ?? "SKIN")
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundStyle(.white)
                                            .lineLimit(2)

                                        Text("SKIN • FF \(selectedGameRaw.uppercased())")
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.50))
                                    }

                                    Spacer()

                                    Toggle(
                                        "",
                                        isOn: Binding(
                                            get: { store.isApplied(projectID: item.id) },
                                            set: { enabled in
                                                store.setApplied(
                                                    enabled,
                                                    for: item,
                                                    freeFireVariant: selectedGameRaw
                                                )
                                            }
                                        )
                                    )
                                    .labelsHidden()
                                    .tint(AppTheme.accent)
                                    .disabled(item.isLocked || store.isBusy)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.58))
                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("SKINS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("FECHAR") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
}

private struct WarRedBackground: View {
    var body: some View {
        ZStack {
            Color.black

            LinearGradient(
                colors: [
                    Color.black,
                    AppTheme.accent.opacity(0.10),
                    Color.black,
                    AppTheme.accent.opacity(0.05),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    AppTheme.accent.opacity(0.34),
                    AppTheme.accent.opacity(0.08),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 330
            )

            RadialGradient(
                colors: [
                    AppTheme.accent.opacity(0.18),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 320
            )

            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.13))
                        .frame(width: 160, height: 160)
                        .blur(radius: 45)
                        .position(x: proxy.size.width * 0.84, y: 130)

                    Circle()
                        .fill(AppTheme.accent.opacity(0.10))
                        .frame(width: 110, height: 110)
                        .blur(radius: 35)
                        .position(x: proxy.size.width * 0.10, y: proxy.size.height * 0.64)

                    Rectangle()
                        .fill(AppTheme.accent.opacity(0.09))
                        .frame(width: 1, height: proxy.size.height * 0.60)
                        .rotationEffect(.degrees(28))
                        .position(x: proxy.size.width * 0.74, y: proxy.size.height * 0.42)
                }
            }
        }
    }
}


private struct PatchProjectRow: View {
    let item: PatchLibraryItem
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            AppRowIcon(systemName: item.isLocked ? "lock.doc.fill" : "shippingbox.fill")
            VStack(alignment: .leading, spacing: 3) {
                AnimatedPatchRowTitle(
                    text: item.project?.name ?? language.text("patch.locked_project")
                )
                Text(item.isLocked
                     ? language.text("patch.tap_to_unlock")
                     : language.text(
                        item.summary.schemaVersion >= 2 ? "patch.workspace_items_count" : "patch.rules_count",
                        Int64((item.project?.rules.count ?? 0) + (item.project?.directories.count ?? 0))
                     ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if item.summary.isPasswordProtected {
                Image(systemName: "key.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(language.text("patch.password_protected"))
            }
        }
        .padding(.vertical, 4)
    }
}

private struct PatchUnlockView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: PatchProjectStore
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField(language.text("patch.password"), text: $password)
                        .textContentType(.password)
                        .submitLabel(.done)
                        .onSubmit(unlock)
                        .onChange(of: password) { _ in
                            store.clearUnlockError()
                        }
                    if let errorKey = store.unlockErrorKey {
                        Text(language.text(errorKey))
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text(language.text("patch.password_once_message"))
                }
            }
            .navigationTitle(language.text("patch.unlock"))
            .navigationBarTitleDisplayMode(.inline)

        }
    }

    private func unlock() {
        guard !password.isEmpty else { return }
        store.unlock(password: password)
    }
}

private struct PatchProjectDetailView: View {
    @Environment(\.appLanguage) private var language
    @ObservedObject var store: PatchProjectStore
    let projectID: UUID
    @State private var showEditor = false
    @State private var editingRule: PatchRule?
    @State private var isWorking = false
    @State private var actionAlert: PatchStoreAlert?
    @State private var shareRequest: PatchShareRequest?

    private var item: PatchLibraryItem? {
        store.items.first(where: { $0.id == projectID })
    }

    private var isWorkspaceProject: Bool {
        (item?.summary.schemaVersion ?? 1) >= 2
    }

    var body: some View {
        List {
            if let item, let project = item.project {
                if isWorkspaceProject {
                    Section {
                        ForEach(project.allBundleIdentifiers, id: \.self) { bundleID in
                            Label {
                                Text(bundleID)
                                    .font(.subheadline.monospaced())
                            } icon: {
                                Image(systemName: "app.dashed")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        LabeledContent(language.text("patch.files")) {
                            Text("\(project.rules.count)")
                        }
                        LabeledContent(language.text("patch.folders")) {
                            Text("\(project.directories.count)")
                        }
                        if let workspaceURL = item.workspaceURL {
                            NavigationLink {
                                FileBrowserView(
                                    containerPath: workspaceURL.path,
                                    title: project.name,
                                    bundleID: nil
                                )
                            } label: {
                                Label(
                                    language.text("patch.open_workspace"),
                                    systemImage: "folder"
                                )
                            }
                        }
                    } header: {
                        Text(language.text("patch.workspace"))
                    } footer: {
                        Text(language.text("patch.workspace_detail_footer"))
                    }
                } else {
                    Section {
                        ForEach(project.rules) { rule in
                            Button {
                                editingRule = rule
                            } label: {
                                HStack(spacing: 10) {
                                    ruleSummary(rule)
                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(language.text("patch.edit_rule_hint"))
                        }
                    } header: {
                        Text(language.text("patch.rules"))
                    } footer: {
                        Text(language.text("patch.legacy_footer"))
                    }
                }

                Section(language.text("patch.password")) {
                    HStack(spacing: 12) {
                        Image(systemName: item.summary.isPasswordProtected ? "lock.fill" : "lock.open")
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 24)
                        Text(language.text(item.summary.isPasswordProtected
                            ? "patch.password_locked"
                            : "patch.no_password"))
                            .font(.subheadline)
                    }
                }

            }
        }
        .listStyle(.plain)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                AnimatedTitleText(text: item?.project?.name ?? language.text("patch.title"))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isWorking {
                    ProgressView()
                } else if !isWorkspaceProject {
                    Button(language.text("patch.edit")) { showEditor = true }
                        .disabled(item?.project == nil)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            if let item, let project = item.project {
                PatchProjectEditorView(
                    existingProject: project,
                    passwordIsProtected: item.summary.isPasswordProtected
                ) { updatedProject, _ in
                    store.update(project: updatedProject)
                }
            }
        }
        .sheet(item: $editingRule) { rule in
            PatchRuleEditorView(rule: rule) { updatedRule in
                updateRule(updatedRule)
            }
        }
        .alert(item: $actionAlert) { alert in
            Alert(
                title: Text(language.text(alert.titleKey)),
                message: Text(alert.message(language: language)),
                dismissButton: .default(Text(language.text("common.ok")))
            )
        }
        .sheet(item: $shareRequest) { request in
            PatchActivityView(items: [request.url])
                .ignoresSafeArea()
        }
    }

    private func actionLabel(_ key: String, systemImage: String) -> some View {
        Label(language.text(key), systemImage: systemImage)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ruleSummary(_ rule: PatchRule) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(rule.bundleID)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(rule.relativePath)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Label(rule.replacementFilename, systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.vertical, 3)
    }

    private func updateRule(_ updatedRule: PatchRule) {
        guard var project = item?.project,
              let index = project.rules.firstIndex(where: { $0.id == updatedRule.id }) else {
            return
        }
        project.rules[index] = updatedRule
        project.updatedAt = Date()
        do {
            try PatchPackageCodec.validate(project)
            store.update(project: project)
        } catch let error as PatchPackageError {
            actionAlert = PatchStoreAlert(
                titleKey: "common.failed",
                messageKey: error.localizationKey,
                messageArgument: error.localizationArgument
            )
        } catch {
            actionAlert = PatchStoreAlert(
                titleKey: "common.failed",
                messageKey: "patch.error.invalid_project"
            )
        }
    }

    private func prepareExport() {
        guard let item else { return }
        isWorking = true
        Task.detached(priority: .userInitiated) {
            do {
                if item.summary.schemaVersion >= 2 {
                    _ = try PatchProjectLibrary.synchronizeWorkspace(item: item)
                }
                await MainActor.run {
                    store.reload()
                    isWorking = false
                    shareRequest = PatchShareRequest(url: item.packageURL)
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    isWorking = false
                    actionAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: error.localizationKey,
                        messageArgument: error.localizationArgument
                    )
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    actionAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: "patch.error.invalid_project"
                    )
                }
            }
        }
    }

}

private struct PatchShareRequest: Identifiable {
    let id = UUID()
    let url: URL
}

private struct PatchActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}




