import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common.dart';
import '../models.dart';
import '../store.dart';

class BoletimTab extends StatefulWidget {
  const BoletimTab({super.key});

  @override
  State<BoletimTab> createState() => _BoletimTabState();
}

class _BoletimTabState extends State<BoletimTab> {
  bool _editing = false;

  static String _pad(int n) => n.toString().padLeft(2, '0');

  List<Birthday> get _today {
    final now = DateTime.now();
    final list = AppState.i.birthdays
        .where((b) => b.day == now.day && b.month == now.month)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<ChurchEvent> get _upcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final list = AppState.i.events
        .where((e) => !e.dateTime.isBefore(today))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final t = appTheme;
    return Container(
      color: t.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  if (_editing)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          size: 20, color: t.primary),
                      onPressed: () => setState(() => _editing = false),
                    ),
                  Expanded(
                    child: Text(
                      'Boletim',
                      style: TextStyle(
                          color: t.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _editing = !_editing),
                    icon: Icon(_editing ? Icons.check : Icons.edit,
                        size: 18, color: t.accent),
                    label: Text(
                      _editing ? 'Concluir' : 'Editar',
                      style: TextStyle(
                          color: t.accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
                children: _editing ? _editChildren() : _viewChildren(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _viewChildren() {
    final t = appTheme;
    final today = _today;
    final upcoming = _upcoming;

    return [
      _sectionHeader('🎂 Aniversariantes do dia', null),
      if (today.isEmpty)
        _empty('Nenhum aniversariante hoje.')
      else
        for (final b in today) _card(child: Text(b.name, style: _cardText)),
      const SizedBox(height: 12),
      _sectionHeader('📅 Próximos eventos', null),
      if (upcoming.isEmpty)
        _empty('Nenhum evento agendado.')
      else
        for (final e in upcoming)
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: _cardText.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  _eventSubtitle(e),
                  style: TextStyle(color: t.muted, fontSize: 13),
                ),
              ],
            ),
          ),
    ];
  }

  List<Widget> _editChildren() {
    final t = appTheme;
    return [
      _sectionHeader('Aniversariantes', () => _birthdayDialog(null)),
      if (AppState.i.birthdays.isEmpty)
        _empty('Nenhum aniversariante cadastrado.')
      else
        for (var i = 0; i < AppState.i.birthdays.length; i++)
          _card(
            onTap: () => _birthdayDialog(i),
            onLongPress: () => _birthdayMenu(i),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppState.i.birthdays[i].name, style: _cardText),
                const SizedBox(height: 2),
                Text(
                  '${_pad(AppState.i.birthdays[i].day)}/${_pad(AppState.i.birthdays[i].month)}',
                  style: TextStyle(color: t.muted, fontSize: 13),
                ),
              ],
            ),
          ),
      const SizedBox(height: 12),
      _sectionHeader('Eventos', () => _eventDialog(null)),
      if (AppState.i.events.isEmpty)
        _empty('Nenhum evento cadastrado.')
      else
        for (var i = 0; i < AppState.i.events.length; i++)
          _card(
            onTap: () => _eventDialog(i),
            onLongPress: () => _eventMenu(i),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppState.i.events[i].title, style: _cardText),
                const SizedBox(height: 2),
                Text(
                  _eventSubtitle(AppState.i.events[i]),
                  style: TextStyle(color: t.muted, fontSize: 13),
                ),
              ],
            ),
          ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          'Toque para editar e segure para abrir o menu. Aniversariantes aparecem automaticamente no dia, e eventos com data passada deixam de ser exibidos.',
          style: TextStyle(color: t.muted, fontSize: 12),
        ),
      ),
    ];
  }

  TextStyle get _cardText => TextStyle(
      color: appTheme.text, fontSize: 16, fontWeight: FontWeight.normal);

  String _eventSubtitle(ChurchEvent e) {
    final date = '${_pad(e.day)}/${_pad(e.month)}/${e.year}';
    final time = e.time.isEmpty ? '' : '  às ${e.time}';
    final note = e.note.isEmpty ? '' : '  ·  ${e.note}';
    return '$date$time$note';
  }

  Widget _sectionHeader(String label, VoidCallback? onAdd) {
    final t = appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: t.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          if (onAdd != null)
            IconButton(
              icon: Icon(Icons.add_circle, color: t.accent),
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final t = appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) {
    final t = appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(text, style: TextStyle(color: t.muted, fontSize: 14)),
    );
  }

  Future<void> _birthdayDialog(int? index) async {
    final t = appTheme;
    final name = TextEditingController();
    final day = TextEditingController();
    final month = TextEditingController();
    if (index != null) {
      final b = AppState.i.birthdays[index];
      name.text = b.name;
      day.text = '${b.day}';
      month.text = '${b.month}';
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        title: Text(
            index == null ? 'Novo aniversariante' : 'Editar aniversariante',
            style: TextStyle(color: t.text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                style: TextStyle(color: t.text),
                decoration: const InputDecoration(hintText: 'Nome'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _numField(day, 'Dia')),
                  const SizedBox(width: 8),
                  Expanded(child: _numField(month, 'Mês')),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true) return;
    final n = name.text.trim();
    final d = int.tryParse(day.text.trim()) ?? -1;
    final m = int.tryParse(month.text.trim()) ?? -1;
    if (n.isEmpty || d < 1 || d > 31 || m < 1 || m > 12) return;
    if (index == null) {
      AppState.i.birthdays.add(Birthday(n, d, m));
    } else {
      AppState.i.birthdays[index]
        ..name = n
        ..day = d
        ..month = m;
    }
    await AppState.i.saveBoletim();
    if (mounted) setState(() {});
  }

  Future<void> _eventDialog(int? index) async {
    final t = appTheme;
    final title = TextEditingController();
    final day = TextEditingController();
    final month = TextEditingController();
    final year = TextEditingController(text: '${DateTime.now().year}');
    final time = TextEditingController();
    final note = TextEditingController();
    if (index != null) {
      final e = AppState.i.events[index];
      title.text = e.title;
      day.text = '${e.day}';
      month.text = '${e.month}';
      year.text = '${e.year}';
      time.text = e.time;
      note.text = e.note;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        title: Text(index == null ? 'Novo evento' : 'Editar evento',
            style: TextStyle(color: t.text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                style: TextStyle(color: t.text),
                decoration: const InputDecoration(hintText: 'Título do evento'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _numField(day, 'Dia')),
                  const SizedBox(width: 8),
                  Expanded(child: _numField(month, 'Mês')),
                  const SizedBox(width: 8),
                  Expanded(child: _numField(year, 'Ano')),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: time,
                style: TextStyle(color: t.text),
                decoration:
                    const InputDecoration(hintText: 'Hora (opcional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                style: TextStyle(color: t.text),
                decoration:
                    const InputDecoration(hintText: 'Observação (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true) return;
    final ttl = title.text.trim();
    final d = int.tryParse(day.text.trim()) ?? -1;
    final m = int.tryParse(month.text.trim()) ?? -1;
    final y = int.tryParse(year.text.trim()) ?? -1;
    if (ttl.isEmpty ||
        d < 1 ||
        d > 31 ||
        m < 1 ||
        m > 12 ||
        y < 2000 ||
        y > 2100) {
      return;
    }
    if (index == null) {
      AppState.i.events.add(ChurchEvent(
          ttl, d, m, y, time.text.trim(), note.text.trim()));
    } else {
      AppState.i.events[index]
        ..title = ttl
        ..day = d
        ..month = m
        ..year = y
        ..time = time.text.trim()
        ..note = note.text.trim();
    }
    await AppState.i.saveBoletim();
    if (mounted) setState(() {});
  }

  Widget _numField(TextEditingController c, String hint) {
    final t = appTheme;
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(color: t.text),
      decoration: InputDecoration(hintText: hint),
    );
  }

  Future<void> _birthdayMenu(int index) async {
    final action = await _actionSheet();
    if (action == 'edit') {
      await _birthdayDialog(index);
    } else if (action == 'delete') {
      AppState.i.birthdays.removeAt(index);
      await AppState.i.saveBoletim();
      if (mounted) setState(() {});
    }
  }

  Future<void> _eventMenu(int index) async {
    final action = await _actionSheet();
    if (action == 'edit') {
      await _eventDialog(index);
    } else if (action == 'delete') {
      AppState.i.events.removeAt(index);
      await AppState.i.saveBoletim();
      if (mounted) setState(() {});
    }
  }

  Future<String?> _actionSheet() {
    final t = appTheme;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: t.card,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: t.text),
              title: Text('Editar', style: TextStyle(color: t.text)),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: t.text),
              title: Text('Excluir', style: TextStyle(color: t.text)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
  }
}
