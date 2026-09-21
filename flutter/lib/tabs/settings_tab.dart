import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common.dart';
import '../store.dart';
import '../theme.dart';

const String kContactEmail = 'valdenorsa@proton.me';
const String kContactWhatsapp = '+55 81 98835-3131';
const String kContactWhatsappLink = 'https://wa.me/5581988353131';
const String kInstagramLink = 'https://www.instagram.com/ipmadalena/';
const String kInstagramHandle = '@ipmadalena';
const String kYoutubeLink = 'https://www.youtube.com/@IPMadalena';
const String kYoutubeHandle = 'IP Madalena';
const String kPixKey = '09.829.847/0001-58';
const String kPixBeneficiario = 'IP Madalena';

Future<void> _openEmail() async {
  await launchUrl(Uri(scheme: 'mailto', path: kContactEmail));
}

Future<void> _openWhatsapp() async {
  await launchUrl(Uri.parse(kContactWhatsappLink));
}

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
            Text('Configurações',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.text, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('$kAppName - versão ${state.appVersion}',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted, fontSize: 13)),
            const SizedBox(height: 20),
            Text('Tamanho da letra',
                style: TextStyle(
                    color: t.text, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(kFontLevelNames[level],
                textAlign: TextAlign.center,
                style: TextStyle(color: t.accent, fontSize: 14)),
            Slider(
              value: level.toDouble(),
              min: 0,
              max: (kFontLevels.length - 1).toDouble(),
              divisions: kFontLevels.length - 1,
              activeColor: t.accent,
              label: kFontLevelNames[level],
              onChanged: (v) =>
                  state.setFontScale(kFontLevels[v.round()]),
            ),
            Row(
              children: [
                for (final n in kFontLevelNames)
                  Expanded(
                    child: Text(n,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.muted, fontSize: 12)),
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
            Text('Aparência',
                style: TextStyle(
                    color: t.text, fontSize: 15, fontWeight: FontWeight.bold)),
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
            _pixSection(context),
            _contactSection(context),
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

  Future<void> _openInstagram() async {
    await launchUrl(Uri.parse(kInstagramLink));
  }

  Future<void> _openYoutube() async {
    await launchUrl(Uri.parse(kYoutubeLink));
  }

  Widget _pixSection(BuildContext context) {
    final t = appTheme;
    final messenger = ScaffoldMessenger.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dízimos e ofertas',
            style: TextStyle(
                color: t.text, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Material(
          color: t.card,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A550),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code_2,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Contribua pela chave Pix (CNPJ), com sua oferta e '
                        'dízimo, e ajude a obra do Senhor.',
                        style: TextStyle(color: t.muted, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: t.light,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kPixKey,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Beneficiário: $kPixBeneficiario',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await copyText(kPixKey);
                        messenger.showSnackBar(SnackBar(
                          content: Text('Chave Pix copiada.',
                              style: TextStyle(color: t.text)),
                          backgroundColor: t.card,
                        ));
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copiar chave'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => shareText(
                          'Dízimos e ofertas — $kPixBeneficiario\n'
                          'Chave Pix (CNPJ): $kPixKey'),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Compartilhar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _contactSection(BuildContext context) {
    final t = appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              'assets/logo_ipm.png',
              width: 220,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Contato',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: t.text, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(kAppName,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.muted, fontSize: 12)),
        const SizedBox(height: 8),
        _contactTile(
          icon: Icons.email,
          title: kContactEmail,
          subtitle: 'Enviar e-mail',
          onTap: _openEmail,
        ),
        const SizedBox(height: 8),
        _contactTile(
          icon: Icons.chat,
          title: kContactWhatsapp,
          subtitle: 'Conversar no WhatsApp',
          onTap: _openWhatsapp,
        ),
        const SizedBox(height: 8),
        _contactTile(
          icon: Icons.camera_alt,
          title: kInstagramHandle,
          subtitle: 'Seguir no Instagram',
          onTap: _openInstagram,
        ),
        const SizedBox(height: 8),
        _contactTile(
          icon: Icons.play_circle_fill,
          title: kYoutubeHandle,
          subtitle: 'Assistir no YouTube',
          onTap: _openYoutube,
        ),
      ],
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
                    Text(title,
                        style: TextStyle(color: t.text, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(color: t.muted, fontSize: 12)),
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
              Text('Versão ${AppState.i.appVersion}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.muted, fontSize: 13)),
              const SizedBox(height: 12),
              Text(
                'Bíblia em 5 traduções, Hinário Novo Cântico, Músicas, '
                'Biblioteca de credos e Boletim da igreja — tudo offline. '
                'Destaques, notas, plano de leitura e backup dos seus dados.',
                style: TextStyle(color: t.text, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _openInstagram,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Instagram'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _openYoutube,
                    icon: const Icon(Icons.play_circle_fill, size: 18),
                    label: const Text('YouTube'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _openEmail,
                    icon: const Icon(Icons.email, size: 18),
                    label: const Text('E-mail'),
                  ),
                ],
              ),
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
        Text('Leitura por voz',
            style: TextStyle(
                color: t.text, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Material(
          color: t.card,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voz',
                    style: TextStyle(color: t.muted, fontSize: 13)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'default',
                      label: Text('Padrão'),
                      icon: Icon(Icons.record_voice_over, size: 18),
                    ),
                    ButtonSegment(
                      value: 'female',
                      label: Text('Feminina'),
                      icon: Icon(Icons.female, size: 18),
                    ),
                    ButtonSegment(
                      value: 'male',
                      label: Text('Masculina'),
                      icon: Icon(Icons.male, size: 18),
                    ),
                  ],
                  selected: {state.ttsVoice},
                  onSelectionChanged: (s) => state.setTtsVoice(s.first),
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
                    Text('Velocidade: ',
                        style: TextStyle(color: t.muted, fontSize: 13)),
                    Text(state.ttsRate.toStringAsFixed(2),
                        style: TextStyle(
                            color: t.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
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
                    Text('Tom da voz: ',
                        style: TextStyle(color: t.muted, fontSize: 13)),
                    Text(state.ttsPitch.toStringAsFixed(2),
                        style: TextStyle(
                            color: t.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
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
    final selected = AppState.i.themeIndex == index;
    final swatch = themeForIndex(index, AppState.i.systemBrightness);
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                if (index == kSystemThemeIndex)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [Colors.white, Colors.black],
                        stops: [0.0, 1.0],
                      ),
                      border: Border.all(color: Colors.black26),
                    ),
                  )
                else
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: swatch.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(kThemeNames[index],
                      style: TextStyle(color: t.text, fontSize: 15)),
                ),
                if (selected)
                  Icon(Icons.check, color: t.accent, size: 20),
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
        Text('Plano de leitura',
            style: TextStyle(
                color: t.text, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Material(
          color: t.card,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              SwitchListTile(
                value: enabled,
                activeTrackColor: t.accent,
                title: Text('Plano anual',
                    style: TextStyle(color: t.text, fontSize: 15)),
                subtitle: Text(
                  'Mostra o progresso da Bíblia e a meta do dia na aba Bíblia.',
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
                onChanged: (v) => state.setPlanEnabled(v),
              ),
              if (enabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meta diária: $goal capítulo${goal == 1 ? '' : 's'}',
                          style: TextStyle(color: t.text, fontSize: 14)),
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
                              onChanged: (v) =>
                                  state.setDailyGoal(v.round()),
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
        Text('Backup',
            style: TextStyle(
                color: t.text, fontSize: 15, fontWeight: FontWeight.bold)),
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
          subtitle: 'Restaura um backup colado abaixo',
          onTap: () => _importData(context),
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final t = appTheme;
    final json = AppState.i.buildExportJson();
    await copyText(json);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(
        'Backup copiado para a área de transferência. Envie por e-mail/'
        'WhatsApp ou salve num arquivo.',
        style: TextStyle(color: t.text),
      ),
      backgroundColor: t.card,
    ));
    shareText(json);
  }

  Future<void> _importData(BuildContext context) async {
    final t = appTheme;
    final ctrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        title: Text('Importar dados', style: TextStyle(color: t.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cole abaixo o backup (JSON) copiado pela opção "Exportar dados".',
              style: TextStyle(color: t.muted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              maxLines: 8,
              style: TextStyle(color: t.text),
              decoration: const InputDecoration(hintText: '{ "export": 1, ... }'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok != true) return;
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map || decoded['export'] != 1) {
        messenger.showSnackBar(SnackBar(
          content: Text('Backup inválido.', style: TextStyle(color: t.text)),
          backgroundColor: t.card,
        ));
        return;
      }
      await AppState.i.importFromJson(text);
      messenger.showSnackBar(SnackBar(
        content:
            Text('Dados restaurados com sucesso.', style: TextStyle(color: t.text)),
        backgroundColor: t.card,
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text('Não foi possível ler o backup.',
            style: TextStyle(color: t.text)),
        backgroundColor: t.card,
      ));
    }
  }
}
