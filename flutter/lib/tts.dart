import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsPhase { none, playing, paused }

/// Abstração da engine de síntese de voz, para permitir testes sem
/// dependência de plataforma (Android/iOS).
abstract class TtsEngine {
  Future<void> setLanguage(String language);
  Future<bool> isLanguageAvailable(String language);
  Future<void> setSpeechRate(double rate);
  Future<void> setPitch(double pitch);
  Future<void> speak(String text);
  Future<void> stop();
}

/// Engine real que usa o plugin flutter_tts.
class FlutterTtsEngine implements TtsEngine {
  final FlutterTts _tts;

  FlutterTtsEngine() : _tts = FlutterTts();

  @override
  Future<void> setLanguage(String language) => _tts.setLanguage(language);

  @override
  Future<bool> isLanguageAvailable(String language) =>
      _tts.isLanguageAvailable(language).then((v) => v as bool);

  @override
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);

  @override
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> stop() => _tts.stop();
}

/// Engine falsa para testes unitários.
///
/// Por padrão, [speak] é síncrono (completa imediatamente). Para testar
/// interrupções, use [FakeTtsEngine.async] ou configure [delay] para
/// fazer cada [speak] completar de forma assíncrona.
class FakeTtsEngine implements TtsEngine {
  final List<String> spoken = [];
  final List<String> languagesSet = [];
  bool _available = true;
  bool _stopRequested = false;

  /// Se verdadeiro, [speak] aguarda um microtask antes de completar,
  /// permitindo que o loop observe cancelamentos entre itens.
  final bool async;

  FakeTtsEngine({this.async = false});

  @override
  Future<void> setLanguage(String language) async {
    languagesSet.add(language);
  }

  @override
  Future<bool> isLanguageAvailable(String language) async => _available;

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> speak(String text) async {
    if (_stopRequested) return;
    spoken.add(text);
    if (async) {
      await Future<void>.microtask(() {});
    }
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;
    if (async) {
      await Future<void>.microtask(() {});
    }
    _stopRequested = false;
  }

  void setAvailable(bool available) => _available = available;
}

/// Leitura por voz (text-to-speech) para acessibilidade.
///
/// Fala uma frase simples (versículo) ou uma sequência (capítulo),
/// verso a verso, atualizando [phase] e [index] para a UI reagir.
class TtsService {
  TtsService._({
    TtsEngine? engine,
  })  : _engine = engine ?? FlutterTtsEngine(),
        _tts = null {
    // Configuração inicial síncrona — sem chamadas de plataforma.
  }

  /// Instância única do serviço (produção).
  static final TtsService i = TtsService._();

  /// Cria uma instância com engine falsa, para testes.
  static TtsService createForTest({FakeTtsEngine? fake}) {
    return TtsService._(engine: fake ?? FakeTtsEngine());
  }

  /// Engine de TTS injetada (para testes) ou real (produção).
  final TtsEngine _engine;

  /// Referência nula mantida apenas por compatibilidade com código
  /// existente — não utilizada quando [_engine] está presente.
  final FlutterTts? _tts;

  /// Estado atual da leitura (disponível para a interface reagir).
  final ValueNotifier<TtsPhase> phase = ValueNotifier(TtsPhase.none);

  /// Índice do versículo sendo lido (ou `null` fora de uma sequência).
  final ValueNotifier<int?> index = ValueNotifier(null);

  List<String> _queue = [];
  int _cursor = 0;
  bool _cancel = false;
  Completer<void>? _completer;

  // --- acessadores de teste ---
  List<String> get testQueue => _queue;
  set testQueue(List<String> v) => _queue = v;
  int get testCursor => _cursor;
  set testCursor(int v) => _cursor = v;
  bool get testCancel => _cancel;
  set testCancel(bool v) => _cancel = v;
  // ---

  bool get isActive =>
      phase.value == TtsPhase.playing || phase.value == TtsPhase.paused;

  bool _langReady = false;

  Future<void> _ensureLanguage() async {
    if (_langReady) return;
    await _engine.setLanguage('pt-BR');
    if (!await _engine.isLanguageAvailable('pt-BR')) {
      await _engine.setLanguage('pt');
    }
    _langReady = true;
  }

  void _release() {
    final c = _completer;
    if (c != null && !c.isCompleted) c.complete();
  }

  Future<void> _speakOne(String text) {
    return _ensureLanguage().then((_) {
      _cancel = false;
      final c = Completer<void>();
      _completer = c;
      _engine.speak(text).then((_) {
        if (!c.isCompleted) c.complete();
      }).catchError((_) {
        if (!c.isCompleted) c.complete();
      });
      return c.future;
    });
  }

  Future<void> _loop() async {
    while (!_cancel && _cursor < _queue.length) {
      index.value = _cursor;
      await _speakOne(_queue[_cursor]);
      _cursor++;
    }
    if (!_cancel) {
      phase.value = TtsPhase.none;
      index.value = null;
      _queue = [];
      _cursor = 0;
    }
  }

  /// Lê uma sequência de textos (ex.: capítulo). O primeiro item pode ser a
  /// introdução (ex.: "Gênesis, capítulo 1").
  Future<void> playChapter(List<String> items) async {
    if (items.isEmpty) return;
    if (isActive) await stop();
    _queue = List.of(items);
    _cursor = 0;
    _cancel = false;
    phase.value = TtsPhase.playing;
    await _loop();
  }

  /// Lê um único texto (ex.: um versículo) e encerra.
  Future<void> speakOne(String text) async {
    if (isActive) await stop();
    phase.value = TtsPhase.playing;
    index.value = null;
    await _speakOne(text);
    if (!isActive) return;
    phase.value = TtsPhase.none;
    index.value = null;
  }

  /// Pausa a leitura do capítulo (mantém a posição atual).
  Future<void> pause() async {
    if (phase.value != TtsPhase.playing) return;
    _cancel = true;
    phase.value = TtsPhase.paused;
    await _engine.stop();
    _release();
  }

  /// Continua do versículo em que a leitura foi pausada.
  Future<void> resume() async {
    if (phase.value != TtsPhase.paused) return;
    if (_queue.isEmpty) return; // fila corrompida ou limpa: não resetar
    if (_cursor >= _queue.length) _cursor = 0;
    _cancel = false;
    phase.value = TtsPhase.playing;
    await _loop();
  }

  Future<void> stop() async {
    _cancel = true;
    await _engine.stop();
    _release();
    _queue = [];
    _cursor = 0;
    index.value = null;
    if (phase.value == TtsPhase.playing ||
        phase.value == TtsPhase.paused) {
      phase.value = TtsPhase.none;
    }
  }
}
