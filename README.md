# Bíblia IPM

Aplicativo de leitura da **Bíblia Sagrada** fora do ar, com **Hinário**, **Músicas**, **Biblioteca** e **Boletim da igreja** — desenvolvido em Flutter para Android e iOS.

> Nome do projeto: **BibliaApp** · versão atual: **4.8.1**

## Funcionalidades

### 📖 Bíblia
- Leitura completa dos 66 livros, offline, com capítulos e versículos.
- **5 traduções** disponíveis:
  - **JFAA** — João Ferreira de Almeida Atualizada Livre
  - **ARA** — Almeida Revista e Atualizada
  - **NVI** — Nova Versão Internacional
  - **NTLH** — Nova Tradução na Linguagem de Hoje
  - **BKJ** — Bíblia King James Fiel 1611 (nova versão, na 4.7)
- Livros organizados por grandes grupos literários (Pentateuco, Históricos,
  Poéticos, Sapenciais, Proféticos Maiores/Menores, Evangelhos, Atos, Cartas
  Paulinas, Cartas Gerais e Revelação), dentro de Antigo e Novo Testamento.
- Busca por texto em qualquer versículo (com 3 ou mais letras).
- **Destaques** em 6 cores por versículo e por linha de hino/música.
- **Copiar** e **compartilhar** versículos com referência.
- **Leitura por voz (acessibilidade)** — leia o capítulo inteiro com
  play/pausa/parar, ou um único versículo pelo botão de som ao lado de cada
  versículo (funciona também no menu de toque longo).

### 🎶 Hinário
- Hinário **Novo Cântico** completo (405 hinos) com busca por título, autor ou letra.
- Coros, pontes e prelúdios identificados.
- **Ouvir o hino completo** por voz (em estrofes, com pausa/continuar/parar).

### 🎵 Músicas
- **150 cânticos** do *Livro de Cânticos PG Micheline* já inclusos.
- Adicionar, editar e excluir letras de músicas próprias.
- Compartilhar e destacar linhas.
- **Ouvir a música completa** por voz (em estrofes, com pausa/continuar/parar).

### 📚 Biblioteca
- **Confissão de Fé de Westminster** (35 capítulos).
- **Catecismo Maior de Westminster** (196 perguntas, texto completo).
- **Catecismo Menor de Westminster** (107 perguntas).
- **Credo Apostólico** e **Credo Niceno**.
- **Os Dez Mandamentos** (Êxodo 20, ARA).
- **Os Cinco Pontos do Calvinismo** (as doutrinas da graça).
- **As 95 Teses de Lutero** (1517).
- Busca por documento e **leitura por voz** do texto completo.

### 📅 Boletim
- **Aniversariantes do dia**, exibidos automaticamente.
- **Próximos eventos** da igreja com data, hora e observações (eventos passados somem).
- Cadastro e edição integrados ao calendário.

### ⚙️ Configurações
- Tamanho da letra: **Pequeno**, **Normal**, **Grande** e **Extra grande**.
- Tema: **Claro**, **Escuro**, **Marrom** e **Verde**.
- Logomarca IPM e dados de contato (e-mail e WhatsApp).
- Preferências e destaques preservados entre versões.

## Contato

- **E-mail:** valdenorsa@proton.me
- **WhatsApp:** +55 (81) 98835-3131

## Tecnologias

- **Flutter / Dart** (SDK `^3.13.3`)
- `shared_preferences` — persistência local
- `share_plus` — compartilhamento de texto
- `flutter_tts` — leitura por voz (acessibilidade)
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
│   ├── assets/        # Bíblias (5 traduções), hinos, músicas, biblioteca e boletim
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

## Repositório

GitHub: [alunoadsnoite/bibliaappipm](https://github.com/alunoadsnoite/bibliaappipm)