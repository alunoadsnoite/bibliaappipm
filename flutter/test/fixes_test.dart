import 'dart:convert';

import 'package:biblia_app/common.dart';
import 'package:biblia_app/daily.dart';
import 'package:biblia_app/models.dart';
import 'package:biblia_app/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.i.load();
  });

  group('stripDiacritics / busca sem acento', () {
    test('remove acentos e cedilha', () {
      expect(
        stripDiacritics('É água do correio? Não.'),
        'É agua do correio? Nao.',
      );
      expect(stripDiacritics('João Ferreira'), 'Joao Ferreira');
    });

    test('foldSortKey compara ignorando acento e caixa', () {
      expect(foldSortKey('Água'), foldSortKey('agua'));
      expect(foldSortKey('Salvação'), foldSortKey('salvacao'));
    });
  });

  group('versículo do dia', () {
    test('a lista cabe em um ano (≤ 366 entradas)', () {
      // Rotações além do dia 366 são inalcançáveis e ficariam mortas.
      expect(kDailyVerses.length, lessThanOrEqualTo(366));
    });

    test('todos os dias de um ano bissexto passam por todas as entradas', () {
      final seen = <(int, int, int)>{};
      for (var i = 1; i <= 366; i++) {
        final day = DateTime(2028, 1, 1); // 2028 é bissexto
        final d = day.add(Duration(days: i - 1));
        seen.add(dailyVerseFor(d));
      }
      expect(
        seen.length,
        kDailyVerses.length,
        reason: 'alguma entrada da lista nunca é exibida',
      );
    });

    test('a rotação cobre o dia 365 comum e o 366 bissexto', () {
      final comum = DateTime(2027, 12, 31); // dia 365
      final bissexto = DateTime(2028, 12, 31); // dia 366
      expect(dayOfYear(comum), 365);
      expect(dayOfYear(bissexto), 366);
      expect(dailyVerseForIn(AppState.i.bible, bissexto), isNotNull);
    });
  });

  group('destaques', () {
    test('limpar um destaque remove a preferência (sem tombstone)', () async {
      await AppState.i.setHighlight('v:42:3:16', 3);
      expect(AppState.i.prefs.containsKey('hl_v:42:3:16'), isTrue);

      await AppState.i.setHighlight('v:42:3:16', -1);
      expect(AppState.i.prefs.containsKey('hl_v:42:3:16'), isFalse);
      expect(AppState.i.getHighlight('v:42:3:16'), -1);
    });

    test('tombstones antigos ficam fora do backup', () async {
      SharedPreferences.setMockInitialValues({
        'hl_v:42:3:16': -1, // lixo do formato antigo
        'hl_v:18:23:1': 2,
      });
      await AppState.i.load();
      final data =
          jsonDecode(AppState.i.buildExportJson()) as Map<String, dynamic>;
      final highlights = (data['highlights'] as Map).map(
        (k, v) => MapEntry(k.toString(), v),
      );
      expect(highlights.containsKey('v:42:3:16'), isFalse);
      expect(highlights['v:18:23:1'], 2);
    });
  });

  group('plano de leitura — dia da leitura', () {
    test('desmarcar debita o dia em que o capítulo foi lido', () async {
      final yesterday = _key(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'plan_enabled': true,
        'read_day_by_chapter': jsonEncode({'1:2': yesterday}),
        'reads_by_day': jsonEncode({yesterday: 1}),
        'read_chapters': jsonEncode(['1:2']),
      });
      await AppState.i.load();

      await AppState.i.unmarkChapterRead(1, 2);

      expect(AppState.i.isChapterRead(1, 2), isFalse);
      final byDay = jsonDecode(
        AppState.i.prefs.getString('reads_by_day')!,
      ) as Map<String, dynamic>;
      expect(byDay[yesterday], 0, reason: 'deve debitar de ontem, não de hoje');
      expect(AppState.i.todayReadCount, 0);
    });

    test('marca registra o dia da leitura', () async {
      await AppState.i.markChapterRead(1, 2);
      final dayMap = jsonDecode(
        AppState.i.prefs.getString('read_day_by_chapter')!,
      ) as Map<String, dynamic>;
      expect(dayMap['1:2'], _key(DateTime.now()));
    });
  });

  group('backup', () {
    test('falha de gravação recupera dados anteriores', () async {
      final store = _FailOnceStore();
      SharedPreferencesStorePlatform.instance = store;
      SharedPreferences.resetStatic();
      await AppState.i.load();
      await AppState.i.setNote('v:0:1:1', 'original');
      store.failNextNotes = true;
      await expectLater(
        AppState.i.importFromJson(
          jsonEncode({
            'export': 1,
            'highlights': {'v:0:1:1': 2},
            'notes': {'v:0:1:1': 'alterada'},
          }),
        ),
        throwsStateError,
      );
      expect(AppState.i.getNote('v:0:1:1'), 'original');
      expect(AppState.i.getHighlight('v:0:1:1'), -1);
      expect(AppState.i.prefs.getString('backup_before_restore'), isNotNull);
      await AppState.i.load();
      expect(AppState.i.getNote('v:0:1:1'), 'original');
    });

    test('músicas novas iguais têm IDs distintos', () {
      expect(Song.create('A', 'B').id, isNot(Song.create('A', 'B').id));
    });

    test('seção inválida não altera notas nem destaques', () async {
      await AppState.i.setNote('v:0:1:1', 'original');
      final data = {
        'export': 1,
        'notes': {'v:0:1:1': 'alterada'},
        'highlights': {'v:0:1:1': 2},
        'songs': 'inválido',
      };
      await expectLater(
        AppState.i.importFromJson(jsonEncode(data)),
        throwsA(anything),
      );
      expect(AppState.i.getNote('v:0:1:1'), 'original');
      expect(AppState.i.getHighlight('v:0:1:1'), -1);
    });

    test('editar música mantém ID e vínculos após recarregar', () async {
      final song = Song('Título', 'Letra');
      AppState.i.songs = [song];
      final key = 's:${song.id}:0';
      await AppState.i.setNote(key, 'Minha nota');
      await AppState.i.setHighlight(key, 2);
      song.title = 'Novo título';
      song.lyrics = 'Nova letra';
      await AppState.i.saveSongs();
      await AppState.i.load();
      expect(AppState.i.songs.single.id, song.id);
      expect(AppState.i.getNote(key), 'Minha nota');
      expect(AppState.i.getHighlight(key), 2);
    });

    test('backup antigo recupera contagens sem duplicar', () async {
      final raw = jsonEncode({
        'export': 1,
        'read_chapters': ['0:0'],
        'reads_by_day': {'2026-10-01': 1},
      });
      await AppState.i.importFromJson(raw);
      await AppState.i.importFromJson(raw);
      expect(AppState.i.readsByDay['2026-10-01'], 1);
    });

    test('restaurar preserva o dia local de capítulo já lido', () async {
      await AppState.i.markChapterRead(0, 0);
      final original = AppState.i.readDayByChapter['0:0'];
      await AppState.i.importFromJson(
        jsonEncode({
          'export': 1,
          'read_chapters': ['0:0'],
          'read_day_by_chapter': {'0:0': '2020-01-01'},
          'reads_by_day': {'2020-01-01': 1},
        }),
      );
      expect(AppState.i.readDayByChapter['0:0'], original);
      expect(AppState.i.todayReadCount, 1);
    });

    test('exporta e restaura as configurações do plano', () async {
      AppState.i.setPlanEnabled(false);
      AppState.i.setDailyGoal(2);
      final json = AppState.i.buildExportJson();

      SharedPreferences.setMockInitialValues({});
      await AppState.i.load();
      expect(AppState.i.planEnabled, isTrue);
      expect(AppState.i.dailyGoal, kDefaultDailyGoal);

      await AppState.i.importFromJson(json);
      expect(AppState.i.planEnabled, isFalse);
      expect(AppState.i.dailyGoal, 2);
    });

    test('restaurar não apaga seções ausentes do backup', () async {
      AppState.i.birthdays
        ..clear()
        ..add(Birthday('Ana', 5, 10));
      AppState.i.events
        ..clear()
        ..add(ChurchEvent('Culto de domingo', 10, 3, 2027, '19:00', ''));

      final data =
          jsonDecode(AppState.i.buildExportJson()) as Map<String, dynamic>;
      // Backup editado à mão sem as listas do boletim.
      data.remove('aniversariantes');
      data.remove('eventos');
      final json = jsonEncode(data);

      // Sem resetar o estado local: um backup parcial não pode apagar o que
      // já estava na memória.
      await AppState.i.importFromJson(json);

      expect(AppState.i.birthdays.single.name, 'Ana');
      expect(AppState.i.events.single.title, 'Culto de domingo');
    });

    test('restaurar não conta em dobro capítulos já lidos', () async {
      final today = _key(DateTime.now());
      SharedPreferences.setMockInitialValues({
        'plan_enabled': true,
        'plan_daily_goal': 4,
        'read_chapters': jsonEncode(['0:0']),
        'reads_by_day': jsonEncode({today: 1}),
        'read_day_by_chapter': jsonEncode({'0:0': today}),
      });
      await AppState.i.load();

      final data =
          jsonDecode(AppState.i.buildExportJson()) as Map<String, dynamic>;
      // Reimporta o próprio backup: a contagem do dia não pode dobrar.
      await AppState.i.importFromJson(jsonEncode(data));

      expect(AppState.i.todayReadCount, 1);
      expect(AppState.i.totalRead, 1);
    });
  });

  group('tradução', () {
    test('código fora da lista é ignorado sem tocar no estado', () async {
      final before = AppState.i.version;
      await AppState.i.setVersion('xyz');
      expect(AppState.i.version, before);
      expect(
        AppState.i.prefs.containsKey('biblia_version'),
        isFalse,
        reason: 'o código inválido não pode ser persistido',
      );
    });

    test('posições ficam por versão e são cached', () async {
      await AppState.i.savePosition(3, 5);
      expect(AppState.i.positionOf('blivre')!.book, 3);
      expect(AppState.i.positionOf('bpm'), isNull);
      // Segunda leitura usa o cache (mesmo valor, sem decodificar de novo).
      expect(AppState.i.positionOf('blivre')!.chapter, 5);
    });

    test('importar posições limpa o cache em memória', () async {
      await AppState.i.savePosition(1, 1);
      final json = AppState.i.buildExportJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      data['positions'] = {
        'blivre': {'b': 9, 'c': 3},
      };
      data['version'] = 'blivre';
      await AppState.i.importFromJson(jsonEncode(data));
      expect(AppState.i.lastPosition!.book, 9);
    });
  });

  group('meta diária', () {
    test('valor fora da faixa é limitado de 1 a 10', () async {
      SharedPreferences.setMockInitialValues({'plan_daily_goal': 99});
      await AppState.i.load();
      expect(AppState.i.dailyGoal, 10);

      AppState.i.setDailyGoal(0);
      expect(AppState.i.dailyGoal, 1);
    });
  });
}

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class _FailOnceStore extends InMemorySharedPreferencesStore {
  _FailOnceStore() : super.empty();
  bool failNextNotes = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (failNextNotes && key == 'flutter.notes') {
      failNextNotes = false;
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}
