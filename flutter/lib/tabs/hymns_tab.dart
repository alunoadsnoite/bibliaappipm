import 'package:flutter/material.dart';

import '../common.dart';
import '../models.dart';
import '../store.dart';

class HymnsTab extends StatefulWidget {
  const HymnsTab({super.key});

  @override
  State<HymnsTab> createState() => _HymnsTabState();
}

class _HymnsTabState extends State<HymnsTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  Hymn? _current;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Hymn> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return AppState.i.hymns;
    return AppState.i.hymns.where((h) => h.searchText().contains(q)).toList();
  }

  static String _stanzaLabel(String name) {
    if (name.isEmpty) return '';
    switch (name[0]) {
      case 'c':
        return 'CORO';
      case 'b':
        return 'PONTE';
      case 'p':
        return 'PRELÚDIO';
      case 'o':
        return 'OUTRO';
      case 'e':
        return name.toUpperCase();
      default:
        return '';
    }
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
                      onPressed: () => setState(() => _current = null),
                    ),
                  Expanded(
                    child: Text(
                      _current == null
                          ? 'Hinário Novo Cântico'
                          : '${_current!.num} - ${_current!.title}',
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
                          hintText: 'Buscar hino',
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
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text('Nenhum hino encontrado.',
            style: TextStyle(color: t.muted, fontSize: 15)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final h = items[i];
        return Card(
          color: t.card,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: ListTile(
            onTap: () => setState(() => _current = h),
            title: Text('${h.num}',
                style: TextStyle(
                    color: t.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(h.title,
                style: TextStyle(color: t.text, fontSize: 16)),
          ),
        );
      },
    );
  }

  Widget _detail(Hymn h) {
    final t = appTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          h.title,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: t.text, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        if (h.author.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(h.author,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        for (var s = 0; s < h.stanzas.length; s++) ...[
          if (_stanzaLabel(h.stanzaNames[s]).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 2),
              child: Text(_stanzaLabel(h.stanzaNames[s]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: t.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            )
          else
            const SizedBox(height: 10),
          for (var l = 0; l < h.stanzas[s].length; l++)
            _line(
              text: h.stanzas[s][l],
              key: 'h:${h.num}:$s:$l',
            ),
        ],
      ],
    );
  }

  Widget _line({required String text, required String key}) {
    final t = appTheme;
    return GestureDetector(
      onLongPress: () => showLineMenu(
        context,
        title: text,
        text: text,
        highlightKey: key,
        onHighlightChanged: (_) => setState(() {}),
      ),
      child: Container(
        width: double.infinity,
        color: highlightColor(key),
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: t.text, fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}
