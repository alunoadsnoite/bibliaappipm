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

AppTheme get appTheme => kThemes[AppState.i.themeIndex];

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

/// Menu de toque longo: copiar, compartilhar e cores de destaque.
Future<void> showLineMenu(
  BuildContext context, {
  required String title,
  required String text,
  required String highlightKey,
  ValueChanged<int>? onHighlightChanged,
  bool clearOption = true,
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
                    color: t.text, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.volume_up, color: t.text),
              title: Text('Ouvir', style: TextStyle(color: t.text)),
              onTap: () {
                TtsService.i.speakOne(text);
                Navigator.pop(ctx);
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
              child: Text('Destaque',
                  style: TextStyle(
                      color: t.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < kHighlightColors.length; i++)
                    GestureDetector(
                      onTap: () async {
                        await AppState.i.setHighlight(highlightKey, i);
                        onHighlightChanged?.call(i);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kHighlightColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: current == i ? t.primary : Colors.black12,
                            width: current == i ? 3 : 1,
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: t.light,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Icon(Icons.format_color_reset,
                            size: 20, color: t.muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
