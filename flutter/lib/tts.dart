import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsPhase { none, playing, paused }

/// Leitura por voz (text-to-speech) para acessibilidade.
///
/// Fala uma frase simples (versículo) ou uma sequência (capítulo),
/// verso a verso, chamando [onVerse] com o índice atual para a UI
/// destacar o que está sendo lido.
class TtsService {
  TtsService._() {
    _tts.setLanguage('pt-BR');
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.0);
  }

  static final TtsService i = TtsService._();

  final FlutterTts _tts = FlutterTts();

  /// Estado atual da leitura (disponível para a interface reagir).
  final ValueNotifier<TtsPhase> phase = ValueNotifier(TtsPhase.none);

  /// Índice do versículo sendo lido (ou `null` fora de uma sequência).
  final ValueNotifier<int?> index = ValueNotifier(null);

  List<String> _queue = [];
  int _cursor = 0;
  bool _cancel = false;
  Completer<void>? _completer;

  bool get isActive =>
      phase.value == TtsPhase.playing || phase.value == TtsPhase.paused;

  void _release() {
    final c = _completer;
    if (c != null && !c.isCompleted) c.complete();
  }

  Future<void> _speakOne(String text) {
    _cancel = false;
    final c = Completer<void>();
    _completer = c;
    _tts.setCompletionHandler(() {
      if (!c.isCompleted) c.complete();
    });
    _tts.speak(text);
    return c.future;
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
    }
  }

  /// Lê uma sequência de textos (ex.: capítulo). O primeiro item pode ser a
  /// introdução (ex.: "Gênesis, capítulo 1").
  Future<void> playChapter(List<String> items) async {
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
    await _tts.stop();
    _release();
  }

  /// Continua do versículo em que a leitura foi pausada.
  Future<void> resume() async {
    if (phase.value != TtsPhase.paused) return;
    if (_cursor >= _queue.length) _cursor = 0;
    _cancel = false;
    phase.value = TtsPhase.playing;
    await _loop();
  }

  Future<void> stop() async {
    _cancel = true;
    await _tts.stop();
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