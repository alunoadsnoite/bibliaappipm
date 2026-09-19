import 'package:biblia_app/models.dart';
import 'package:biblia_app/theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseia uma música', () {
    final s = Song.fromJson({'title': 'Título', 'lyrics': 'linha'});
    expect(s.title, 'Título');
    expect(s.lyrics, 'linha');
  });

  test('serializa boletim', () {
    final json = parseBoletimJson(
      [Birthday('Ana', 1, 2)],
      [ChurchEvent('Culto', 3, 4, 2026, '19:00', '')],
    );
    expect(json.contains('aniversariantes'), isTrue);
    expect(json.contains('eventos'), isTrue);
  });

  test('temas e níveis de fonte definidos', () {
    expect(kThemes.length, 4);
    expect(kThemeNames.length, kThemes.length + 1);
    expect(kSystemThemeIndex, 4);
    expect(kFontLevels.length, kFontLevelNames.length);
    expect(fontLevelIndex(1.0), 1);
  });
}
