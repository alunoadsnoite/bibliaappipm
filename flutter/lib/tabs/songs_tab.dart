import 'package:flutter/material.dart';

import '../common.dart';
import '../models.dart';
import '../store.dart';
import '../tts.dart';
import '../tts_bar.dart';

class SongsTab extends StatefulWidget {
  const SongsTab({super.key});

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab> {
  int? _current;

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
                      _current == null
                          ? 'Músicas'
                          : AppState.i.songs[_current!].title,
                      style: TextStyle(
                          color: t.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _edit(_current),
                    icon: Icon(
                        _current == null ? Icons.add : Icons.edit,
                        size: 18,
                        color: t.accent),
                    label: Text(
                      _current == null ? 'Adicionar' : 'Editar',
                      style: TextStyle(
                          color: t.accent, fontWeight: FontWeight.bold),
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
    final songs = AppState.i.songs;
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Nenhuma música adicionada.\nToque em "Adicionar" para incluir letras.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.muted, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: songs.length,
      itemBuilder: (context, i) {
        final s = songs[i];
        var preview = s.lyrics.trim();
        final nl = preview.indexOf('\n');
        if (nl >= 0) preview = preview.substring(0, nl);
        if (preview.length > 70) {
          preview = '${preview.substring(0, 70)}…';
        }
        return Card(
          color: t.card,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: ListTile(
            onTap: () => setState(() => _current = i),
            onLongPress: () => _itemMenu(i),
            title: Text(s.title,
                style: TextStyle(
                    color: t.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(preview,
                style: TextStyle(color: t.muted, fontSize: 13)),
          ),
        );
      },
    );
  }

  Widget _detail(int index) {
    final t = appTheme;
    final s = AppState.i.songs[index];
    final lines = s.lyrics.split('\n');
    final stanzas = _songStanzas(s.lyrics);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TtsBar(
          positionLabel: 'Estrofe',
          playLabel: 'Ouvir a música completa',
          itemCount: stanzas.length,
          onPlay: () => _playSong(index),
        ),
        const SizedBox(height: 8),
        Text(
          s.title,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: t.text, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (var li = 0; li < lines.length; li++)
          if (lines[li].trim().isEmpty)
            const SizedBox(height: 8)
          else
            _line(
              text: lines[li],
              key: 's:$index:$li',
            ),
      ],
    );
  }

  List<String> _songStanzas(String lyrics) {
    final groups = <List<String>>[];
    var cur = <String>[];
    for (final l in lyrics.split('\n')) {
      if (l.trim().isEmpty) {
        if (cur.isNotEmpty) {
          groups.add(cur);
          cur = [];
        }
      } else {
        cur.add(l.trim());
      }
    }
    if (cur.isNotEmpty) groups.add(cur);
    return [for (final g in groups) g.join('. ')];
  }

  void _playSong(int index) {
    final s = AppState.i.songs[index];
    final stanzas = _songStanzas(s.lyrics);
    final queue = <String>[
      if (s.title.trim().isNotEmpty) '${s.title.trim()}.',
      for (var i = 0; i < stanzas.length; i++)
        'Estrofe ${i + 1}. ${stanzas[i]}',
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
          textAlign: TextAlign.center,
          style: TextStyle(color: t.text, fontSize: 16, height: 1.4),
        ),
      ),
    );
  }

  Future<void> _edit(int? index) async {
    final t = appTheme;
    final titleCtrl = TextEditingController();
    final lyricsCtrl = TextEditingController();
    if (index != null) {
      titleCtrl.text = AppState.i.songs[index].title;
      lyricsCtrl.text = AppState.i.songs[index].lyrics;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        title: Text(index == null ? 'Nova música' : 'Editar música',
            style: TextStyle(color: t.text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: t.text),
                decoration: const InputDecoration(hintText: 'Título da música'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lyricsCtrl,
                maxLines: 10,
                style: TextStyle(color: t.text),
                decoration:
                    const InputDecoration(hintText: 'Letra (uma frase por linha)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final title = titleCtrl.text.trim();
    final lyrics = lyricsCtrl.text.trim();
    if (title.isEmpty || lyrics.isEmpty) return;
    if (index == null) {
      AppState.i.songs.add(Song(title, lyrics));
    } else {
      AppState.i.songs[index].title = title;
      AppState.i.songs[index].lyrics = lyrics;
    }
    await AppState.i.saveSongs();
    if (mounted) setState(() => _current = index);
  }

  Future<void> _itemMenu(int index) async {
    final t = appTheme;
    final s = AppState.i.songs[index];
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: t.card,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: t.text),
              title: Text('Editar', style: TextStyle(color: t.text)),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: t.text),
              title: Text('Excluir', style: TextStyle(color: t.text)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            ListTile(
              leading: Icon(Icons.share, color: t.text),
              title: Text('Compartilhar', style: TextStyle(color: t.text)),
              onTap: () => Navigator.pop(ctx, 'share'),
            ),
          ],
        ),
      ),
    );
    if (action == 'edit') {
      await _edit(index);
    } else if (action == 'delete') {
      AppState.i.songs.removeAt(index);
      await AppState.i.saveSongs();
      if (mounted) setState(() => _current = null);
    } else if (action == 'share') {
      shareText('${s.title}\n\n${s.lyrics}');
    }
  }
}
