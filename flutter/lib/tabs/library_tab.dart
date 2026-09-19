import 'package:flutter/material.dart';

import '../common.dart';
import '../models.dart';
import '../store.dart';
import '../tts.dart';
import '../tts_bar.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  BibliotecaText? _current;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BibliotecaText> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return AppState.i.biblioteca;
    return AppState.i.biblioteca
        .where((d) => d.searchText().contains(q))
        .toList();
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
                  if (_current != null)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          size: 20, color: t.primary),
                      onPressed: () {
                        TtsService.i.stop();
                        setState(() => _current = null);
                      },
                    ),
                  Expanded(
                    child: Text(
                      _current == null ? 'Biblioteca' : _current!.title,
                      style: TextStyle(
                          color: t.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_current == null)
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(color: t.text, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar',
                          hintStyle: TextStyle(color: t.muted, fontSize: 14),
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
            Expanded(
              child: _current == null ? _list() : _detail(_current!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    final t = appTheme;
    final docs = _filtered;
    if (docs.isEmpty) {
      return Center(
        child: Text('Nenhum documento encontrado.',
            style: TextStyle(color: t.muted, fontSize: 15)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final d = docs[i];
        final itemsCount = d.items.length;
        final label = d.items.isEmpty
            ? ''
            : (itemsCount == 1 ? '1 item' : '$itemsCount itens');
        return Card(
          color: t.card,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: ListTile(
            leading: Icon(Icons.auto_stories, color: t.primary),
            onTap: () => setState(() => _current = d),
            title: Text(d.title,
                style: TextStyle(
                    color: t.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(
              d.sub,
              style: TextStyle(color: t.muted, fontSize: 13),
            ),
            trailing: Text(label,
                style: TextStyle(color: t.muted, fontSize: 12)),
          ),
        );
      },
    );
  }

  Widget _detail(BibliotecaText d) {
    final t = appTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TtsBar(
          positionLabel: 'Item',
          playLabel: 'Ouvir ${d.title}',
          itemCount: d.items.length,
          onPlay: () => _playDoc(d),
        ),
        const SizedBox(height: 8),
        Text(
          d.title,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: t.text, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        if (d.sub.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(d.sub,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < d.items.length; i++) ...[
          if (d.items[i].t.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 2),
              child: Text(d.items[i].t,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: t.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            )
          else
            const SizedBox(height: 14),
          for (var j = 0; j < d.items[i].p.length; j++)
            _line(
              text: d.items[i].p[j],
              key: 'b:${d.id}:$i:$j',
            ),
        ],
      ],
    );
  }

  void _playDoc(BibliotecaText d) {
    final queue = <String>[
      d.title,
      for (final it in d.items) ...[
        if (it.t.isNotEmpty) it.t,
        for (final p in it.p) p,
      ],
    ];
    TtsService.i.playChapter(queue);
  }

  Widget _line({required String text, required String key}) {
    final t = appTheme;
    return GestureDetector(
      onLongPress: () => showLineMenu(
        context,
        title: text,
        text: text,
        highlightKey: key,
        note: AppState.i.getNote(key) ?? '',
        onHighlightChanged: (_) => setState(() {}),
        onNoteChanged: (_) => setState(() {}),
      ),
      child: Container(
        width: double.infinity,
        color: highlightColor(key),
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          text,
          textAlign: TextAlign.justify,
          style: TextStyle(color: t.text, fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}