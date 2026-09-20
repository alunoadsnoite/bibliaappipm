import 'dart:convert';
import 'dart:io';

import 'package:biblia_app/daily.dart';
import 'package:biblia_app/store.dart';
import 'package:biblia_app/tabs/bible_tab.dart';
import 'package:biblia_app/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.i.load();
  });

  group('parseReference', () {
    test('abreviação com versículo (Jo 3:16)', () {
      final r = parseReference(AppState.i.bible, 'Jo 3:16');
      expect(r, isNotNull);
      expect(r!.book, 42); // João (canônico, 0-based)
      expect(r.chapter, 2);
      expect(r.verse, 15);
    });

    test('nome por extenso (Salmos 23)', () {
      final r = parseReference(AppState.i.bible, 'Salmos 23');
      expect(r, isNotNull);
      expect(r!.book, 18);
      expect(r.chapter, 22);
      expect(r.verse, isNull);
    });

    test('prefixo sem acento (1co13)', () {
      final r = parseReference(AppState.i.bible, '1co13');
      expect(r, isNotNull);
      expect(r!.book, 45); // 1 Coríntios
      expect(r.chapter, 12);
      expect(r.verse, isNull);
    });

    test('texto comum não é referência', () {
      expect(parseReference(AppState.i.bible, 'amor'), isNull);
      expect(parseReference(AppState.i.bible, 'Jo'), isNull);
      expect(parseReference(AppState.i.bible, 'abc 99:99'), isNull);
    });
  });

  group('versículo do dia', () {
    test('rotação determinística por data', () {
      final a = DateTime(2026, 9, 19);
      final b = DateTime(2026, 9, 19);
      expect(dailyVerseFor(a), dailyVerseFor(b));
      expect(dailyVerseFor(a) == dailyVerseFor(DateTime(2026, 9, 20)),
          isFalse);
    });

    test('todas as referências existem na tradução ativa', () {
      final bible = AppState.i.bible;
      for (final (b, c, v) in kDailyVerses) {
        expect(b, inInclusiveRange(0, bible.length - 1),
            reason: 'livro inválido em $b:$c:$v');
        expect(c, inInclusiveRange(0, bible[b].chapters.length - 1),
            reason: 'capítulo inválido em $b:$c:$v');
        expect(v, inInclusiveRange(0, bible[b].chapters[c].length - 1),
            reason: 'versículo inválido em $b:$c:$v');
      }
    });
  });

  group('posição de leitura', () {
    test('salva e recupera a última posição da versão', () async {
      await AppState.i.savePosition(3, 5);
      final p = AppState.i.lastPosition;
      expect(p, isNotNull);
      expect(p!.book, 3);
      expect(p.chapter, 5);
    });

    test('posições ficam por versão', () async {
      await AppState.i.savePosition(1, 2);
      final p = AppState.i.positionOf('ara');
      expect(p!.book, 1);
      expect(AppState.i.positionOf('nvi'), isNull);
    });
  });

  group('notas', () {
    test('cria, lê e remove uma nota', () async {
      await AppState.i.setNote('v:18:23:1', 'Meu versículo favorito.');
      expect(AppState.i.getNote('v:18:23:1'), 'Meu versículo favorito.');
      expect(AppState.i.hasNote('v:18:23:1'), isTrue);
      await AppState.i.setNote('v:18:23:1', '  ');
      expect(AppState.i.hasNote('v:18:23:1'), isFalse);
    });
  });

  group('plano de leitura', () {
    test('marca capítulo lido e soma a meta do dia uma única vez', () async {
      final before = AppState.i.totalRead;
      final today = AppState.i.todayReadCount;
      await AppState.i.markChapterRead(18, 22);
      expect(AppState.i.totalRead, before + 1);
      expect(AppState.i.todayReadCount, today + 1);
      // repetir o mesmo capítulo não conta de novo
      await AppState.i.markChapterRead(18, 22);
      expect(AppState.i.totalRead, before + 1);
      expect(AppState.i.todayReadCount, today + 1);
    });

    test('desmarcar capítulo lido remove do total', () async {
      await AppState.i.markChapterRead(18, 22);
      final afterRead = AppState.i.totalRead;
      await AppState.i.unmarkChapterRead(18, 22);
      expect(AppState.i.totalRead, afterRead - 1);
      expect(AppState.i.isChapterRead(18, 22), isFalse);
    });

    test('próximo capítulo a ler é o primeiro não lido', () async {
      AppState.i.markChapterRead(0, 0);
      AppState.i.markChapterRead(0, 1);
      final next = AppState.i.nextUnreadChapter;
      expect(next, isNotNull);
      expect(next!.$1, 0);
      expect(next.$2, 2);
    });

    test('streak conta dias seguidos com leitura', () async {
      AppState.i.markChapterRead(0, 0); // hoje
      final byDay = jsonDecode(
          AppState.i.prefs.getString('reads_by_day')!) as Map<String, dynamic>;
      String key(DateTime d) => '${d.year}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      final d1 = DateTime.now().subtract(const Duration(days: 1));
      final d2 = DateTime.now().subtract(const Duration(days: 2));
      byDay[key(d1)] = 1;
      byDay[key(d2)] = 1;
      await AppState.i.prefs.setString('reads_by_day', jsonEncode(byDay));
      await AppState.i.load();
      expect(AppState.i.streak, greaterThanOrEqualTo(3));
    });

    test('meta diária padrão e personalizada', () {
      expect(AppState.i.dailyGoal, kDefaultDailyGoal);
      AppState.i.setDailyGoal(7);
      expect(AppState.i.dailyGoal, 7);
      AppState.i.setDailyGoal(99);
      expect(AppState.i.dailyGoal, 10);
    });
  });

  group('migração de chaves canônicas', () {
    test('converte destaques e notas do formato antigo', () async {
      SharedPreferences.setMockInitialValues({
        'hl_v:Jo 3:16': 1,
        'notes': jsonEncode({'v:Sl 23:1': 'Lindo.'}),
      });
      await AppState.i.load();
      expect(AppState.i.getHighlight('v:42:3:16'), 1);
      expect(AppState.i.getHighlight('v:Jo 3:16'), -1);
      expect(AppState.i.getNote('v:18:23:1'), 'Lindo.');
    });

    test('normaliza chaves importadas de backups antigos', () async {
      final json = AppState.i.buildExportJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      data['highlights'] = {'v:Jo 3:16': 3};
      data['notes'] = {'v:Jo 3:16': 'Anotado no backup antigo.'};
      await AppState.i.importFromJson(jsonEncode(data));
      expect(AppState.i.getHighlight('v:42:3:16'), 3);
      expect(AppState.i.getNote('v:42:3:16'), 'Anotado no backup antigo.');
    });
  });

  group('backup', () {
    test('exporta e importa destaques, notas e progresso', () async {
      await AppState.i.setHighlight('v:42:3:16', 2);
      await AppState.i.setNote('v:42:3:16', 'Anotado.');
      await AppState.i.markChapterRead(0, 0);
      await AppState.i.savePosition(1, 1);

      final json = AppState.i.buildExportJson();

      SharedPreferences.setMockInitialValues({});
      await AppState.i.load();

      expect(AppState.i.totalRead, 0);
      expect(AppState.i.getHighlight('v:42:3:16'), -1);

      await AppState.i.importFromJson(json);

      expect(AppState.i.getHighlight('v:42:3:16'), 2);
      expect(AppState.i.getNote('v:42:3:16'), 'Anotado.');
      expect(AppState.i.totalRead, 1);
      expect(AppState.i.lastPosition!.chapter, 1);
    });
  });

  group('comparação de traduções', () {
    test('retorna o mesmo versículo nas 5 versões', () async {
      final rows = await AppState.i.comparedVerses(42, 2, 15);
      expect(rows.length, 5);
      expect(rows.map((r) => r.$1).toList(),
          ['ARA', 'NVI', 'NTLH', 'JFAA', 'BKJ']);
      for (final (_, text) in rows) {
        expect(text.trim(), isNotEmpty);
      }
    });
  });

  group('versão do app', () {
    test('kAppVersion corresponde ao pubspec', () {
      final pub = File('pubspec.yaml').readAsStringSync();
      final m = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(pub);
      expect(m, isNotNull);
      expect(kAppVersion, m!.group(1)!.trim().split('+').first);
    });
  });

  group('tema', () {
    test('tema do sistema não existe mais', () {
      expect(kThemeNames, isNot(contains('Sistema')));
      expect(kThemeNames.length, kThemes.length);
    });

    test('tema persistido inválido (Sistema removido) é normalizado',
        () async {
      SharedPreferences.setMockInitialValues({'theme': 4});
      await AppState.i.load();
      expect(AppState.i.themeIndex, 0);
    });

    test('importar backup com tema inválido não quebra', () async {
      final json = AppState.i.buildExportJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      data['theme'] = 4;
      await AppState.i.importFromJson(jsonEncode(data));
      expect(AppState.i.themeIndex, 0);
    });
  });
}