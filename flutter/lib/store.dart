import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'backup_validation.dart';
import 'daily.dart';
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
const String kAppVersion = '5.4.0';

const int kDefaultDailyGoal = 4;
const int kMaxRecent = 6;

const MethodChannel _migrationChannel = MethodChannel(
  'br.com.valdenor.bibliaapp/migration',
);
const MethodChannel _widgetChannel = MethodChannel(
  'br.com.valdenor.bibliaapp/widget',
);

/// Decodifica o JSON de uma Bíblia em um isolate separado, para não travar a
/// interface na leitura de arquivos grandes (ex.: 4 MB por tradução).
List<dynamic> _decodeBibleJson(String text) =>
    jsonDecode(text) as List<dynamic>;

/// Cast seguro com retorno `null` se o tipo não bater — evita `TypeError` ao
/// processar dados vindos de fora (canal nativo, backup editado à mão).
T? _as<T>(Object? v) => v is T ? v : null;

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState i = AppState._();

  late SharedPreferences prefs;
  bool storageAvailable = true;
  SharedPreferencesStorePlatform? _failedStore;
  final List<String> loadErrors = [];

  /// Obtém o SharedPreferences sem deixar o app nascer sem ele: se o canal de
  /// plataforma falhar, cai num armazenamento em memória para a sessão.
  Future<SharedPreferences> _initPrefs() async {
    try {
      if (_failedStore != null) {
        SharedPreferencesStorePlatform.instance = _failedStore!;
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.resetStatic();
        _failedStore = null;
      }
      final result = await SharedPreferences.getInstance();
      storageAvailable = true;
      return result;
    } catch (e) {
      _failedStore = SharedPreferencesStorePlatform.instance;
      storageAvailable = false;
      debugPrint('SharedPreferences indisponível, usando memória: $e');
      // Necessário para cair no armazenamento em memória mesmo sem o plugin.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      return await SharedPreferences.getInstance();
    }
  }

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

  Set<String> favorites = {};
  Map<String, String> notes = {};
  List<RecentRef> recent = [];

  /// Capítulos lidos no formato "livro:capítulo" (índices canônicos),
  /// usados pelo plano de leitura anual.
  Set<String> readChapters = {};
  Map<String, int> readsByDay = {};

  /// Dia ("ano-mês-dia") em que cada capítulo foi lido, para o desmarcar
  /// corrigir a contagem do dia certo (e não o de hoje).
  Map<String, String> readDayByChapter = {};

  Future<void> load() async {
    loadErrors.clear();
    prefs = await _initPrefs();
    // O cache de posição reflete o conteúdo das preferências; se o store for
    // recarregado (ou redefinido), valores antigos ficariam errados.
    _positionCache.clear();
    // O handler do widget é registrado cedo: mesmo que algum passo opcional
    // abaixo falhe, o Android ainda responde ao pedido do versículo do dia.
    _widgetChannel.setMethodCallHandler(_handleWidgetCall);
    await _optional('migração nativa', _migrateFromNative);
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    } catch (_) {
      // Mantém o fallback ([kAppVersion]) fora de plataformas suportadas.
    }
    themeIndex =
        prefs.getInt('theme') ?? ((prefs.getBool('night') ?? false) ? 1 : 0);
    if (themeIndex < 0 || themeIndex >= kThemeNames.length) themeIndex = 0;
    fontScale = snapFontLevel(prefs.getDouble('font_scale') ?? 1.0);
    version = prefs.getString('biblia_version') ?? 'ara';
    if (!kVersionOrder.contains(version)) version = 'ara';
    redLetterEnabled = prefs.getBool('red_letter_enabled') ?? false;

    await _optional('letras vermelhas', _loadRedLetter);

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

    // Carrega apenas a tradução ativa; as demais entram sob demanda. Uma
    // falha aqui não pode derrubar o resto da inicialização (hinário, notas,
    // plano e biblioteca continuam carregando).
    await _optional('bíblia', () async {
      bible = await _ensureBible(version);
    });
    await _optional('versículo do dia', _saveDailyVerse);

    await _optional('hinário', () async {
      final hymnJson = jsonDecode(
        await rootBundle.loadString('assets/hinos.json'),
      ) as List<dynamic>;
      hymns = hymnJson
          .map((e) => Hymn.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    await _optional('músicas', _loadSongs);
    await _optional('boletim', _loadBoletim);
    favorites = (prefs.getStringList('favorites') ?? []).toSet();
    _optionalSync('notas', _loadNotes);
    _optionalSync('recentes', _loadRecent);
    _optionalSync('plano de leitura', _loadPlan);
    await _optional('normalização de chaves', _migrateKeysToCanonical);
    await _optional('normalização de chaves de músicas', _migrateSongKeys);

    await _optional('biblioteca', () async {
      final libraryJson = jsonDecode(
        await rootBundle.loadString('assets/biblioteca.json'),
      ) as Map<String, dynamic>;
      biblioteca = ((libraryJson['texts'] as List<dynamic>?) ?? [])
          .map((e) => BibliotecaText.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    loaded = true;
    notifyListeners();
  }

  /// Executa uma etapa opcional do [load] sem impedir a partida do app.
  ///
  /// Sem isto, um único asset corrompido ou uma preferência malformada deixa a
  /// tela inicial preta para sempre, porque `runApp` só é chamado depois que o
  /// [load] termina.
  Future<void> _optional(String label, Future<void> Function() step) async {
    try {
      await step();
    } catch (error, stack) {
      loadErrors.add(label);
      debugPrint('Falha ao carregar "$label": $error\n$stack');
    }
  }

  /// Igual a [_optional], para etapas síncronas.
  void _optionalSync(String label, void Function() step) {
    try {
      step();
    } catch (error, stack) {
      loadErrors.add(label);
      debugPrint('Falha ao carregar "$label": $error\n$stack');
    }
  }

  Future<dynamic> _handleWidgetCall(MethodCall call) async {
    if (call.method == 'getDailyVerse') {
      final today = DateTime.now();
      final verse = dailyVerseForIn(bible, today);
      if (verse == null) return null;
      final (book, chapter, v) = verse;
      final verseText = bible[book].chapters[chapter][v];
      final ref = formatRef(bible, book, chapter, v);
      return {
        'text': verseText,
        'ref': ref,
        'date': today.toIso8601String().split('T')[0],
      };
    }
    return null;
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
    } catch (error, stack) {
      // Canal indisponível neste aparelho: NÃO marca como migrado, para
      // tentar de novo na próxima inicialização.
      debugPrint('Migração nativa indisponível: $error\n$stack');
      return;
    }

    if (data == null) {
      await prefs.setBool('migrated_native_v1', true);
      return;
    }

    final theme = _as<int>(data['theme']);
    final night = _as<bool>(data['night']);
    if (!prefs.containsKey('theme')) {
      if (theme != null) {
        await prefs.setInt('theme', theme);
      } else if (night == true) {
        await prefs.setInt('theme', 1);
      }
    }
    final font = _as<num>(data['fontScale'])?.toDouble();
    if (font != null && !prefs.containsKey('font_scale')) {
      await prefs.setDouble('font_scale', font);
    }
    final savedVersion = _as<String>(data['version']);
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

    final songs = _as<String>(data['songs']);
    if (songs != null &&
        songs.trim().isNotEmpty &&
        !prefs.containsKey('songs_json')) {
      try {
        if (jsonDecode(songs) is List) {
          await prefs.setString('songs_json', songs);
        }
      } catch (_) {}
    }

    final boletim = _as<String>(data['boletim']);
    if (boletim != null &&
        boletim.trim().isNotEmpty &&
        !prefs.containsKey('boletim_json')) {
      try {
        if (jsonDecode(boletim) is Map) {
          await prefs.setString('boletim_json', boletim);
        }
      } catch (_) {}
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

  /// Identificador estável de uma música, usado nas chaves de nota/destaque.
  ///
  /// Antes a chave usava o índice na lista, que muda quando qualquer música é
  /// excluída ou reordenada — e as notas passavam a apontar para a música
  /// errada. O ID é persistido e permanece o mesmo ao editar título ou letra.
  static String songId(Song s) => s.id;

  /// Converte, uma única vez, as chaves antigas `s:<índice>:<linha>` das notas
  /// e destaques de músicas para `s:<id>:<linha>`.
  Future<void> _migrateSongKeys() async {
    if (prefs.getBool('migrated_song_keys_v1') == true) return;
    try {
      final pattern = RegExp(r'^s:(\d+):(\d+)$');

      final newNotes = <String, String>{};
      var changed = false;
      for (final entry in notes.entries) {
        final m = pattern.firstMatch(entry.key);
        final idx = m == null ? -1 : int.parse(m.group(1)!);
        if (idx < 0 || idx >= songs.length) {
          // Já canônica, ou um índice que não existe mais: mantém como está.
          newNotes[entry.key] = entry.value;
          continue;
        }
        newNotes['s:${songId(songs[idx])}:${m!.group(2)}'] = entry.value;
        changed = true;
      }
      if (changed) {
        notes = newNotes;
        await prefs.setString('notes', jsonEncode(notes));
      }

      for (final key in prefs.getKeys()) {
        if (!key.startsWith('hl_s:')) continue;
        final m = pattern.firstMatch(key.substring(3));
        if (m == null) continue;
        final idx = int.parse(m.group(1)!);
        if (idx < 0 || idx >= songs.length) continue;
        final value = prefs.getInt(key);
        if (value == null) continue;
        await prefs.setInt('hl_s:${songId(songs[idx])}:${m.group(2)}', value);
        await prefs.remove(key);
      }

      await prefs.setBool('migrated_song_keys_v1', true);
    } catch (error, stack) {
      debugPrint('Falha ao migrar chaves de músicas: $error\n$stack');
    }
  }

  // ------------------------------------------------------------- traduções

  /// Carrega o conjunto de versículos com falas de Deus/Jesus ("letras
  /// vermelhas"), indexado por livro/capítulo canônicos.
  Future<void> _loadRedLetter() async {
    try {
      final raw = jsonDecode(
        await rootBundle.loadString('assets/redletter.json'),
      ) as Map<String, dynamic>;
      redLetter = raw.map(
        (book, chapters) => MapEntry(
          book,
          (chapters as Map<String, dynamic>).map(
            (ch, vs) => MapEntry(ch, (vs as List<dynamic>).cast<int>()),
          ),
        ),
      );
    } catch (_) {
      redLetter = {};
      rethrow;
    }
  }

  /// `true` se o versículo (índices canônicos) contém fala de Jesus/Deus.
  bool isRedLetter(int book, int chapter, int verse) {
    final chs = redLetter['${book + 1}'];
    if (chs == null) return false;
    final vs = chs['${chapter + 1}'];
    return vs != null && vs.contains(verse + 1);
  }

  /// Faturas de carga em andamento, por código — evita ler duas vezes o mesmo
  /// arquivo de ~4 MB quando duas chamadas concorrentes pedem a tradução.
  final Map<String, Future<List<Book>>> _bibleLoads = {};

  Future<List<Book>> _ensureBible(String code) async {
    final cached = _bibleCache[code];
    if (cached != null) return cached;
    final inFlight = _bibleLoads[code];
    if (inFlight != null) return inFlight;
    final future = _doEnsureBible(code);
    _bibleLoads[code] = future;
    try {
      return await future;
    } finally {
      _bibleLoads.remove(code);
    }
  }

  Future<List<Book>> _doEnsureBible(String code) async {
    final asset = kVersionAssets[code];
    if (asset == null) {
      // Código desconhecido: cai na tradução padrão (jfaal), que passa pela
      // mesma via de cache acima — o resultado fica gravado em `_bibleCache`.
      return _ensureBible('jfaal');
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
    int book,
    int chapter,
    int verse,
  ) async {
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
      final text = stored ?? await rootBundle.loadString('assets/musicas.json');
      final arr = jsonDecode(text) as List<dynamic>;
      songs = arr.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      songs = [];
      rethrow;
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
      rethrow;
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
  /// em memória. Só muda o estado depois que a carga tiver sucesso — se o
  /// asset falhar, `version` e `bible` permanecem os da tradução atual e o
  /// erro é propagado para a UI tratar.
  Future<void> setVersion(String code) async {
    if (!kVersionOrder.contains(code)) return;
    final next = await _ensureBible(code);
    final wasVersion = version;
    final wasBible = bible;
    version = code;
    bible = next;
    try {
      await prefs.setString('biblia_version', code);
      await _saveDailyVerse();
    } catch (error, stack) {
      version = wasVersion;
      bible = wasBible;
      debugPrint('Falha ao persistir tradução "$code": $error\n$stack');
      rethrow;
    }
    notifyListeners();
  }

  /// Envia o versículo do dia para o widget Android e pede o redesenhe.
  ///
  /// O texto e a referência são resolvidos aqui, na tradução ativa, para que o
  /// widget mostre exatamente o mesmo conteúdo da tela inicial.
  ///
  /// Não lança: uma referência ausente na tradução ativa apenas mantém o
  /// valor anterior no widget, para não derrubar a inicialização do app.
  Future<void> _saveDailyVerse() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final today = DateTime.now();
    final verse = dailyVerseForIn(bible, today);
    if (verse == null) return;
    final (book, chapter, v) = verse;
    try {
      await _widgetChannel.invokeMethod<void>('syncWidget', {
        'text': bible[book].chapters[chapter][v],
        'ref': formatRef(bible, book, chapter, v),
        'date': today.toIso8601String().split('T')[0],
      });
    } catch (_) {
      // Plataforma sem suporte a widget: segue sem aviso.
    }
  }

  // ------------------------------------------------------------- posição

  String get _positionKey => 'lastpos_$version';

  /// Cache da última posição por versão — evita `jsonDecode` a cada build do
  /// card "Continuar lendo" (o vetor de estado notifica a raiz a cada
  /// evento, reconstruindo as abas).
  final Map<String, Position> _positionCache = {};

  /// Última posição lida na versão ativa (ou `null`).
  Position? get lastPosition => positionOf(version);

  /// Última posição lida em uma versão específica (ou `null`).
  Position? positionOf(String v) {
    final cached = _positionCache[v];
    if (cached != null) return cached;
    final raw = prefs.getString('lastpos_$v');
    if (raw == null || raw.isEmpty) return null;
    try {
      final p = Position.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _positionCache[v] = p;
      return p;
    } catch (_) {
      return null;
    }
  }

  Future<void> savePosition(int book, int chapter) async {
    _positionCache[version] = Position(book, chapter);
    await prefs.setString(
      _positionKey,
      jsonEncode(Position(book, chapter).toJson()),
    );
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
      (r) => r.version == version && r.book == book && r.chapter == chapter,
    );
    recent.insert(0, RecentRef(version, book, chapter));
    while (recent.length > kMaxRecent) {
      recent.removeLast();
    }
    await prefs.setString(
      'recent',
      jsonEncode(recent.map((r) => r.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> removeRecent(int index) async {
    if (index < 0 || index >= recent.length) return;
    recent.removeAt(index);
    await prefs.setString(
      'recent',
      jsonEncode(recent.map((r) => r.toJson()).toList()),
    );
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

  bool hasNote(String key) => (notes[key] ?? '').trim().isNotEmpty;

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

  void preferencesChanged() => notifyListeners();

  bool isFavorite(String key) => favorites.contains(key);

  Future<void> toggleFavorite(String key) async {
    final next = {...favorites};
    if (!next.add(key)) next.remove(key);
    if (!await prefs.setStringList('favorites', next.toList()..sort())) {
      throw StateError('Não foi possível salvar o favorito.');
    }
    favorites = next;
    notifyListeners();
  }

  Map<String, int> get highlights => _allHighlights();

  DateTime? get planDeadline =>
      DateTime.tryParse(prefs.getString('plan_deadline') ?? '');

  int goalForDate(DateTime now) {
    final deadline = planDeadline;
    if (deadline == null) return dailyGoal;
    final remaining = (totalChapters - totalRead).clamp(0, totalChapters);
    final today = DateTime.utc(now.year, now.month, now.day);
    final end = DateTime.utc(deadline.year, deadline.month, deadline.day);
    final days = (end.difference(today).inDays + 1).clamp(1, 100000);
    return (remaining / days).ceil();
  }

  int get effectiveDailyGoal => goalForDate(DateTime.now());

  Future<void> setPlanDeadline(DateTime? date) async {
    final ok = date == null
        ? await prefs.remove('plan_deadline')
        : await prefs.setString('plan_deadline', _dateKey(date));
    if (!ok) throw StateError('Não foi possível salvar o prazo.');
    notifyListeners();
  }

  // ------------------------------------------------------------- plano

  bool get planEnabled => prefs.getBool('plan_enabled') ?? true;

  int get dailyGoal =>
      (prefs.getInt('plan_daily_goal') ?? kDefaultDailyGoal).clamp(1, 10);

  void _loadPlan() {
    readChapters = {};
    readsByDay = {};
    readDayByChapter = {};
    final raw = prefs.getString('read_chapters');
    if (raw != null && raw.isNotEmpty) {
      try {
        readChapters = (jsonDecode(raw) as List<dynamic>)
            .cast<String>()
            .toSet();
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
    final dayMap = prefs.getString('read_day_by_chapter');
    if (dayMap != null && dayMap.isNotEmpty) {
      try {
        final obj = jsonDecode(dayMap) as Map<String, dynamic>;
        readDayByChapter = {};
        for (final e in obj.entries) {
          final v = e.value;
          readDayByChapter[e.key] = v is String ? v : '';
        }
      } catch (_) {
        readDayByChapter = {};
      }
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String get _todayKey => _dateKey(DateTime.now());

  int get todayReadCount => readsByDay[_todayKey] ?? 0;

  int get totalRead => readChapters.length;

  double get planProgress => totalChapters == 0 ? 0 : totalRead / totalChapters;

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
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if ((readsByDay[_dateKey(day)] ?? 0) == 0) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    while ((readsByDay[_dateKey(day)] ?? 0) > 0) {
      n++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return n;
  }

  /// Marca um capítulo como lido (índices canônicos). A contagem do dia só
  /// aumenta na primeira vez que o capítulo é marcado; reabrir um capítulo
  /// já marcado não reescreve as preferências.
  Future<void> markChapterRead(int book, int chapter) async {
    final key = '$book:$chapter';
    if (readChapters.add(key)) {
      final day = _todayKey;
      readsByDay[day] = (readsByDay[day] ?? 0) + 1;
      readDayByChapter[key] = day;
      await prefs.setString('reads_by_day', jsonEncode(readsByDay));
      await prefs.setString(
        'read_day_by_chapter',
        jsonEncode(readDayByChapter),
      );
      await prefs.setString(
        'read_chapters',
        jsonEncode(readChapters.toList()..sort()),
      );
    }
    notifyListeners();
  }

  /// Desmarca um capítulo lido (para correção manual). A contagem diária é
  /// debitada do dia em que o capítulo foi realmente lido (não do dia atual).
  Future<void> unmarkChapterRead(int book, int chapter) async {
    final key = '$book:$chapter';
    if (!readChapters.remove(key)) return;
    final readOn = readDayByChapter.remove(key);
    if (readOn != null) {
      final v = (readsByDay[readOn] ?? 0) - 1;
      readsByDay[readOn] = v < 0 ? 0 : v;
      await prefs.setString('reads_by_day', jsonEncode(readsByDay));
      await prefs.setString(
        'read_day_by_chapter',
        jsonEncode(readDayByChapter),
      );
    }
    await prefs.setString(
      'read_chapters',
      jsonEncode(readChapters.toList()..sort()),
    );
    notifyListeners();
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

  String exportBoletim() => jsonEncode({
    'boletim': 1,
    'app': kAppName,
    'aniversariantes': birthdays.map((b) => b.toJson()).toList(),
    'eventos': events.map((e) => e.toJson()).toList(),
  });

  Future<void> importBoletim(String raw) async {
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data['boletim'] != 1 ||
        (data['aniversariantes'] is! List && data['eventos'] is! List)) {
      throw const FormatException('Arquivo de boletim inválido.');
    }
    validateBackup(data, bible, kVersionOrder);
    final mergedBirthdays = {
      ...{
        for (final b in birthdays)
          '${b.name.trim().toLowerCase()}:${b.month}:${b.day}': b,
      },
    };
    for (final raw in ((data['aniversariantes'] as List?) ?? [])) {
      final b = Birthday.fromJson(raw as Map<String, dynamic>);
      mergedBirthdays['${b.name.trim().toLowerCase()}:${b.month}:${b.day}'] = b;
    }
    final mergedEvents = {
      ...{
        for (final e in events)
          '${e.title.trim().toLowerCase()}:${e.year}:${e.month}:${e.day}:${e.time}':
              e,
      },
    };
    for (final raw in ((data['eventos'] as List?) ?? [])) {
      final e = ChurchEvent.fromJson(raw as Map<String, dynamic>);
      mergedEvents['${e.title.trim().toLowerCase()}:${e.year}:${e.month}:${e.day}:${e.time}'] =
          e;
    }
    final bs = mergedBirthdays.values.toList();
    final es = mergedEvents.values.toList();
    if (!await prefs.setString('boletim_json', parseBoletimJson(bs, es))) {
      throw StateError('Não foi possível salvar o boletim.');
    }
    birthdays = bs;
    events = es;
    notifyListeners();
  }

  Future<void> saveBoletim() async {
    await prefs.setString('boletim_json', parseBoletimJson(birthdays, events));
    notifyListeners();
  }

  // ------------------------------------------------------------- destaques

  int getHighlight(String key) => prefs.getInt('hl_$key') ?? -1;

  Future<void> setHighlight(String key, int colorIndex) async {
    if (colorIndex < 0) {
      // Limpar REMOVE a preferência; o antigo gravava `hl_*= -1` para sempre,
      // acumulando entradas mortas que entravam em backups e restaurações.
      await prefs.remove('hl_$key');
    } else {
      await prefs.setInt('hl_$key', colorIndex);
    }
    notifyListeners();
  }

  Map<String, int> _allHighlights() {
    final map = <String, int>{};
    for (var key in prefs.getKeys()) {
      if (!key.startsWith('hl_')) continue;
      final v = prefs.getInt(key);
      // Ignora tombstones do formato antigo (hl_*= -1) na exportação.
      if (v != null && v >= 0) map[key.substring(3)] = v;
    }
    return map;
  }

  // ------------------------------------------------------------- backup

  /// Serializa todos os dados do usuário para exportação/backup.
  String buildExportJson() {
    final positions = <String, dynamic>{};
    for (final v in kVersionOrder) {
      final raw = prefs.getString('lastpos_$v');
      if (raw == null || raw.isEmpty) continue;
      try {
        positions[v] = jsonDecode(raw);
      } catch (error, stack) {
        // Uma posição corrompida não pode abortar o backup inteiro.
        debugPrint('Posição inválida em backup ($v): $error\n$stack');
      }
    }
    return jsonEncode({
      'app': kAppName,
      'export': 1,
      'date': DateTime.now().toIso8601String(),
      'version': version,
      'theme': themeIndex,
      'font_scale': fontScale,
      'red_letter_enabled': redLetterEnabled,
      'tts_rate': ttsRate,
      'tts_pitch': ttsPitch,
      'tts_voice': ttsVoice,
      'plan_enabled': planEnabled,
      'plan_daily_goal': dailyGoal,
      'highlights': _allHighlights(),
      'notes': notes,
      'favorites': favorites.toList()..sort(),
      'plan_deadline': planDeadline == null ? null : _dateKey(planDeadline!),
      'songs': parseSongsJson(songs),
      'aniversariantes': birthdays.map((b) => b.toJson()).toList(),
      'eventos': events.map((e) => e.toJson()).toList(),
      'read_chapters': readChapters.toList(),
      'reads_by_day': readsByDay,
      'read_day_by_chapter': readDayByChapter,
      'recent': recent.map((r) => r.toJson()).toList(),
      'positions': positions,
    });
  }

  /// Importa (restaura) um backup gerado por [buildExportJson].
  /// Mescla destaques, notas, capítulos lidos e recentes; sobrescreve
  /// músicas, boletim e preferências.
  Future<void> importFromJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['export'] != 1) {
      throw const FormatException('Backup inválido.');
    }
    validateBackup(decoded, bible, kVersionOrder);
    if (!storageAvailable) throw StateError('Armazenamento indisponível.');
    final snapshot = {
      for (final key in prefs.getKeys())
        if (key != 'backup_before_restore') key: prefs.get(key),
    };
    // Cópia recuperável persistida antes da primeira alteração.
    if (!await prefs.setString('backup_before_restore', jsonEncode(snapshot))) {
      throw StateError('Não foi possível preservar os dados atuais.');
    }
    try {
      await _applyBackup(raw);
    } catch (error) {
      try {
        for (final key in prefs.getKeys()) {
          if (key != 'backup_before_restore' && !await prefs.remove(key)) {
            throw StateError('Falha ao recuperar $key.');
          }
        }
        for (final entry in snapshot.entries) {
          if (!await _writePreference(entry.key, entry.value!)) {
            throw StateError('Falha ao recuperar ${entry.key}.');
          }
        }
        await load();
      } catch (_) {
        storageAvailable = false;
        notifyListeners();
        throw StateError(
          'Restauração interrompida. A cópia anterior está preservada para recuperação.',
        );
      }
      throw StateError(
        'Restauração cancelada; os dados anteriores foram recuperados. $error',
      );
    }
  }

  Future<void> _applyBackup(String raw) async {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final writes = <String, Object>{};
    if (data['favorites'] is List) {
      writes['favorites'] = {
        ...favorites,
        ...(data['favorites'] as List).cast<String>(),
      }.toList()..sort();
    }
    if (data['plan_deadline'] is String) {
      writes['plan_deadline'] = data['plan_deadline'] as String;
    }
    for (final entry in ((data['highlights'] as Map?) ?? {}).entries) {
      writes['hl_${normalizeVKey(entry.key.toString())}'] = entry.value as int;
    }
    final mergedNotes = {...notes};
    for (final entry in ((data['notes'] as Map?) ?? {}).entries) {
      final key = normalizeVKey(entry.key.toString());
      final text = (entry.value as String).trim();
      if (text.isEmpty) {
        mergedNotes.remove(key);
      } else {
        mergedNotes[key] = text;
      }
    }
    writes['notes'] = jsonEncode(mergedNotes);
    if (data.containsKey('songs')) {
      writes['songs_json'] = data['songs'] as String;
    }
    {
      writes['boletim_json'] = jsonEncode({
        'aniversariantes':
            data['aniversariantes'] ??
            birthdays.map((b) => b.toJson()).toList(),
        'eventos': data['eventos'] ?? events.map((e) => e.toJson()).toList(),
      });
    }
    final chapters = {
      ...readChapters,
      ...((data['read_chapters'] as List?) ?? []).cast<String>(),
    };
    final days = {...readDayByChapter};
    final counts = {...readsByDay};
    final importedDays = (data['read_day_by_chapter'] as Map?) ?? {};
    for (final entry in importedDays.entries) {
      final key = entry.key as String;
      if (!chapters.contains(key) || days.containsKey(key)) continue;
      final day = entry.value as String;
      days[key] = day;
      counts[day] = (counts[day] ?? 0) + 1;
    }
    if (!data.containsKey('read_day_by_chapter')) {
      for (final entry in ((data['reads_by_day'] as Map?) ?? {}).entries) {
        final day = entry.key as String;
        final count = entry.value as int;
        if (count > (counts[day] ?? 0)) counts[day] = count;
      }
    }
    writes['read_chapters'] = jsonEncode(chapters.toList()..sort());
    writes['read_day_by_chapter'] = jsonEncode(days);
    writes['reads_by_day'] = jsonEncode(counts);
    if (data.containsKey('recent')) {
      final refs = (data['recent'] as List).map(
        (e) => RecentRef.fromJson(e as Map<String, dynamic>),
      );
      writes['recent'] = jsonEncode(
        refs.take(kMaxRecent).map((r) => r.toJson()).toList(),
      );
    }
    for (final entry in ((data['positions'] as Map?) ?? {}).entries) {
      writes['lastpos_${entry.key}'] = jsonEncode(entry.value);
    }
    final versionIn = data['version'];
    if (versionIn is String && kVersionOrder.contains(versionIn)) {
      await _ensureBible(versionIn); // asset validado antes das escritas
      writes['biblia_version'] = versionIn;
    }
    final theme = data['theme'];
    if (theme is int && theme >= 0 && theme < kThemeNames.length) {
      writes['theme'] = theme;
    }
    if (data['font_scale'] is num) {
      writes['font_scale'] = snapFontLevel(
        (data['font_scale'] as num).toDouble(),
      );
    }
    for (final key in ['red_letter_enabled', 'plan_enabled']) {
      if (data[key] is bool) writes[key] = data[key] as bool;
    }
    if (data['tts_rate'] is num) {
      writes['tts_rate'] = (data['tts_rate'] as num)
          .clamp(0.25, 0.75)
          .toDouble();
    }
    if (data['tts_pitch'] is num) {
      writes['tts_pitch'] = (data['tts_pitch'] as num)
          .clamp(0.5, 2.0)
          .toDouble();
    }
    if (data['tts_voice'] is String) {
      writes['tts_voice'] = data['tts_voice'] as String;
    }
    if (data['plan_daily_goal'] is num) {
      writes['plan_daily_goal'] = (data['plan_daily_goal'] as num)
          .toInt()
          .clamp(1, 10);
    }
    for (final entry in writes.entries) {
      if (!await _writePreference(entry.key, entry.value)) {
        throw StateError('Não foi possível salvar ${entry.key}.');
      }
    }
    if (data.containsKey('plan_deadline') &&
        data['plan_deadline'] == null &&
        !await prefs.remove('plan_deadline')) {
      throw StateError('Não foi possível restaurar o prazo.');
    }
    await load();
  }

  Future<bool> _writePreference(String key, Object value) {
    if (value is String) return prefs.setString(key, value);
    if (value is int) return prefs.setInt(key, value);
    if (value is double) return prefs.setDouble(key, value);
    if (value is bool) return prefs.setBool(key, value);
    if (value is List<String>) return prefs.setStringList(key, value);
    throw ArgumentError('Preferência inválida: $key');
  }
}
