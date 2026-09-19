import 'models.dart';

/// Versículos do dia (referência canônica em índices: livro, capítulo 0‑based,
/// versículo 0‑based). A rotação é determinística por dia do ano, 100% offline.
const List<(int, int, int)> kDailyVerses = [
  (0, 0, 0), // Gênesis 1:1
  (1, 13, 13), // Êxodo 14:14
  (4, 30, 5), // Deuteronômio 31:6
  (5, 0, 8), // Josué 1:9
  (18, 0, 0), // Salmos 1:1
  (18, 22, 0), // Salmos 23:1
  (18, 22, 3), // Salmos 23:4
  (18, 45, 0), // Salmos 46:1
  (18, 118, 104), // Salmos 119:105
  (18, 118, 10), // Salmos 119:11
  (19, 2, 4), // Provérbios 3:5
  (19, 2, 5), // Provérbios 3:6
  (22, 25, 2), // Isaías 26:3
  (22, 39, 30), // Isaías 40:31
  (22, 40, 9), // Isaías 41:10
  (23, 28, 10), // Jeremias 29:11
  (39, 4, 15), // Mateus 5:16
  (39, 5, 32), // Mateus 6:33
  (39, 10, 27), // Mateus 11:28
  (40, 9, 26), // Marcos 10:27
  (41, 0, 36), // Lucas 1:37
  (42, 0, 0), // João 1:1
  (42, 2, 15), // João 3:16
  (42, 13, 5), // João 14:6
  (42, 14, 4), // João 15:5
  (44, 4, 7), // Romanos 5:8
  (44, 7, 27), // Romanos 8:28
  (44, 11, 1), // Romanos 12:2
  (45, 12, 3), // 1 Coríntios 13:4
  (45, 14, 57), // 1 Coríntios 15:58
  (46, 4, 16), // 2 Coríntios 5:17
  (47, 4, 21), // Gálatas 5:22
  (48, 1, 7), // Efésios 2:8
  (49, 3, 5), // Filipenses 4:6
  (49, 3, 12), // Filipenses 4:13
  (50, 2, 22), // Colossenses 3:23
  (51, 4, 17), // 1 Tessalonicenses 5:18
  (54, 0, 6), // 2 Timóteo 1:7
  (58, 0, 4), // Tiago 1:5
  (59, 4, 6), // 1 Pedro 5:7
  (61, 0, 8), // 1 João 1:9
  (65, 20, 3), // Apocalipse 21:4
  (65, 2, 19), // Apocalipse 3:20
];

/// Seleciona o versículo do dia, girando pela lista de forma determinística.
(int, int, int) dailyVerseFor(DateTime day) {
  final start = DateTime(day.year);
  final dayOfYear = day.difference(start).inDays + 1;
  return kDailyVerses[dayOfYear % kDailyVerses.length];
}

/// Rótulo amigável de uma referência (livro + capítulo + versículo) dado o
/// índice canônico do livro e a lista de livros da versão atual.
String formatRef(List<Book> books, int book, int chapter, int? verse) {
  if (book < 0 || book >= books.length) return '';
  final b = books[book];
  if (verse != null) return '${b.abbr} ${chapter + 1}:${verse + 1}';
  return '${b.abbr} ${chapter + 1}';
}