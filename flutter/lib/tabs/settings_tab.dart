import 'dart:convert';

import 'package:flutter/material.dart';

import '../common.dart';
import '../data_files.dart';
import '../reminder_settings.dart';
import '../store.dart';
import '../theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = appTheme;
    final state = AppState.i;
    final level = fontLevelIndex(state.fontScale);

    return ColoredBox(
      color: t.bg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Configurações',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$kAppName - versão ${state.appVersion}',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Text(
              'Tamanho da letra',
              style: TextStyle(
                color: t.text,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              kFontLevelNames[level],
              textAlign: TextAlign.center,
              style: TextStyle(color: t.accent, fontSize: 14),
            ),
            Slider(
              value: level.toDouble(),
              min: 0,
              max: (kFontLevels.length - 1).toDouble(),
              divisions: kFontLevels.length - 1,
              activeColor: t.accent,
              label: kFontLevelNames[level],
              onChanged: (v) => state.setFontScale(kFontLevels[v.round()]),
            ),
            Row(
              children: [
                for (var i = 0; i < kFontLevelNames.length; i++)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => state.setFontScale(kFontLevels[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          kFontLevelNames[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: i == level ? t.accent : t.muted,
                            fontSize: 12,
                            fontWeight: i == level
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'O Senhor é o meu pastor, nada me faltará.',
                style: TextStyle(color: t.text, fontSize: 16, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aparência',
              style: TextStyle(
                color: t.text,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < kThemeNames.length; i++) _themeRow(context, i),
            const SizedBox(height: 8),
            Material(
              color: t.card,
              borderRadius: BorderRadius.circular(8),
              child: SwitchListTile(
                value: state.redLetterEnabled,
                activeTrackColor: t.accent,
                title: Text(
                  'Falas de Jesus e Deus em vermelho',
                  style: TextStyle(color: t.text, fontSize: 15),
                ),
                subtitle: Text(
                  'Destaca em vermelho os versículos com as palavras de '
                  'Jesus e de Deus em toda a Bíblia.',
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
                onChanged: (v) => state.setRedLetterEnabled(v),
              ),
            ),
            const SizedBox(height: 20),
            _planSection(context),
            const SizedBox(height: 20),
            const ReminderSettings(),
            const SizedBox(height: 20),
            _backupSection(context),
            const SizedBox(height: 20),
            _voiceSection(context),
            const SizedBox(height: 8),
            _contactTile(
              icon: Icons.info_outline,
              title: 'Sobre o app',
              subtitle: 'Versão ${AppState.i.appVersion} e informações',
              onTap: () => _aboutDialog(context),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            Text(
              'Seus destaques e músicas são mantidos entre as versões.',
              style: TextStyle(color: t.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final t = appTheme;
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: t.light,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: t.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: t.text, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _aboutDialog(BuildContext context) async {
    final t = appTheme;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        title: Text(kAppName, style: TextStyle(color: t.text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/logo_ipm.png',
                  width: 160,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Versão ${AppState.i.appVersion}',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                'Bíblia em 5 traduções, Hinário Novo Cântico, Músicas, '
                'Biblioteca de credos e Boletim da igreja — tudo offline. '
                'Destaques, notas, plano de leitura e backup dos seus dados.',
                style: TextStyle(color: t.text, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _voiceSection(BuildContext context) {
    final t = appTheme;
    final state = AppState.i;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leitura por voz',
          style: TextStyle(
            color: t.text,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: t.card,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voz', style: TextStyle(color: t.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final voice in [
                      ('default', 'Padrão', Icons.record_voice_over),
                      ('female', 'Feminina', Icons.female),
                      ('male', 'Masculina', Icons.male),
                    ])
                      ChoiceChip(
                        label: Text(voice.$2),
                        avatar: Icon(voice.$3, size: 18),
                        selected: state.ttsVoice == voice.$1,
                        onSelected: (_) => state.setTtsVoice(voice.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Se não houver voz do gênero instalada no aparelho, o tom '
                  'é ajustado para simular a voz (aguda na feminina, grave '
                  'na masculina) — mesmo offline.',
                  style: TextStyle(color: t.muted, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Velocidade: ',
                      style: TextStyle(color: t.muted, fontSize: 13),
                    ),
                    Text(
                      state.ttsRate.toStringAsFixed(2),
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: state.ttsRate,
                  min: 0.25,
                  max: 0.75,
                  divisions: 10,
                  activeColor: t.accent,
                  onChanged: state.setTtsRate,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Tom da voz: ',
                      style: TextStyle(color: t.muted, fontSize: 13),
                    ),
                    Text(
                      state.ttsPitch.toStringAsFixed(2),
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: state.ttsPitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 30,
                  activeColor: t.accent,
                  onChanged: state.setTtsPitch,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _themeRow(BuildContext context, int index) {
    final t = appTheme;
    final chosen = AppState.i.themeIndex;
    // O visto marca a opção ESCOLHIDA pelo usuário. No tema "Sistema" o selo
    // AUTO já indica que o tema efetivo (claro/escuro) segue o aparelho.
    final selected = chosen == index;
    final isSystemMode = chosen == kSystemThemeIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (!selected) AppState.i.setTheme(index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    kThemeNames[index],
                    style: TextStyle(color: t.text, fontSize: 15),
                  ),
                ),
                if (index == kSystemThemeIndex && isSystemMode) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'AUTO',
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check, color: t.accent, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planSection(BuildContext context) {
    final t = appTheme;
    final state = AppState.i;
    final enabled = state.planEnabled;
    final goal = state.dailyGoal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plano de leitura',
          style: TextStyle(
            color: t.text,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: t.card,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              SwitchListTile(
                value: enabled,
                activeTrackColor: t.accent,
                title: Text(
                  'Acompanhar leitura',
                  style: TextStyle(color: t.text, fontSize: 15),
                ),
                subtitle: Text(
                  'Mostra o progresso da Bíblia e a meta do dia na aba Bíblia.',
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
                onChanged: (v) => state.setPlanEnabled(v),
              ),
              if (enabled)
                ListTile(
                  title: const Text('Prazo para concluir'),
                  subtitle: Text(
                    state.planDeadline == null
                        ? 'Sem prazo — meta manual'
                        : '${state.planDeadline!.day}/${state.planDeadline!.month}/${state.planDeadline!.year} · ${state.effectiveDailyGoal} capítulos por dia',
                  ),
                  trailing: state.planDeadline == null
                      ? const Icon(Icons.event)
                      : IconButton(
                          tooltip: 'Remover prazo',
                          icon: const Icon(Icons.close),
                          onPressed: () => state.setPlanDeadline(null),
                        ),
                  onTap: () async {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final current = state.planDeadline;
                    final date = await showDatePicker(
                      context: context,
                      initialDate: current != null && !current.isBefore(today)
                          ? current
                          : today.add(const Duration(days: 365)),
                      firstDate: today,
                      lastDate: DateTime(now.year + 10, 12, 31),
                    );
                    if (date != null) await state.setPlanDeadline(date);
                  },
                ),
              if (enabled && state.planDeadline == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meta diária: $goal capítulo${goal == 1 ? '' : 's'}',
                        style: TextStyle(color: t.text, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: t.accent,
                            visualDensity: VisualDensity.compact,
                            onPressed: goal > 1
                                ? () => state.setDailyGoal(goal - 1)
                                : null,
                          ),
                          Expanded(
                            child: Slider(
                              value: goal.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              activeColor: t.accent,
                              label: '$goal',
                              onChanged: (v) => state.setDailyGoal(v.round()),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: t.accent,
                            visualDensity: VisualDensity.compact,
                            onPressed: goal < 10
                                ? () => state.setDailyGoal(goal + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _backupSection(BuildContext context) {
    final t = appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup',
          style: TextStyle(
            color: t.text,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _contactTile(
          icon: Icons.system_update_alt,
          title: 'Exportar dados',
          subtitle: 'Destaques, notas, músicas, boletim e progresso',
          onTap: () => _exportData(context),
        ),
        const SizedBox(height: 8),
        _contactTile(
          icon: Icons.settings_backup_restore,
          title: 'Importar dados',
          subtitle: 'Escolher um arquivo JSON ou colar o backup',
          onTap: () => _importData(context),
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final t = appTheme;
    final json = AppState.i.buildExportJson();
    try {
      await shareJsonFile(context, json, 'biblia-ipm-backup.json');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível compartilhar o arquivo de backup.',
            style: TextStyle(color: t.text),
          ),
        ),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    final t = appTheme;
    final ctrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: t.card,
          title: Text('Importar dados', style: TextStyle(color: t.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Escolha um arquivo de backup ou cole seu conteúdo JSON abaixo.',
                style: TextStyle(color: t.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Escolher arquivo JSON'),
                onPressed: () async {
                  try {
                    final text = await openJsonFile();
                    if (text == null) return;
                    if (!ctx.mounted) return;
                    ctrl.text = text;
                  } catch (_) {
                    if (!ctx.mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Não foi possível abrir o arquivo.'),
                      ),
                    );
                  }
                },
              ),
              Text(
                'Músicas, boletim e preferências serão substituídos. Notas e progresso serão mesclados.',
                style: TextStyle(color: t.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLines: 8,
                style: TextStyle(color: t.text),
                decoration: const InputDecoration(
                  hintText: '{ "export": 1, ... }',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      final text = ctrl.text.trim();
      if (text.isEmpty) return;
      try {
        final decoded = jsonDecode(text);
        if (decoded is! Map || decoded['export'] != 1) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Backup inválido.',
                style: TextStyle(color: t.text),
              ),
              backgroundColor: t.card,
            ),
          );
          return;
        }
        await AppState.i.importFromJson(text);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Dados restaurados com sucesso.',
              style: TextStyle(color: t.text),
            ),
            backgroundColor: t.card,
          ),
        );
      } catch (_) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível ler o backup.',
              style: TextStyle(color: t.text),
            ),
            backgroundColor: t.card,
          ),
        );
      }
    } finally {
      ctrl.dispose();
    }
  }
}
