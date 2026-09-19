# Bíblia IPM

Aplicativo de leitura da **Bíblia Sagrada** fora do ar, com **Hinário**, **Músicas** e **Boletim da igreja** — desenvolvido em Flutter para Android e iOS.

> Nome do projeto: **BibliaApp** · versão atual: **4.2.2**

## Funcionalidades

### 📖 Bíblia
- Leitura completa dos 66 livros, offline, com capítulos e versículos.
- 4 traduções disponíveis:
  - **JFAA** — João Ferreira de Almeida Atualizada Livre
  - **ARA** — Almeida Revista e Atualizada
  - **NVI** — Nova Versão Internacional
  - **NTLH** — Nova Tradução na Linguagem de Hoje
- Busca por texto em qualquer versículo (com 3 ou mais letras).
- **Destaques** em 6 cores por versículo e por linha de hino/música.
- **Copiar** e **compartilhar** versículos com referência.

### 🎶 Hinário
- Hinário **Novo Cântico** completo (405 hinos) com busca por título, autor ou letra.
- Coros, pontes e prelúdios identificados.

### ⭐ Músicas
- Adicionar, editar e excluir letras de músicas próprias.
- Compartilhar e destacar linhas.

### 📅 Boletim
- **Aniversariantes do dia**, exibidos automaticamente.
- **Próximos eventos** da igreja com data, hora e observações (eventos passados somem).
- Cadastro e edição integrados ao calendário.

### ⚙️ Configurações
- Tamanho da letra: **Pequeno**, **Normal**, **Grande** e **Extra grande**.
- Tema: **Claro**, **Escuro** e **Marrom**.
- Preferências e destaques preservados entre versões.

## Tecnologias

- **Flutter / Dart** (SDK `^3.13.3`)
- `shared_preferences` — persistência local
- `share_plus` — compartilhamento de texto
- Código 100% offline — todos os conteúdos são empacotados como assets do app

## Estrutura do projeto

```
BibliaApp/
├── flutter/           # Código principal do app (Flutter)
│   ├── lib/           # Código Dart (UI, estado, modelos)
│   │   ├── main.dart  # Ponto de entrada e navegação (5 abas)
│   │   ├── store.dart # Estado global, persistência e migração
│   │   ├── models.dart
│   │   ├── theme.dart # Temas e níveis de fonte
│   │   ├── common.dart # Destaques, copiar e compartilhar
│   │   └── tabs/      # Abas: Bíblia, Hinário, Músicas, Boletim, Config
│   ├── assets/        # Bíblias (4 traduções), hinos, músicas e boletim
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
| 4.2.2 | Versão atual |

## Repositório

GitHub: [alunoadsnoite/bibliaappipm](https://github.com/alunoadsnoite/bibliaappipm)