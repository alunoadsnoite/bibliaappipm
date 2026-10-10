import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'personal_tools.dart';
import 'reminders.dart';
import 'store.dart';
import 'tabs/bible_tab.dart';
import 'tabs/boletim_tab.dart';
import 'tabs/hymns_tab.dart';
import 'tabs/library_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/songs_tab.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppState.i.load();
    await ReminderService.i.restore(AppState.i);
  } catch (error, stack) {
    // Sem isto, uma falha de leitura deixa a tela preta para sempre, porque
    // `runApp` nunca seria chamado.
    debugPrint('Falha ao iniciar: $error\n$stack');
  }
  runApp(const BibliaApp());
}

class BibliaApp extends StatefulWidget {
  const BibliaApp({super.key});

  @override
  State<BibliaApp> createState() => _BibliaAppState();
}

class _BibliaAppState extends State<BibliaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ReminderService.i.restore(AppState.i);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dependência em MediaQuery: quando o brilho do aparelho muda, este build
    // roda de novo antes dos filhos, atualizando o tema Sistema.
    final sys = MediaQuery.platformBrightnessOf(context);
    AppState.i.systemBrightness = sys;
    return ListenableBuilder(
      listenable: AppState.i,
      builder: (context, _) {
        final t = themeForIndex(AppState.i.displayedThemeIndex, sys);
        final brightness = resolveBrightness(
          AppState.i.displayedThemeIndex,
          sys,
        );
        return MaterialApp(
          title: kAppName,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: brightness,
            scaffoldBackgroundColor: t.bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: t.primary,
              primary: t.primary,
              secondary: t.accent,
              brightness: brightness,
            ),
            textSelectionTheme: TextSelectionThemeData(cursorColor: t.accent),
          ),
          builder: (context, child) {
            // Multiplica o fator do aplicativo pelo ajuste de acessibilidade
            // do sistema, em vez de substituí-lo.
            final sys = MediaQuery.textScalerOf(context);
            final sysFactor = sys.scale(16) / 16;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(sysFactor * AppState.i.fontScale),
              ),
              child: child!,
            );
          },
          home: const HomeShell(),
        );
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _openTools(PersonalView view) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => PersonalToolsPage(view: view)),
  );

  Future<void> _more() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in [
                (2, 'Músicas', Icons.music_note),
                (3, 'Biblioteca', Icons.local_library),
                (4, 'Boletim', Icons.calendar_month),
                (5, 'Config', Icons.settings),
              ])
                ListTile(
                  leading: Icon(item.$3),
                  title: Text(item.$2),
                  selected: _index == item.$1,
                  onTap: () => Navigator.pop(ctx, item.$1),
                ),
            ],
          ),
        ),
      ),
    );
    if (index != null && mounted) {
      setState(() => _index = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sys = MediaQuery.platformBrightnessOf(context);
    AppState.i.systemBrightness = sys;
    return ListenableBuilder(
      listenable: AppState.i,
      builder: (context, _) {
        final t = themeForIndex(AppState.i.displayedThemeIndex, sys);
        return Scaffold(
          appBar: AppBar(
            title: const Text(kAppName),
            actions: [
              IconButton(
                tooltip: 'Buscar em tudo',
                icon: const Icon(Icons.search),
                onPressed: () => _openTools(PersonalView.search),
              ),
              IconButton(
                tooltip: 'Notas e destaques',
                icon: const Icon(Icons.bookmarks_outlined),
                onPressed: () => _openTools(PersonalView.annotations),
              ),
              IconButton(
                tooltip: 'Favoritos',
                icon: const Icon(Icons.star_border),
                onPressed: () => _openTools(PersonalView.favorites),
              ),
            ],
          ),
          body: Column(
            children: [
              if (!AppState.i.storageAvailable ||
                  AppState.i.loadErrors.isNotEmpty)
                SafeArea(
                  bottom: false,
                  child: MaterialBanner(
                    content: Text(
                      !AppState.i.storageAvailable
                          ? 'Armazenamento indisponível. As alterações desta sessão não serão salvas.'
                          : 'Não foi possível carregar: ${AppState.i.loadErrors.join(', ')}.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          await AppState.i.load();
                        },
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  // A lista NÃO pode ser `const`: widgets const são canonicados e o
                  // Flutter pula o `update()` deles (Element.updateChild compara
                  // `child.widget == newWidget`), então as abas nunca mais rodariam
                  // o `build()` e não repaintariam na troca de tema. É exatamente o
                  // bug que a v4.2.1 corrigiu e que voltou na v5.2.0.
                  // ignore: prefer_const_literals_to_create_immutables
                  children: [
                    BibleTab(), // ignore: prefer_const_constructors
                    HymnsTab(), // ignore: prefer_const_constructors
                    SongsTab(), // ignore: prefer_const_constructors
                    LibraryTab(), // ignore: prefer_const_constructors
                    BoletimTab(), // ignore: prefer_const_constructors
                    SettingsTab(), // ignore: prefer_const_constructors
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar:
              MediaQuery.sizeOf(context).width < 600 ||
                  MediaQuery.textScalerOf(context).scale(16) > 24
              ? NavigationBar(
                  selectedIndex: _index < 2 ? _index : 2,
                  onDestinationSelected: (i) {
                    if (i < 2) {
                      setState(() => _index = i);
                    } else {
                      _more();
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.menu_book),
                      label: 'Bíblia',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.library_music),
                      label: 'Hinário',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu),
                      label: 'Mais',
                    ),
                  ],
                )
              : BottomNavigationBar(
                  currentIndex: _index,
                  onTap: (i) => setState(() => _index = i),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: t.primaryDark,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white70,
                  selectedLabelStyle: const TextStyle(fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.menu_book),
                      label: 'Bíblia',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.library_music),
                      label: 'Hinário',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.music_note),
                      label: 'Músicas',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.local_library),
                      label: 'Biblioteca',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_month),
                      label: 'Boletim',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Config',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
