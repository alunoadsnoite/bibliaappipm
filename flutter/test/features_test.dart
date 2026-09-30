import 'dart:convert';
import 'dart:io';

import 'package:biblia_app/daily.dart';
import 'package:biblia_app/models.dart';
import 'package:biblia_app/store.dart';
import 'package:biblia_app/tabs/bible_tab.dart';
import 'package:biblia_app/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

    test('a primeira entrada da lista é alcançável', () {
      // 1 de janeiro é o dia 1 e precisa cair no índice 0: com
      // `dayOfYear % length` a primeira entrada ficaria inalcançável.
      expect(dayOfYear(DateTime(2026, 1, 1)), 1);
      expect(dailyVerseFor(DateTime(2026, 1, 1)), kDailyVerses.first);
      expect(dailyVerseFor(DateTime(2027, 1, 1)), kDailyVerses.first);
    });

    test('sem referências repetidas', () {
      expect(kDailyVerses.toSet().length, kDailyVerses.length);
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

    test('todas as referências existem em todas as traduções', () async {
      // As traduções discordam na contagem de versículos (1 Reis 22 tem 53 na
      // ARA e 54 na NVI, por exemplo), então uma referência válida só na ARA
      // ainda quebraria o app ao trocar de tradução.
      for (final entry in kVersionAssets.entries) {
        final raw =
            jsonDecode(await rootBundle.loadString(entry.value))
                as List<dynamic>;
        final books = raw
            .map((e) => Book.fromJson(e as Map<String, dynamic>))
            .toList();
        expect(books.length, 66, reason: '${entry.key} com livros incompletos');
        for (final (b, c, v) in kDailyVerses) {
          expect(b, inInclusiveRange(0, books.length - 1),
              reason: '${entry.key}: livro $b inválido em $b:$c:$v');
          expect(c, inInclusiveRange(0, books[b].chapters.length - 1),
              reason: '${entry.key}: capítulo $c inválido em $b:$c:$v');
          expect(v, inInclusiveRange(0, books[b].chapters[c].length - 1),
              reason: '${entry.key}: versículo $v inválido em $b:$c:$v');
        }
      }
    });

    test('a rotação do ano inteiro é resolvível na tradução ativa', () {
      final bible = AppState.i.bible;
      var day = DateTime(2026, 1, 1);
      for (var i = 0; i < 365; i++) {
        expect(dailyVerseForIn(bible, day), isNotNull,
            reason: 'sem versículo para $day');
        day = day.add(const Duration(days: 1));
      }
    });
  });

  group('widget do versículo do dia', () {
    // O widget não lê as preferências do shared_preferences: o plugin grava no
    // arquivo "FlutterSharedPreferences" com prefixo "flutter." (ou em
    // DataStore). O texto precisa chegar pelo canal nativo, senão o widget
    // fica preso no placeholder.
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('envia texto, referência e data de hoje ao widget no load',
        () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('br.com.valdenor.bibliaapp/widget'),
              (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('br.com.valdenor.bibliaapp/widget'), null));

      await AppState.i.load();

      final sync = calls.where((c) => c.method == 'syncWidget').toList();
      expect(sync, isNotEmpty,
          reason: 'o app precisa pedir o sync do widget ao abrir');

      final args = (sync.first.arguments as Map).cast<String, dynamic>();
      expect((args['text'] as String).trim(), isNotEmpty);
      expect((args['ref'] as String).trim(), isNotEmpty);
      expect(args['date'], DateTime.now().toIso8601String().split('T')[0]);
    });

    test('o texto enviado é o mesmo da tela inicial', () async {
      final args = <String, dynamic>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('br.com.valdenor.bibliaapp/widget'),
              (call) async {
        if (call.method == 'syncWidget') {
          args
            ..clear()
            ..addAll((call.arguments as Map).cast<String, dynamic>());
        }
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('br.com.valdenor.bibliaapp/widget'), null));

      await AppState.i.load();

      final bible = AppState.i.bible;
      final (b, c, v) = dailyVerseFor(DateTime.now());
      expect(args['text'], bible[b].chapters[c][v]);
      expect(args['ref'], formatRef(bible, b, c, v));
    });

    test('trocar de tradução reenvia o versículo na nova versão', () async {
      final texts = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('br.com.valdenor.bibliaapp/widget'),
              (call) async {
        if (call.method == 'syncWidget') {
          texts.add(((call.arguments as Map)['text']) as String);
        }
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('br.com.valdenor.bibliaapp/widget'), null));

      await AppState.i.setVersion('nvi');
      final nvi = AppState.i.bible;
      final (b, c, v) = dailyVerseFor(DateTime.now());
      expect(texts.last, nvi[b].chapters[c][v]);
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

    test('restaura tamanho de letra e preferências de leitura', () async {
      final level = kFontLevels[2];
      AppState.i.setFontScale(level);
      AppState.i.setRedLetterEnabled(true);
      AppState.i.setTtsRate(0.7);
      AppState.i.setTtsPitch(1.5);
      AppState.i.setTtsVoice('female');

      final json = AppState.i.buildExportJson();

      SharedPreferences.setMockInitialValues({});
      await AppState.i.load();
      expect(AppState.i.fontScale, isNot(level));

      await AppState.i.importFromJson(json);

      expect(AppState.i.fontScale, level);
      expect(AppState.i.redLetterEnabled, isTrue);
      expect(AppState.i.ttsRate, closeTo(0.7, 0.001));
      expect(AppState.i.ttsPitch, closeTo(1.5, 0.001));
      expect(AppState.i.ttsVoice, 'female');
    });
  });

  group('músicas', () {
    test('o id não depende da posição na lista', () {
      final a = Song('Opressor', 'Versículo um\nVersículo dois');
      final b = Song('Outra', 'Só um versículo');
      expect(AppState.songId(a), AppState.songId(Song('Opressor',
          'Versículo um\nVersículo dois')));
      expect(AppState.songId(a), isNot(AppState.songId(b)));
    });

    test('nota de uma música sobrevive à exclusão de outra', () async {
      AppState.i.songs
        ..clear()
        ..add(Song('A', 'la'))
        ..add(Song('B', 'lb'));
      await AppState.i.saveSongs();

      final key = 's:${AppState.songId(AppState.i.songs[1])}:0';
      await AppState.i.setNote(key, 'nota da B');

      // Exclui a primeira música: a B passa a ocupar o índice 0.
      AppState.i.songs.removeAt(0);
      await AppState.i.saveSongs();
      await AppState.i.load();

      expect(AppState.i.songs.single.title, 'B');
      expect(AppState.i.getNote(key), 'nota da B');
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

  group('letras vermelhas', () {
    test('dataset carrega com capítulos e versículos', () {
      expect(AppState.i.redLetter, isNotEmpty);
      final joao = AppState.i.redLetter['43'];
      expect(joao, isNotNull);
      expect(joao!['3'], contains(16));
    });

    test('isRedLetter reconhece fala de Jesus e de Deus', () {
      expect(AppState.i.isRedLetter(42, 2, 15), isTrue);
      expect(AppState.i.isRedLetter(0, 2, 14), isTrue);
      expect(AppState.i.isRedLetter(0, 2, 0), isFalse);
    });

    test('versículo sem fala divina não é vermelho', () {
      expect(AppState.i.isRedLetter(42, 3, 0), isFalse);
      expect(AppState.i.isRedLetter(18, 0, 0), isFalse);
    });

    test('setRedLetterEnabled liga, persiste e notifica', () async {
      AppState.i.setRedLetterEnabled(true);
      expect(AppState.i.redLetterEnabled, isTrue);
      expect(AppState.i.prefs.getBool('red_letter_enabled'), isTrue);
      AppState.i.setRedLetterEnabled(false);
      expect(AppState.i.redLetterEnabled, isFalse);
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
    test('tema Sistema existe como último índice', () {
      expect(kThemeNames.last, 'Sistema');
      expect(kSystemThemeIndex, kThemes.length);
      expect(kThemeNames.length, kThemes.length + 1);
    });

    test('tema persistido fora da faixa é normalizado', () async {
      SharedPreferences.setMockInitialValues({'theme': 99});
      await AppState.i.load();
      expect(AppState.i.themeIndex, 0);
    });

    test('importar backup com tema inválido não quebra', () async {
      AppState.i.setTheme(0);
      final json = AppState.i.buildExportJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      data['theme'] = 99;
      await AppState.i.importFromJson(jsonEncode(data));
      expect(AppState.i.themeIndex, 0);
    });

    test('importar backup com tema válido é aplicado', () async {
      AppState.i.setTheme(0);
      final json = AppState.i.buildExportJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      data['theme'] = 2;
      await AppState.i.importFromJson(jsonEncode(data));
      expect(AppState.i.themeIndex, 2);
    });
  });
}