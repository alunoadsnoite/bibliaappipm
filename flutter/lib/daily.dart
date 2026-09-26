import 'models.dart';

/// Versículos do dia (referência canônica em índices: livro, capítulo 0‑based,
/// versículo 0‑based). A rotação é determinística por dia do ano, 100% offline.
const List<(int, int, int)> kDailyVerses = [
  // --- Antigo Testamento ---
  (0, 0, 0), // Gênesis 1:1
  (0, 1, 31), // Gênesis 2:7
  (1, 13, 13), // Êxodo 14:14
  (1, 20, 3), // Êxodo 20:12
  (3, 11, 6), // Números 14:18
  (4, 30, 5), // Deuteronômio 31:6
  (5, 0, 8), // Josué 1:9
  (7, 11, 11), // Rute 1:16
  (8, 1, 27), // 1 Samuel 1:27
  (9, 13, 22), // 2 Samuel 15:25
  (10, 6, 11), // 1 Reis 8:23
  (15, 9, 2), // Neemias 9:6
  (17, 8, 3), // Jó 8:3
  (18, 0, 0), // Salmos 1:1
  (18, 18, 10), // Salmos 19:11
  (18, 22, 0), // Salmos 23:1
  (18, 22, 3), // Salmos 23:4
  (18, 26, 1), // Salmos 27:1
  (18, 33, 22), // Salmos 34:8
  (18, 36, 5), // Salmos 37:5
  (18, 36, 7), // Salmos 37:7
  (18, 39, 0), // Salmos 40:1
  (18, 45, 0), // Salmos 46:1
  (18, 45, 10), // Salmos 46:11
  (18, 50, 10), // Salmos 51:12
  (18, 55, 22), // Salmos 56:3
  (18, 61, 1), // Salmos 62:2
  (18, 67, 6), // Salmos 68:6
  (18, 70, 5), // Salmos 71:5
  (18, 72, 0), // Salmos 73:1
  (18, 72, 28), // Salmos 73:28
  (18, 85, 0), // Salmos 86:1
  (18, 85, 15), // Salmos 86:16
  (18, 91, 1), // Salmos 91:2
  (18, 91, 11), // Salmos 91:12
  (18, 96, 0), // Salmos 97:1
  (18, 102, 17), // Salmos 103:8
  (18, 103, 13), // Salmos 104:14
  (18, 117, 0), // Salmos 118:1
  (18, 118, 10), // Salmos 119:11
  (18, 118, 104), // Salmos 119:105
  (18, 120, 1), // Salmos 121:2
  (18, 126, 5), // Salmos 127:2
  (18, 138, 8), // Salmos 139:23
  (18, 144, 3), // Salmos 145:3
  (18, 146, 5), // Salmos 147:5
  (19, 0, 6), // Provérbios 1:7
  (19, 2, 4), // Provérbios 3:5
  (19, 2, 5), // Provérbios 3:6
  (19, 2, 6), // Provérbios 3:7
  (19, 3, 13), // Provérbios 4:13
  (19, 4, 23), // Provérbios 5:23
  (19, 6, 6), // Provérbios 7:6
  (19, 9, 10), // Provérbios 10:10
  (19, 12, 1), // Provérbios 13:1
  (19, 15, 1), // Provérbios 16:1
  (19, 15, 33), // Provérbios 16:33
  (19, 17, 22), // Provérbios 18:22
  (19, 22, 6), // Provérbios 23:6
  (19, 25, 1), // Provérbios 26:1
  (19, 28, 13), // Provérbios 29:13
  (20, 0, 1), // Eclesiastes 1:1
  (20, 2, 24), // Eclesiastes 3:11
  (20, 6, 9), // Eclesiastes 7:9
  (20, 11, 1), // Eclesiastes 12:1
  (20, 11, 13), // Eclesiastes 12:14
  (21, 0, 5), // Cantares 1:5
  (22, 6, 2), // Isaías 7:2
  (22, 8, 12), // Isaías 9:13
  (22, 11, 6), // Isaías 12:3
  (22, 25, 2), // Isaías 26:3
  (22, 25, 4), // Isaías 26:4
  (22, 39, 30), // Isaías 40:31
  (22, 40, 1), // Isaías 41:1
  (22, 40, 9), // Isaías 41:10
  (22, 42, 1), // Isaías 43:1
  (22, 43, 5), // Isaías 44:22
  (22, 49, 12), // Isaías 50:12
  (22, 52, 7), // Isaías 53:7
  (22, 52, 10), // Isaías 53:10
  (22, 55, 12), // Isaías 56:1
  (22, 58, 11), // Isaías 59:11
  (22, 61, 1), // Isaías 62:1
  (22, 65, 17), // Isaías 66:17
  (23, 5, 8), // Jeremias 6:8
  (23, 17, 7), // Jeremias 18:7
  (23, 28, 10), // Jeremias 29:11
  (23, 29, 11), // Jeremias 30:11
  (23, 31, 33), // Jeremias 32:33
  (23, 33, 3), // Jeremias 34:3
  (24, 2, 32), // Lamentações 3:32
  (25, 0, 1), // Ezequiel 1:1
  (25, 36, 26), // Ezequiel 37:26
  (25, 37, 14), // Ezequiel 38:14
  (26, 0, 1), // Daniel 1:1
  (26, 3, 17), // Daniel 4:17
  (26, 5, 14), // Daniel 6:14
  (26, 9, 4), // Daniel 10:4
  (26, 11, 32), // Daniel 12:32
  (27, 0, 1), // Oseias 1:1
  (27, 6, 6), // Oseias 7:6
  (28, 1, 1), // Joel 1:1
  (28, 2, 32), // Joel 3:32
  (29, 2, 1), // Amós 2:1
  (29, 5, 24), // Amós 6:24
  (30, 0, 1), // Obadias 1:1
  (31, 2, 4), // Jonas 3:4
  (32, 1, 1), // Miqueias 1:1
  (32, 6, 8), // Miqueias 7:8
  (33, 4, 5), // Naum 5:5
  (34, 3, 2), // Habacuque 4:2
  (35, 2, 4), // Sofonias 3:4
  (36, 2, 3), // Ageu 3:3
  (37, 1, 5), // Zacarias 2:5
  (37, 4, 6), // Zacarias 5:6
  (37, 8, 23), // Zacarias 9:23
  (38, 4, 5), // Malaquias 5:5
  // --- Novo Testamento ---
  (39, 0, 1), // Mateus 1:1
  (39, 0, 21), // Mateus 1:21
  (39, 3, 16), // Mateus 4:16
  (39, 4, 15), // Mateus 5:16
  (39, 5, 3), // Mateus 6:3
  (39, 5, 4), // Mateus 6:4
  (39, 5, 32), // Mateus 6:33
  (39, 6, 34), // Mateus 7:34
  (39, 7, 7), // Mateus 8:7
  (39, 8, 22), // Mateus 9:22
  (39, 9, 35), // Mateus 10:35
  (39, 10, 27), // Mateus 11:28
  (39, 11, 11), // Mateus 12:11
  (39, 12, 37), // Mateus 13:37
  (39, 13, 44), // Mateus 14:44
  (39, 16, 18), // Mateus 17:18
  (39, 18, 5), // Mateus 19:5
  (39, 18, 26), // Mateus 19:26
  (39, 20, 16), // Mateus 21:16
  (39, 22, 37), // Mateus 23:37
  (39, 24, 6), // Mateus 25:6
  (39, 25, 40), // Mateus 26:40
  (39, 26, 26), // Mateus 27:26
  (39, 27, 51), // Mateus 28:51
  (39, 28, 19), // Mateus 29:19
  (40, 0, 1), // Marcos 1:1
  (40, 1, 15), // Marcos 2:15
  (40, 3, 5), // Marcos 4:5
  (40, 4, 41), // Marcos 5:41
  (40, 8, 36), // Marcos 9:36
  (40, 9, 26), // Marcos 10:27
  (40, 10, 45), // Marcos 11:45
  (40, 12, 40), // Marcos 13:40
  (40, 14, 36), // Marcos 15:36
  (40, 15, 39), // Marcos 16:39
  (40, 16, 15), // Marcos 17:15
  (41, 0, 1), // Lucas 1:1
  (41, 0, 36), // Lucas 1:37
  (41, 0, 37), // Lucas 1:38
  (41, 1, 14), // Lucas 2:14
  (41, 1, 40), // Lucas 2:40
  (41, 2, 1), // Lucas 3:1
  (41, 3, 3), // Lucas 4:3
  (41, 4, 13), // Lucas 5:13
  (41, 6, 27), // Lucas 7:27
  (41, 7, 36), // Lucas 8:36
  (41, 9, 51), // Lucas 10:51
  (41, 10, 42), // Lucas 11:42
  (41, 12, 6), // Lucas 13:6
  (41, 15, 11), // Lucas 16:11
  (41, 16, 9), // Lucas 17:9
  (41, 18, 14), // Lucas 19:14
  (41, 21, 37), // Lucas 22:37
  (41, 22, 20), // Lucas 23:20
  (41, 23, 33), // Lucas 24:33
  (41, 24, 49), // Lucas 25:49
  (42, 0, 0), // João 1:1
  (42, 1, 29), // João 2:29
  (42, 2, 15), // João 3:16
  (42, 2, 16), // João 3:17
  (42, 3, 35), // João 4:35
  (42, 6, 35), // João 7:35
  (42, 8, 12), // João 9:12
  (42, 11, 35), // João 12:35
  (42, 12, 24), // João 13:24
  (42, 13, 5), // João 14:6
  (42, 14, 1), // João 15:1
  (42, 14, 4), // João 15:5
  (42, 14, 13), // João 15:13
  (42, 14, 15), // João 15:15
  (42, 15, 26), // João 16:26
  (42, 17, 3), // João 18:3
  (42, 19, 30), // João 20:30
  (42, 21, 25), // João 22:25
  (43, 4, 8), // Atos 5:8
  (43, 8, 22), // Atos 9:22
  (43, 10, 43), // Atos 11:43
  (43, 13, 32), // Atos 14:32
  (43, 16, 31), // Atos 17:31
  (43, 17, 26), // Atos 18:26
  (43, 20, 24), // Atos 21:24
  (43, 26, 18), // Atos 27:18
  (43, 27, 23), // Atos 28:23
  (44, 1, 8), // Romanos 2:8
  (44, 3, 23), // Romanos 4:23
  (44, 4, 7), // Romanos 5:8
  (44, 5, 1), // Romanos 6:1
  (44, 6, 23), // Romanos 7:23
  (44, 7, 27), // Romanos 8:28
  (44, 7, 29), // Romanos 8:29
  (44, 7, 37), // Romanos 8:37
  (44, 9, 1), // Romanos 10:1
  (44, 10, 9), // Romanos 11:9
  (44, 11, 1), // Romanos 12:2
  (44, 11, 36), // Romanos 12:36
  (44, 14, 10), // Romanos 15:10
  (44, 15, 13), // Romanos 16:13
  (44, 15, 14), // Romanos 16:14
  (44, 16, 20), // Romanos 17:20
  (45, 0, 1), // 1 Coríntios 1:1
  (45, 1, 30), // 1 Coríntios 2:30
  (45, 2, 2), // 1 Coríntios 3:2
  (45, 3, 16), // 1 Coríntios 4:16
  (45, 6, 14), // 1 Coríntios 7:14
  (45, 9, 22), // 1 Coríntios 10:22
  (45, 11, 1), // 1 Coríntios 12:1
  (45, 12, 3), // 1 Coríntios 13:4
  (45, 12, 13), // 1 Coríntios 13:13
  (45, 14, 57), // 1 Coríntios 15:58
  (45, 15, 1), // 1 Coríntios 16:1
  (45, 15, 22), // 1 Coríntios 16:22
  (46, 0, 1), // 2 Coríntios 1:1
  (46, 1, 3), // 2 Coríntios 2:3
  (46, 3, 17), // 2 Coríntios 4:17
  (46, 4, 4), // 2 Coríntios 5:4
  (46, 4, 16), // 2 Coríntios 5:17
  (46, 4, 17), // 2 Coríntios 5:18
  (46, 5, 21), // 2 Coríntios 6:21
  (46, 8, 9), // 2 Coríntios 9:9
  (46, 9, 15), // 2 Coríntios 10:15
  (46, 11, 23), // 2 Coríntios 12:23
  (46, 13, 13), // 2 Coríntios 14:13
  (47, 0, 1), // Gálatas 1:1
  (47, 2, 20), // Gálatas 3:20
  (47, 3, 26), // Gálatas 4:26
  (47, 3, 28), // Gálatas 4:28
  (47, 4, 21), // Gálatas 5:22
  (47, 5, 1), // Gálatas 6:1
  (47, 5, 2), // Gálatas 6:2
  (47, 5, 9), // Gálatas 6:9
  (47, 5, 14), // Gálatas 6:14
  (48, 1, 7), // Efésios 2:8
  (48, 2, 8), // Efésios 3:8
  (48, 3, 17), // Efésios 4:17
  (48, 3, 20), // Efésios 4:20
  (48, 4, 32), // Efésios 5:32
  (48, 5, 2), // Efésios 6:2
  (48, 5, 10), // Efésios 6:10
  (48, 5, 11), // Efésios 6:11
  (48, 5, 13), // Efésios 6:13
  (49, 0, 1), // Filipenses 1:1
  (49, 1, 6), // Filipenses 2:6
  (49, 2, 5), // Filipenses 3:5
  (49, 3, 5), // Filipenses 4:6
  (49, 3, 12), // Filipenses 4:13
  (49, 3, 19), // Filipenses 4:19
  (49, 4, 1), // Filipenses 5:1
  (50, 2, 22), // Colossenses 3:23
  (50, 3, 12), // Colossenses 4:12
  (50, 3, 16), // Colossenses 4:16
  (51, 1, 3), // 1 Tessalonicenses 2:3
  (51, 2, 13), // 1 Tessalonicenses 3:13
  (51, 4, 17), // 1 Tessalonicenses 5:18
  (51, 5, 9), // 1 Tessalonicenses 6:9
  (52, 3, 16), // 2 Tessalonicenses 4:16
  (52, 4, 8), // 2 Tessalonicenses 5:8
  (53, 6, 12), // 1 Timóteo 7:12
  (53, 10, 6), // 1 Timóteo 11:6
  (53, 11, 15), // 1 Timóteo 12:15
  (53, 15, 5), // 1 Timóteo 16:5
  (54, 0, 6), // 2 Timóteo 1:7
  (54, 1, 7), // 2 Timóteo 2:7
  (54, 1, 15), // 2 Timóteo 2:15
  (54, 2, 15), // 2 Timóteo 3:15
  (54, 3, 14), // 2 Timóteo 4:14
  (54, 4, 5), // 2 Timóteo 5:5
  (54, 4, 8), // 2 Timóteo 5:8
  (55, 1, 5), // Tito 2:5
  (55, 2, 11), // Tito 3:11
  (56, 6, 18), // Filemom 7:18
  (57, 0, 1), // Hebreus 1:1
  (57, 1, 1), // Hebreus 2:1
  (57, 2, 9), // Hebreus 3:9
  (57, 3, 6), // Hebreus 4:6
  (57, 3, 13), // Hebreus 4:13
  (57, 3, 14), // Hebreus 4:14
  (57, 4, 12), // Hebreus 5:12
  (57, 5, 9), // Hebreus 6:9
  (57, 10, 23), // Hebreus 11:23
  (57, 11, 6), // Hebreus 12:6
  (57, 12, 2), // Hebreus 13:2
  (57, 13, 5), // Hebreus 14:5
  (57, 13, 6), // Hebreus 14:6
  (57, 13, 8), // Hebreus 14:8
  (57, 13, 15), // Hebreus 14:15
  (57, 13, 16), // Hebreus 14:16
  (58, 0, 4), // Tiago 1:5
  (58, 1, 2), // Tiago 2:2
  (58, 1, 5), // Tiago 2:5
  (58, 1, 17), // Tiago 2:17
  (58, 1, 22), // Tiago 2:22
  (58, 1, 26), // Tiago 2:26
  (58, 3, 17), // Tiago 4:17
  (58, 4, 6), // Tiago 5:6
  (58, 4, 7), // Tiago 5:7
  (58, 4, 10), // Tiago 5:10
  (58, 4, 12), // Tiago 5:12
  (58, 5, 16), // Tiago 6:16
  (59, 1, 3), // 1 Pedro 2:3
  (59, 1, 7), // 1 Pedro 2:7
  (59, 1, 11), // 1 Pedro 2:11
  (59, 1, 22), // 1 Pedro 3:22
  (59, 3, 8), // 1 Pedro 4:8
  (59, 4, 6), // 1 Pedro 5:7
  (59, 4, 8), // 1 Pedro 5:8
  (59, 4, 10), // 1 Pedro 5:10
  (59, 4, 11), // 1 Pedro 5:11
  (60, 3, 8), // 2 Pedro 4:8
  (60, 3, 18), // 2 Pedro 4:18
  (61, 0, 8), // 1 João 1:9
  (61, 1, 3), // 1 João 2:3
  (61, 1, 9), // 1 João 2:9
  (61, 2, 15), // 1 João 3:15
  (61, 2, 29), // 1 João 3:29
  (61, 3, 2), // 1 João 4:2
  (61, 3, 3), // 1 João 4:3
  (61, 3, 10), // 1 João 4:10
  (61, 3, 16), // 1 João 4:16
  (61, 4, 7), // 1 João 5:7
  (61, 4, 8), // 1 João 5:8
  (61, 4, 12), // 1 João 5:12
  (61, 4, 13), // 1 João 5:13
  (61, 5, 14), // 1 João 6:14
  (61, 5, 20), // 1 João 6:20
  (62, 2, 2), // 2 João 3:2
  (62, 2, 3), // 2 João 3:3
  (62, 2, 5), // 2 João 3:5
  (62, 2, 6), // 2 João 3:6
  (62, 2, 12), // 2 João 3:12
  (62, 3, 9), // 2 João 4:9
  (62, 3, 15), // 2 João 4:15
  (63, 0, 1), // 3 João 1:1
  (63, 0, 2), // 3 João 1:2
  (63, 0, 11), // 3 João 1:11
  (63, 1, 14), // 3 João 2:14
  (64, 0, 9), // Judas 1:9
  (64, 0, 24), // Judas 1:24
  (64, 0, 25), // Judas 1:25
  (65, 0, 1), // Apocalipse 1:1
  (65, 1, 5), // Apocalipse 2:5
  (65, 1, 8), // Apocalipse 2:8
  (65, 2, 19), // Apocalipse 3:20
  (65, 3, 8), // Apocalipse 4:8
  (65, 3, 12), // Apocalipse 4:12
  (65, 5, 9), // Apocalipse 6:9
  (65, 7, 12), // Apocalipse 8:12
  (65, 11, 15), // Apocalipse 12:15
  (65, 12, 10), // Apocalipse 13:10
  (65, 14, 13), // Apocalipse 15:13
  (65, 16, 15), // Apocalipse 17:15
  (65, 19, 9), // Apocalipse 20:9
  (65, 20, 3), // Apocalipse 21:4
  (65, 21, 3), // Apocalipse 22:3
  (65, 21, 5), // Apocalipse 22:5
  (65, 21, 6), // Apocalipse 22:6
  (65, 21, 12), // Apocalipse 22:12
  (65, 21, 17), // Apocalipse 22:17
  (65, 21, 20), // Apocalipse 22:20
  (65, 21, 21), // Apocalipse 22:21
];

/// Seleciona o versículo do dia, girando pela lista de forma determinística.
(int, int, int) dailyVerseFor(DateTime day) {
  // Calcula o dia do ano em UTC: em horário local, um dia de transição de DST
  // teria 23 h e o dia do ano sairia um a menos.
  final dayOfYear =
      DateTime.utc(
        day.year,
        day.month,
        day.day,
      ).difference(DateTime.utc(day.year)).inDays +
      1;
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
