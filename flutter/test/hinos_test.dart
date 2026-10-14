import 'package:biblia_app/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.i.load();
  });

  test('hinário Salmos e Hinos (1880) completo', () {
    expect(AppState.i.hymns.length, 287);
  });

  test('todos os hinos têm título e ao menos uma linha', () {
    for (var h in AppState.i.hymns) {
      expect(h.title.trim(), isNotEmpty, reason: 'hino ${h.num}');
      var lines = 0;
      for (var s in h.stanzas) {
        lines += s.length;
      }
      expect(lines, greaterThan(0), reason: 'hino ${h.num}');
    }
  });

  test('nenhuma linha de hino fica vazia', () {
    for (var h in AppState.i.hymns) {
      for (var s in h.stanzas) {
        for (var l in s) {
          expect(l.trim(), isNotEmpty, reason: 'hino ${h.num}');
        }
      }
    }
  });

  test('hino 1 completo (Salmo I)', () {
    final h = AppState.i.hymns.first;
    expect(h.num, 1);
    expect(h.title, 'Psalmo I');
    expect(h.stanzas.first, contains('Quão bem aventurado'));
  });
}