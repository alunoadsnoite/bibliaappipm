import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common.dart';
import '../store.dart';
import '../theme.dart';

const String kContactEmail = 'valdenorsa@proton.me';
const String kContactWhatsapp = '+55 81 98835-3131';
const String kContactWhatsappLink = 'https://wa.me/5581988353131';

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

    return Container(
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
            Text('$kAppName - versão $kAppVersion',
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
            for (var i = 0; i < kThemes.length; i++) _themeRow(context, i),
            const SizedBox(height: 20),
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

  Widget _themeRow(BuildContext context, int index) {
    final t = appTheme;
    final selected = AppState.i.themeIndex == index;
    final swatch = kThemes[index];
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
}
