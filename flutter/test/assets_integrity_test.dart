import 'dart:convert';
import 'dart:io';

import 'package:biblia_app/models.dart';
import 'package:biblia_app/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('todas as traduções têm livros e capítulos canônicos e texto', () {
    List<Book>? reference;
    for (final asset in kVersionAssets.values) {
      final raw = jsonDecode(File(asset).readAsStringSync()) as List;
      final books = raw
          .map((b) => Book.fromJson(b as Map<String, dynamic>))
          .toList();
      expect(books.length, 66, reason: asset);
      expect(
        books.fold<int>(0, (n, b) => n + b.chapters.length),
        1189,
        reason: asset,
      );
      for (var i = 0; i < books.length; i++) {
        expect(books[i].name.trim(), isNotEmpty);
        expect(books[i].abbr.trim(), isNotEmpty);
        if (reference != null) {
          expect(
            books[i].chapters.length,
            reference[i].chapters.length,
            reason: '$asset livro $i',
          );
        }
        for (final chapter in books[i].chapters) {
          expect(chapter, isNotEmpty);
          for (final verse in chapter) {
            expect(verse.trim(), isNotEmpty);
          }
        }
      }
      reference ??= books;
    }
  });
}
