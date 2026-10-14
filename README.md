# Bíblia IPM

Aplicativo de leitura da **Bíblia Sagrada** fora do ar, com **Hinário**, **Músicas**, **Biblioteca** e **Boletim da igreja** — desenvolvido em Flutter para Android e iOS.

> Nome do projeto: **BibliaApp** · versão atual: **5.5.0**

## Funcionalidades

### 📖 Bíblia
- Leitura completa dos 66 livros, offline, com capítulos e versículos.
- **4 traduções livres** disponíveis (domínio público ou licença livre):
  - **BLIVRE** — Bíblia Livre (CC BY 4.0 BR)
  - **BPM** — Bíblia Portuguesa Mundial (domínio público)
  - **JFAAL** — João Ferreira de Almeida Atualizada Livre (MIT)
  - **ALM1911** — Almeida 1911 (domínio público)
- Livros organizados por grandes grupos literários (Pentateuco, Históricos,
  Poéticos, Sapenciais, Proféticos Maiores/Menores, Evangelhos, Atos, Cartas
  Paulinas, Cartas Gerais e Revelação), dentro de Antigo e Novo Testamento.
- **Busca por texto** em qualquer versículo (com 3 ou mais letras) e **busca
  por referência** (ex.: `Jo 3:16`, `Salmos 23`, `1co13`) — resultados
  paginados com contagem, com opção de **limitar a busca ao livro aberto**.
- **Versículo do dia**: rotação determinística por data, 100% offline.
- **Widget Android**: versículo do dia na tela inicial, atualização diária automática.
- **Plano de leitura**: meta manual ou data de conclusão com cálculo automático
  dos capítulos restantes por dia, contagem diária, sequência e próximo capítulo.
- **Concluí este capítulo**: o progresso só muda por ação explícita; abrir,
  deslizar ou ouvir um capítulo não o marca automaticamente.
- **Capítulos lidos** marcados na grade de capítulos (toque longo desmarca).
- **Modo leitura (foco)**: leitura em tela cheia, sem barras de navegação,
  com **deslizar para a esquerda/direita** e passar de capítulo.
- **Destaques** em 6 cores por versículo e por linha de hino/música.
- **Notas por versículo** (e por linha de hino/música/documentos), exibidas ao
  lado do texto, agora independentes da tradução (chaves canônicas).
- **Letras vermelhas**: destaca em vermelho as **falas de Jesus e de Deus**
  em toda a Bíblia (recurso opcional nas Configurações).
- **Comparar traduções** de um mesmo versículo, lado a lado.
- **Central de notas e destaques**: filtro por livro, categoria e cor, com acesso à leitura.
- **Favoritos**: versículos, hinos, músicas e documentos, preservados no backup.
- **Busca unificada**: Bíblia, hinário, músicas, biblioteca e notas, com filtros
  por categoria, busca sem acentos, referências e resultados paginados.
- **Copiar** e **compartilhar** versículos com referência.
- **Leitura por voz (acessibilidade)** — leia o capítulo inteiro com
  play/pausa/parar, ou um único versículo pelo menu de toque longo, com
  **voz feminina/masculina**, **velocidade** e **tom** configuráveis. Quando
  o gênero escolhido não estiver instalado no aparelho, o tom simula a voz
  (aguda/grave) — o recurso funciona **mesmo fora do ar**.

### 🎶 Hinário
- Hinário **Salmos e Hinos** (edição de 1880, domínio público), com 287 hinos.
- Coros, pontes e prelúdios identificados.
- **Ouvir o hino completo** por voz (em estrofes, com pausa/continuar/parar).

### 🎵 Músicas
- Adicionar, editar e excluir letras de músicas próprias.
- Compartilhar e destacar linhas.
- **Ouvir a música completa** por voz (em estrofes, com pausa/continuar/parar).

### 📚 Biblioteca
- **Confissão de Fé de Westminster** (35 capítulos).
- **Catecismo Maior de Westminster** (196 perguntas, texto completo).
- **Catecismo Menor de Westminster** (107 perguntas).
- **Credo Apostólico** e **Credo Niceno**.
- **Os Dez Mandamentos** (Êxodo 20, BPM).
- **Os Cinco Pontos do Calvinismo** (as doutrinas da graça).
- **As 95 Teses de Lutero** (1517).
- Busca por documento e **leitura por voz** do texto completo.

### 📅 Boletim
- **Aniversariantes do dia**, exibidos automaticamente.
- **Próximos eventos** da igreja com data, hora e observações (eventos passados somem).
- Cadastro e edição integrados ao calendário.
- Compartilhar e importar arquivo JSON do boletim separadamente; a importação
  adiciona eventos e aniversariantes sem duplicar itens iguais ou alterar os outros dados.

### ⚙️ Configurações
- Tamanho da letra: **Pequeno**, **Normal**, **Grande** e **Extra grande**
  (respeita o ajuste de acessibilidade do aparelho).
- Tema: **Claro**, **Escuro**, **Marrom** e **Verde**.
- **Plano de leitura**: ativar/desativar e definir a meta diária.
- **Leitura por voz**: escolher a **voz** (padrão/feminina/masculina), a
  **velocidade** e o **tom** da leitura.
- **Sobre o app**: logomarca, versão e links (Instagram, YouTube e e-mail).
- **Lembrete diário**: notificação local opcional em Android/iOS, com horário
  escolhido pelo usuário. A permissão é solicitada ao ativar; o sistema pode
  atrasar a entrega por economia de bateria. A ativação é específica do aparelho.
- Navegação compacta em celulares e com texto ampliado: Bíblia, Hinário e
  **Mais**, que abre Músicas, Biblioteca, Boletim e Configurações.
- **Backup**: compartilhar um arquivo JSON e importar pelo seletor de arquivos
  ou colando o conteúdo. Validação antes da restauração e cópia local dos dados
  anteriores; notas, destaques e progresso são mesclados.
- Logomarca IPM, **Instagram** e **YouTube** da igreja.
- **Dízimos e ofertas**: chave **Pix** da igreja para copiar/compartilhar, e
  contatos por e-mail e WhatsApp.
- Preferências e destaques preservados entre versões.

## Contato

- **E-mail:** valdenorsa@proton.me
- **WhatsApp:** +55 (81) 98835-3131

## Tecnologias

- **Flutter / Dart** (SDK `^3.13.3`)
- `shared_preferences` — persistência local
- `share_plus` — compartilhamento de texto e arquivos de backup
- `file_selector` — importação de arquivos JSON
- `flutter_tts` — leitura por voz (acessibilidade)
- `flutter_local_notifications`, `flutter_timezone`, `timezone` — lembretes locais
- `url_launcher` — contatos (e-mail e WhatsApp)
- Código 100% offline — todos os conteúdos são empacotados como assets do app

## Estrutura do projeto

```
BibliaApp/
├── flutter/           # Código principal do app (Flutter)
│   ├── lib/           # Código Dart (UI, estado, modelos)
│   │   ├── main.dart  # Ponto de entrada e navegação (6 abas)
│   │   ├── store.dart # Estado global, persistência e migração
│   │   ├── models.dart
│   │   ├── theme.dart # Temas e níveis de fonte
│   │   ├── common.dart # Destaques, copiar e compartilhar
│   │   └── tabs/      # Abas: Bíblia, Hinário, Músicas, Biblioteca, Boletim, Config
│   ├── assets/        # Bíblias (4 traduções livres), hinos, biblioteca e boletim
│   ├── android/       # Projeto Android
│   ├── ios/           # Projeto iOS
│   └── test/          # Testes unitários e de widget
├── app/               # App nativo Android legado (v4.0) — usado para migrar dados
├── design/            # Artes do ícone do app
└── settings.gradle.kts
```

## Como executar

1. Instale o [Flutter](https://docs.flutter.dev/get-started/install).
2. Rode o app:

```bash
cd flutter
flutter pub get
flutter run
```

3. Para gerar um APK de release:

```bash
flutter build apk --release
```

A compilação de produção requer `flutter/android/key.properties` com os
campos `storePassword`, `keyPassword`, `keyAlias` e `storeFile`, apontando para
a chave de assinatura local. A chave e esse arquivo são ignorados pelo Git.
Guarde ambos em um backup privado para assinar futuras atualizações.

### F-Droid

As descrições, ícone e changelog estão em `fastlane/metadata/android/`.
O estado da preparação e as pendências para o catálogo oficial estão em
[docs/FDROID.md](docs/FDROID.md).

### Testes

```bash
cd flutter
flutter test
```

## Migração do app nativo

Nas instalações novas, e em uma única execução, o aplicativo lê os dados do app nativo Android legado (v4.0) — que compartilhava o mesmo `applicationId` — e migra para o Flutter, **sem sobrescrever** o que já existir:

- versão/tradução da Bíblia, tema e tamanho da letra;
- destaques;
- músicas e boletim (aniversariantes e eventos).

## Histórico de versões

| Versão | Descrição |
| ------ | --------- |
| 5.5.0 | **Conteúdo 100% livre**: substituição das traduções bíblicas não-livres (ARA, NVI, NTLH, BKJ, JFAA) pelas livres **Bíblia Livre**, **Bíblia Portuguesa Mundial**, **JFAAL** e **Almeida 1911**; hinário **Salmos e Hinos** (edição de 1880, domínio público) no lugar do Novo Cântico; remoção do cancioneiro empacotado; **Dez Mandamentos** e **Oração Dominical** na Biblioteca passam a usar a BPM. Preparação para inclusão no F-Droid |
| 5.4.0 | Central de notas e destaques, favoritos, busca unificada, plano com prazo, conclusão explícita de capítulos, boletim compartilhável, navegação adaptativa e lembretes locais opcionais |
| 4.0 | App nativo Android |
| 4.2 | Rewrite em Flutter (Android + iOS) com a marca **Bíblia IPM** |
| 4.2.1 | Novo ícone, correções na atualização de tema e tamanho da letra |
| 4.3 | Tema **Verde**, refino do hinário, logomarca IPM e contatos (e-mail e WhatsApp) nas Configurações |
| 4.4 | **Leitura por voz** na Bíblia: capítulo inteiro ou versículo isolado (acessibilidade) |
| 4.5 | **Leitura por voz** do hino inteiro (Hinário) e da música inteira (Músicas) |
| 4.6 | **150 cânticos** do *Livro de Cânticos PG Micheline* na aba Músicas; testes unitários da leitura por voz (engines de TTS testáveis); ajustes de tema/boletim |
| 4.7 | Versão **BKJ** (Bíblia King James Fiel 1611) como 5ª tradução da Bíblia; livros agrupados por categorias literárias; novo ícone de música na aba Músicas; correção de indexação da NTLH ("2 Samuel" de 38 para 24 capítulos) |
| 4.8 | Nova aba **Biblioteca**: Confissão de Fé de Westminster, Catecismo Maior e Menor, Credo Apostólico, Credo Niceno, Os Dez Mandamentos, Os Cinco Pontos do Calvinismo e As 95 Teses de Lutero — com busca e leitura por voz |
| 4.8.1 | **Catecismo Maior** com o texto completo: restauradas as perguntas 176, 177 e 192, ausentes na edição IPB (de 193 para 196 perguntas) |
| 4.9 | **Versículo do dia**, **plano de leitura anual** com meta diária, **continuar lendo** e **histórico recente**; **notas** por versículo/linha; **comparar traduções** lado a lado; **busca por referência** e resultados paginados; **modo leitura** em tela cheia; tema **Sistema**; **backup** (exportar/importar); traduções carregadas **sob demanda**; redes sociais (**Instagram/YouTube**) e **dízimos e ofertas (chave Pix)** nas Configurações; ícone de áudio individual removido do texto (leitura por voz segue via TTS) |
| 4.10 | **Voz feminina/masculina, velocidade e tom** na leitura por voz; **capítulos lidos** na grade (toque longo desmarca) e **deslizar** entre capítulos no modo leitura; **próximo capítulo** e **sequência de dias** no plano de leitura; **busca restrita ao livro aberto**; **destaques/notas com chaves canônicas** (independentes da tradução) e **migração automática** de dados antigos; tamanho da letra respeitando a **acessibilidade do sistema**; **Sobre o app** nas Configurações; eventos já passados somem do boletim no mesmo dia |
| 5.0 | **Simulação de voz por tom**: quando a voz do gênero escolhido não estiver instalada no aparelho, o app ajusta o tom (agudo na feminina, grave na masculina) — o recurso funciona **100% offline** |
| 5.0.1 | Músicas em **ordem alfabética** (ignorando acentos) com **busca** na aba; **busca dentro dos documentos** da Biblioteca (ex.: achar uma tese das 95 de Lutero ou uma pergunta do catecismo); grupo **Atos dos Apóstolos**; voz masculina menos robotizada; **correção da leitura do capítulo** (espera cada versículo terminar antes do próximo); referência lida por extenso (ex.: "Neemias, capítulo 8, versículo 15") |
| 5.0.2 | **Destaque do versículo sendo lido** corrigido (antes marcava o versículo seguinte); **Oração Dominical (Pai Nosso)** e **As Cinco Solas da Reforma** na Biblioteca; modo leitura com **texto limpo em coluna centralizada** (oculta números, notas e destaques), **imersão total por toque** e **scroll contínuo entre capítulos/livros** |
| 5.0.3 | **Seleção múltipla de versículos**: toque longo (ou menu → **Selecionar**) marca vários versículos para **copiar** (com ou sem referências), **compartilhar**, **anotar** e **destacar** de uma vez, com botão "selecionar tudo" e barra de ações; botão "texto limpo" removido do modo leitura |
| 5.0.4 | **Leitura contínua também no modo normal**: deslizar à esquerda/direita troca de capítulo (cruzando livros) e, ao chegar ao fim do texto, o próximo capítulo entra automaticamente — como no modo leitura |
| 5.1.0 | **Letras vermelhas**: falas de Jesus e de Deus destacadas em vermelho em toda a Bíblia (AT e NT), com opção de ativar/desativar nas Configurações |
| 5.2.0 | **Tema "Sistema"** (configurações): acompanha automaticamente o tema claro/escuro do aparelho; o visto agora segue o tema exibido (com selo AUTO no Sistema); **atalho claro/escuro na leitura**: botão sol/lua na barra do capítulo e no modo leitura, restaura o tema salvo ao sair; **busca destacando o termo encontrado** em negrito; análise estática sem pendências |
| 5.2.3 | **Widget Android** com versículo do dia na tela inicial; atualização diária automática e ao mudar de data; sincronização via SharedPreferences com o app Flutter; fallback inteligente quando app não foi aberto ainda (mostra referência + mensagem para tocar e carregar); clique no widget abre o app |
| 5.2.4 | **Correção do widget Android**: o texto do versículo do dia agora é sempre exibido, mesmo sem conexão com o app Flutter; adicionados textos fallback hardcoded para os 43 versículos diários |
| 5.2.5 | **Versículo do dia com ~90 versículos**: lista expandida de 43 para ~90 versículos diários, reduzindo a repetição de ~8-9x para ~4x por ano (ciclo de ~90 dias em vez de ~43 dias); widget Android sincronizado com a mesma lista expandida |
| 5.2.2 | **Configurações voltam a reagir às mudanças**: as abas eram `const` no `IndexedStack` e o Flutter pulava a reconstrução delas — o **visto do tema e o slider do tamanho da letra travavam** no valor inicial (regressão da correção da v4.2.1); **rótulos do tamanho da letra clicáveis** (Pequeno/Normal/Grande/Extra grande) com o nível ativo em destaque; **o visto marca a opção escolhida** (o selo AUTO continua no tema Sistema) e qualquer linha tocada é aplicada; escala de fonte salva é **encaixada no nível mais próximo**; testes atualizados para o tema Sistema e suíte verde |

## Repositório

GitHub: [alunoadsnoite/bibliaappipm](https://github.com/alunoadsnoite/bibliaappipm)
