import 'dart:convert';

import 'models.dart';

void validateBackup(
  Map<String, dynamic> data,
  List<Book> bible,
  List<String> versions,
) {
  if (data.containsKey('favorites')) {
    for (final key in data['favorites'] as List) {
      if (key is! String || key.isEmpty) {
        throw const FormatException('Favoritos inválidos.');
      }
    }
  }
  final deadline = data['plan_deadline'];
  if (deadline != null) {
    final parsed = deadline is String ? DateTime.tryParse(deadline) : null;
    if (parsed == null ||
        parsed.toIso8601String().split('T').first != deadline) {
      throw const FormatException('Prazo inválido.');
    }
  }
  // Valida todas as seções antes de tocar nos dados locais.
  for (final key in ['red_letter_enabled', 'plan_enabled']) {
    if (data.containsKey(key) && data[key] is! bool) {
      throw FormatException('$key inválido.');
    }
  }
  for (final key in [
    'font_scale',
    'tts_rate',
    'tts_pitch',
    'plan_daily_goal',
  ]) {
    if (data.containsKey(key) &&
        (data[key] is! num || !(data[key] as num).isFinite)) {
      throw FormatException('$key inválido.');
    }
  }
  for (final key in ['version', 'tts_voice']) {
    if (data.containsKey(key) && data[key] is! String) {
      throw FormatException('$key inválido.');
    }
  }
  if (data.containsKey('theme') && data['theme'] is! int) {
    throw const FormatException('Tema inválido.');
  }

  if (data.containsKey('songs')) {
    for (final item in jsonDecode(data['songs'] as String) as List) {
      Song.fromJson(item as Map<String, dynamic>);
    }
  }
  if (data.containsKey('aniversariantes')) {
    for (final item in data['aniversariantes'] as List) {
      final b = Birthday.fromJson(item as Map<String, dynamic>);
      if (b.day < 1 || b.day > 31 || b.month < 1 || b.month > 12) {
        throw const FormatException('Aniversário inválido.');
      }
    }
  }
  if (data.containsKey('eventos')) {
    for (final item in data['eventos'] as List) {
      final e = ChurchEvent.fromJson(item as Map<String, dynamic>);
      final date = e.dateTime;
      if (date.year != e.year || date.month != e.month || date.day != e.day) {
        throw const FormatException('Data de evento inválida.');
      }
    }
  }
  for (final section in ['notes', 'read_day_by_chapter']) {
    if (!data.containsKey(section)) continue;
    for (final value in (data[section] as Map).values) {
      if (value is! String) throw FormatException('$section inválido.');
    }
  }
  for (final day in [
    ...((data['read_day_by_chapter'] as Map?) ?? {}).values,
    ...((data['reads_by_day'] as Map?) ?? {}).keys,
  ]) {
    final parsed = day is String ? DateTime.tryParse(day) : null;
    if (parsed == null || parsed.toIso8601String().split('T').first != day) {
      throw const FormatException('Dia de leitura inválido.');
    }
  }
  for (final section in ['highlights', 'reads_by_day']) {
    if (!data.containsKey(section)) continue;
    for (final value in (data[section] as Map).values) {
      if (value is! int ||
          value < 0 ||
          (section == 'highlights' && value >= 6)) {
        throw FormatException('$section inválido.');
      }
    }
  }
  if (data.containsKey('read_chapters')) {
    for (final key in data['read_chapters'] as List) {
      final parts = (key as String).split(':').map(int.parse).toList();
      if (parts.length != 2 ||
          parts[0] < 0 ||
          parts[0] >= bible.length ||
          parts[1] < 0 ||
          parts[1] >= bible[parts[0]].chapters.length) {
        throw const FormatException('Capítulo inválido.');
      }
    }
  }
  if (data.containsKey('recent')) {
    for (final item in data['recent'] as List) {
      final ref = RecentRef.fromJson(item as Map<String, dynamic>);
      if (!versions.contains(ref.version)) {
        throw const FormatException('Tradução inválida.');
      }
      _validatePosition(Position(ref.book, ref.chapter), bible);
    }
  }
  if (data.containsKey('positions')) {
    for (final entry in (data['positions'] as Map).entries) {
      if (!versions.contains(entry.key)) {
        throw const FormatException('Tradução inválida.');
      }
      _validatePosition(
        Position.fromJson(entry.value as Map<String, dynamic>),
        bible,
      );
    }
  }
}

void _validatePosition(Position position, List<Book> bible) {
  if (position.book < 0 ||
      position.book >= bible.length ||
      position.chapter < 0 ||
      position.chapter >= bible[position.book].chapters.length) {
    throw const FormatException('Posição de leitura inválida.');
  }
}
