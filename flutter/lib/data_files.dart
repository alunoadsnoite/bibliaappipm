import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareJsonFile(
  BuildContext context,
  String json,
  String name,
) async {
  final file = XFile.fromData(
    Uint8List.fromList(utf8.encode(json)),
    mimeType: 'application/json',
    name: name,
  );
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [file],
      fileNameOverrides: [name],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

Future<String?> openJsonFile() async {
  final file = await openFile(
    acceptedTypeGroups: [
      const XTypeGroup(
        label: 'Arquivo JSON',
        extensions: ['json'],
        mimeTypes: ['application/json'],
        uniformTypeIdentifiers: ['public.json'],
      ),
    ],
  );
  if (file == null) return null;
  if (await file.length() > 20 * 1024 * 1024) {
    throw const FormatException('Arquivo muito grande.');
  }
  return file.readAsString();
}
