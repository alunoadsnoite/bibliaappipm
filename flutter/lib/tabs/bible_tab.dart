import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common.dart';
import '../models.dart';
import '../store.dart';
import '../tts.dart';
import '../tts_bar.dart';

class _SearchArg {
  final List<Book> books;
  final String query;
  _SearchArg(this.books, this.query);
}

List<List<int>> _searchVerses(_SearchArg arg) {
  final res = <List<int>>[];
  final lower = arg.query.toLowerCase();
  for (var bi = 0; bi < arg.books.length; bi++) {
    final b = arg.books[bi];
    for (var c = 0; c < b.chapters.length; c++) {
      final vs = b.chapters[c];
      for (var v = 0; v < vs.length; v++) {
        if (vs[v].toLowerCase().contains(lower)) {
          res.add([bi, c, v]);
          if (res.length >= 200) return res;
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
  Timer? _debounce;

  Book? _book;
  int? _chapter;
  List<List<int>>? _results;
  bool _searching = false;
  int _job = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  String get _title {
    if (_results != null) return 'Resultados';
    if (_book == null) return 'Bíblia';
    if (_chapter == null) return _book!.name;
    return '${_book!.name} ${_chapter! + 1}';
  }

  String get _versionLabel {
    final idx = kVersionOrder.indexOf(AppState.i.version);
    return '${kVersionAbbrs[idx < 0 ? 0 : idx]} ▾';
  }

  void _back() {
    if (_chapter != null || _results != null) TtsService.i.stop();
    setState(() {
      _search.clear();
      if (_results != null) {
        _results = null;
      } else if (_chapter != null) {
        _chapter = null;
      } else {
        _book = null;
      }
    });
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = q.trim();
      if (query.length >= 3) {
        _runSearch(query);
      } else if (_results != null) {
        setState(() {
          _results = null;
          _search.clear();
        });
      }
    });
  }

  Future<void> _runSearch(String query) async {
    final myJob = ++_job;
    setState(() {
      _results = null;
      _searching = true;
    });
    final res =
        await compute(_searchVerses, _SearchArg(List.of(AppState.i.bible), query));
    if (!mounted || myJob != _job) return;
    setState(() {
      _results = res;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = appTheme;
    return Container(
      color: t.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  if (_book != null || _results != null)
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
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _search,
                      onChanged: _onQuery,
                      style: TextStyle(color: t.text, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar (≥ 3 letras)',
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
    if (_searching) {
      return Center(
        child: Text('Buscando…',
            style: TextStyle(color: t.muted, fontSize: 15)),
      );
    }
    if (_results != null) return _resultsView();
    if (_book == null) return _booksView();
    if (_chapter == null) return _chaptersView();
    return _versesView();
  }

  Widget _booksView() {
    final bible = AppState.i.bible;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        _section('ANTIGO TESTAMENTO'),
        for (var i = 0; i < 39 && i < bible.length; i++)
          _bookItem(bible[i], i),
        _section('NOVO TESTAMENTO'),
        for (var i = 39; i < bible.length; i++) _bookItem(bible[i], i),
      ],
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

  Widget _bookItem(Book b, int index) {
    final t = appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() {
            _book = b;
            _chapter = null;
          }),
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
        return Material(
          color: t.card,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _chapter = i),
            child: Center(
              child: Text('${i + 1}',
                  style: TextStyle(color: t.text, fontSize: 14)),
            ),
          ),
        );
      },
    );
  }

  Widget _versesView() {
    final t = appTheme;
    final b = _book!;
    final chapter = _chapter!;
    final verses = b.chapters[chapter];
    return ListenableBuilder(
      listenable:
          Listenable.merge([TtsService.i.phase, TtsService.i.index]),
      builder: (context, _) {
        final readingIndex = TtsService.i.index.value;
        return Column(
          children: [
            TtsBar(
              positionLabel: 'Versículo',
              playLabel: 'Ouvir o capítulo',
              itemCount: verses.length,
              onPlay: _playChapter,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
                itemCount: verses.length,
                itemBuilder: (context, v) {
                  final ref = '${b.abbr} ${chapter + 1}:${v + 1}';
                  final key = 'v:$ref';
                  final reading = readingIndex == v;
                  return GestureDetector(
                    onLongPress: () => showLineMenu(
                      context,
                      title: ref,
                      text: '$ref  ${verses[v]}',
                      highlightKey: key,
                      onHighlightChanged: (_) => setState(() {}),
                    ),
                    child: Container(
                      color: reading
                          ? t.accent.withValues(alpha: 0.16)
                          : highlightColor(key),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ref,
                                    style: TextStyle(
                                        color: reading
                                            ? t.accent
                                            : t.accentDark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                Text(verses[v],
                                    style: TextStyle(
                                        color: t.text,
                                        fontSize: 16,
                                        height: 1.4)),
                              ],
                            ),
                          ),
                          if (reading)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Icon(Icons.volume_up,
                                  color: t.accent, size: 18),
                            )
                          else
                            IconButton(
                              icon: Icon(Icons.volume_up,
                                  color: t.muted,
                                  size: 18),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => TtsService.i
                                  .speakOne('$ref. ${verses[v]}'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _playChapter() {
    final verses = _book!.chapters[_chapter!];
    final queue = [
      '${_book!.name}, capítulo ${_chapter! + 1}.',
      for (var v = 0; v < verses.length; v++)
        'Versículo ${v + 1}. ${verses[v]}',
    ];
    TtsService.i.playChapter(queue);
  }

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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
      itemCount: res.length,
      itemBuilder: (context, i) {
        final r = res[i];
        final b = AppState.i.bible[r[0]];
        final text = b.chapters[r[1]][r[2]];
        final ref = '${b.abbr} ${r[1] + 1}:${r[2] + 1}';
        return Card(
          color: t.card,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            onTap: () => setState(() {
              _search.clear();
              _results = null;
              _book = b;
              _chapter = r[1];
            }),
            title: Text(ref,
                style: TextStyle(
                    color: t.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(text,
                style: TextStyle(color: t.text, fontSize: 15)),
          ),
        );
      },
    );
  }

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
    if (selected == null) return;
    AppState.i.setVersion(kVersionOrder[selected]);
    if (mounted) setState(() {});
  }
}
