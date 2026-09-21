import 'package:flutter/material.dart';

class AppTheme {
  final Color bg;
  final Color card;
  final Color text;
  final Color muted;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color accentDark;
  final Color light;
  final Color tabSelected;
  final Color redText;

  const AppTheme({
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.accentDark,
    required this.light,
    required this.tabSelected,
    required this.redText,
  });
}

const AppTheme kClaro = AppTheme(
  bg: Color(0xFFFAFAFB),
  card: Color(0xFFFFFFFF),
  text: Color(0xFF1B1B1F),
  muted: Color(0xFF6B7280),
  primary: Color(0xFF154360),
  primaryDark: Color(0xFF0E2E44),
  accent: Color(0xFFE67E22),
  accentDark: Color(0xFFB45309),
  light: Color(0xFFEEF2F6),
  tabSelected: Color(0xFF1F5E93),
  redText: Color(0xFFC62828),
);

const AppTheme kEscuro = AppTheme(
  bg: Color(0xFF121212),
  card: Color(0xFF1E1E1E),
  text: Color(0xFFE6E6E6),
  muted: Color(0xFF9E9E9E),
  primary: Color(0xFF5B9BD5),
  primaryDark: Color(0xFF0F2537),
  accent: Color(0xFFF5A623),
  accentDark: Color(0xFFC0841A),
  light: Color(0xFF2A2A2A),
  tabSelected: Color(0xFF2D5C8A),
  redText: Color(0xFFFF8A80),
);

const AppTheme kMarrom = AppTheme(
  bg: Color(0xFFFBF4E6),
  card: Color(0xFFFFFDF7),
  text: Color(0xFF4A361F),
  muted: Color(0xFF9B7B4F),
  primary: Color(0xFFA5702C),
  primaryDark: Color(0xFF7C5218),
  accent: Color(0xFFD9A034),
  accentDark: Color(0xFFB07C1E),
  light: Color(0xFFF2E6CC),
  tabSelected: Color(0xFFBC8A3C),
  redText: Color(0xFFB3261E),
);

const AppTheme kVerde = AppTheme(
  bg: Color(0xFFF6FBF8),
  card: Color(0xFFFFFFFF),
  text: Color(0xFF12261B),
  muted: Color(0xFF5C7B6A),
  primary: Color(0xFF0D5131),
  primaryDark: Color(0xFF07321E),
  accent: Color(0xFF38AF00),
  accentDark: Color(0xFF2E8B00),
  light: Color(0xFFE7F4F2),
  tabSelected: Color(0xFF2C8B6C),
  redText: Color(0xFFB3261E),
);

const List<AppTheme> kThemes = [kClaro, kEscuro, kMarrom, kVerde];

/// Índice do tema "Sistema" (segue o claro/escuro do aparelho).
const int kSystemThemeIndex = 4;

const List<String> kThemeNames = [
  'Claro',
  'Escuro',
  'Marrom',
  'Verde',
  'Sistema',
];

/// Resolve o brilho (claro/escuro) de um índice de tema. O tema Sistema usa
/// o brilho do aparelho ([system]); os demais têm brilho fixo.
Brightness resolveBrightness(int index,
    [Brightness system = Brightness.light]) {
  if (index == kSystemThemeIndex) return system;
  return index == 1 ? Brightness.dark : Brightness.light;
}

/// Paleta efetiva para um índice de tema. No tema Sistema, alterna entre a
/// paleta clara e a escura conforme o brilho do aparelho.
AppTheme themeForIndex(int index,
    [Brightness system = Brightness.light]) {
  if (index == kSystemThemeIndex) {
    return system == Brightness.dark ? kEscuro : kClaro;
  }
  return kThemes[index];
}

/// Índice do tema efetivamente exibido. No tema Sistema, retorna 0 (claro)
/// ou 1 (escuro) conforme o brilho do aparelho.
int effectiveThemeIndex(int index,
    [Brightness system = Brightness.light]) {
  if (index == kSystemThemeIndex) {
    return system == Brightness.dark ? 1 : 0;
  }
  return index;
}

const List<double> kFontLevels = [0.85, 1.0, 1.15, 1.30];
const List<String> kFontLevelNames = [
  'Pequeno',
  'Normal',
  'Grande',
  'Extra grande',
];

int fontLevelIndex(double scale) {
  for (var i = 0; i < kFontLevels.length; i++) {
    if ((kFontLevels[i] - scale).abs() < 0.001) return i;
  }
  return 1;
}