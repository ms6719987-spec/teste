import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @AppStorage("external.login.authenticated") private var isAuthenticated = false
    @AppStorage("external.login.expiry") private var expiryTimestamp: Double = 0
    @State private var showSettings = false
    @State private var showLogs = false

    private var hasExpired: Bool {
        expiryTimestamp > 0 && Date().timeIntervalSince1970 >= expiryTimestamp
    }

    var body: some View {
        Group {
            if isAuthenticated && !hasExpired {
                PatchProjectsView(
                    onOpenSettings: { showSettings = true },
                    onOpenLogs: { showLogs = true }
                )
                .tint(AppTheme.accent)
                .overlay(alignment: .topTrailing) {
                    if expiryTimestamp > 0 {
                        Text("Expira em \(max(0, Int(ceil((expiryTimestamp - Date().timeIntervalSince1970) / 86400)))) dias")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.45), in: Capsule())
                            .padding(.top, 6)
                            .padding(.trailing, 10)
                    }
                }
                .sheet(isPresented: $showSettings) { SettingsView() }
                .sheet(isPresented: $showLogs) { LogView() }
                .patchStorePresentation(patchStore)
            } else {
                ExternalLoginView(isExpired: hasExpired) {
                    if expiryTimestamp == 0 {
                        expiryTimestamp = Date().addingTimeInterval(32 * 24 * 60 * 60).timeIntervalSince1970
                    }
                    isAuthenticated = true
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct ExternalLoginView: View {
    let isExpired: Bool
    let onLogin: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.025, green: 0.025, blue: 0.035), Color(red: 0.16, green: 0.015, blue: 0.025), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .red.opacity(0.65), radius: 14)
                Text("EXTERNAL")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Color(red: 1, green: 0.15, blue: 0.19))
                Text(isExpired ? "ACESSO EXPIRADO" : "ENTRAR NA SUA CONTA")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.72))

                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill").foregroundStyle(.red)
                        TextField("Usuário", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(15)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(.white.opacity(0.12), lineWidth: 1))

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill").foregroundStyle(.red)
                        SecureField("Senha", text: $password)
                    }
                    .padding(15)
                    .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(.white.opacity(0.12), lineWidth: 1))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        if isExpired {
                            errorMessage = "Este acesso expirou. É necessário renovar a licença."
                        } else if username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "external"
                                    && password == "external123" {
                            onLogin()
                        } else {
                            errorMessage = "Usuário ou senha incorretos."
                        }
                    } label: {
                        HStack {
                            Text("ENTRAR")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                        .padding(17)
                        .background(LinearGradient(colors: [.red, Color(red: 0.55, green: 0.01, blue: 0.05)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(.white.opacity(0.18), lineWidth: 1))
                        .shadow(color: .red.opacity(0.28), radius: 12, y: 5)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.red.opacity(0.28), lineWidth: 1))

                Text("LICENÇA DE 32 DIAS APÓS O PRIMEIRO LOGIN")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
                Text("© Teus ios")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 26)
        }
    }
}
