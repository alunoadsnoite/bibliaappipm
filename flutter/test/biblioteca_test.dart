import 'package:biblia_app/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.i.load();
  });

  test('biblioteca com os dez documentos', () {
    expect(AppState.i.biblioteca.length, 10);
    expect(
      AppState.i.biblioteca.map((d) => d.id).toList(),
      ['cfw', 'cm', 'cb', 'ca', 'cn', 'dm', '5p', 't95', 'pn', '5s'],
    );
  });

  test('contagem de itens por documento', () {
    int items(String id) =>
        AppState.i.biblioteca.firstWhere((d) => d.id == id).items.length;
    expect(items('cfw'), 35);
    expect(items('cm'), 196);
    expect(items('cb'), 107);
    expect(items('dm'), 1);
    expect(items('5p'), 6);
    expect(items('t95'), 96); // prefácio + 95 teses
    expect(items('pn'), 3); // introdução + Mateus + Lucas
    expect(items('5s'), 6); // introdução + as cinco solas
  });

  test('todo item tem conteúdo e parágrafos não vazios', () {
    for (var d in AppState.i.biblioteca) {
      expect(d.title.trim(), isNotEmpty, reason: d.id);
      for (var it in d.items) {
        expect(it.p, isNotEmpty, reason: '${d.id} item "${it.t}"');
        for (var p in it.p) {
          expect(p.trim(), isNotEmpty, reason: '${d.id} "${it.t}"');
        }
      }
    }
  });
}
