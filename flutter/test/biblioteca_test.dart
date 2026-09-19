import 'package:biblia_app/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.i.load();
  });

  test('biblioteca com os oito documentos', () {
    expect(AppState.i.biblioteca.length, 8);
    expect(
      AppState.i.biblioteca.map((d) => d.id).toList(),
      ['cfw', 'cm', 'cb', 'ca', 'cn', 'dm', '5p', 't95'],
    );
  });

  test('contagem de itens por documento', () {
    int items(String id) =>
        AppState.i.biblioteca.firstWhere((d) => d.id == id).items.length;
    expect(items('cfw'), 35);
    expect(items('cm'), 193);
    expect(items('cb'), 107);
    expect(items('dm'), 1);
    expect(items('5p'), 6);
    expect(items('t95'), 96); // prefácio + 95 teses
  });

  test('todo item tem conteúdo e parágrafos não vazios', () {
    for (final d in AppState.i.biblioteca) {
      expect(d.title.trim(), isNotEmpty, reason: d.id);
      for (final it in d.items) {
        expect(it.p, isNotEmpty, reason: '${d.id} item "${it.t}"');
        for (final p in it.p) {
          expect(p.trim(), isNotEmpty, reason: '${d.id} "${it.t}"');
        }
      }
    }
  });
}
