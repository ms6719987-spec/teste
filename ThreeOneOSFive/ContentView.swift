import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore

    var body: some View {
        PatchProjectsView()
            .tint(AppTheme.accent)
            .imageScale(.small)
            .patchStorePresentation(patchStore)
            .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
    }
}
