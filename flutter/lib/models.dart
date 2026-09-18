import 'dart:convert';

class Book {
  final String abbr;
  final String name;
  final List<List<String>> chapters;

  Book(this.abbr, this.name, this.chapters);

  factory Book.fromJson(Map<String, dynamic> o) {
    final abbr = (o['abbr'] ?? o['abbrev'] ?? '') as String;
    final raw = (o['ch'] ?? o['chapters']) as List<dynamic>;
    final chapters = raw
        .map((c) => (c as List<dynamic>).map((v) => v as String).toList())
        .toList();
    return Book(abbr, o['name'] as String, chapters);
  }
}

class Hymn {
  final int num;
  final String title;
  final String author;
  final List<String> stanzaNames;
  final List<List<String>> stanzas;

  Hymn(this.num, this.title, this.author, this.stanzaNames, this.stanzas);

  factory Hymn.fromJson(Map<String, dynamic> o) {
    final verses = (o['verses'] as List<dynamic>);
    final names = <String>[];
    final stanzas = <List<String>>[];
    for (final v in verses) {
      final m = v as Map<String, dynamic>;
      names.add((m['name'] ?? '') as String);
      stanzas.add((m['lines'] as List<dynamic>).map((e) => e as String).toList());
    }
    return Hymn(
      o['num'] as int,
      o['title'] as String,
      (o['author'] ?? '') as String,
      names,
      stanzas,
    );
  }

  String searchText() {
    final sb = StringBuffer('$title $author ');
    for (final s in stanzas) {
      for (final l in s) {
        sb.write('$l ');
      }
    }
    return sb.toString().toLowerCase();
  }
}

class Song {
  String title;
  String lyrics;

  Song(this.title, this.lyrics);

  factory Song.fromJson(Map<String, dynamic> o) =>
      Song(o['title'] as String, (o['lyrics'] ?? '') as String);

  Map<String, dynamic> toJson() => {'title': title, 'lyrics': lyrics};
}

class Birthday {
  String name;
  int day;
  int month;

  Birthday(this.name, this.day, this.month);

  factory Birthday.fromJson(Map<String, dynamic> o) =>
      Birthday(o['name'] as String, o['day'] as int, o['month'] as int);

  Map<String, dynamic> toJson() => {'name': name, 'day': day, 'month': month};
}

class ChurchEvent {
  String title;
  int day;
  int month;
  int year;
  String time;
  String note;

  ChurchEvent(this.title, this.day, this.month, this.year, this.time, this.note);

  factory ChurchEvent.fromJson(Map<String, dynamic> o) => ChurchEvent(
        o['title'] as String,
        o['day'] as int,
        o['month'] as int,
        o['year'] as int,
        (o['time'] ?? '') as String,
        (o['note'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'year': year,
        'month': month,
        'day': day,
        if (time.isNotEmpty) 'time': time,
        if (note.isNotEmpty) 'note': note,
      };

  DateTime get dateTime => DateTime(
        year,
        month,
        day,
        _hour,
        _minute,
      );

  int get _hour {
    final h = time.split(':');
    if (h.isEmpty) return 0;
    return int.tryParse(h[0].trim()) ?? 0;
  }

  int get _minute {
    final h = time.split(':');
    if (h.length < 2) return 0;
    return int.tryParse(h[1].trim()) ?? 0;
  }
}

String parseSongsJson(List<Song> songs) =>
    jsonEncode(songs.map((s) => s.toJson()).toList());

String parseBoletimJson(List<Birthday> birthdays, List<ChurchEvent> events) =>
    jsonEncode({
      'aniversariantes': birthdays.map((b) => b.toJson()).toList(),
      'eventos': events.map((e) => e.toJson()).toList(),
    });
