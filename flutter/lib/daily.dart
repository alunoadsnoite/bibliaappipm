import 'models.dart';

/// Versículos do dia (referência canônica em índices: livro, capítulo 0‑based,
/// versículo 0‑based). A rotação é determinística por dia do ano, 100% offline.
const List<(int, int, int)> kDailyVerses = [
  // --- Antigo Testamento ---
  (0, 0, 0), // Gênesis 1:1
  (0, 1, 6), // Gênesis 2:7
  (1, 13, 13), // Êxodo 14:14
  (1, 19, 11), // Êxodo 20:12
  (3, 13, 17), // Números 14:18
  (4, 30, 5), // Deuteronômio 31:6
  (5, 0, 8), // Josué 1:9
  (7, 0, 15), // Rute 1:16
  (8, 0, 26), // 1 Samuel 1:27
  (9, 14, 24), // 2 Samuel 15:25
  (10, 7, 22), // 1 Reis 8:23
  (15, 8, 5), // Neemias 9:6
  (17, 7, 2), // Jó 8:3
  (18, 0, 0), // Salmos 1:1
  (18, 18, 10), // Salmos 19:11
  (18, 22, 0), // Salmos 23:1
  (18, 22, 3), // Salmos 23:4
  (18, 26, 0), // Salmos 27:1
  (18, 33, 7), // Salmos 34:8
  (18, 36, 4), // Salmos 37:5
  (18, 36, 6), // Salmos 37:7
  (18, 39, 0), // Salmos 40:1
  (18, 45, 0), // Salmos 46:1
  (18, 45, 10), // Salmos 46:11
  (18, 50, 11), // Salmos 51:12
  (18, 55, 2), // Salmos 56:3
  (18, 61, 1), // Salmos 62:2
  (18, 67, 5), // Salmos 68:6
  (18, 70, 4), // Salmos 71:5
  (18, 72, 0), // Salmos 73:1
  (18, 72, 27), // Salmos 73:28
  (18, 85, 0), // Salmos 86:1
  (18, 85, 15), // Salmos 86:16
  (18, 90, 1), // Salmos 91:2
  (18, 90, 11), // Salmos 91:12
  (18, 96, 0), // Salmos 97:1
  (18, 102, 7), // Salmos 103:8
  (18, 103, 13), // Salmos 104:14
  (18, 117, 0), // Salmos 118:1
  (18, 118, 10), // Salmos 119:11
  (18, 118, 104), // Salmos 119:105
  (18, 120, 1), // Salmos 121:2
  (18, 126, 1), // Salmos 127:2
  (18, 138, 22), // Salmos 139:23
  (18, 144, 2), // Salmos 145:3
  (18, 146, 4), // Salmos 147:5
  (19, 0, 6), // Provérbios 1:7
  (19, 2, 4), // Provérbios 3:5
  (19, 2, 5), // Provérbios 3:6
  (19, 2, 6), // Provérbios 3:7
  (19, 3, 12), // Provérbios 4:13
  (19, 4, 22), // Provérbios 5:23
  (19, 6, 5), // Provérbios 7:6
  (19, 9, 9), // Provérbios 10:10
  (19, 12, 0), // Provérbios 13:1
  (19, 15, 0), // Provérbios 16:1
  (19, 15, 32), // Provérbios 16:33
  (19, 17, 21), // Provérbios 18:22
  (19, 22, 5), // Provérbios 23:6
  (19, 25, 0), // Provérbios 26:1
  (19, 28, 12), // Provérbios 29:13
  (20, 0, 0), // Eclesiastes 1:1
  (20, 2, 10), // Eclesiastes 3:11
  (20, 6, 8), // Eclesiastes 7:9
  (20, 11, 0), // Eclesiastes 12:1
  (20, 11, 13), // Eclesiastes 12:14
  (21, 0, 4), // Cantares 1:5
  (22, 6, 1), // Isaías 7:2
  (22, 8, 12), // Isaías 9:13
  (22, 11, 2), // Isaías 12:3
  (22, 25, 2), // Isaías 26:3
  (22, 25, 3), // Isaías 26:4
  (22, 39, 7), // Isaías 40:8
  (22, 39, 30), // Isaías 40:31
  (22, 40, 0), // Isaías 41:1
  (22, 40, 9), // Isaías 41:10
  (22, 42, 0), // Isaías 43:1
  (22, 43, 21), // Isaías 44:22
  (22, 52, 6), // Isaías 53:7
  (22, 52, 9), // Isaías 53:10
  (22, 55, 0), // Isaías 56:1
  (22, 58, 10), // Isaías 59:11
  (22, 61, 0), // Isaías 62:1
  (22, 65, 16), // Isaías 66:17
  (23, 5, 7), // Jeremias 6:8
  (23, 17, 6), // Jeremias 18:7
  (23, 28, 10), // Jeremias 29:11
  (23, 29, 10), // Jeremias 30:11
  (23, 31, 32), // Jeremias 32:33
  (23, 33, 2), // Jeremias 34:3
  (24, 2, 31), // Lamentações 3:32
  (25, 0, 0), // Ezequiel 1:1
  (25, 36, 25), // Ezequiel 37:26
  (25, 37, 13), // Ezequiel 38:14
  (26, 0, 0), // Daniel 1:1
  (26, 3, 16), // Daniel 4:17
  (26, 5, 13), // Daniel 6:14
  (26, 9, 3), // Daniel 10:4
  (26, 11, 2), // Daniel 12:3
  (27, 0, 0), // Oseias 1:1
  (27, 6, 5), // Oseias 7:6
  (28, 0, 0), // Joel 1:1
  (28, 1, 22), // Joel 2:23
  (29, 1, 0), // Amós 2:1
  (29, 4, 23), // Amós 5:24
  (30, 0, 0), // Obadias 1:1
  (31, 2, 3), // Jonas 3:4
  (32, 0, 0), // Miqueias 1:1
  (32, 6, 7), // Miqueias 7:8
  (33, 0, 14), // Naum 1:15
  (34, 1, 3), // Habacuque 2:4
  (35, 2, 3), // Sofonias 3:4
  (36, 1, 8), // Ageu 2:9
  (37, 1, 4), // Zacarias 2:5
  (37, 3, 5), // Zacarias 4:6
  (37, 4, 5), // Zacarias 5:6
  (38, 2, 9), // Malaquias 3:10
  // --- Novo Testamento ---
  (39, 0, 0), // Mateus 1:1
  (39, 0, 20), // Mateus 1:21
  (39, 3, 15), // Mateus 4:16
  (39, 4, 15), // Mateus 5:16
  (39, 5, 2), // Mateus 6:3
  (39, 5, 3), // Mateus 6:4
  (39, 5, 32), // Mateus 6:33
  (39, 6, 6), // Mateus 7:7
  (39, 7, 6), // Mateus 8:7
  (39, 8, 21), // Mateus 9:22
  (39, 9, 34), // Mateus 10:35
  (39, 10, 27), // Mateus 11:28
  (39, 11, 10), // Mateus 12:11
  (39, 12, 36), // Mateus 13:37
  (39, 13, 28), // Mateus 14:29
  (39, 16, 17), // Mateus 17:18
  (39, 18, 4), // Mateus 19:5
  (39, 18, 25), // Mateus 19:26
  (39, 20, 15), // Mateus 21:16
  (39, 22, 36), // Mateus 23:37
  (39, 24, 5), // Mateus 25:6
  (39, 25, 39), // Mateus 26:40
  (39, 26, 25), // Mateus 27:26
  (39, 27, 17), // Mateus 28:18
  (39, 27, 19), // Mateus 28:20
  (40, 0, 0), // Marcos 1:1
  (40, 1, 14), // Marcos 2:15
  (40, 3, 4), // Marcos 4:5
  (40, 4, 40), // Marcos 5:41
  (40, 8, 34), // Marcos 9:35
  (40, 8, 35), // Marcos 9:36
  (40, 9, 26), // Marcos 10:27
  (40, 9, 44), // Marcos 10:45
  (40, 12, 34), // Marcos 13:35
  (40, 14, 35), // Marcos 15:36
  (40, 15, 14), // Marcos 16:15
  (41, 0, 0), // Lucas 1:1
  (41, 0, 36), // Lucas 1:37
  (41, 0, 37), // Lucas 1:38
  (41, 1, 13), // Lucas 2:14
  (41, 1, 39), // Lucas 2:40
  (41, 2, 0), // Lucas 3:1
  (41, 3, 2), // Lucas 4:3
  (41, 4, 12), // Lucas 5:13
  (41, 6, 26), // Lucas 7:27
  (41, 7, 35), // Lucas 8:36
  (41, 9, 41), // Lucas 10:42
  (41, 10, 41), // Lucas 11:42
  (41, 12, 5), // Lucas 13:6
  (41, 15, 10), // Lucas 16:11
  (41, 16, 8), // Lucas 17:9
  (41, 18, 13), // Lucas 19:14
  (41, 21, 36), // Lucas 22:37
  (41, 22, 19), // Lucas 23:20
  (41, 23, 31), // Lucas 24:32
  (41, 23, 32), // Lucas 24:33
  (42, 0, 0), // João 1:1
  (42, 1, 24), // João 2:25
  (42, 2, 15), // João 3:16
  (42, 2, 16), // João 3:17
  (42, 3, 34), // João 4:35
  (42, 6, 34), // João 7:35
  (42, 8, 11), // João 9:12
  (42, 11, 34), // João 12:35
  (42, 12, 23), // João 13:24
  (42, 13, 5), // João 14:6
  (42, 14, 0), // João 15:1
  (42, 14, 4), // João 15:5
  (42, 14, 12), // João 15:13
  (42, 14, 14), // João 15:15
  (42, 15, 25), // João 16:26
  (42, 17, 2), // João 18:3
  (42, 19, 29), // João 20:30
  (42, 20, 17), // João 21:18
  (43, 4, 7), // Atos 5:8
  (43, 8, 21), // Atos 9:22
  (43, 10, 23), // Atos 11:24
  (43, 13, 21), // Atos 14:22
  (43, 16, 30), // Atos 17:31
  (43, 17, 25), // Atos 18:26
  (43, 20, 23), // Atos 21:24
  (43, 26, 17), // Atos 27:18
  (43, 27, 22), // Atos 28:23
  (44, 1, 7), // Romanos 2:8
  (44, 3, 22), // Romanos 4:23
  (44, 4, 7), // Romanos 5:8
  (44, 5, 0), // Romanos 6:1
  (44, 6, 22), // Romanos 7:23
  (44, 7, 27), // Romanos 8:28
  (44, 7, 28), // Romanos 8:29
  (44, 7, 36), // Romanos 8:37
  (44, 9, 0), // Romanos 10:1
  (44, 10, 8), // Romanos 11:9
  (44, 11, 1), // Romanos 12:2
  (44, 11, 11), // Romanos 12:12
  (44, 14, 9), // Romanos 15:10
  (44, 14, 12), // Romanos 15:13
  (44, 15, 12), // Romanos 16:13
  (44, 15, 13), // Romanos 16:14
  (45, 0, 0), // 1 Coríntios 1:1
  (45, 0, 17), // 1 Coríntios 1:18
  (45, 2, 1), // 1 Coríntios 3:2
  (45, 3, 15), // 1 Coríntios 4:16
  (45, 6, 13), // 1 Coríntios 7:14
  (45, 9, 21), // 1 Coríntios 10:22
  (45, 11, 0), // 1 Coríntios 12:1
  (45, 12, 3), // 1 Coríntios 13:4
  (45, 12, 12), // 1 Coríntios 13:13
  (45, 14, 57), // 1 Coríntios 15:58
  (45, 15, 0), // 1 Coríntios 16:1
  (45, 15, 21), // 1 Coríntios 16:22
  (46, 0, 0), // 2 Coríntios 1:1
  (46, 1, 2), // 2 Coríntios 2:3
  (46, 3, 16), // 2 Coríntios 4:17
  (46, 4, 3), // 2 Coríntios 5:4
  (46, 4, 6), // 2 Coríntios 5:7
  (46, 4, 16), // 2 Coríntios 5:17
  (46, 4, 17), // 2 Coríntios 5:18
  (46, 8, 8), // 2 Coríntios 9:9
  (46, 9, 14), // 2 Coríntios 10:15
  (46, 11, 8), // 2 Coríntios 12:9
  (46, 12, 3), // 2 Coríntios 13:4
  (47, 0, 0), // Gálatas 1:1
  (47, 2, 19), // Gálatas 3:20
  (47, 3, 25), // Gálatas 4:26
  (47, 3, 27), // Gálatas 4:28
  (47, 4, 21), // Gálatas 5:22
  (47, 5, 0), // Gálatas 6:1
  (47, 5, 1), // Gálatas 6:2
  (47, 5, 8), // Gálatas 6:9
  (47, 5, 13), // Gálatas 6:14
  (48, 1, 7), // Efésios 2:8
  (48, 2, 7), // Efésios 3:8
  (48, 3, 16), // Efésios 4:17
  (48, 3, 19), // Efésios 4:20
  (48, 4, 31), // Efésios 5:32
  (48, 5, 1), // Efésios 6:2
  (48, 5, 9), // Efésios 6:10
  (48, 5, 10), // Efésios 6:11
  (48, 5, 12), // Efésios 6:13
  (49, 0, 0), // Filipenses 1:1
  (49, 1, 5), // Filipenses 2:6
  (49, 1, 13), // Filipenses 2:14
  (49, 2, 4), // Filipenses 3:5
  (49, 3, 5), // Filipenses 4:6
  (49, 3, 12), // Filipenses 4:13
  (49, 3, 18), // Filipenses 4:19
  (50, 2, 22), // Colossenses 3:23
  (50, 3, 11), // Colossenses 4:12
  (50, 3, 15), // Colossenses 4:16
  (51, 1, 2), // 1 Tessalonicenses 2:3
  (51, 2, 12), // 1 Tessalonicenses 3:13
  (51, 4, 15), // 1 Tessalonicenses 5:16
  (51, 4, 17), // 1 Tessalonicenses 5:18
  (52, 1, 14), // 2 Tessalonicenses 2:15
  (52, 2, 12), // 2 Tessalonicenses 3:13
  (53, 3, 11), // 1 Timóteo 4:12
  (53, 3, 15), // 1 Timóteo 4:16
  (53, 4, 7), // 1 Timóteo 5:8
  (53, 5, 11), // 1 Timóteo 6:12
  (54, 0, 6), // 2 Timóteo 1:7
  (54, 1, 1), // 2 Timóteo 2:2
  (54, 1, 6), // 2 Timóteo 2:7
  (54, 1, 14), // 2 Timóteo 2:15
  (54, 2, 14), // 2 Timóteo 3:15
  (54, 2, 15), // 2 Timóteo 3:16
  (54, 3, 13), // 2 Timóteo 4:14
  (55, 1, 4), // Tito 2:5
  (55, 2, 10), // Tito 3:11
  (56, 0, 5), // Filemom 1:6
  (57, 0, 0), // Hebreus 1:1
  (57, 1, 0), // Hebreus 2:1
  (57, 2, 8), // Hebreus 3:9
  (57, 3, 5), // Hebreus 4:6
  (57, 3, 12), // Hebreus 4:13
  (57, 3, 13), // Hebreus 4:14
  (57, 3, 14), // Hebreus 4:15
  (57, 4, 11), // Hebreus 5:12
  (57, 5, 8), // Hebreus 6:9
  (57, 9, 23), // Hebreus 10:24
  (57, 10, 0), // Hebreus 11:1
  (57, 10, 22), // Hebreus 11:23
  (57, 11, 1), // Hebreus 12:2
  (57, 11, 5), // Hebreus 12:6
  (57, 12, 1), // Hebreus 13:2
  (57, 12, 7), // Hebreus 13:8
  (58, 0, 4), // Tiago 1:5
  (58, 0, 21), // Tiago 1:22
  (58, 1, 1), // Tiago 2:2
  (58, 1, 4), // Tiago 2:5
  (58, 1, 16), // Tiago 2:17
  (58, 1, 21), // Tiago 2:22
  (58, 1, 25), // Tiago 2:26
  (58, 3, 16), // Tiago 4:17
  (58, 4, 5), // Tiago 5:6
  (58, 4, 6), // Tiago 5:7
  (58, 4, 9), // Tiago 5:10
  (58, 4, 11), // Tiago 5:12
  (59, 1, 2), // 1 Pedro 2:3
  (59, 1, 6), // 1 Pedro 2:7
  (59, 1, 10), // 1 Pedro 2:11
  (59, 2, 21), // 1 Pedro 3:22
  (59, 3, 7), // 1 Pedro 4:8
  (59, 4, 6), // 1 Pedro 5:7
  (59, 4, 7), // 1 Pedro 5:8
  (59, 4, 9), // 1 Pedro 5:10
  (59, 4, 10), // 1 Pedro 5:11
  (60, 0, 2), // 2 Pedro 1:3
  (60, 2, 17), // 2 Pedro 3:18
  (61, 0, 8), // 1 João 1:9
  (61, 1, 2), // 1 João 2:3
  (61, 1, 8), // 1 João 2:9
  (61, 2, 14), // 1 João 3:15
  (61, 2, 17), // 1 João 3:18
  (61, 3, 1), // 1 João 4:2
  (61, 3, 2), // 1 João 4:3
  (61, 3, 7), // 1 João 4:8
  (61, 3, 9), // 1 João 4:10
  (61, 3, 15), // 1 João 4:16
  (61, 4, 6), // 1 João 5:7
  (61, 4, 7), // 1 João 5:8
  (61, 4, 11), // 1 João 5:12
  (61, 4, 12), // 1 João 5:13
  (61, 4, 13), // 1 João 5:14
  (62, 0, 1), // 2 João 1:2
  (62, 0, 2), // 2 João 1:3
  (62, 0, 4), // 2 João 1:5
  (62, 0, 5), // 2 João 1:6
  (62, 0, 6), // 2 João 1:7
  (62, 0, 8), // 2 João 1:9
  (62, 0, 9), // 2 João 1:10
  (63, 0, 0), // 3 João 1:1
  (63, 0, 1), // 3 João 1:2
  (63, 0, 4), // 3 João 1:5
  (63, 0, 10), // 3 João 1:11
  (64, 0, 8), // Judas 1:9
  (64, 0, 23), // Judas 1:24
  (64, 0, 24), // Judas 1:25
  (65, 0, 0), // Apocalipse 1:1
  (65, 1, 4), // Apocalipse 2:5
  (65, 1, 6), // Apocalipse 2:7
  (65, 1, 7), // Apocalipse 2:8
  (65, 2, 19), // Apocalipse 3:20
  (65, 3, 7), // Apocalipse 4:8
  (65, 5, 8), // Apocalipse 6:9
  (65, 7, 11), // Apocalipse 8:12
  (65, 11, 14), // Apocalipse 12:15
  (65, 12, 9), // Apocalipse 13:10
  (65, 16, 14), // Apocalipse 17:15
  (65, 19, 8), // Apocalipse 20:9
  (65, 20, 3), // Apocalipse 21:4
  (65, 20, 4), // Apocalipse 21:5
  (65, 21, 2), // Apocalipse 22:3
  (65, 21, 4), // Apocalipse 22:5
  (65, 21, 5), // Apocalipse 22:6
  (65, 21, 11), // Apocalipse 22:12
  (65, 21, 16), // Apocalipse 22:17
  (65, 21, 19), // Apocalipse 22:20
  (65, 21, 20), // Apocalipse 22:21
];

/// Dia do ano (1‑based) de [day]. Calculado em UTC: em horário local, um dia de
/// transição de DST teria 23 h e o dia do ano sairia um a menos.
int dayOfYear(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(day.year)).inDays +
    1;

/// Seleciona o versículo do dia, girando pela lista de forma determinística.
///
/// O índice é `(diaDoAno - 1) % tamanho`: sem o `-1` a primeira entrada da lista
/// jamais seria exibida.
(int, int, int) dailyVerseFor(DateTime day) {
  final index = (dayOfYear(day) - 1) % kDailyVerses.length;
  return kDailyVerses[index];
}

/// Mesma rotação de [dailyVerseFor], mas devolvendo `null` em vez de lançar
/// [RangeError] quando a referência não existe em [books].
///
/// As traduções têm contagens de versículos diferentes entre si (por exemplo
/// 1 Reis 22 tem 53 versículos na ARA e 54 na NVI), então toda referência do
/// dia precisa ser verificada contra a tradução ativa antes do uso.
(int, int, int)? dailyVerseForIn(
  List<Book> books,
  DateTime day,
) {
  final (book, chapter, verse) = dailyVerseFor(day);
  if (book < 0 || book >= books.length) return null;
  final chapters = books[book].chapters;
  if (chapter < 0 || chapter >= chapters.length) return null;
  final verses = chapters[chapter];
  if (verse < 0 || verse >= verses.length) return null;
  return (book, chapter, verse);
}

/// Rótulo amigável de uma referência (livro + capítulo + versículo) dado o
/// índice canônico do livro e a lista de livros da versão atual.
String formatRef(List<Book> books, int book, int chapter, int? verse) {
  if (book < 0 || book >= books.length) return '';
  final b = books[book];
  if (verse != null) return '${b.abbr} ${chapter + 1}:${verse + 1}';
  return '${b.abbr} ${chapter + 1}';
}
