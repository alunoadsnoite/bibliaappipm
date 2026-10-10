import 'package:biblia_app/store.dart';
import 'package:biblia_app/tts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    // Isola o estado global de preferências de voz entre os testes (evita
    // dependência de ordem quando a suíte roda com seeds aleatórios).
    AppState.i.ttsRate = 0.5;
    AppState.i.ttsPitch = 1.0;
    AppState.i.ttsVoice = 'default';
  });

  group('TtsService — estado inicial', () {
    test('phase inicial é none e index é null', () {
      final svc = TtsService.createForTest();
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.index.value, isNull);
      expect(svc.isActive, isFalse);
    });

    test('stop com phase none não quebra', () async {
      final svc = TtsService.createForTest();
      svc.phase.value = TtsPhase.none;
      await svc.stop();
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.isActive, isFalse);
    });

    test('speakOne sem atividade vai para playing e volta para none', () async {
      final engine = FakeTtsEngine();
      final svc = TtsService.createForTest(fake: engine);
      await svc.speakOne('olá');
      expect(engine.spoken, ['olá']);
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.index.value, isNull);
    });
  });

  group('TtsService — stop e pause', () {
    test('stop com phase playing redefine para none', () async {
      final svc = TtsService.createForTest();
      svc.phase.value = TtsPhase.playing;
      svc.index.value = 3;
      await svc.stop();
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.index.value, isNull);
      expect(svc.isActive, isFalse);
      expect(svc.queue, isEmpty);
      expect(svc.cursor, 0);
    });

    test('pause só afeta se playing', () async {
      final svc = TtsService.createForTest();
      svc.phase.value = TtsPhase.playing;
      await svc.pause();
      expect(svc.phase.value, TtsPhase.paused);
      expect(svc.isActive, isTrue);
    });

    test('pause com phase none não faz nada', () async {
      final svc = TtsService.createForTest();
      svc.phase.value = TtsPhase.none;
      await svc.pause();
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.isActive, isFalse);
    });

    test('pause define _cancel=true', () async {
      final svc = TtsService.createForTest();
      svc.phase.value = TtsPhase.playing;
      await svc.pause();
      expect(svc.cancel, isTrue);
    });
  });

  group('TtsService — resume', () {
    test('resume só afeta se paused', () async {
      // Usa engine async para que o loop possa ser interrompido.
      final engine = FakeTtsEngine(async: true);
      final svc = TtsService.createForTest(fake: engine);
      svc.phase.value = TtsPhase.paused;
      svc.queue = ['x'];
      svc.cursor = 0;
      svc.cancel = true;
      await svc.resume();
      // Após completar o loop (engine async completa em microtask),
      // phase volta para none e queue é limpa.
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.queue, isEmpty);
      expect(svc.cursor, 0);
    });

    test('resume com phase não-paused não faz nada', () async {
      final svc = TtsService.createForTest();
      svc.phase.value = TtsPhase.playing;
      await svc.resume();
      expect(svc.phase.value, TtsPhase.playing);
      expect(svc.isActive, isTrue);
    });

    test('resume com fase paused mas fila vazia não altera estado', () async {
      final svc = TtsService.createForTest();
      svc.phase.value = TtsPhase.paused;
      await svc.resume();
      expect(svc.phase.value, TtsPhase.paused);
      expect(svc.isActive, isTrue);
    });

    test('resume com phase none não faz nada', () async {
      final svc = TtsService.createForTest();
      svc.phase.value = TtsPhase.none;
      await svc.resume();
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.isActive, isFalse);
    });
  });

  group('TtsService — playChapter', () {
    test('playChapter vazio é no-op', () async {
      final svc = TtsService.createForTest();
      svc.phase.value = TtsPhase.none;
      await svc.playChapter([]);
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.isActive, isFalse);
    });

    test('playChapter com itens reproduz a sequência completa', () async {
      final engine = FakeTtsEngine();
      final svc = TtsService.createForTest(fake: engine);
      svc.phase.value = TtsPhase.none;
      await svc.playChapter(['um', 'dois', 'três']);
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.index.value, isNull);
      expect(engine.spoken, ['um', 'dois', 'três']);
      expect(svc.queue, isEmpty);
      expect(svc.cursor, 0);
    });

    test('playChapter preenche _queue e depois limpa', () async {
      final svc = TtsService.createForTest();
      svc.phase.value = TtsPhase.none;
      await svc.playChapter(['a', 'b']);
      // Após o loop completar, _queue deve ser limpo e _cursor resetado
      expect(svc.queue, isEmpty);
      expect(svc.cursor, 0);
      expect(svc.phase.value, TtsPhase.none);
    });

    test('playChapter encerra reprodução anterior ativa', () async {
      // Engine async permite observar a interrupção entre itens.
      final engine = FakeTtsEngine(async: true);
      final svc = TtsService.createForTest(fake: engine);
      // Inicia uma reprodução com vários itens — não await para testar interrupção.
      svc.playChapter(['antes1', 'antes2', 'antes3', 'antes4', 'antes5']);
      // Aguarda alguns microtasks para que o loop processe alguns itens.
      await Future<void>.microtask(() {});
      await Future<void>.microtask(() {});
      // Inicia outra reprodução — a anterior deve ser interrompida pelo stop().
      svc.playChapter(['depois']);
      // Deixamos completar tudo.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Pelo menos o último playChapter deve ter falado.
      expect(engine.spoken, isNotEmpty);
      // Os últimos itens devem ser do último playChapter.
      expect(engine.spoken.sublist(engine.spoken.length - 1), ['depois']);
    });

    test('playChapter interrompe DE VERDADE a reprodução anterior', () async {
      // Antes da correção de sessão: um loop antigo retomado após o stop()
      // continuava falando os itens antigos no meio da nova reprodução.
      final engine = FakeTtsEngine(async: true);
      final svc = TtsService.createForTest(fake: engine);
      svc.playChapter(['antes1', 'antes2', 'antes3']);
      await Future<void>.microtask(() {});
      await Future<void>.microtask(() {});
      svc.playChapter(['depois']);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Nada da reprodução antiga pode aparecer depois de 'depois'.
      final lastDepois = engine.spoken.lastIndexOf('depois');
      expect(lastDepois, isNot(-1));
      for (var i = lastDepois + 1; i < engine.spoken.length; i++) {
        expect(engine.spoken[i], isNot(startsWith('antes')));
      }
      // O estado final fica são após a interrupção.
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.queue, isEmpty);
      expect(svc.cursor, 0);
    });

    test('pausa durante a preparação cancela a fala pendente', () async {
      // Regressão: _speakOne reescrevia `cancel = false` após o setup async,
      // fazendo o áudio continuar com a UI pausada.
      final engine = FakeTtsEngine(async: true);
      final svc = TtsService.createForTest(fake: engine);
      final f = svc.playChapter(['x']);
      await svc.pause();
      expect(svc.phase.value, TtsPhase.paused);
      expect(svc.cancel, isTrue);
      await f;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        engine.spoken,
        isEmpty,
        reason: 'nada deve ser falado depois da pausa',
      );
    });

    test('resume não recomeça um versículo único do zero', () async {
      // speakOne trata o texto como fila de um item: pausar e retomar
      // deve completar a leitura (não travar no botão play).
      final engine = FakeTtsEngine(async: true);
      final svc = TtsService.createForTest(fake: engine);
      final f = svc.speakOne('versículo');
      await svc.pause();
      expect(svc.phase.value, TtsPhase.paused);
      await svc.resume();
      await f;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.queue, isEmpty);
      expect(engine.spoken, contains('versículo'));
    });

    test('resume retoma do cursor preservado, sem pular versículo', () async {
      final engine = FakeTtsEngine();
      final svc = TtsService.createForTest(fake: engine);
      svc.phase.value = TtsPhase.paused;
      svc.queue = ['a', 'b', 'c'];
      svc.cursor = 2;
      svc.cancel = true;
      await svc.resume();
      expect(engine.spoken, ['c']);
      expect(svc.phase.value, TtsPhase.none);
      expect(svc.queue, isEmpty);
    });

    test('resume de capítulo já concluído não reinicia sozinho', () async {
      // Regressão: cursor no fim + resume reiniciava o capítulo do começo.
      final engine = FakeTtsEngine();
      final svc = TtsService.createForTest(fake: engine);
      svc.phase.value = TtsPhase.paused;
      svc.queue = ['a'];
      svc.cursor = 1;
      svc.cancel = true;
      await svc.resume();
      expect(engine.spoken, isEmpty);
      expect(svc.phase.value, TtsPhase.paused);
    });
  });

  group('TtsService — idioma', () {
    test('usa pt-BR e fallback para pt quando indisponível', () async {
      final engine = FakeTtsEngine();
      engine.setAvailable(false);
      final svc = TtsService.createForTest(fake: engine);
      await svc.playChapter(['teste']);
      expect(engine.languagesSet, ['pt-BR', 'pt']);
    });

    test('não refaz fallback após primeiro uso', () async {
      final engine = FakeTtsEngine();
      engine.setAvailable(false);
      final svc = TtsService.createForTest(fake: engine);
      await svc.playChapter(['um']);
      await svc.playChapter(['dois']);
      // Apenas uma chamada de setLanguage por uso, pois _langReady=true
      expect(engine.languagesSet, ['pt-BR', 'pt']);
    });
  });

  group('TtsService — preferências de voz', () {
    test('aplica velocidade e tom do AppState', () async {
      AppState.i.ttsRate = 0.6;
      AppState.i.ttsPitch = 1.2;
      AppState.i.ttsVoice = 'default';
      final engine = FakeTtsEngine();
      final svc = TtsService.createForTest(fake: engine);
      await svc.speakOne('teste');
      expect(engine.rates, [0.6]);
      expect(engine.pitches, [1.2]);
      expect(engine.selectedVoiceName, isNull);
    });

    test('seleciona voz feminina em português quando pedida', () async {
      AppState.i.ttsVoice = 'female';
      final engine = FakeTtsEngine();
      final svc = TtsService.createForTest(fake: engine);
      await svc.speakOne('teste');
      expect(engine.selectedVoiceName, 'pt-BR-female');
      expect(engine.selectedVoiceLocale, 'pt-BR');
    });

    test('seleciona voz masculina em português quando pedida', () async {
      AppState.i.ttsVoice = 'male';
      final engine = FakeTtsEngine();
      final svc = TtsService.createForTest(fake: engine);
      await svc.speakOne('teste');
      expect(engine.selectedVoiceName, 'pt-BR-male');
    });

    test('adivinha o gênero pelo nome quando o campo gender falta', () async {
      AppState.i.ttsVoice = 'male';
      final engine = FakeTtsEngine()
        ..availableVoices = [
          {'name': 'voz-masculina-pt', 'locale': 'pt-BR'},
          {'name': 'voz-feminina-pt', 'locale': 'pt-BR'},
        ];
      final svc = TtsService.createForTest(fake: engine);
      await svc.speakOne('teste');
      expect(engine.selectedVoiceName, 'voz-masculina-pt');
    });

    test('não seleciona voz quando não há nenhuma em português', () async {
      AppState.i.ttsVoice = 'female';
      final engine = FakeTtsEngine()
        ..availableVoices = [
          {'name': 'goog-EN', 'locale': 'en-US', 'gender': 'female'},
        ];
      final svc = TtsService.createForTest(fake: engine);
      await svc.speakOne('teste');
      expect(engine.selectedVoiceName, isNull);
    });

    test('sem voz feminina instalada, o tom simula o gênero', () async {
      AppState.i.ttsPitch = 1.0;
      AppState.i.ttsVoice = 'female';
      final engine = FakeTtsEngine()
        ..availableVoices = [
          {'name': 'goog-EN', 'locale': 'en-US', 'gender': 'female'},
        ];
      final svc = TtsService.createForTest(fake: engine);
      await svc.speakOne('teste');
      expect(engine.selectedVoiceName, isNull);
      expect(engine.pitches, [1.25]); // agudo (feminina)
    });

    test('sem voz masculina instalada, o tom simula o gênero', () async {
      AppState.i.ttsPitch = 1.0;
      AppState.i.ttsVoice = 'male';
      final engine = FakeTtsEngine()
        ..availableVoices = [
          {'name': 'goog-EN', 'locale': 'en-US', 'gender': 'male'},
        ];
      final svc = TtsService.createForTest(fake: engine);
      await svc.speakOne('teste');
      expect(engine.selectedVoiceName, isNull);
      expect(engine.pitches, [0.8]); // grave (masculina)
    });

    test(
      'com voz instalada, usa a voz real e mantém o tom do usuário',
      () async {
        AppState.i.ttsPitch = 1.2;
        AppState.i.ttsVoice = 'female';
        final engine = FakeTtsEngine();
        final svc = TtsService.createForTest(fake: engine);
        await svc.speakOne('teste');
        expect(engine.selectedVoiceName, 'pt-BR-female');
        expect(engine.pitches, [1.2]);
      },
    );

    test('restaura voz padrão após vozes feminina e masculina', () async {
      final engine = FakeTtsEngine();
      final svc = TtsService.createForTest(fake: engine);
      for (final voice in ['female', 'male']) {
        AppState.i.ttsVoice = voice;
        await svc.speakOne('teste');
        expect(engine.selectedVoiceName, 'pt-BR-$voice');
      }
      AppState.i.ttsVoice = 'default';
      await svc.speakOne('teste');
      expect(engine.selectedVoiceName, isNull);
      expect(engine.languagesSet.last, 'pt-BR');
    });

    test('não reaplica a voz enquanto a preferência não muda', () async {
      AppState.i.ttsRate = 0.5;
      AppState.i.ttsPitch = 1.0;
      AppState.i.ttsVoice = 'male';
      final engine = FakeTtsEngine();
      final svc = TtsService.createForTest(fake: engine);
      await svc.playChapter(['um', 'dois']);
      // A voz é escolhida uma única vez, na primeira fala.
      expect(engine.selectedVoiceName, 'pt-BR-male');
      expect(engine.rates, [0.5, 0.5]);
    });
  });
}
