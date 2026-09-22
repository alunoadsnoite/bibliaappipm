import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
const Map<String, String> kVersionAssets = {
  'ara': 'assets/biblia_ara.json',
  'nvi': 'assets/biblia_nvi.json',
  'ntlh': 'assets/biblia_ntlh.json',
  'jfaal': 'assets/biblia.json',
  'bkj': 'assets/biblia_bkj.json',
};

const String kAppName = 'Bíblia IPM';

/// Versão de fallback (desenvolvimento/testes), sobrescrita no [AppState.load]
/// pelo valor real do pacote via [PackageInfo].
const String kAppVersion = '5.2.2';

const int kDefaultDailyGoal = 4;
const int kMaxRecent = 6;

const MethodChannel _migrationChannel =
    MethodChannel('br.com.valdenor.bibliaapp/migration');

/// Decodifica o JSON de uma Bíblia em um isolate separado, para não travar a
/// interface na leitura de arquivos grandes (ex.: 4 MB por tradução).
List<dynamic> _decodeBibleJson(String text) => jsonDecode(text) as List<dynamic>;

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState i = AppState._();

  late SharedPreferences prefs;

  /// Traduções já carregadas em memória (carga sob demanda via
  /// [_ensureBible]).
  final Map<String, List<Book>> _bibleCache = {};
  Map<String, List<Book>> get bibles => _bibleCache;

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

  /// Brilho atual do aparelho (claro/escuro), usado pelo tema Sistema.
  /// Atualizado no build da raiz a partir do `MediaQuery`.
  Brightness systemBrightness = Brightness.light;

  /// Versão real do pacote instalado, preenchida no [load].
  String appVersion = kAppVersion;

  /// Versículos das falas de Jesus e de Deus, por livro/capítulo canônicos
  /// (chaves "livro", "capítulo" e valores = números de versículos).
  Map<String, Map<String, List<int>>> redLetter = {};
  bool redLetterEnabled = false;

  // ------------------------------------------------------------- leitura por voz
  double ttsRate = 0.5;
  double ttsPitch = 1.0;
  String ttsVoice = 'default'; // 'default' | 'female' | 'male'

  Map<String, String> notes = {};
  List<RecentRef> recent = [];

  /// Capítulos lidos no formato "livro:capítulo" (índices canônicos),
  /// usados pelo plano de leitura anual.
  Set<String> readChapters = {};
  Map<String, int> readsByDay = {};

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    await _migrateFromNative();
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    } catch (_) {
      // Mantém o fallback ([kAppVersion]) fora de plataformas suportadas.
    }
    themeIndex = prefs.getInt('theme') ??
        ((prefs.getBool('night') ?? false) ? 1 : 0);
    if (themeIndex < 0 || themeIndex >= kThemeNames.length) themeIndex = 0;
    fontScale = snapFontLevel(prefs.getDouble('font_scale') ?? 1.0);
    version = prefs.getString('biblia_version') ?? 'ara';
    if (!kVersionOrder.contains(version)) version = 'ara';
    redLetterEnabled = prefs.getBool('red_letter_enabled') ?? false;

    await _loadRedLetter();

    ttsRate = prefs.getDouble('tts_rate') ?? 0.5;
    ttsPitch = prefs.getDouble('tts_pitch') ?? 1.0;
    ttsVoice = prefs.getString('tts_voice') ?? 'default';
    if (ttsRate < 0.25) ttsRate = 0.25;
    if (ttsRate > 0.75) ttsRate = 0.75;
    if (ttsPitch < 0.5) ttsPitch = 0.5;
    if (ttsPitch > 2.0) ttsPitch = 2.0;
    if (!const ['default', 'female', 'male'].contains(ttsVoice)) {
      ttsVoice = 'default';
    }

    // Carrega apenas a tradução ativa; as demais entram sob demanda.
    bible = await _ensureBible(version);

    final hymnJson = jsonDecode(await rootBundle.loadString('assets/hinos.json'))
        as List<dynamic>;
    hymns = hymnJson
        .map((e) => Hymn.fromJson(e as Map<String, dynamic>))
        .toList();

    await _loadSongs();
    await _loadBoletim();
    _loadNotes();
    _loadRecent();
    _loadPlan();
    await _migrateKeysToCanonical();

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
        for (var entry in highlights.entries) {
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

  /// Normaliza a chave de destaque/nota da Bíblia. Chaves do formato antigo
  /// ("v:ABBR C:V") viram chaves canônicas por índice de livro
  /// ("v:livro:cap:vers"), que não dependem da tradução. Chaves atuais
  /// são retornadas sem alteração.
  String normalizeVKey(String key) {
    final m = RegExp(r'^v:(\S+)\s+(\d+)(?::(\d+))?$').firstMatch(key);
    if (m == null) return key;
    int? idx;
    for (var i = 0; i < bible.length; i++) {
      if (bible[i].abbr.toLowerCase() == m.group(1)!.toLowerCase()) {
        idx = i;
        break;
      }
    }
    if (idx == null) return key;
    final c = int.parse(m.group(2)!);
    final v = m.group(3);
    return v == null ? 'v:$idx:$c' : 'v:$idx:$c:$v';
  }

  /// Converte, uma única vez, destaques e notas salvos com chaves do formato
  /// antigo (abreviação da tradução) para chaves canônicas por índice de
  /// livro, para que fiquem visíveis em qualquer tradução.
  Future<void> _migrateKeysToCanonical() async {
    if (prefs.getBool('migrated_keys_v2') == true) return;

    for (var key in prefs.getKeys()) {
      if (!key.startsWith('hl_v:')) continue;
      final canon = normalizeVKey(key.substring(3));
      if (canon == key.substring(3)) continue;
      final value = prefs.getInt(key);
      if (value != null) {
        await prefs.setInt('hl_$canon', value);
        await prefs.remove(key);
      }
    }

    final newNotes = <String, String>{};
    var changed = false;
    notes.forEach((key, value) {
      final canon = !key.startsWith('v:') ? key : normalizeVKey(key);
      if (canon != key) changed = true;
      newNotes[canon] = value;
    });
    if (changed) {
      notes = newNotes;
      await prefs.setString('notes', jsonEncode(notes));
    }

    await prefs.setBool('migrated_keys_v2', true);
  }

  // ------------------------------------------------------------- traduções

  /// Carrega o conjunto de versículos com falas de Deus/Jesus ("letras
  /// vermelhas"), indexado por livro/capítulo canônicos.
  Future<void> _loadRedLetter() async {
    try {
      final raw = jsonDecode(
              await rootBundle.loadString('assets/redletter.json'))
          as Map<String, dynamic>;
      redLetter = raw.map((book, chapters) => MapEntry(
            book,
            (chapters as Map<String, dynamic>).map(
                (ch, vs) => MapEntry(ch, (vs as List<dynamic>).cast<int>())),
          ));
    } catch (_) {
      redLetter = {};
    }
  }

  /// `true` se o versículo (índices canônicos) contém fala de Jesus/Deus.
  bool isRedLetter(int book, int chapter, int verse) {
    final chs = redLetter['${book + 1}'];
    if (chs == null) return false;
    final vs = chs['${chapter + 1}'];
    return vs != null && vs.contains(verse + 1);
  }

  Future<List<Book>> _ensureBible(String code) async {
    final cached = _bibleCache[code];
    if (cached != null) return cached;
    final asset = kVersionAssets[code];
    if (asset == null) {
      return _bibleCache['jfaal'] ??
        await _loadBible(kVersionAssets['jfaal']!);
    }
    final books = await _loadBible(asset);
    _bibleCache[code] = books;
    return books;
  }

  /// Garante que todas as traduções estejam em memória (usado pela
  /// comparação lado a lado).
  Future<void> ensureAllBibles() async {
    for (var code in kVersionOrder) {
      await _ensureBible(code);
    }
  }

  /// Texto de um mesmo versículo em todas as traduções, lado a lado.
  /// Cada entrada é (abreviação da versão, texto do versículo).
  Future<List<(String, String)>> comparedVerses(
      int book, int chapter, int verse) async {
    await ensureAllBibles();
    final out = <(String, String)>[];
    for (var i = 0; i < kVersionOrder.length; i++) {
      final code = kVersionOrder[i];
      final b = _bibleCache[code]!;
      if (book >= b.length) continue;
      final chs = b[book].chapters;
      if (chapter >= chs.length) continue;
      final vs = chs[chapter];
      if (verse >= vs.length) continue;
      out.add((kVersionAbbrs[i], vs[verse]));
    }
    return out;
  }

  Future<List<Book>> _loadBible(String asset) async {
    final text = await rootBundle.loadString(asset);
    final raw = await compute(_decodeBibleJson, text);
    return raw.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Total de capítulos da Bíblia na versão ativa.
  int get totalChapters {
    var n = 0;
    for (var b in bible) {
      n += b.chapters.length;
    }
    return n;
  }

  Future<void> _loadSongs() async {
    try {
      final stored = prefs.getString('songs_json');
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
    if (index < 0 || index >= kThemeNames.length) return;
    themeIndex = index;
    prefs.setInt('theme', index);
    notifyListeners();
  }

  // ------------------------------------------------------------- tema em leitura
  int? _readingThemeOverride;

  /// Índice de tema exibido. Enquanto o modo leitura estiver ativo, retorna o
  /// tema temporário escolhido pelo atalho claro/escuro; caso contrário, o
  /// tema salvo pelo usuário.
  int get displayedThemeIndex => _readingThemeOverride ?? themeIndex;

  /// Alterna momentaneamente entre claro e escuro no modo leitura, sem mudar a
  /// preferência salva pelo usuário.
  void toggleReadingTheme() {
    final base = _readingThemeOverride ?? themeIndex;
    final eff = effectiveThemeIndex(base, systemBrightness);
    _readingThemeOverride = eff == 1 ? 0 : 1;
    notifyListeners();
  }

  /// Restaura o tema salvo pelo usuário ao sair do modo leitura.
  void endReadingTheme() {
    if (_readingThemeOverride == null) return;
    _readingThemeOverride = null;
    notifyListeners();
  }

  void setFontScale(double scale) {
    fontScale = scale;
    prefs.setDouble('font_scale', scale);
    notifyListeners();
  }

  // ------------------------------------------------------------ leitura por voz

  void setTtsRate(double rate) {
    ttsRate = rate.clamp(0.25, 0.75).toDouble();
    prefs.setDouble('tts_rate', ttsRate);
    notifyListeners();
  }

  void setTtsPitch(double pitch) {
    ttsPitch = pitch.clamp(0.5, 2.0).toDouble();
    prefs.setDouble('tts_pitch', ttsPitch);
    notifyListeners();
  }

  void setTtsVoice(String voice) {
    if (!const ['default', 'female', 'male'].contains(voice)) return;
    ttsVoice = voice;
    prefs.setString('tts_voice', voice);
    notifyListeners();
  }

  /// Liga/desliga as falas de Jesus e de Deus em vermelho.
  void setRedLetterEnabled(bool enabled) {
    redLetterEnabled = enabled;
    prefs.setBool('red_letter_enabled', enabled);
    notifyListeners();
  }

  /// Define a tradução ativa, carregando-a sob demanda caso ainda não esteja
  /// em memória.
  Future<void> setVersion(String code) async {
    if (!kVersionOrder.contains(code)) return;
    version = code;
    bible = await _ensureBible(code);
    await prefs.setString('biblia_version', code);
    notifyListeners();
  }

  // ------------------------------------------------------------- posição

  String get _positionKey => 'lastpos_$version';

  /// Última posição lida na versão atual (ou `null`).
  Position? get lastPosition {
    final raw = prefs.getString(_positionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Position.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Última posição lida em uma versão específica (ou `null`).
  Position? positionOf(String v) {
    final raw = prefs.getString('lastpos_$v');
    if (raw == null || raw.isEmpty) return null;
    try {
      return Position.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePosition(int book, int chapter) async {
    await prefs.setString(
        _positionKey, jsonEncode(Position(book, chapter).toJson()));
  }

  // ------------------------------------------------------------- histórico

  void _loadRecent() {
    recent = [];
    final raw = prefs.getString('recent');
    if (raw == null || raw.isEmpty) return;
    try {
      final arr = jsonDecode(raw) as List<dynamic>;
      recent = arr
          .map((e) => RecentRef.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      recent = [];
    }
  }

  Future<void> addRecent(int book, int chapter) async {
    recent.removeWhere(
        (r) => r.version == version && r.book == book && r.chapter == chapter);
    recent.insert(0, RecentRef(version, book, chapter));
    while (recent.length > kMaxRecent) {
      recent.removeLast();
    }
    await prefs.setString(
        'recent', jsonEncode(recent.map((r) => r.toJson()).toList()));
    notifyListeners();
  }

  Future<void> removeRecent(int index) async {
    if (index < 0 || index >= recent.length) return;
    recent.removeAt(index);
    await prefs.setString(
        'recent', jsonEncode(recent.map((r) => r.toJson()).toList()));
    notifyListeners();
  }

  // ------------------------------------------------------------- notas

  void _loadNotes() {
    notes = {};
    final raw = prefs.getString('notes');
    if (raw == null || raw.isEmpty) return;
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      notes = obj.map((k, v) => MapEntry(k, (v as String? ?? '')));
    } catch (_) {
      notes = {};
    }
  }

  String? getNote(String key) => notes[key];

  bool hasNote(String key) =>
      (notes[key] ?? '').trim().isNotEmpty;

  Future<void> setNote(String key, String text) async {
    final t = text.trim();
    if (t.isEmpty) {
      notes.remove(key);
    } else {
      notes[key] = t;
    }
    await prefs.setString('notes', jsonEncode(notes));
    notifyListeners();
  }

  // ------------------------------------------------------------- plano

  bool get planEnabled => prefs.getBool('plan_enabled') ?? true;

  int get dailyGoal => prefs.getInt('plan_daily_goal') ?? kDefaultDailyGoal;

  void _loadPlan() {
    readChapters = {};
    readsByDay = {};
    final raw = prefs.getString('read_chapters');
    if (raw != null && raw.isNotEmpty) {
      try {
        readChapters =
            (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
      } catch (_) {
        readChapters = {};
      }
    }
    final byDay = prefs.getString('reads_by_day');
    if (byDay != null && byDay.isNotEmpty) {
      try {
        final obj = jsonDecode(byDay) as Map<String, dynamic>;
        readsByDay = obj.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {
        readsByDay = {};
      }
    }
  }

  String _dateKey(DateTime d) => '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String get _todayKey => _dateKey(DateTime.now());

  int get todayReadCount => readsByDay[_todayKey] ?? 0;

  int get totalRead => readChapters.length;

  double get planProgress =>
      totalChapters == 0 ? 0 : totalRead / totalChapters;

  bool isChapterRead(int book, int chapter) =>
      readChapters.contains('$book:$chapter');

  /// Próximo capítulo ainda não lido (índices canônicos), percorrendo a
  /// Bíblia na ordem — ou `null` se todos já foram lidos.
  (int, int)? get nextUnreadChapter {
    for (var b = 0; b < bible.length; b++) {
      for (var c = 0; c < bible[b].chapters.length; c++) {
        if (!isChapterRead(b, c)) return (b, c);
      }
    }
    return null;
  }

  /// Sequência (em dias) com pelo menos um capítulo lido, contando a partir
  /// de hoje (ou de ontem, se hoje ainda não leu).
  int get streak {
    var n = 0;
    var day = DateTime.now();
    if ((readsByDay[_dateKey(day)] ?? 0) == 0) {
      day = day.subtract(const Duration(days: 1));
    }
    while ((readsByDay[_dateKey(day)] ?? 0) > 0) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// Marca um capítulo como lido (índices canônicos). A contagem do dia só
  /// aumenta na primeira vez que o capítulo é marcado.
  Future<void> markChapterRead(int book, int chapter) async {
    final key = '$book:$chapter';
    if (readChapters.add(key)) {
      final day = _todayKey;
      readsByDay[day] = (readsByDay[day] ?? 0) + 1;
      await prefs.setString('reads_by_day', jsonEncode(readsByDay));
    }
    await prefs.setString(
        'read_chapters', jsonEncode(readChapters.toList()..sort()));
    notifyListeners();
  }

  /// Desmarca um capítulo lido (para correção manual).
  Future<void> unmarkChapterRead(int book, int chapter) async {
    final key = '$book:$chapter';
    if (readChapters.remove(key)) {
      final day = _todayKey;
      final v = (readsByDay[day] ?? 0) - 1;
      readsByDay[day] = v < 0 ? 0 : v;
      await prefs.setString('reads_by_day', jsonEncode(readsByDay));
      await prefs.setString(
          'read_chapters', jsonEncode(readChapters.toList()..sort()));
      notifyListeners();
    }
  }

  void setPlanEnabled(bool enabled) {
    prefs.setBool('plan_enabled', enabled);
    notifyListeners();
  }

  void setDailyGoal(int goal) {
    prefs.setInt('plan_daily_goal', goal.clamp(1, 10));
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

  Map<String, int> _allHighlights() {
    final map = <String, int>{};
    for (var key in prefs.getKeys()) {
      if (!key.startsWith('hl_')) continue;
      final v = prefs.getInt(key);
      if (v != null) map[key.substring(3)] = v;
    }
    return map;
  }

  // ------------------------------------------------------------- backup

  /// Serializa todos os dados do usuário para exportação/backup.
  String buildExportJson() {
    return jsonEncode({
      'app': kAppName,
      'export': 1,
      'date': DateTime.now().toIso8601String(),
      'version': version,
      'theme': themeIndex,
      'font_scale': fontScale,
      'highlights': _allHighlights(),
      'notes': notes,
      'songs': parseSongsJson(songs),
      'aniversariantes': birthdays.map((b) => b.toJson()).toList(),
      'eventos': events.map((e) => e.toJson()).toList(),
      'read_chapters': readChapters.toList(),
      'reads_by_day': readsByDay,
      'recent': recent.map((r) => r.toJson()).toList(),
      'positions': {
        for (final v in kVersionOrder)
          if (prefs.getString('lastpos_$v') != null)
            v: jsonDecode(prefs.getString('lastpos_$v')!),
      },
    });
  }

  /// Importa (restaura) um backup gerado por [buildExportJson].
  /// Mescla destaques, notas, capítulos lidos e recentes; sobrescreve
  /// músicas, boletim e preferências.
  Future<void> importFromJson(String raw) async {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final highlights = data['highlights'];
    if (highlights is Map) {
      for (var e in highlights.entries) {
        final key = normalizeVKey(e.key.toString());
        final value = e.value;
        if (value is int) {
          await prefs.setInt('hl_$key', value);
        }
      }
    }

    final notesIn = data['notes'];
    if (notesIn is Map) {
      for (var e in notesIn.entries) {
        final key = normalizeVKey(e.key.toString());
        final t = (e.value as String? ?? '').trim();
        if (t.isEmpty) {
          notes.remove(key);
        } else {
          notes[key] = t;
        }
      }
      await prefs.setString('notes', jsonEncode(notes));
    }

    final songsIn = data['songs'];
    if (songsIn is String && songsIn.trim().isNotEmpty) {
      try {
        final arr = jsonDecode(songsIn) as List<dynamic>;
        final parsed = arr
            .map((e) => Song.fromJson(e as Map<String, dynamic>))
            .toList();
        songs = parsed;
        await prefs.setString('songs_json', songsIn);
      } catch (_) {}
    }

    final birthdaysIn = data['aniversariantes'];
    final eventosIn = data['eventos'];
    if (birthdaysIn is List || eventosIn is List) {
      try {
        birthdays = ((birthdaysIn as List<dynamic>?) ?? [])
            .map((e) => Birthday.fromJson(e as Map<String, dynamic>))
            .toList();
        events = ((eventosIn as List<dynamic>?) ?? [])
            .map((e) => ChurchEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveBoletim();
      } catch (_) {}
    }

    final read = data['read_chapters'];
    if (read is List) {
      readChapters = {
        ...readChapters,
        ...read.whereType<String>(),
      };
      await prefs.setString(
          'read_chapters', jsonEncode(readChapters.toList()..sort()));
    }
    final reads = data['reads_by_day'];
    if (reads is Map) {
      readsByDay = reads.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      await prefs.setString('reads_by_day', jsonEncode(readsByDay));
    }

    final recentIn = data['recent'];
    if (recentIn is List) {
      try {
        recent = recentIn
            .map((e) => RecentRef.fromJson(e as Map<String, dynamic>))
            .toList();
        while (recent.length > kMaxRecent) {
          recent.removeLast();
        }
        await prefs.setString(
            'recent', jsonEncode(recent.map((r) => r.toJson()).toList()));
      } catch (_) {}
    }

    final positions = data['positions'];
    if (positions is Map) {
      for (var e in positions.entries) {
        try {
          final p = Position.fromJson(e.value as Map<String, dynamic>);
          await prefs.setString(
              'lastpos_${e.key}', jsonEncode(p.toJson()));
        } catch (_) {}
      }
    }

    final savedVersion = data['version'];
    if (savedVersion is String && kVersionOrder.contains(savedVersion)) {
      await setVersion(savedVersion);
    }
    final theme = data['theme'];
    if (theme is int && theme >= 0 && theme < kThemeNames.length) {
      setTheme(theme);
    }

    notifyListeners();
  }
}