import 'common.dart';
import 'store.dart';

enum ContentKind { bible, hymn, song, library, note }

const contentKindNames = [
  'Bíblia',
  'Hinário',
  'Músicas',
  'Biblioteca',
  'Notas',
];

class ContentEntry {
  final String key;
  final String title;
  final String text;
  final ContentKind kind;
  final int? book;
  const ContentEntry(this.key, this.title, this.text, this.kind, {this.book});
}

List<ContentEntry> buildCatalog(AppState state) {
  final out = <ContentEntry>[];
  for (var b = 0; b < state.bible.length; b++) {
    final book = state.bible[b];
    for (var c = 0; c < book.chapters.length; c++) {
      for (var v = 0; v < book.chapters[c].length; v++) {
        out.add(
          ContentEntry(
            'v:$b:${c + 1}:${v + 1}',
            '${book.name} ${c + 1}:${v + 1}',
            book.chapters[c][v],
            ContentKind.bible,
            book: b,
          ),
        );
      }
    }
  }
  for (final h in state.hymns) {
    out.add(
      ContentEntry(
        'h:${h.num}',
        '${h.num} — ${h.title}',
        '${h.author}\n${h.stanzas.map((s) => s.join('\n')).join('\n\n')}',
        ContentKind.hymn,
      ),
    );
    for (var s = 0; s < h.stanzas.length; s++) {
      for (var l = 0; l < h.stanzas[s].length; l++) {
        out.add(
          ContentEntry(
            'h:${h.num}:$s:$l',
            '${h.num} — ${h.title}',
            h.stanzas[s][l],
            ContentKind.hymn,
          ),
        );
      }
    }
  }
  for (final song in state.songs) {
    out.add(
      ContentEntry('s:${song.id}', song.title, song.lyrics, ContentKind.song),
    );
    final lines = song.lyrics.split('\n');
    for (var l = 0; l < lines.length; l++) {
      out.add(
        ContentEntry('s:${song.id}:$l', song.title, lines[l], ContentKind.song),
      );
    }
  }
  for (final doc in state.biblioteca) {
    out.add(
      ContentEntry(
        'b:${doc.id}',
        doc.title,
        doc.items.map((i) => '${i.t}\n${i.p.join('\n')}').join('\n\n'),
        ContentKind.library,
      ),
    );
    for (var i = 0; i < doc.items.length; i++) {
      for (var p = 0; p < doc.items[i].p.length; p++) {
        out.add(
          ContentEntry(
            'b:${doc.id}:$i:$p',
            '${doc.title} — ${doc.items[i].t}',
            doc.items[i].p[p],
            ContentKind.library,
          ),
        );
      }
    }
  }
  return out;
}

class SearchRequest {
  final List<ContentEntry> entries;
  final String query;
  final ContentKind? kind;
  const SearchRequest(this.entries, this.query, this.kind);
}

List<ContentEntry> searchCatalog(SearchRequest request) {
  final query = foldSortKey(request.query.trim());
  if (query.isEmpty) return [];
  return request.entries.where((entry) {
    if (request.kind != null && entry.kind != request.kind) return false;
    // Busca músicas/hinos inteiros e itens da biblioteca, evitando duplicatas
    // de linhas que só são necessárias para resolver as anotações existentes.
    final parts = entry.key.split(':');
    if (entry.kind == ContentKind.hymn && parts.length > 2) return false;
    if (entry.kind == ContentKind.song && parts.length > 2) return false;
    if (entry.kind == ContentKind.library && parts.length == 2) return false;
    return foldSortKey('${entry.title}\n${entry.text}').contains(query);
  }).toList();
}
