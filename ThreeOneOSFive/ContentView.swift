import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var patchStore: PatchProjectStore
    @AppStorage("external.login.authenticated") private var isAuthenticated = false
    // Data fixa: 12/10/2026 às 00:00 no horário de Brasília + 32 dias.
    private let licenseExpiry: Double = 1794538800
    @AppStorage("external.login.lastSeen") private var lastSeenTimestamp: Double = 0
    @AppStorage("external.login.clockRollback") private var clockRollbackDetected = false
    @State private var showSettings = false
    @State private var showLogs = false

    private var hasExpired: Bool {
        Date().timeIntervalSince1970 >= licenseExpiry || clockRollbackDetected
    }

    private var daysRemaining: Int {
        max(0, Int(ceil((licenseExpiry - Date().timeIntervalSince1970) / 86400)))
    }

    private func validateClock() {
        let now = Date().timeIntervalSince1970
        if lastSeenTimestamp > 0 && now < lastSeenTimestamp - 300 {
            clockRollbackDetected = true
        } else if now > lastSeenTimestamp {
            lastSeenTimestamp = now
        }
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
                    if !hasExpired {
                        Text("Expira em \(daysRemaining) dias")
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
                    isAuthenticated = true
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { validateClock() }
    }
}

private struct ExternalLoginView: View {
    let isExpired: Bool
    let onLogin: () -> Void

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
                        } else if password == "external123" {
                            onLogin()
                        } else {
                            errorMessage = "Senha incorreta."
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

                Text("LICENÇA VÁLIDA ATÉ 13/11/2026")
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
