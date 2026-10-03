# Compilar no Windows usando Codemagic

1. Extraia este ZIP.
2. Envie todo o conteúdo para um repositório no GitHub.
3. Entre no Codemagic e conecte o GitHub.
4. Adicione o repositório.
5. Selecione o workflow **iOS Unsigned IPA**.
6. Clique em **Start new build**.
7. Ao terminar, baixe `3105-unsigned.ipa` em **Artifacts**.

Projeto detectado: `ThreeOneOSFive.xcodeproj`
Scheme configurado: `3105`

Se o passo "Listar schemes" mostrar outro scheme, troque o valor de `SCHEME` no `codemagic.yaml`.

A IPA será unsigned e precisará ser assinada antes da instalação no iPhone.
