import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'store.dart';

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

  /// Faz com que [speak] só conclua quando a fala terminar de verdade.
  /// Sem isso, speak retorna imediatamente e o próximo trecho interrompe
  /// o anterior (lê-se apenas o fim de cada versículo).
  Future<void> setAwaitSpeechCompletion(bool awaitCompletion);

  /// Vozes disponíveis (mapas com `name`, `locale` e opcional `gender`).
  Future<List<Map<String, String>>> voices();

  /// Seleciona uma voz pelo nome e localidade.
  Future<void> selectVoice(String name, String locale);
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

  @override
  Future<void> setAwaitSpeechCompletion(bool awaitCompletion) async {
    try {
      await _tts.awaitSpeakCompletion(awaitCompletion);
    } catch (_) {
      // Recurso opcional — em plataformas sem suporte, segue sem esperar.
    }
  }

  @override
  Future<List<Map<String, String>>> voices() async {
    final raw = await _tts.getVoices;
    if (raw is! List) return const [];
    final out = <Map<String, String>>[];
    for (final v in raw) {
      if (v is! Map) continue;
      final name = (v['name'] ?? '') as String;
      final locale = (v['locale'] ?? '') as String;
      final gender = (v['gender'] ?? '') as String;
      out.add({
        'name': name,
        'locale': locale,
        if (gender.isNotEmpty) 'gender': gender,
      });
    }
    return out;
  }

  @override
  Future<void> selectVoice(String name, String locale) async {
    await _tts.setVoice({'name': name, 'locale': locale});
  }
}

/// Engine falsa para testes unitários.
///
/// Por padrão, [speak] é síncrono (completa imediatamente). Para testar
/// interrupções, use [FakeTtsEngine.async] ou configure [delay] para
/// fazer cada [speak] completar de forma assíncrona.
class FakeTtsEngine implements TtsEngine {
  final List<String> spoken = [];
  final List<String> languagesSet = [];
  final List<double> rates = [];
  final List<double> pitches = [];
  String? selectedVoiceName;
  String? selectedVoiceLocale;
  bool _available = true;
  bool _stopRequested = false;

  /// Reflete a última chamada de [setAwaitSpeechCompletion].
  bool awaitSpeechCompletion = false;

  /// Vozes usadas nos testes de seleção de voz.
  List<Map<String, String>> availableVoices = [
    {'name': 'pt-BR-female', 'locale': 'pt-BR', 'gender': 'female'},
    {'name': 'pt-BR-male', 'locale': 'pt-BR', 'gender': 'male'},
  ];

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
  Future<void> setSpeechRate(double rate) async {
    rates.add(rate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    pitches.add(pitch);
  }

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

  @override
  Future<void> setAwaitSpeechCompletion(bool awaitCompletion) async {
    awaitSpeechCompletion = awaitCompletion;
  }

  @override
  Future<List<Map<String, String>>> voices() async => availableVoices;

  @override
  Future<void> selectVoice(String name, String locale) async {
    selectedVoiceName = name;
    selectedVoiceLocale = locale;
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
  }) : _engine = engine ?? FlutterTtsEngine() {
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
  List<Map<String, String>> _voices = const [];
  String _appliedVoice = 'default';

  Future<void> _ensureLanguage() async {
    if (_langReady) return;
    await _engine.setLanguage('pt-BR');
    if (!await _engine.isLanguageAvailable('pt-BR')) {
      await _engine.setLanguage('pt');
    }
    // Garante que speak só encerre quando a fala terminar, para que o loop
    // espere cada versículo antes de falar o próximo.
    await _engine.setAwaitSpeechCompletion(true);
    try {
      _voices = await _engine.voices();
    } catch (_) {
      _voices = const [];
    }
    _langReady = true;
  }

  /// Escolhe, entre as vozes em português, uma do gênero pedido
  /// ('female' ou 'male'). Prioriza o campo `gender` e, se ausente,
  /// tenta adivinhar pelo nome da voz.
  Map<String, String>? _pickVoice(String gender) {
    final pt = _voices
        .where((v) =>
            (v['locale'] ?? '').toLowerCase().startsWith('pt'))
        .toList();
    for (final v in pt) {
      final g = (v['gender'] ?? '').toLowerCase();
      if (g == gender) return v;
    }
    final kws = gender == 'female'
        ? const ['female', 'femin', 'feminina', 'fem']
        : const ['male', 'masc', 'masculin', 'masculina'];
    for (final v in pt) {
      final name = (v['name'] ?? '').toLowerCase();
      if (kws.any((k) => name.contains(k))) return v;
    }
    return null;
  }

  /// Fatores de simulação de gênero quando não há voz instalada com o gênero
  /// pedido: tom um pouco mais agudo para feminina, um pouco mais grave para
  /// masculina — valores suaves para não soar robotizado.
  static const double kSimFemalePitch = 1.25;
  static const double kSimMalePitch = 0.8;

  /// Aplica as preferências do usuário: velocidade, tom e voz
  /// (padrão/feminina/masculina). Quando não existir voz do gênero pedido
  /// instalada no aparelho, o tom é ajustado para simular o gênero —
  /// permitindo o recurso mesmo 100% offline.
  Future<void> _applyVoice() async {
    final state = AppState.i;
    final wanted = state.ttsVoice;

    bool genderApplied = false;
    if (wanted != 'default' && wanted != _appliedVoice && _voices.isNotEmpty) {
      final v = _pickVoice(wanted);
      final name = v?['name'] ?? '';
      if (name.isNotEmpty) {
        await _engine.selectVoice(name, v?['locale'] ?? '');
        genderApplied = true;
      }
    }

    var pitch = state.ttsPitch;
    if (wanted != 'default') {
      final usingRealVoice =
          genderApplied || _appliedVoice.endsWith(':real');
      if (!usingRealVoice) {
        pitch = wanted == 'female'
            ? (pitch * kSimFemalePitch).clamp(0.5, 2.0).toDouble()
            : (pitch * kSimMalePitch).clamp(0.5, 2.0).toDouble();
      }
    }

    await _engine.setPitch(pitch);
    await _engine.setSpeechRate(state.ttsRate);
    _appliedVoice = genderApplied ? '$wanted:real' : wanted;
  }

  void _release() {
    final c = _completer;
    if (c != null && !c.isCompleted) c.complete();
  }

  Future<void> _speakOne(String text) {
    return _ensureLanguage().then((_) => _applyVoice()).then((_) {
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
