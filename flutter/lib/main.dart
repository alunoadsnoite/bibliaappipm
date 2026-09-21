import 'package:flutter/material.dart';

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
  await AppState.i.load();
  runApp(const BibliaApp());
}

class BibliaApp extends StatefulWidget {
  const BibliaApp({super.key});

  @override
  State<BibliaApp> createState() => _BibliaAppState();
}

class _BibliaAppState extends State<BibliaApp> {
  @override
  Widget build(BuildContext context) {
    // Dependência em MediaQuery: quando o brilho do aparelho muda, este build
    // roda de novo antes dos filhos, atualizando o tema Sistema.
    final sys = MediaQuery.platformBrightnessOf(context);
    AppState.i.systemBrightness = sys;
    return ListenableBuilder(
      listenable: AppState.i,
      builder: (context, _) {
        final t = themeForIndex(AppState.i.themeIndex, sys);
        final brightness = resolveBrightness(AppState.i.themeIndex, sys);
        return MaterialApp(
          title: kAppName,
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
            textSelectionTheme:
                TextSelectionThemeData(cursorColor: t.accent),
          ),
          builder: (context, child) {
            // Multiplica o fator do aplicativo pelo ajuste de acessibilidade
            // do sistema, em vez de substituí-lo.
            final sys = MediaQuery.textScalerOf(context);
            final sysFactor = sys.scale(16) / 16;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler:
                    TextScaler.linear(sysFactor * AppState.i.fontScale),
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

  @override
  Widget build(BuildContext context) {
    final sys = MediaQuery.platformBrightnessOf(context);
    AppState.i.systemBrightness = sys;
    return ListenableBuilder(
      listenable: AppState.i,
      builder: (context, _) {
        final t = themeForIndex(AppState.i.themeIndex, sys);
        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: const [
              BibleTab(),
              HymnsTab(),
              SongsTab(),
              LibraryTab(),
              BoletimTab(),
              SettingsTab(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
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
                  icon: Icon(Icons.menu_book), label: 'Bíblia'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.library_music), label: 'Hinário'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.music_note), label: 'Músicas'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.local_library), label: 'Biblioteca'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month), label: 'Boletim'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings), label: 'Config'),
            ],
          ),
        );
      },
    );
  }
}
