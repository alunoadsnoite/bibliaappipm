import 'dart:convert';

import 'package:biblia_app/content_catalog.dart';
import 'package:biblia_app/main.dart';
import 'package:biblia_app/models.dart';
import 'package:biblia_app/personal_tools.dart';
import 'package:biblia_app/reminders.dart';
import 'package:biblia_app/store.dart';
import 'package:biblia_app/tabs/bible_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class FakeReminderEngine implements ReminderEngine {
  bool permission = true;
  int scheduled = 0;
  int cancelled = 0;
  int? hour;
  bool? requested;
  @override
  Future<bool> prepare({required bool requestPermission}) async {
    requested = requestPermission;
    return permission;
  }

  @override
  Future<void> schedule(int hour, int minute) async {
    scheduled++;
    this.hour = hour;
  }

  @override
  Future<void> cancel() async {
    cancelled++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.i.load();
  });

  test('favoritos sobrevivem à reinicialização e ao backup', () async {
    await AppState.i.toggleFavorite('v:42:3:16');
    await AppState.i.load();
    expect(AppState.i.isFavorite('v:42:3:16'), isTrue);
    final backup = AppState.i.buildExportJson();
    SharedPreferences.setMockInitialValues({});
    await AppState.i.load();
    await AppState.i.importFromJson(backup);
    expect(AppState.i.isFavorite('v:42:3:16'), isTrue);
    await AppState.i.toggleFavorite('v:42:3:16');
    expect(AppState.i.isFavorite('v:42:3:16'), isFalse);
  });

  test(
    'plano com prazo considera dias inclusivos e capítulos restantes',
    () async {
      await AppState.i.setPlanDeadline(DateTime(2027, 1, 10));
      expect(AppState.i.goalForDate(DateTime(2027, 1, 1)), 119);
      AppState.i.readChapters = {for (var i = 0; i < 100; i++) 'capítulo:$i'};
      expect(AppState.i.goalForDate(DateTime(2027, 1, 1)), 109);
      expect(AppState.i.goalForDate(DateTime(2027, 1, 11)), 1089);
      await AppState.i.setPlanDeadline(null);
      expect(
        AppState.i.goalForDate(DateTime(2027, 1, 1)),
        AppState.i.dailyGoal,
      );
    },
  );

  test(
    'prazo é restaurado e pode voltar para meta manual pelo backup',
    () async {
      final original = AppState.i.buildExportJson();
      await AppState.i.setPlanDeadline(DateTime(2027, 5, 1));
      final deadlineBackup = AppState.i.buildExportJson();
      await AppState.i.importFromJson(original);
      expect(AppState.i.planDeadline, isNull);
      await AppState.i.importFromJson(deadlineBackup);
      expect(AppState.i.planDeadline, DateTime(2027, 5, 1));
    },
  );

  test('boletim isolado mescla sem duplicar nem alterar notas, músicas ou favoritos', () async {
    AppState.i.birthdays = [Birthday('Ana', 1, 1)];
    AppState.i.events = [ChurchEvent('Culto', 10, 10, 2027, '19:00', '')];
    await AppState.i.setNote('v:0:1:1', 'Minha nota');
    await AppState.i.toggleFavorite('v:0:1:1');
    final songs = AppState.i.songs.map((s) => s.id).toList();
    final raw = AppState.i.exportBoletim();
    await AppState.i.importBoletim(raw);
    await AppState.i.importBoletim(raw);
    expect(AppState.i.birthdays.length, 1);
    expect(AppState.i.events.length, 1);
    expect(AppState.i.getNote('v:0:1:1'), 'Minha nota');
    expect(AppState.i.isFavorite('v:0:1:1'), isTrue);
    expect(AppState.i.songs.map((s) => s.id), songs);
    await expectLater(
      AppState.i.importBoletim(
        jsonEncode({
          'boletim': 1,
          'eventos': [
            {'title': 'Inválido'},
          ],
        }),
      ),
      throwsA(anything),
    );
    expect(AppState.i.events.single.title, 'Culto');
  });

  test(
    'busca unificada ignora acentos, filtra categorias e evita duplicar linhas',
    () {
      const entries = [
        ContentEntry('v:0:1:1', 'Gênesis 1:1', 'Deus criou', ContentKind.bible),
        ContentEntry('h:1', 'Hino de fé', 'Deus é amor', ContentKind.hymn),
        ContentEntry('h:1:0:0', 'Hino de fé', 'Deus é amor', ContentKind.hymn),
        ContentEntry(
          'note:v:0:1:1',
          'Gênesis 1:1',
          'Minha fé',
          ContentKind.note,
        ),
      ];
      expect(searchCatalog(const SearchRequest(entries, 'fe', null)).length, 2);
      expect(
        searchCatalog(const SearchRequest(entries, 'Deus', ContentKind.bible))
            .single
            .key,
        'v:0:1:1',
      );
    },
  );

  test('lembrete solicita permissão somente por ação do usuário e pode ser cancelado', () async {
    final engine = FakeReminderEngine();
    final service = ReminderService(engine: engine);
    await service.restore(AppState.i);
    expect(engine.scheduled, 0);
    await service.configure(AppState.i, enabled: true, hour: 20, minute: 30);
    expect(engine.requested, isTrue);
    expect(service.enabled(AppState.i), isTrue);
    await service.restore(AppState.i);
    expect(engine.requested, isFalse);
    await service.configure(AppState.i, enabled: false, hour: 20, minute: 30);
    expect(service.enabled(AppState.i), isFalse);
    expect(engine.cancelled, 1);
  });

  test('permissão negada não ativa o lembrete', () async {
    final service = ReminderService(
      engine: FakeReminderEngine()..permission = false,
    );
    await expectLater(
      service.configure(AppState.i, enabled: true, hour: 8, minute: 0),
      throwsStateError,
    );
    expect(service.enabled(AppState.i), isFalse);
  });

  test('próximo lembrete mantém o horário local ao atravessar meia-noite e horário de verão', () {
    tzdata.initializeTimeZones();
    final recife = tz.getLocation('America/Recife');
    final result = LocalReminderEngine.nextTime(
      tz.TZDateTime(recife, 2026, 10, 10, 21),
      8,
      30,
    );
    expect(result.day, 11);
    expect(result.hour, 8);
    expect(result.minute, 30);
    final ny = tz.getLocation('America/New_York');
    final dst = LocalReminderEngine.nextTime(
      tz.TZDateTime(ny, 2027, 3, 13, 21),
      8,
      30,
    );
    expect(dst.day, 14);
    expect(dst.hour, 8);
  });

  testWidgets(
    'abrir capítulo não marca leitura; conclusão exige ação explícita',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: AppState.i,
              // ignore: prefer_const_constructors
              builder: (_, _) => BibleTab(initialKey: 'v:0:1:1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(AppState.i.totalRead, 0);
      await tester.tap(find.text('Concluí este capítulo'));
      await tester.pumpAndSettle();
      expect(AppState.i.isChapterRead(0, 0), isTrue);
      await tester.tap(find.text('Capítulo concluído — desmarcar'));
      await tester.pumpAndSettle();
      expect(AppState.i.totalRead, 0);
    },
  );

  testWidgets('central filtra por livro e permite abrir a leitura', (
    tester,
  ) async {
    await AppState.i.setNote('v:42:3:16', 'Minha reflexão');
    await tester.pumpWidget(
      const MaterialApp(
        home: PersonalToolsPage(view: PersonalView.annotations),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('João 3:16'), findsOneWidget);
    await tester.tap(find.text('João 3:16'));
    await tester.pumpAndSettle();
    expect(find.text('João 3'), findsOneWidget);
    expect(AppState.i.totalRead, 0);
  });

  testWidgets('navegação compacta oferece todas as abas com fonte ampliada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const BibliaApp());
    await tester.pumpAndSettle();
    expect(find.text('Mais'), findsOneWidget);
    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    expect(find.text('Config'), findsOneWidget);
    await tester.tap(find.text('Config'));
    await tester.pumpAndSettle();
  });
}
