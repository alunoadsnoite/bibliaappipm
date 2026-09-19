import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'theme.dart';

const List<String> kVersionOrder = ['ara', 'nvi', 'ntlh', 'jfaal', 'bkj'];
const List<String> kVersionNames = [
  'Almeida Revista e Atualizada',
  'Nova Versão Internacional',
  'Nova Tradução na Linguagem de Hoje',
  'João Ferreira de Almeida Atualizada Livre',
  'Bíblia King James Fiel 1611',
];
const List<String> kVersionAbbrs = ['ARA', 'NVI', 'NTLH', 'JFAA', 'BKJ'];

const String kHighlightColors = 'highlights';

const String kAppName = 'Bíblia IPM';
const String kAppVersion = '4.8';

const MethodChannel _migrationChannel =
    MethodChannel('br.com.valdenor.bibliaapp/migration');

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState i = AppState._();

  late SharedPreferences prefs;

  final Map<String, List<Book>> bibles = {};
  List<Book> bible = [];
  List<Hymn> hymns = [];
  List<Song> songs = [];
  List<Birthday> birthdays = [];
  List<ChurchEvent> events = [];
  List<BibliotecaText> biblioteca = [];

  int themeIndex = 0;
  double fontScale = 1.0;
  String version = 'ara';
  bool loaded = false;

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    await _migrateFromNative();
    themeIndex = prefs.getInt('theme') ??
        ((prefs.getBool('night') ?? false) ? 1 : 0);
    if (themeIndex < 0 || themeIndex >= kThemes.length) themeIndex = 0;
    fontScale = prefs.getDouble('font_scale') ?? 1.0;
    if (fontScale < 0.5) fontScale = 0.5;
    if (fontScale > 1.5) fontScale = 1.5;
    version = prefs.getString('biblia_version') ?? 'ara';

    bibles['jfaal'] = await _loadBible('assets/biblia.json');
    bibles['ara'] = await _loadBible('assets/biblia_ara.json');
    bibles['nvi'] = await _loadBible('assets/biblia_nvi.json');
    bibles['ntlh'] = await _loadBible('assets/biblia_ntlh.json');
    bibles['bkj'] = await _loadBible('assets/biblia_bkj.json');
    bible = bibles[version] ?? bibles['jfaal']!;

    final hymnJson = jsonDecode(await rootBundle.loadString('assets/hinos.json'))
        as List<dynamic>;
    hymns = hymnJson
        .map((e) => Hymn.fromJson(e as Map<String, dynamic>))
        .toList();

    await _loadSongs();
    await _loadBoletim();

    final libraryJson =
        jsonDecode(await rootBundle.loadString('assets/biblioteca.json'))
            as Map<String, dynamic>;
    biblioteca = ((libraryJson['texts'] as List<dynamic>?) ?? [])
        .map((e) => BibliotecaText.fromJson(e as Map<String, dynamic>))
        .toList();

    loaded = true;
    notifyListeners();
  }

  /// Migra, uma única vez, os dados do app nativo Android (v4.0 e anteriores)
  /// que compartilha o mesmo applicationId: destaques, músicas, boletim e
  /// preferências. Só preenche o que ainda não existir no Flutter.
  Future<void> _migrateFromNative() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (prefs.getBool('migrated_native_v1') == true) return;

    Map<dynamic, dynamic>? data;
    try {
      data = await _migrationChannel.invokeMethod<Map<dynamic, dynamic>>(
        'readNativeData',
      );
    } catch (_) {
      data = null;
    }

    if (data != null) {
      final theme = data['theme'] as int?;
      final night = data['night'] as bool?;
      if (!prefs.containsKey('theme')) {
        if (theme != null) {
          await prefs.setInt('theme', theme);
        } else if (night == true) {
          await prefs.setInt('theme', 1);
        }
      }
      final font = (data['fontScale'] as num?)?.toDouble();
      if (font != null && !prefs.containsKey('font_scale')) {
        await prefs.setDouble('font_scale', font);
      }
      final savedVersion = data['version'] as String?;
      if (savedVersion != null && !prefs.containsKey('biblia_version')) {
        await prefs.setString('biblia_version', savedVersion);
      }

      final highlights = data['highlights'];
      if (highlights is Map) {
        for (final entry in highlights.entries) {
          final key = 'hl_${entry.key}';
          final value = entry.value;
          if (value is int && !prefs.containsKey(key)) {
            await prefs.setInt(key, value);
          }
        }
      }

      final songs = data['songs'] as String?;
      if (songs != null &&
          songs.trim().isNotEmpty &&
          !prefs.containsKey('songs_json')) {
        try {
          if (jsonDecode(songs) is List) {
            await prefs.setString('songs_json', songs);
          }
        } catch (_) {}
      }

      final boletim = data['boletim'] as String?;
      if (boletim != null &&
          boletim.trim().isNotEmpty &&
          !prefs.containsKey('boletim_json')) {
        try {
          if (jsonDecode(boletim) is Map) {
            await prefs.setString('boletim_json', boletim);
          }
        } catch (_) {}
      }
    }

    await prefs.setBool('migrated_native_v1', true);
  }

  Future<List<Book>> _loadBible(String asset) async {
    final raw = jsonDecode(await rootBundle.loadString(asset)) as List<dynamic>;
    return raw.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _loadSongs() async {
    final stored = prefs.getString('songs_json');
    try {
      final text =
          stored ?? await rootBundle.loadString('assets/musicas.json');
      final arr = jsonDecode(text) as List<dynamic>;
      songs = arr.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      songs = [];
    }
  }

  Future<void> _loadBoletim() async {
    try {
      final stored = prefs.getString('boletim_json');
      final text = stored ?? await rootBundle.loadString('assets/boletim.json');
      final obj = jsonDecode(text) as Map<String, dynamic>;
      final b = (obj['aniversariantes'] as List<dynamic>?) ?? [];
      final e = (obj['eventos'] as List<dynamic>?) ?? [];
      birthdays = b
          .map((x) => Birthday.fromJson(x as Map<String, dynamic>))
          .toList();
      events = e
          .map((x) => ChurchEvent.fromJson(x as Map<String, dynamic>))
          .toList();
    } catch (_) {
      birthdays = [];
      events = [];
    }
  }

  // ------------------------------------------------------------- preferências

  void setTheme(int index) {
    themeIndex = index;
    prefs.setInt('theme', index);
    notifyListeners();
  }

  void setFontScale(double scale) {
    fontScale = scale;
    prefs.setDouble('font_scale', scale);
    notifyListeners();
  }

  void setVersion(String code) {
    if (!bibles.containsKey(code)) return;
    version = code;
    bible = bibles[code]!;
    prefs.setString('biblia_version', code);
    notifyListeners();
  }

  // ------------------------------------------------------------- músicas

  Future<void> saveSongs() async {
    await prefs.setString('songs_json', parseSongsJson(songs));
    notifyListeners();
  }

  // ------------------------------------------------------------- boletim

  Future<void> saveBoletim() async {
    await prefs.setString(
        'boletim_json', parseBoletimJson(birthdays, events));
    notifyListeners();
  }

  // ------------------------------------------------------------- destaques

  int getHighlight(String key) => prefs.getInt('hl_$key') ?? -1;

  Future<void> setHighlight(String key, int colorIndex) async {
    await prefs.setInt('hl_$key', colorIndex);
    notifyListeners();
  }
}
