import SwiftUI

struct NetflixCoverView: View {
    @State private var tapCount = 0
    @State private var showInjector = false
    @State private var resetTask: Task<Void, Never>?
    @State private var selectedTab: FakeNetflixTab = .home

    @State private var isLoading = true
    @State private var selectedMovie: MovieCard?
    @State private var myList: Set<String> = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showInjector {
                ContentView(onReturnToNetflix: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showInjector = false
                    }
                })
                .transition(.opacity)
            } else if isLoading {
                NetflixLoadingView {
                    withAnimation(.easeOut(duration: 0.22)) {
                        isLoading = false
                    }
                }
                    .transition(.opacity)
            } else {
                netflixShell
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showInjector)
        .animation(.easeInOut(duration: 0.25), value: isLoading)
        .sheet(item: $selectedMovie) { movie in
            MovieDetailView(
                movie: movie,
                isInList: myList.contains(movie.title),
                onToggleList: {
                    if myList.contains(movie.title) {
                        myList.remove(movie.title)
                    } else {
                        myList.insert(movie.title)
                    }
                }
            )
            .preferredColorScheme(.dark)
        }
    }

    private var netflixShell: some View {
        VStack(spacing: 0) {
            topBar

            Group {
                switch selectedTab {
                case .home:
                    homeContent
                case .trending:
                    trendingContent
                case .newAndHot:
                    newContent
                case .downloads:
                    downloadsContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
        .background(Color.black)
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                registerLogoTap()
            } label: {
                Image("NetflixLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: {}) {
                Image(systemName: "airplayvideo")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Button(action: {}) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.black)
    }

    private var homeContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                hero

                posterSection(
                    "Populares na Netflix",
                    [
                        MovieCard(title: "STRANGER\nTHINGS", subtitle: "Série", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/uOOtwVbSr4QDjAGIifLDwpb2Pdl.jpg", description: "Mistério, aventura e acontecimentos sobrenaturais em uma pequena cidade."),
                        MovieCard(title: "WANDINHA", subtitle: "Série", accent: .purple, posterURL: "https://image.tmdb.org/t/p/w500/9PFonBhy4cQy7Jz20NpMygczOkv.jpg", description: "Uma estudante incomum investiga segredos e acontecimentos estranhos em sua escola."),
                        MovieCard(title: "LA CASA\nDE PAPEL", subtitle: "Série", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/reEMJA1uzscCbkpeRJeTT2bjqUp.jpg", description: "Um grupo executa um plano ambicioso enquanto enfrenta pressão dentro e fora do assalto."),
                        MovieCard(title: "OUTER\nBANKS", subtitle: "Série", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/ovDgO2LPfwdVRfvScAqo9aMiIW.jpg", description: "Amigos partem em busca de respostas, pistas e um tesouro perdido.")
                    ]
                )

                posterSection(
                    "Continuar assistindo",
                    [
                        MovieCard(title: "BLACK\nMIRROR", subtitle: "Série", accent: .white, posterURL: "https://image.tmdb.org/t/p/w500/7PRddO7z7mcPi21nZTCMGShAyy1.jpg", description: "Histórias independentes exploram tecnologia e seus impactos sobre a sociedade."),
                        MovieCard(title: "LUPIN", subtitle: "Série", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/sgxawbFB5Vi5OkPWQLNfl3dvkNJ.jpg", description: "Um ladrão elegante usa inteligência e disfarces para executar seus planos."),
                        MovieCard(title: "OZARK", subtitle: "Série", accent: .cyan, posterURL: "https://image.tmdb.org/t/p/w500/pCGyPVrI9Fzw6rE1Pvi4BIXF6ET.jpg", description: "Uma família tenta sobreviver em meio a negócios perigosos e alianças frágeis."),
                        MovieCard(title: "DARK", subtitle: "Série", accent: .yellow, posterURL: "https://image.tmdb.org/t/p/w500/apbrbWs8M9lyOpJYU5WXrpFbk1Z.jpg", description: "Desaparecimentos revelam segredos e conexões entre diferentes gerações."),
                        MovieCard(title: "THE CROWN", subtitle: "Série", accent: .blue, posterURL: "https://image.tmdb.org/t/p/w500/1M876KPjulVwppEpldhdc8V4o68.jpg", description: "Drama acompanha décadas de mudanças, decisões e conflitos da monarquia britânica."),
                        MovieCard(title: "NARCOS", subtitle: "Série", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/rTmal9fDbwh5F0waol2hq35U4ah.jpg", description: "Agentes enfrentam organizações criminosas em uma longa disputa por poder."),
                        MovieCard(title: "VIKINGS\nVALHALLA", subtitle: "Série", accent: .red, posterURL: "https://br.web.img3.acsta.net/c_310_420/pictures/21/09/25/22/05/0235210.jpg", description: "Guerreiros nórdicos enfrentam novas batalhas e disputas por território."),
                        MovieCard(title: "COBRA KAI", subtitle: "Série", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/6POBWybSBDBKjSs1VAQcnQC1qyt.jpg", description: "Antigos rivais voltam a se enfrentar através de uma nova geração de alunos."),
                        MovieCard(title: "YOU", subtitle: "Série", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/7bEYwjUvlJW7GerM8GYmqwl4oS3.jpg", description: "Uma obsessão perigosa transforma relacionamentos em um jogo de segredos."),
                        MovieCard(title: "THE NIGHT\nAGENT", subtitle: "Série", accent: .blue, posterURL: "https://br.web.img3.acsta.net/c_310_420/pictures/23/03/01/20/46/5374187.jpg", description: "Um agente se envolve em uma conspiração enquanto tenta proteger uma testemunha.")
                    ]
                )

                posterSection(
                    "Filmes para você",
                    [
                        MovieCard(title: "OPPENHEIMER", subtitle: "Filme", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg", description: "Um físico assume um papel central em um dos projetos científicos mais importantes do século."),
                        MovieCard(title: "INTERSTELLAR", subtitle: "Filme", accent: .blue, posterURL: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", description: "Exploradores atravessam o espaço em busca de uma nova esperança para a humanidade."),
                        MovieCard(title: "BLADE RUNNER\n2049", subtitle: "Filme", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg", description: "Um agente descobre um segredo capaz de mudar o equilíbrio entre humanos e replicantes."),
                        MovieCard(title: "DUNA\nPARTE 2", subtitle: "Filme", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg", description: "Paul Atreides une forças com os Fremen enquanto enfrenta escolhas que podem definir o futuro."),
                        MovieCard(title: "THE GRAY\nMAN", subtitle: "Filme", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/8cXbitsS6dWQ5gfMTZdorpAAzEH.jpg", description: "Um agente altamente treinado passa a ser perseguido por inimigos de dentro da própria organização."),
                        MovieCard(title: "RED NOTICE", subtitle: "Filme", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/lAXONuqg41NwUMuzMiFvicDET9Y.jpg", description: "Um agente e dois criminosos entram em uma disputa internacional cheia de reviravoltas."),
                        MovieCard(title: "THE ADAM\nPROJECT", subtitle: "Filme", accent: .blue, posterURL: "https://image.tmdb.org/t/p/w500/wFjboE0aFZNbVOF05fzrka9Fqyx.jpg", description: "Um piloto viaja no tempo e encontra uma versão mais jovem de si mesmo."),
                        MovieCard(title: "ENOLA\nHOLMES", subtitle: "Filme", accent: .purple, posterURL: "https://image.tmdb.org/t/p/w500/riYInlsq2kf1AWoGm80JQW5dLKp.jpg", description: "Uma jovem investigadora parte em busca da mãe desaparecida."),
                        MovieCard(title: "GLASS\nONION", subtitle: "Filme", accent: .yellow, posterURL: "https://image.tmdb.org/t/p/w500/vDGr1YdrlfbU9wxTOdpf3zChmv9.jpg", description: "Um detetive enfrenta um novo mistério durante uma reunião em uma ilha."),
                        MovieCard(title: "DON'T LOOK\nUP", subtitle: "Filme", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/th4E1yqsE8DGpAseLiUrI60Hf8V.jpg", description: "Dois cientistas tentam alertar o mundo sobre uma ameaça que se aproxima.")
                    ]
                )

                posterSection(
                    "Ação e aventura",
                    [
                        MovieCard(title: "EXTRACTION\n2", subtitle: "Filme", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/7gKI9hpEMcZUQpNgKrkDzJpbnNS.jpg", description: "Um mercenário retorna para uma nova missão de resgate ainda mais perigosa."),
                        MovieCard(title: "ARMY OF\nTHE DEAD", subtitle: "Filme", accent: .yellow, posterURL: "https://image.tmdb.org/t/p/w500/z8CExJekGrEThbpMXAmCFvvgoJR.jpg", description: "Um grupo entra em uma cidade isolada para tentar realizar um grande roubo."),
                        MovieCard(title: "6 UNDERGROUND", subtitle: "Filme", accent: .green, posterURL: "https://image.tmdb.org/t/p/w500/lnWkyG3LLgbbrIEeyl5mK5VRFe4.jpg", description: "Uma equipe secreta tenta derrubar criminosos que parecem estar acima da lei."),
                        MovieCard(title: "PROJECT\nPOWER", subtitle: "Filme", accent: .purple, posterURL: "https://image.tmdb.org/t/p/w500/TnOeov4w0sTtV2gqICqIxVi74V.jpg", description: "Uma droga misteriosa concede habilidades imprevisíveis por alguns minutos."),
                        MovieCard(title: "THE OLD\nGUARD", subtitle: "Filme", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/cjr4NWURcVN3gW5FlHeabgBHLrY.jpg", description: "Um grupo de guerreiros imortais precisa proteger seu segredo e enfrentar uma nova ameaça."),
                        MovieCard(title: "BRIGHT", subtitle: "Filme", accent: .blue, posterURL: "https://image.tmdb.org/t/p/w500/whkT53Sv2vKAUiknQ13pqcWaPXB.jpg", description: "Dois policiais de origens muito diferentes enfrentam uma ameaça sobrenatural."),
                        MovieCard(title: "TRIPLE\nFRONTIER", subtitle: "Filme", accent: .green, posterURL: "https://image.tmdb.org/t/p/w500/aBw8zYuAljVM1FeK5bZKITPH8ZD.jpg", description: "Ex-soldados se reúnem para uma missão arriscada na América do Sul."),
                        MovieCard(title: "POLAR", subtitle: "Filme", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/qOBEpKVLl8Q9CZScbOcRRVISezV.jpg", description: "Um assassino prestes a se aposentar vira alvo de uma organização perigosa."),
                        MovieCard(title: "CARTER", subtitle: "Filme", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/uzAh3Ub2YttCz13cnyB9PvhpmIL.jpg", description: "Um homem sem memória recebe ordens para cumprir uma missão extrema."),
                        MovieCard(title: "HEART OF\nSTONE", subtitle: "Filme", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/vB8o2p4ETnrfiWEgVxHmHWP9yRl.jpg", description: "Uma agente tenta impedir que uma tecnologia poderosa caia em mãos erradas.")
                    ]
                )
            }
            .padding(.bottom, 24)
        }
    }

    private var trendingContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader(
                    title: "Em alta",
                    subtitle: "Os títulos mais assistidos agora."
                )

                posterSection(
                    "Top 10 hoje",
                    [
                        MovieCard(title: "ARCANE", subtitle: "Top 1", accent: .pink, posterURL: "https://image.tmdb.org/t/p/w500/fqldf2t8ztc9aiwn3k6mlX3tvRT.jpg", description: "Duas irmãs são separadas por conflitos em uma cidade marcada por tecnologia e poder."),
                        MovieCard(title: "ELITE", subtitle: "Top 2", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/3NTAbAiao4JLzFQw6YxP1YZppM8.jpg", description: "Segredos, rivalidades e crimes cercam estudantes de uma escola exclusiva."),
                        MovieCard(title: "1899", subtitle: "Top 3", accent: .gray, posterURL: "https://image.tmdb.org/t/p/w500/gZleGu1MQVBArH2dlpZ9CGi0hhy.jpg", description: "Passageiros de um navio encontram mistérios que desafiam suas certezas."),
                        MovieCard(title: "DAHMER", subtitle: "Top 4", accent: .yellow, posterURL: "https://image.tmdb.org/t/p/w500/f2PVrphK0u81ES256lw3oAZuF3x.jpg", description: "Uma dramatização sombria inspirada em crimes reais.")
                    ]
                )

                posterSection(
                    "Filmes em alta",
                    [
                        MovieCard(title: "EXTRACTION", subtitle: "Filme", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/nygOUcBKPHFTbxsYRFZVePqgPK6.jpg", description: "Um mercenário entra em uma missão perigosa para resgatar um alvo."),
                        MovieCard(title: "JOHN\nWICK 4", subtitle: "Filme", accent: .yellow, posterURL: "https://image.tmdb.org/t/p/w500/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg", description: "Um assassino enfrenta novos adversários em sua busca por liberdade."),
                        MovieCard(title: "TOP GUN", subtitle: "Filme", accent: .white, posterURL: "https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg", description: "Pilotos de elite enfrentam desafios de treinamento e combate."),
                        MovieCard(title: "BATMAN", subtitle: "Filme", accent: .red, posterURL: "https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg", description: "Um vigilante investiga uma série de crimes em uma cidade corrompida."),
                        MovieCard(title: "OPPENHEIMER", subtitle: "Filme", accent: .orange, posterURL: "https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg", description: "Um físico assume um papel central em um dos projetos científicos mais importantes do século."),
                        MovieCard(title: "INTERSTELLAR", subtitle: "Filme", accent: .blue, posterURL: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", description: "Exploradores atravessam o espaço em busca de uma nova esperança para a humanidade.")
                    ]
                )
            }
            .padding(.bottom, 24)
        }
    }

    private var newContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader(
                    title: "Novidades",
                    subtitle: "Novos episódios, séries e filmes."
                )

                updateCard(
                    icon: "sparkles",
                    title: "Novos lançamentos",
                    message: "Conteúdo adicionado recentemente à plataforma."
                )

                updateCard(
                    icon: "bell.fill",
                    title: "Em breve",
                    message: "Ative o lembrete para não perder os próximos lançamentos."
                )

                posterSection(
                    "Lançados recentemente",
                    [
                        MovieCard(title: "MANIFEST", subtitle: "Novo", accent: .blue, posterURL: "https://image.tmdb.org/t/p/w500/eTemCphrglLKrXOsNRhYezHA7H9.jpg", description: "Passageiros de um voo retornam e descobrem que o mundo mudou."),
                        MovieCard(title: "WANDINHA", subtitle: "Novo", accent: .purple, posterURL: "https://image.tmdb.org/t/p/w500/9PFonBhy4cQy7Jz20NpMygczOkv.jpg", description: "Mistério e humor sombrio em uma escola cheia de segredos."),
                        MovieCard(title: "ARCANE", subtitle: "Novo", accent: .pink, posterURL: "https://image.tmdb.org/t/p/w500/fqldf2t8ztc9aiwn3k6mlX3tvRT.jpg", description: "Uma história de irmandade e rivalidade em uma cidade dividida.")
                    ]
                )
            }
            .padding(.bottom, 24)
        }
    }

    private var downloadsContent: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 110, height: 110)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.88))
            }

            Text("Seus downloads")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Filmes e séries baixados aparecem aqui para assistir offline.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)

            Button {
                selectedTab = .home
            } label: {
                Text("Encontrar títulos")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }

            Spacer()
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    .black,
                    Color(red: 0.10, green: 0.10, blue: 0.13),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 380)

            VStack(alignment: .leading, spacing: 10) {
                Text("N  SÉRIE")
                    .font(.caption.bold())
                    .foregroundStyle(.red)

                Image("TheWitcherLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, alignment: .leading)
                    .frame(height: 54, alignment: .leading)

                Text("Destino é uma fera. Você é o que faz dele.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))

                HStack(spacing: 10) {
                    Button(action: {}) {
                        Label("Assistir", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 11)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Button(action: {}) {
                        Label("Minha lista", systemImage: "plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(Color.white.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(18)
        }
    }

    private func pageHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private func updateCard(icon: String, title: String, message: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.red)
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 18)
    }

    private func posterSection(_ title: String, _ items: [MovieCard]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        Button {
                            selectedMovie = item
                        } label: {
                            fakePoster(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private func fakePoster(_ item: MovieCard) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: item.posterURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    LinearGradient(
                        colors: [item.accent.opacity(0.45), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                case .empty:
                    ZStack {
                        Color.black
                        ProgressView()
                            .tint(.red)
                    }
                @unknown default:
                    Color.black
                }
            }
            .frame(width: 116, height: 165)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(item.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(8)
        }
        .frame(width: 116, height: 165)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        HStack {
            fakeTab(.home, "house.fill", "Início")
            fakeTab(.trending, "play.rectangle.on.rectangle", "Em alta")
            fakeTab(.newAndHot, "rectangle.stack.fill", "Novidades")
            fakeTab(.downloads, "arrow.down.circle.fill", "Downloads")
        }
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.98))
    }

    private func fakeTab(_ tab: FakeNetflixTab, _ icon: String, _ title: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17))

                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(selectedTab == tab ? Color.red : Color.white.opacity(0.55))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func registerLogoTap() {
        tapCount += 1

        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                await MainActor.run {
                    tapCount = 0
                }
            }
        }

        if tapCount >= 3 {
            resetTask?.cancel()
            tapCount = 0
            withAnimation(.easeInOut(duration: 0.25)) {
                showInjector = true
            }
        }
    }
}




private struct NetflixLoadingView: View {
    let onFinished: () -> Void

    @State private var logoOpacity = 0.0
    @State private var logoScale: CGFloat = 0.94
    @State private var loadingProgress: CGFloat = 0.0
    @State private var didFinish = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                Text("NETFLIX")
                    .font(.system(size: 52, weight: .black, design: .default))
                    .tracking(-1.8)
                    .foregroundStyle(Color(red: 0.90, green: 0.00, blue: 0.05))
                    .shadow(color: Color.red.opacity(0.22), radius: 12)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                VStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.13))

                            Capsule()
                                .fill(Color(red: 0.90, green: 0.00, blue: 0.05))
                                .frame(width: geo.size.width * loadingProgress)
                                .shadow(color: Color.red.opacity(0.55), radius: 5)
                        }
                    }
                    .frame(width: 132, height: 3)

                    Text("Carregando...")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                }
                .opacity(logoOpacity)

                Spacer()
            }
        }
        .onAppear {
            guard !didFinish else { return }

            withAnimation(.easeOut(duration: 0.48)) {
                logoOpacity = 1
                logoScale = 1
            }

            withAnimation(.linear(duration: 1.75)) {
                loadingProgress = 1
            }

            Task {
                try? await Task.sleep(for: .seconds(1.9))
                guard !Task.isCancelled, !didFinish else { return }
                await MainActor.run {
                    didFinish = true
                    withAnimation(.easeOut(duration: 0.22)) {
                        logoOpacity = 0
                    }
                }
                try? await Task.sleep(for: .milliseconds(230))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    onFinished()
                }
            }
        }
    }
}
private struct MovieDetailView: View {
    let movie: MovieCard
    let isInList: Bool
    let onToggleList: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AsyncImage(url: URL(string: movie.posterURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            Rectangle()
                                .fill(movie.accent.opacity(0.25))
                        case .empty:
                            ZStack {
                                Rectangle().fill(Color.black)
                                ProgressView().tint(.red)
                            }
                        @unknown default:
                            Color.black
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 330)
                    .clipped()
                    .background(Color.black)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(movie.title.replacingOccurrences(of: "\n", with: " "))
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text(movie.subtitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)

                        Text(movie.description)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.78))

                        Button(action: {}) {
                            Label("Assistir", systemImage: "play.fill")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }

                        Button(action: onToggleList) {
                            Label(
                                isInList ? "Remover da minha lista" : "Adicionar à minha lista",
                                systemImage: isInList ? "checkmark" : "plus"
                            )
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

private enum FakeNetflixTab {
    case home
    case trending
    case newAndHot
    case downloads
}

private struct MovieCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let accent: Color
    let posterURL: String
    let description: String
}
