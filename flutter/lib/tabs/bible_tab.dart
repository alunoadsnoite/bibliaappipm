import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common.dart';
import '../daily.dart';
import '../models.dart';
import '../store.dart';
import '../tts.dart';
import '../tts_bar.dart';

class _SearchArg {
  final List<Book> books;
  final String query;
  final int? bookOnly;
  _SearchArg(this.books, this.query, [this.bookOnly]);
}

/// Referência parseada de um texto de busca ("Jo 3:16", "Salmos 23"...).
class _ParsedRef {
  final int book;
  final int chapter;
  final int? verse;
  _ParsedRef(this.book, this.chapter, this.verse);
}

/// Agrupamentos dos 66 livros por índices canônicos, independentes da
/// grafia da abreviação em cada versão.
class _Group {
  final String label;
  final List<int> indices;
  const _Group(this.label, this.indices);
}

const List<_Group> _kGroups = [
  _Group('Pentateuco', [0, 1, 2, 3, 4]),
  _Group('Livros Históricos', [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]),
  _Group('Poéticos', [17, 18, 21]),
  _Group('Sapenciais', [19, 20]),
  _Group('Proféticos Maiores', [22, 23, 24, 25, 26]),
  _Group('Proféticos Menores', [
    27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
  ]),
  _Group('Evangelhos', [39, 40, 41, 42]),
  _Group('Atos dos Apóstolos', [43]),
  _Group('Cartas Paulinas', [
    44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
  ]),
  _Group('Cartas Gerais', [58, 59, 60, 61, 62, 63, 64]),
  _Group('Revelação', [65]),
];

const int _kResultsPerPage = 50;
const int _kMaxSearchResults = 3000;

/// Normaliza texto para comparação de abreviações/nomes (minúsculas, sem
/// acentos e sem pontuação).
String _normalize(String s) {
  const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  var r = s.toLowerCase();
  for (var i = 0; i < accents.length; i++) {
    r = r.replaceAll(accents[i], plain[i]);
  }
  r = r.replaceAll(RegExp('[^a-z0-9]'), '');
  return r;
}

/// Tenta interpretar `text` como uma referência bíblica ("Jo 3:16",
/// "Salmos 23", "1co13"). Retorna `null` se não for uma referência válida.
_ParsedRef? parseReference(List<Book> books, String text) {
  final m = RegExp(r'^([0-9]{0,2}[A-Za-zÀ-ú]{1,10})\s*(\d{1,3})(?::(\d{1,3}))?$')
      .firstMatch(text.trim());
  if (m == null) return null;
  final token = m.group(1)!;
  final tokenLower = token.toLowerCase();
  final normToken = _normalize(token);
  final chapter = int.parse(m.group(2)!);
  final givenVerse = m.group(3);

  int? bi;
  // 1) abreviação exata (respeitando acentos): "Jo" -> João, "Jó" -> Jó
  for (var i = 0; i < books.length; i++) {
    if (books[i].abbr.toLowerCase() == tokenLower) {
      bi = i;
      break;
    }
  }
  // 2) nome exato (respeitando acentos)
  if (bi == null) {
    for (var i = 0; i < books.length; i++) {
      if (books[i].name.toLowerCase() == tokenLower) {
        bi = i;
        break;
      }
    }
  }
  // 3) abreviação ou nome ignorando acentos
  if (bi == null) {
    for (var i = 0; i < books.length; i++) {
      if (_normalize(books[i].abbr) == normToken ||
          _normalize(books[i].name) == normToken) {
        bi = i;
        break;
      }
    }
  }
  // 4) prefixo (ignorando acentos)
  if (bi == null && normToken.length >= 3) {
    for (var i = 0; i < books.length; i++) {
      if (_normalize(books[i].name).startsWith(normToken) ||
          _normalize(books[i].abbr).startsWith(normToken)) {
        bi = i;
        break;
      }
    }
  }
  if (bi == null) return null;
  if (chapter < 1 || chapter > books[bi].chapters.length) return null;
  if (givenVerse != null) {
    final v = int.parse(givenVerse);
    if (v < 1 || v > books[bi].chapters[chapter - 1].length) return null;
    return _ParsedRef(bi, chapter - 1, v - 1);
  }
  return _ParsedRef(bi, chapter - 1, null);
}

List<List<int>> _searchVerses(_SearchArg arg) {
  final res = <List<int>>[];
  final lower = arg.query.toLowerCase();
  final only = arg.bookOnly;
  for (var bi = 0; bi < arg.books.length; bi++) {
    if (only != null && bi != only) continue;
    final b = arg.books[bi];
    for (var c = 0; c < b.chapters.length; c++) {
      final vs = b.chapters[c];
      for (var v = 0; v < vs.length; v++) {
        if (vs[v].toLowerCase().contains(lower)) {
          res.add([bi, c, v]);
          if (res.length >= _kMaxSearchResults) return res;
        }
      }
    }
  }
  return res;
}

class BibleTab extends StatefulWidget {
  const BibleTab({super.key});

  @override
  State<BibleTab> createState() => _BibleTabState();
}

class _BibleTabState extends State<BibleTab> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _chapterScroll = ScrollController();
  Timer? _debounce;

  int? _bookIndex;
  int? _chapter;
  int? _focusVerse;
  bool _pendingScroll = false;
  bool _focusMode = false;
  bool _immersive = false;
  bool _selMode = false;
  final Set<int> _sel = {};
  bool _loadingVersion = false;

  List<List<int>>? _results;
  int _visible = 0;
  bool _searching = false;
  bool _searchBookOnly = false;
  int _job = 0;

  @override
  void initState() {
    super.initState();
    // Leitura contínua: passa ao próximo capítulo ao chegar ao fim do texto,
    // tanto no modo normal quanto no modo leitura.
    _chapterScroll.addListener(_onChapterScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _chapterScroll.dispose();
    super.dispose();
  }

  Book? get _book {
    final i = _bookIndex;
    if (i == null || i >= AppState.i.bible.length) return null;
    return AppState.i.bible[i];
  }

  String get _title {
    if (_results != null) return 'Resultados';
    final b = _book;
    if (b == null) return 'Bíblia';
    if (_chapter == null) return b.name;
    return '${b.name} ${_chapter! + 1}';
  }

  String get _versionLabel {
    final idx = kVersionOrder.indexOf(AppState.i.version);
    return '${kVersionAbbrs[idx < 0 ? 0 : idx]} ▾';
  }

  bool get _hasResultsMore => _visible < (_results?.length ?? 0);

  void _back() {
    if (_selMode) {
      setState(() {
        _selMode = false;
        _sel.clear();
        _immersive = false;
      });
      return;
    }
    if (_chapter != null || _results != null) TtsService.i.stop();
    setState(() {
      _search.clear();
      _focusMode = false;
      _immersive = false;
      if (_results != null) {
        _results = null;
      } else if (_chapter != null) {
        _chapter = null;
        _focusVerse = null;
      } else {
        _bookIndex = null;
        _focusVerse = null;
        _searchBookOnly = false;
      }
    });
  }

  // ------------------------------------------ navegação e posição de leitura

  void _openBook(int index) {
    setState(() {
      _bookIndex = index;
      _chapter = null;
      _focusVerse = null;
      _pendingScroll = false;
    });
  }

  void _goToChapter(int chapter) {
    final bookIndex = _bookIndex;
    if (bookIndex == null) return;
    setState(() {
      _chapter = chapter;
      _focusVerse = null;
      _pendingScroll = false;
      _resetSelection();
    });
    AppState.i.savePosition(bookIndex, chapter);
    AppState.i.addRecent(bookIndex, chapter);
  }

  void _resetSelection() {
    _selMode = false;
    _sel.clear();
  }

  /// Próxima leitura (livro, capítulo) atravessando o fim do capítulo/livro.
  (int, int)? _nextRef(int book, int chapter) {
    final bible = AppState.i.bible;
    if (book >= bible.length) return null;
    if (chapter + 1 < bible[book].chapters.length) return (book, chapter + 1);
    if (book + 1 < bible.length) return (book + 1, 0);
    return null;
  }

  /// Leitura anterior, atravessando o início do capítulo/livro.
  (int, int)? _prevRef(int book, int chapter) {
    final bible = AppState.i.bible;
    if (chapter > 0) return (book, chapter - 1);
    if (book > 0) return (book - 1, bible[book - 1].chapters.length - 1);
    return null;
  }

  void _goToRef(int book, int chapter) {
    setState(() {
      _bookIndex = book;
      _chapter = chapter;
      _focusVerse = null;
      _pendingScroll = false;
      _resetSelection();
    });
    AppState.i.savePosition(book, chapter);
    AppState.i.addRecent(book, chapter);
  }

  /// Auto-avança para o próximo capítulo quando o leitor chega ao fim do
  /// texto, no modo normal e no modo leitura. Volta o scroll ao topo.
  void _onChapterScroll() {
    final book = _bookIndex;
    final ch = _chapter;
    if (book == null || ch == null || _book == null) return;
    if (!_chapterScroll.hasClients) return;
    final pos = _chapterScroll.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels <= 0 || pos.extentAfter > 100) return;
    final next = _nextRef(book, ch);
    if (next == null) return;
    _goToRef(next.$1, next.$2);
    _jumpTop();
  }

  /// Leva a lista de versículos para o topo após trocar de capítulo.
  void _jumpTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chapterScroll.hasClients) _chapterScroll.jumpTo(0);
    });
  }

  void _openVerse(int book, int chapter, int verse) {
    setState(() {
      _bookIndex = book;
      _chapter = chapter;
      _focusVerse = verse;
      _pendingScroll = true;
      _results = null;
      _searching = false;
      _search.clear();
    });
    AppState.i.savePosition(book, chapter);
    AppState.i.addRecent(book, chapter);
  }

  // ------------------------------------------------ busca (texto e referência)

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = q.trim();
      if (query.isEmpty) {
        if (_results != null) {
          setState(() => _results = null);
        }
        return;
      }
      if (query.length >= 3) {
        if (_tryReference(query)) return;
        _runSearch(query);
      } else if (_results != null) {
        setState(() {
          _results = null;
        });
      }
    });
  }

  bool _tryReference(String query) {
    final parsed = parseReference(AppState.i.bible, query);
    if (parsed == null) return false;
    if (parsed.verse != null) {
      _openVerse(parsed.book, parsed.chapter, parsed.verse!);
    } else {
      _bookIndex = parsed.book;
      _chapter = parsed.chapter;
      setState(() {
        _results = null;
        _searching = false;
        _focusVerse = null;
        _search.clear();
      });
      AppState.i.savePosition(parsed.book, parsed.chapter);
      AppState.i.addRecent(parsed.book, parsed.chapter);
    }
    return true;
  }

  Future<void> _runSearch(String query) async {
    final myJob = ++_job;
    setState(() {
      _results = null;
      _searching = true;
    });
    final res = await compute(
        _searchVerses,
        _SearchArg(List.of(AppState.i.bible), query,
            _searchBookOnly ? _bookIndex : null));
    if (!mounted || myJob != _job) return;
    setState(() {
      _results = res;
      _visible = res.length < _kResultsPerPage ? res.length : _kResultsPerPage;
      _searching = false;
    });
  }

  void _showMore() {
    setState(() {
      _visible = (_visible + _kResultsPerPage).clamp(0, _results!.length);
    });
  }

  /// Alterna a busca para restringir ao livro aberto.
  void _toggleBookOnly() {
    final q = _search.text.trim();
    setState(() {
      _searchBookOnly = !_searchBookOnly;
      if (_results != null) {
        _results = null;
        _visible = 0;
        _searching = false;
      }
    });
    if (q.length >= 3) _onQuery(q);
  }

  /// Abre o próximo capítulo não lido do plano de leitura.
  void _openPlanNext() {
    final next = AppState.i.nextUnreadChapter;
    if (next == null) return;
    setState(() {
      _bookIndex = next.$1;
      _chapter = null;
      _pendingScroll = false;
      _searchBookOnly = false;
    });
    _goToChapter(next.$2);
    AppState.i.markChapterRead(next.$1, next.$2);
  }

  // --------------------------------------------------------------- interface

  @override
  Widget build(BuildContext context) {
    final t = appTheme;
    return Container(
      color: t.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!_focusMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: Row(
                  children: [
                    if (_bookIndex != null || _results != null)
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new,
                            size: 20, color: t.primary),
                        onPressed: _back,
                      ),
                    Expanded(
                      child: Text(_title,
                          style: TextStyle(
                              color: t.text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (_results == null)
                      GestureDetector(
                        onTap: _showVersionDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: t.light,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_versionLabel,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (_bookIndex != null && _chapter != null && _results == null)
                      IconButton(
                        icon: const Icon(Icons.fullscreen,
                            size: 18),
                        color: t.primary,
                        tooltip: 'Modo leitura',
                        onPressed: () {
                          setState(() => _focusMode = true);
                          AppState.i
                              .markChapterRead(_bookIndex!, _chapter!);
                        },
                      ),
                    if (_bookIndex != null && _results == null)
                      IconButton(
                        icon: Icon(_searchBookOnly
                            ? Icons.filter_alt
                            : Icons.filter_alt_off,
                            size: 18),
                        color: _searchBookOnly ? t.accent : t.primary,
                        tooltip: _searchBookOnly && _book != null
                            ? 'Buscar em ${_book!.name}'
                            : 'Buscar em toda a Bíblia',
                        onPressed: _toggleBookOnly,
                      ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _search,
                        onChanged: _onQuery,
                        style: TextStyle(color: t.text, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar ou ref.',
                          hintStyle: TextStyle(color: t.muted, fontSize: 13),
                          isDense: true,
                          filled: true,
                          fillColor: t.light,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final t = appTheme;
    if (_loadingVersion) {
      return Center(
        child: CircularProgressIndicator(color: t.accent),
      );
    }
    if (_searching) {
      return Center(
        child: Text('Buscando…',
            style: TextStyle(color: t.muted, fontSize: 15)),
      );
    }
    if (_results != null) return _resultsView();
    final b = _book;
    if (b == null) return _booksView();
    if (_chapter == null) return _chaptersView();
    return _focusMode ? _focusView() : _versesView();
  }

  // ----------------------------------------------------------------- livros

  Widget _booksView() {
    final bible = AppState.i.bible;
    final children = <Widget>[
      _continueCard(),
      _dailyVerseCard(),
      _planCard(),
      ..._recentSection(),
    ];
    String? lastTestament;
    for (final g in _kGroups) {
      final testamento =
          g.indices.first >= 39 ? 'NOVO TESTAMENTO' : 'ANTIGO TESTAMENTO';
      if (testamento != lastTestament) {
        children.add(_section(testamento));
        lastTestament = testamento;
      }
      final items = <Widget>[];
      for (final idx in g.indices) {
        if (idx < bible.length) items.add(_bookItem(bible[idx], idx));
      }
      if (items.isEmpty) continue;
      children.add(_groupSection(g.label));
      children.addAll(items);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: children,
    );
  }

  Widget _section(String label) {
    final t = appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Text(label,
          style: TextStyle(
              color: t.primary, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _groupSection(String label) {
    final t = appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
      child: Text(label,
          style: TextStyle(
              color: t.accentDark, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _bookItem(Book b, int index) {
    final t = appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openBook(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.light,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${index + 1}',
                      style: TextStyle(color: t.muted, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(b.name,
                        style: TextStyle(color: t.text, fontSize: 16))),
                Icon(Icons.chevron_right, color: t.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------- cards e recentes

  /// Card "Continuar lendo" com a última posição da versão ativa.
  Widget _continueCard() {
    final t = appTheme;
    final p = AppState.i.lastPosition;
    final bible = AppState.i.bible;
    if (p == null || p.book >= bible.length) return SizedBox.shrink();
    final b = bible[p.book];
    final label = 'Continuar lendo · ${b.name} ${p.chapter + 1}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            _bookIndex = p.book;
            _goToChapter(p.chapter);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.history, color: t.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold))),
                Icon(Icons.chevron_right, color: t.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card do versículo do dia (rotação determinística por data).
  Widget _dailyVerseCard() {
    final t = appTheme;
    final day = DateTime.now();
    final (bIdx, cIdx, vIdx) = dailyVerseFor(day);
    final bible = AppState.i.bible;
    if (bIdx >= bible.length ||
        cIdx >= bible[bIdx].chapters.length ||
        vIdx >= bible[bIdx].chapters[cIdx].length) {
      return SizedBox.shrink();
    }
    final ref = formatRef(bible, bIdx, cIdx, vIdx);
    final text = bible[bIdx].chapters[cIdx][vIdx];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Material(
        color: t.primaryDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openVerse(bIdx, cIdx, vIdx),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text('VERSÍCULO DO DIA',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(text,
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, height: 1.4)),
                const SizedBox(height: 6),
                Text(ref,
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Painel do plano de leitura anual.
  Widget _planCard() {
    final state = AppState.i;
    if (!state.planEnabled) return SizedBox.shrink();
    final t = appTheme;
    final total = state.totalChapters;
    final read = state.totalRead;
    final daily = state.dailyGoal;
    final today = state.todayReadCount;
    final progress = total == 0 ? 0.0 : (read / total).clamp(0.0, 1.0);
    final pct = (progress * 100).toStringAsFixed(1);
    final doneToday = today >= daily;
    final streak = state.streak;
    final next = state.nextUnreadChapter;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(doneToday ? Icons.check_circle : Icons.timeline,
                      color: t.accent, size: 18),
                  const SizedBox(width: 6),
                  Text('Plano de leitura',
                      style: TextStyle(
                          color: t.text,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('Hoje $today/$daily',
                      style: TextStyle(color: t.accent, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: t.light,
                  color: t.accent,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$read de $total capítulos lidos ($pct%)',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                  ),
                  Icon(Icons.local_fire_department,
                      color: streak > 0 ? t.accent : t.muted, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    streak == 1
                        ? 'Sequência: 1 dia'
                        : 'Sequência: $streak dias',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                ],
              ),
              if (next != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _openPlanNext,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Próximo capítulo'),
                    style: TextButton.styleFrom(foregroundColor: t.accent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Seção "Recentes" para navegação rápida.
  List<Widget> _recentSection() {
    final state = AppState.i;
    final bible = state.bible;
    final t = appTheme;
    if (state.recent.isEmpty) return const [];
    final children = <Widget>[
      _section('Recentes'),
    ];
    for (var i = 0; i < state.recent.length; i++) {
      final r = state.recent[i];
      if (r.book >= bible.length) continue;
      final b = bible[r.book];
      final title = '${b.name} ${r.chapter + 1}';
      final sameVersion = r.version == AppState.i.version;
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: sameVersion ? t.card : t.light,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                _bookIndex = r.book;
                _goToChapter(r.chapter);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.history,
                        size: 18,
                        color: sameVersion ? t.accent : t.muted),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(title,
                            style: TextStyle(
                                color: t.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w500))),
                    IconButton(
                      icon: Icon(Icons.close, color: t.muted, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => AppState.i.removeRecent(i),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return children;
  }

  // ---------------------------------------------------------------- capítulos

  Widget _chaptersView() {
    final t = appTheme;
    final b = _book!;
    final n = b.chapters.length;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 1.4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 6,
      ),
      itemCount: n,
      itemBuilder: (context, i) {
        final read = AppState.i.isChapterRead(_bookIndex!, i);
        return Material(
          color: read ? t.primaryDark : t.card,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _goToChapter(i),
            onLongPress: () {
              if (read) {
                AppState.i.unmarkChapterRead(_bookIndex!, i);
              } else {
                AppState.i.markChapterRead(_bookIndex!, i);
              }
            },
            child: Center(
              child: Text('${i + 1}',
                  style: TextStyle(
                      color: read ? Colors.white : t.text,
                      fontSize: 14)),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------- capítulo/V.A

  Widget _versesView() {
    final t = appTheme;
    final b = _book!;
    final chapter = _chapter!;
    final verses = b.chapters[chapter];
    final hasPrev = chapter > 0;
    final hasNext = chapter + 1 < b.chapters.length;
    final view = Column(
      children: [
        Material(
          color: t.primaryDark,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: hasPrev
                    ? () {
                        _goToChapter(chapter - 1);
                        _jumpTop();
                      }
                    : null,
                disabledColor: Colors.white24,
              ),
              Expanded(
                child: Text(
                  'Capítulo ${chapter + 1} de ${b.chapters.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: hasNext
                    ? () {
                        _goToChapter(chapter + 1);
                        _jumpTop();
                      }
                    : null,
                disabledColor: Colors.white24,
              ),
            ],
          ),
        ),
        TtsBar(
          positionLabel: 'Versículo',
          playLabel: 'Ouvir o capítulo',
          itemCount: verses.length,
          onPlay: _playChapter,
        ),
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              final next = _nextRef(_bookIndex!, chapter);
              final prev = _prevRef(_bookIndex!, chapter);
              if (v < -200 && next != null) {
                _goToRef(next.$1, next.$2);
                _jumpTop();
              } else if (v > 200 && prev != null) {
                _goToRef(prev.$1, prev.$2);
                _jumpTop();
              }
            },
            child: _verseList(verses, focusMode: false),
          ),
        ),
      ],
    );
    return Stack(
      children: [
        view,
        if (_selMode) _selectionBar(),
      ],
    );
  }

  Widget _focusView() {
    final t = appTheme;
    final b = _book!;
    final chapter = _chapter!;
    final verses = b.chapters[chapter];
    return GestureDetector(
      onTap: () {
        if (_selMode) return;
        setState(() => _immersive = !_immersive);
      },
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        final next = _nextRef(_bookIndex!, chapter);
        final prev = _prevRef(_bookIndex!, chapter);
        if (v < -200 && next != null) {
          _goToRef(next.$1, next.$2);
          _jumpTop();
        } else if (v > 200 && prev != null) {
          _goToRef(prev.$1, prev.$2);
          _jumpTop();
        }
      },
      child: Stack(
        children: [
          _verseList(verses, focusMode: true),
          if (!_immersive && !_selMode)
            Positioned(
              right: 16,
              bottom: 24,
              child: FloatingActionButton.small(
                backgroundColor: t.card,
                foregroundColor: t.primary,
                heroTag: 'exit_focus',
                tooltip: 'Sair do modo leitura',
                onPressed: () {
                  setState(() {
                    _focusMode = false;
                    _immersive = false;
                  });
                  TtsService.i.stop();
                },
                child: const Icon(Icons.fullscreen_exit),
              ),
            ),
          if (!_immersive && !_selMode)
            Positioned(
              left: 16,
              bottom: 24,
              child: FloatingActionButton.small(
                backgroundColor: t.card,
                foregroundColor: t.primary,
                heroTag: 'select_focus',
                tooltip: 'Selecionar versículos',
                onPressed: _selMode
                    ? () {
                        setState(() {
                          _selMode = false;
                          _sel.clear();
                        });
                      }
                    : () {
                        setState(() => _selMode = true);
                      },
                child: const Icon(Icons.checklist),
              ),
            ),
          if (_immersive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: IgnorePointer(
                child: Text(
                  'Toque para exibir os botões',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (_selMode) _selectionBar(),
        ],
      ),
    );
  }

  Widget _verseList(List<String> verses, {required bool focusMode}) {
    return ListenableBuilder(
      listenable: Listenable.merge([TtsService.i.phase, TtsService.i.index]),
      builder: (context, _) {
        final readingIndex = TtsService.i.index.value;
        return ListView.builder(
          controller: _chapterScroll,
          padding: EdgeInsets.fromLTRB(
              focusMode ? 20 : 4, focusMode ? 28 : 4, focusMode ? 20 : 4, 80),
          itemCount: verses.length,
          itemBuilder: (context, v) {
            final row = _verseRow(verses, v, readingIndex, focusMode,
                immersive: focusMode && _immersive);
            if (focusMode || !_pendingScroll || _focusVerse != v) return row;
            final targetCtx = context;
            return Builder(
              builder: (ctx) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final ro =
                      targetCtx.findRenderObject() ?? ctx.findRenderObject();
                  if (ro != null && ro is RenderBox && ro.hasSize) {
                    Scrollable.ensureVisible(
                      targetCtx,
                      duration: const Duration(milliseconds: 400),
                      alignment: 0.15,
                      curve: Curves.easeInOut,
                    );
                  }
                });
                _pendingScroll = false;
                return row;
              },
            );
          },
        );
      },
    );
  }

Widget _verseRow(List<String> verses, int v, int? readingIndex,
    bool focusMode, {bool immersive = false}) {
    final t = appTheme;
    final b = _book!;
    final chapter = _chapter!;
    final ref = '${b.abbr} ${chapter + 1}:${v + 1}';
    final key = 'v:${_bookIndex!}:${chapter + 1}:${v + 1}';
    final reading = readingIndex == v;
    final note = AppState.i.getNote(key) ?? '';
    final hasNote = note.trim().isNotEmpty;
    final selected = _selMode && _sel.contains(v);
    return GestureDetector(
      onTap: immersive
          ? null
          : (_selMode
              ? () => _toggleSelect(v)
              : () => _verseMenu(verses, v)),
      onLongPress: immersive
          ? null
          : (_selMode
              ? () => _toggleSelect(v)
              : () => _enterSelect(v)),
      child: Container(
        color: selected
            ? t.primary.withValues(alpha: 0.14)
            : (reading
                ? t.accent.withValues(alpha: 0.16)
                : highlightColor(key)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(ref,
                            style: TextStyle(
                                color: reading
                                    ? t.accent
                                    : t.accentDark,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (hasNote)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.sticky_note_2,
                              color: t.muted, size: 13),
                        ),
                    ],
                  ),
                  Text(verses[v],
                      style: TextStyle(
                          color: AppState.i.redLetterEnabled &&
                                  AppState.i.isRedLetter(
                                      _bookIndex!, chapter, v)
                              ? t.redText
                              : t.text,
                          fontSize: focusMode ? 18 : 16,
                          height: 1.4)),
                  if (hasNote)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(note,
                          style: TextStyle(
                              color: t.muted,
                              fontSize: focusMode ? 15 : 13,
                              fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
            ),
            if (_selMode)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: Icon(selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                    color: selected ? t.primary : t.muted,
                    size: 20),
              )
            else if (reading && !immersive)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Icon(Icons.volume_up,
                    color: t.accent, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------- seleção múltipla

  String _selKey(int v) => 'v:${_bookIndex!}:${_chapter! + 1}:${v + 1}';

  List<(int, String)> get _selItems {
    final b = _book!;
    final vs = b.chapters[_chapter!];
    final sorted = _sel.toList()..sort();
    return [for (final v in sorted) (v, vs[v])];
  }

  /// Texto dos versículos selecionados, na ordem do capítulo.
  String _selFormatted({required bool withRefs}) {
    final b = _book!;
    final ch = _chapter!;
    final sb = StringBuffer();
    for (final (v, txt) in _selItems) {
      if (withRefs) {
        if (sb.isNotEmpty) sb.write('\n');
        sb.write('${b.abbr} ${ch + 1}:${v + 1}  $txt');
      } else {
        sb.write(txt);
        sb.write(' ');
      }
    }
    return sb.toString().trim();
  }

  void _enterSelect(int v) {
    setState(() {
      _selMode = true;
      _immersive = false;
      _sel
        ..clear()
        ..add(v);
    });
  }

  void _toggleSelect(int v) {
    setState(() {
      if (_sel.contains(v)) {
        _sel.remove(v);
        if (_sel.isEmpty) _selMode = false;
      } else {
        _sel.add(v);
      }
    });
  }

  void _selectAll() {
    final n = _book!.chapters[_chapter!].length;
    setState(() {
      _selMode = true;
      _sel
        ..clear()
        ..addAll(List.generate(n, (i) => i));
    });
  }

  void _leaveSelect() {
    setState(() {
      _selMode = false;
      _sel.clear();
    });
  }

  /// Pergunta se a cópia/compartilhamento deve incluir as referências.
  Future<bool?> _askRefs(String title) {
    final t = appTheme;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: t.card,
        title: Text(title, style: TextStyle(color: t.text)),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Com referências', style: TextStyle(color: t.text)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Somente o texto', style: TextStyle(color: t.text)),
          ),
        ],
      ),
    );
  }

  Future<void> _copySel() async {
    final withRefs = await _askRefs('Copiar versículos');
    if (withRefs == null) return;
    await copyText(_selFormatted(withRefs: withRefs));
    _leaveSelect();
  }

  Future<void> _shareSel() async {
    final withRefs = await _askRefs('Compartilhar versículos');
    if (withRefs == null) return;
    await shareText(_selFormatted(withRefs: withRefs));
    _leaveSelect();
  }

  Future<void> _noteSel() async {
    final notes = [for (final (v, _) in _selItems) AppState.i.getNote(_selKey(v)) ?? ''];
    final common = notes.isNotEmpty && notes.every((s) => s == notes.first)
        ? notes.first
        : '';
    final edited = await editNoteDialog(context, common);
    if (edited == null) return;
    for (final (v, _) in _selItems) {
      await AppState.i.setNote(_selKey(v), edited);
    }
    _leaveSelect();
  }

  Future<void> _highlightSel() async {
    final t = appTheme;
    final ch = _chapter!;
    final firstH = AppState.i.getHighlight(_selKey(_sel.first));
    final same = _sel.every((v) => AppState.i.getHighlight(_selKey(v)) == firstH);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final current = same ? firstH : -1;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destaque ${_sel.length} versículo(s) — capítulo ${ch + 1}',
                    style: TextStyle(
                        color: t.text,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < kHighlightColors.length; i++)
                      GestureDetector(
                        onTap: () async {
                          for (final v in _selItems) {
                            await AppState.i.setHighlight(_selKey(v.$1), i);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _leaveSelect();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kHighlightColors[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  current == i ? t.primary : Colors.black12,
                              width: current == i ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () async {
                        for (final v in _selItems) {
                          await AppState.i.setHighlight(_selKey(v.$1), -1);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _leaveSelect();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: t.light,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Icon(Icons.format_color_reset,
                            size: 20, color: t.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Barra de ações da seleção múltipla (sobrepostas ao rodapé).
  Widget _selectionBar() {
    final t = appTheme;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: t.card,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: t.text, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: _leaveSelect,
                ),
                Text('${_sel.length} selec.',
                    style: TextStyle(color: t.text, fontSize: 13)),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.select_all, size: 20),
                  color: t.text,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Selecionar tudo',
                  onPressed: _selectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.format_paint, size: 20),
                  color: t.primary,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Destacar',
                  onPressed: _highlightSel,
                ),
                IconButton(
                  icon: const Icon(Icons.sticky_note_2, size: 20),
                  color: t.text,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Anotar',
                  onPressed: _noteSel,
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  color: t.text,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Copiar',
                  onPressed: _copySel,
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  color: t.text,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Compartilhar',
                  onPressed: _shareSel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Abre o menu do versículo (toque ou toque longo).
  Future<void> _verseMenu(List<String> verses, int v) {
    final b = _book!;
    final chapter = _chapter!;
    final ref = '${b.abbr} ${chapter + 1}:${v + 1}';
    final key = 'v:${_bookIndex!}:${chapter + 1}:${v + 1}';
    // Referência falada: nome completo e "capítulo/versículo" por extenso,
    // para o TTS não ler "8:15" como horário ("oito e quinze da manhã").
    final spoken = '${b.name}, capítulo ${chapter + 1}, '
        'versículo ${v + 1}. ${verses[v]}';
    return showLineMenu(
      context,
      title: ref,
      text: '$ref  ${verses[v]}',
      highlightKey: key,
      note: AppState.i.getNote(key) ?? '',
      onHighlightChanged: (_) => setState(() {}),
      onNoteChanged: (_) => setState(() {}),
      speakText: spoken,
      onCompare: () =>
          _showComparison(bAbbr: b.abbr, book: _bookIndex!, chapter: chapter, verse: v),
      onSelect: () => _enterSelect(v),
    );
  }

  void _playChapter() {
    final b = _book!;
    final chapter = _chapter!;
    final verses = b.chapters[chapter];
    final intro = '${b.name}, capítulo ${chapter + 1}. ';
    final queue = [
      for (var v = 0; v < verses.length; v++)
        '${v == 0 ? intro : ''}Versículo ${v + 1}. ${verses[v]}',
    ];
    TtsService.i.playChapter(queue);
    AppState.i.markChapterRead(_bookIndex!, chapter);
  }

  // -------------------------------------------------------------- resultados

  Widget _resultsView() {
    final t = appTheme;
    final res = _results!;
    if (res.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Nenhum resultado para "${_search.text.trim()}"',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted, fontSize: 15)),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
          child: Row(
            children: [
              Text(
                '${res.length} resultado${res.length == 1 ? '' : 's'}'
                '${res.length > _visible ? ' (mostrando $_visible)' : ''}'
                '${_searchBookOnly && _bookIndex != null ? ' · em ${AppState.i.bible[_bookIndex!].name}' : ''}',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
            itemCount: _visible + (_hasResultsMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (_hasResultsMore && i == _visible) {
                final rest = res.length - _visible;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextButton.icon(
                      onPressed: _showMore,
                      icon: const Icon(Icons.expand_more, size: 18),
                      label: Text('Mostrar mais ($rest)'),
                    ),
                  ),
                );
              }
              return _resultCard(res, i);
            },
          ),
        ),
      ],
    );
  }

  Widget _resultCard(List<List<int>> res, int i) {
    final t = appTheme;
    final r = res[i];
    final b = AppState.i.bible[r[0]];
    final text = b.chapters[r[1]][r[2]];
    final ref = '${b.abbr} ${r[1] + 1}:${r[2] + 1}';
    return Card(
      color: t.card,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: () => _openVerse(r[0], r[1], r[2]),
        title: Text(ref,
            style: TextStyle(
                color: t.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        subtitle: Text(text,
            style: TextStyle(color: t.text, fontSize: 15)),
      ),
    );
  }

  // ------------------------------------------------------------- traduções

  Future<void> _showVersionDialog() async {
    final t = appTheme;
    final current = kVersionOrder.indexOf(AppState.i.version);
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: t.card,
        title: Text('Versão da Bíblia', style: TextStyle(color: t.text)),
        children: [
          for (var i = 0; i < kVersionOrder.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, i),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${kVersionAbbrs[i]} — ${kVersionNames[i]}',
                      style: TextStyle(
                          color: t.text,
                          fontWeight: i == current
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ),
                  if (i == current)
                    Icon(Icons.check, color: t.accent, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || selected == current) return;
    final code = kVersionOrder[selected];
    TtsService.i.stop();
    setState(() => _loadingVersion = true);
    await AppState.i.setVersion(code);
    if (!mounted) return;
    setState(() {
      _loadingVersion = false;
      _search.clear();
      _results = null;
      _searching = false;
      _focusMode = false;
      _immersive = false;
      _selMode = false;
      _sel.clear();
      _bookIndex = null;
      _chapter = null;
      _focusVerse = null;
    });
    final p = AppState.i.positionOf(code);
    if (p != null &&
        p.book >= 0 &&
        p.book < AppState.i.bible.length &&
        p.chapter < AppState.i.bible[p.book].chapters.length) {
      setState(() {
        _bookIndex = p.book;
        _chapter = p.chapter;
      });
    }
  }

  Future<void> _showComparison({
    required String bAbbr,
    required int book,
    required int chapter,
    required int verse,
  }) async {
    final t = appTheme;
    final ref = '$bAbbr ${chapter + 1}:${verse + 1}';
    final rows = await AppState.i.comparedVerses(book, chapter, verse);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comparação — $ref',
                  style: TextStyle(
                      color: t.text,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: i.isEven ? t.light : t.card,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rows[i].$1,
                                style: TextStyle(
                                    color: t.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(rows[i].$2,
                                style: TextStyle(
                                    color: t.text,
                                    fontSize: 15,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}