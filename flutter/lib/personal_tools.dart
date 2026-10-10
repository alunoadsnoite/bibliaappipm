import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'common.dart';
import 'content_catalog.dart';
import 'store.dart';
import 'tabs/bible_tab.dart';
import 'tabs/hymns_tab.dart';
import 'tabs/library_tab.dart';
import 'tabs/songs_tab.dart';

class FavoriteButton extends StatelessWidget {
  final String contentKey;
  const FavoriteButton({super.key, required this.contentKey});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.i,
    builder: (context, _) => IconButton(
      tooltip: AppState.i.isFavorite(contentKey)
          ? 'Remover dos favoritos'
          : 'Adicionar aos favoritos',
      icon: Icon(
        AppState.i.isFavorite(contentKey) ? Icons.star : Icons.star_border,
      ),
      onPressed: () async {
        try {
          await AppState.i.toggleFavorite(contentKey);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Não foi possível salvar o favorito.'),
              ),
            );
          }
        }
      },
    ),
  );
}

void openContent(BuildContext context, ContentEntry entry) {
  final key = entry.key.startsWith('note:')
      ? entry.key.substring(5)
      : entry.key;
  if (!buildCatalog(AppState.i).any((entry) => entry.key == key)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'O conteúdo foi removido ou não está disponível nesta tradução.',
        ),
      ),
    );
    return;
  }
  final Widget Function() page;
  switch (key.split(':').first) {
    case 'v':
      page = () => BibleTab(initialKey: key);
    case 'h':
      page = () => HymnsTab(initialKey: key);
    case 's':
      page = () => SongsTab(initialKey: key);
    case 'b':
      page = () => LibraryTab(initialKey: key);
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O conteúdo desta anotação não está disponível.'),
        ),
      );
      return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Leitura')),
        body: ListenableBuilder(
          listenable: AppState.i,
          builder: (_, _) => page(),
        ),
      ),
    ),
  );
}

enum PersonalView { search, annotations, favorites }

class PersonalToolsPage extends StatefulWidget {
  final PersonalView view;
  const PersonalToolsPage({super.key, required this.view});
  @override
  State<PersonalToolsPage> createState() => _PersonalToolsPageState();
}

class _PersonalToolsPageState extends State<PersonalToolsPage> {
  final _query = TextEditingController();
  Timer? _timer;
  List<ContentEntry> _catalog = [];
  List<ContentEntry> _results = [];
  ContentKind? _kind;
  int? _book;
  int? _color;
  int _job = 0;
  int _visible = 50;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
    AppState.i.addListener(_reload);
  }

  void _reload() {
    _catalog = buildCatalog(AppState.i);
    final entries = {for (final entry in _catalog) entry.key: entry};
    for (final note in AppState.i.notes.entries) {
      final source = entries[note.key];
      _catalog.add(
        ContentEntry(
          'note:${note.key}',
          source?.title ?? 'Conteúdo indisponível (${note.key})',
          note.value,
          ContentKind.note,
          book: source?.book,
        ),
      );
    }
    if (mounted) {
      setState(() {});
    }
    if (widget.view == PersonalView.search && _query.text.trim().isNotEmpty) {
      _search();
    }
  }

  @override
  void dispose() {
    AppState.i.removeListener(_reload);
    _timer?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final job = ++_job;
    setState(() => _busy = true);
    final ref = (_kind == null || _kind == ContentKind.bible)
        ? parseReference(AppState.i.bible, _query.text.trim())
        : null;
    final results = ref != null
        ? _catalog
              .where(
                (entry) =>
                    entry.kind == ContentKind.bible &&
                    entry.key.startsWith('v:${ref.book}:${ref.chapter + 1}:') &&
                    (ref.verse == null ||
                        entry.key ==
                            'v:${ref.book}:${ref.chapter + 1}:${ref.verse! + 1}'),
              )
              .toList()
        : await compute(
            searchCatalog,
            SearchRequest(_catalog, _query.text, _kind),
          );
    if (!mounted || job != _job) {
      return;
    }
    setState(() {
      _results = results;
      _visible = 50;
      _busy = false;
    });
  }

  List<ContentEntry> get _saved {
    final map = {for (final entry in _catalog) entry.key: entry};
    final keys = widget.view == PersonalView.favorites
        ? AppState.i.favorites
        : {...AppState.i.notes.keys, ...AppState.i.highlights.keys};
    return keys
        .map(
          (key) =>
              map[key] ??
              ContentEntry(
                key,
                'Conteúdo indisponível ($key)',
                AppState.i.getNote(key) ?? '',
                ContentKind.note,
              ),
        )
        .where((entry) {
          return (_kind == null || entry.kind == _kind) &&
              (_book == null || entry.book == _book) &&
              (_color == null ||
                  AppState.i.getHighlight(entry.key) == _color) &&
              (_query.text.isEmpty ||
                  foldSortKey(
                    '${entry.title} ${entry.text} ${AppState.i.getNote(entry.key) ?? ''}',
                  ).contains(foldSortKey(_query.text)));
        })
        .toList()
      ..sort((a, b) => foldSortKey(a.title).compareTo(foldSortKey(b.title)));
  }

  @override
  Widget build(BuildContext context) {
    final searching = widget.view == PersonalView.search;
    final annotations = widget.view == PersonalView.annotations;
    final entries = searching ? _results : _saved;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          searching
              ? 'Buscar em tudo'
              : annotations
              ? 'Notas e destaques'
              : 'Favoritos',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                labelText: searching ? 'Texto ou referência' : 'Filtrar itens',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                _timer?.cancel();
                if (searching) {
                  _timer = Timer(const Duration(milliseconds: 250), _search);
                } else {
                  setState(() {});
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _kind == null,
                    onSelected: (_) {
                      setState(() => _kind = null);
                      if (searching) _search();
                    },
                  ),
                  for (final kind in ContentKind.values)
                    if (searching || kind != ContentKind.note)
                      ChoiceChip(
                        label: Text(contentKindNames[kind.index]),
                        selected: _kind == kind,
                        onSelected: (_) {
                          setState(() => _kind = kind);
                          if (searching) _search();
                        },
                      ),
                ],
              ),
            ),
          ),
          if (annotations)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                children: [
                  DropdownButton<int>(
                    value: _book,
                    hint: const Text('Todos os livros'),
                    items: [
                      const DropdownMenuItem(
                        value: -1,
                        child: Text('Todos os livros'),
                      ),
                      for (var i = 0; i < AppState.i.bible.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(AppState.i.bible[i].name),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _book = v == -1 ? null : v),
                  ),
                  DropdownButton<int>(
                    value: _color,
                    hint: const Text('Todas as cores'),
                    items: [
                      const DropdownMenuItem(
                        value: -1,
                        child: Text('Todas as cores'),
                      ),
                      for (var i = 0; i < kHighlightNames.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(kHighlightNames[i]),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _color = v == -1 ? null : v),
                  ),
                ],
              ),
            ),
          if (_busy) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('${entries.length} item(ns)'),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      searching && _query.text.isEmpty
                          ? 'Busque na Bíblia, hinário, músicas, biblioteca e suas notas.'
                          : 'Nenhum item encontrado.',
                    ),
                  )
                : ListView.builder(
                    itemCount: entries.length > _visible
                        ? _visible + 1
                        : entries.length,
                    itemBuilder: (context, i) {
                      if (i == _visible) {
                        return TextButton(
                          onPressed: () => setState(() => _visible += 50),
                          child: const Text('Mostrar mais'),
                        );
                      }
                      final entry = entries[i];
                      final noteKey = entry.key.startsWith('note:')
                          ? entry.key.substring(5)
                          : entry.key;
                      final note = AppState.i.getNote(noteKey);
                      return Card(
                        child: ListTile(
                          title: Text(entry.title),
                          subtitle: Text(
                            [
                              entry.text,
                              if (annotations && note != null) 'Nota: $note',
                            ].join('\n'),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading:
                              annotations &&
                                  AppState.i.getHighlight(entry.key) >= 0 &&
                                  AppState.i.getHighlight(entry.key) <
                                      kHighlightNames.length
                              ? Semantics(
                                  label:
                                      'Destaque ${kHighlightNames[AppState.i.getHighlight(entry.key)]}',
                                  child: Icon(
                                    Icons.circle,
                                    color: highlightColor(entry.key),
                                  ),
                                )
                              : null,
                          trailing: FavoriteButton(
                            contentKey: entry.key.startsWith('note:')
                                ? entry.key.substring(5)
                                : entry.key,
                          ),
                          onTap: () => openContent(context, entry),
                          onLongPress: () => showLineMenu(
                            context,
                            title: entry.title,
                            text: entry.text,
                            highlightKey: entry.key.startsWith('note:')
                                ? entry.key.substring(5)
                                : entry.key,
                            note: note,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
