import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'store.dart';
import 'theme.dart';
import 'tts.dart';

const List<Color> kHighlightColors = [
  Color(0xFFF3D463),
  Color(0xFF8ED9B0),
  Color(0xFFF2A9A9),
  Color(0xFFA9C4F2),
  Color(0xFFD5B8F2),
  Color(0xFFF2A9DC),
];

const List<String> kHighlightNames = [
  'Amarelo',
  'Verde',
  'Vermelho',
  'Azul',
  'Roxo',
  'Rosa',
];

/// Tema efetivo da interface. Precisa respeitar o override do modo de leitura
/// ([AppState.displayedThemeIndex]), igual ao `MaterialApp`, para os widgets
/// não ficarem com as cores do tema escolhido em vez do exibido.
AppTheme get appTheme =>
    themeForIndex(AppState.i.displayedThemeIndex, AppState.i.systemBrightness);

/// Remove diacríticos (acentos e cedilha) de uma string.
String stripDiacritics(String s) {
  const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  var r = s;
  for (var i = 0; i < accents.length; i++) {
    r = r.replaceAll(accents[i], plain[i]);
  }
  return r;
}

/// Coloca o texto em minúsculas e remove os acentos, para ordenação e
/// comparação que ignorem diacríticos (ex.: "Água" e "Agua" empatam).
String foldSortKey(String s) => stripDiacritics(s.toLowerCase());

Color highlightColor(String key) {
  final i = AppState.i.getHighlight(key);
  if (i >= 0 && i < kHighlightColors.length) return kHighlightColors[i];
  return Colors.transparent;
}

Future<void> copyText(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

Future<void> shareText(String text) async {
  await SharePlus.instance.share(ShareParams(text: text));
}

/// Menu de toque longo: ouvir, comparar, copiar, compartilhar, anotar e
/// cores de destaque.
Future<void> showLineMenu(
  BuildContext context, {
  required String title,
  required String text,
  required String highlightKey,
  ValueChanged<int>? onHighlightChanged,
  bool clearOption = true,
  String? note,
  ValueChanged<String>? onNoteChanged,
  VoidCallback? onCompare,
  String? speakText,
  VoidCallback? onSelect,
}) async {
  final t = appTheme;
  final current = AppState.i.getHighlight(highlightKey);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  AppState.i.isFavorite(highlightKey)
                      ? Icons.star
                      : Icons.star_border,
                ),
                title: Text(
                  AppState.i.isFavorite(highlightKey)
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                ),
                onTap: () async {
                  try {
                    await AppState.i.toggleFavorite(highlightKey);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Não foi possível salvar o favorito.'),
                        ),
                      );
                    }
                  }
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
              ),
              if (onSelect != null)
                ListTile(
                  leading: Icon(Icons.checklist, color: t.text),
                  title: Text(
                    'Selecionar (copiar/nota/destaque em vários)',
                    style: TextStyle(color: t.text),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect();
                  },
                ),
              if (onCompare != null)
                ListTile(
                  leading: Icon(Icons.compare_arrows, color: t.text),
                  title: Text(
                    'Comparar traduções',
                    style: TextStyle(color: t.text),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onCompare();
                  },
                ),
              ListTile(
                leading: Icon(Icons.volume_up, color: t.text),
                title: Text('Ouvir', style: TextStyle(color: t.text)),
                onTap: () {
                  TtsService.i.speakOne(speakText ?? text);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(Icons.note_add, color: t.text),
                title: Text(
                  note == null || note.isEmpty ? 'Anotar' : 'Nota: $note',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final edited = await _editNote(
                    context,
                    highlightKey,
                    note ?? '',
                  );
                  if (edited != null) onNoteChanged?.call(edited);
                },
              ),
              ListTile(
                leading: Icon(Icons.copy, color: t.text),
                title: Text('Copiar', style: TextStyle(color: t.text)),
                onTap: () {
                  copyText(text);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: t.text),
                title: Text('Compartilhar', style: TextStyle(color: t.text)),
                onTap: () {
                  shareText(text);
                  Navigator.pop(ctx);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Text(
                  'Destaque',
                  style: TextStyle(
                    color: t.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < kHighlightColors.length; i++)
                      Semantics(
                        button: true,
                        label: kHighlightNames[i],
                        selected: current == i,
                        child: GestureDetector(
                          onTap: () async {
                            await AppState.i.setHighlight(highlightKey, i);
                            onHighlightChanged?.call(i);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kHighlightColors[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: current == i
                                    ? t.primary
                                    : Colors.black12,
                                width: current == i ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (clearOption)
                      GestureDetector(
                        onTap: () async {
                          await AppState.i.setHighlight(highlightKey, -1);
                          onHighlightChanged?.call(-1);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: t.light,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Icon(
                            Icons.format_color_reset,
                            size: 20,
                            color: t.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Abre o diálogo de anotação e usa o texto salvo em `setNote`. Retorna o
/// novo texto salvo, ou `null` se cancelado.
Future<String?> _editNote(
  BuildContext context,
  String key,
  String initial,
) async {
  final saved = await editNoteDialog(context, initial);
  if (saved == null) return null;
  await AppState.i.setNote(key, saved);
  return saved;
}

/// Abre o diálogo de anotação (apenas) e devolve o texto digitado, ou `null`
/// se cancelado. Não salva — quem chama decide onde gravar.
Future<String?> editNoteDialog(
  BuildContext context, [
  String initial = '',
]) async {
  final t = appTheme;
  final ctrl = TextEditingController(text: initial);
  try {
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        title: Text('Anotação', style: TextStyle(color: t.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 6,
          style: TextStyle(color: t.text),
          decoration: const InputDecoration(
            hintText: 'Escreva sua nota sobre este versículo.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  } finally {
    ctrl.dispose();
  }
}

/// Rola progressivamente até uma linha ainda não construída pela lista.
void scrollToTarget(
  ScrollController controller,
  GlobalKey target,
  bool Function() isMounted,
) {
  void seek() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted() || !controller.hasClients) return;
      final context = target.currentContext;
      if (context != null && context.mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.15,
          duration: const Duration(milliseconds: 250),
        );
        return;
      }
      final position = controller.position;
      if (position.pixels >= position.maxScrollExtent) return;
      controller.jumpTo(
        (position.pixels + position.viewportDimension * 0.7).clamp(
          0,
          position.maxScrollExtent,
        ),
      );
      seek();
    });
  }

  seek();
}
