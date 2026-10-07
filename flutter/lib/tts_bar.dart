import 'package:flutter/material.dart';

import 'common.dart';
import 'tts.dart';

/// Barra de controle da leitura por voz, reutilizada na Bíblia,
/// no Hinário e nas Músicas.
class TtsBar extends StatefulWidget {
  const TtsBar({
    super.key,
    required this.positionLabel,
    required this.playLabel,
    required this.onPlay,
    this.itemCount = 0,
  });

  /// Nome do item lido (ex.: "Versículo", "Estrofe", "Trecho").
  final String positionLabel;

  /// Texto do botão no estado de espera (ex.: "Ouvir o capítulo").
  final String playLabel;

  /// Inicia a leitura da sequência.
  final VoidCallback onPlay;

  /// Quantidade de itens da sequência.
  final int itemCount;

  @override
  State<TtsBar> createState() => _TtsBarState();
}

class _TtsBarState extends State<TtsBar> {
  // Merge cacheado para não (des)registrar listeners a cada build — mesmo
  // padrão usado por BibleTab.
  late final Listenable _ttsListenable =
      Listenable.merge([TtsService.i.phase, TtsService.i.index]);

  @override
  Widget build(BuildContext context) {
    final t = appTheme;
    return ListenableBuilder(
      listenable: _ttsListenable,
      builder: (context, _) {
        final phase = TtsService.i.phase.value;
        final idx = TtsService.i.index.value;
        final playing = phase == TtsPhase.playing;
        final paused = phase == TtsPhase.paused;
        final active = playing || paused;

        String label;
        if (paused) {
          label = idx == null
              ? 'Pausado'
              : 'Pausado · ${widget.positionLabel} ${idx + 1} de ${widget.itemCount}';
        } else if (playing && idx != null) {
          label = '${widget.positionLabel} ${idx + 1} de ${widget.itemCount}';
        } else {
          label = widget.playLabel;
        }

        return Material(
          color: t.primaryDark,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 3, 4, 3),
            child: Row(
              children: [
                Icon(playing
                    ? Icons.graphic_eq
                    : paused
                        ? Icons.pause
                        : Icons.volume_up,
                    color: Colors.white,
                    size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
                if (!active || paused)
                  IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: paused ? TtsService.i.resume : widget.onPlay,
                  ),
                if (playing)
                  IconButton(
                    icon: const Icon(Icons.pause, color: Colors.white),
                    onPressed: TtsService.i.pause,
                  ),
                if (active)
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.white),
                    onPressed: TtsService.i.stop,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}