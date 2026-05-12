import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Global theme notifier ─────────────────────────────────────────────────────

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final s = prefs.getString('theme_mode') ?? 'system';
  themeModeNotifier.value =
      s == 'dark' ? ThemeMode.dark : s == 'light' ? ThemeMode.light : ThemeMode.system;
}

Future<void> saveTheme(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme_mode',
      mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.light ? 'light' : 'system');
}

// ── Color tokens ──────────────────────────────────────────────────────────────

class AC {
  final Color blue;
  final Color blueLight;
  final Color bg;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;

  const AC({
    required this.blue,
    required this.blueLight,
    required this.bg,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
  });

  static const light = AC(
    blue: Color(0xFF185FA5),
    blueLight: Color(0xFFE6F1FB),
    bg: Color(0xFFF2F5F9),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    border: Color(0xFFE5E7EB),
  );

  static const dark = AC(
    blue: Color(0xFF60ABEF),
    blueLight: Color(0xFF0D253F),
    bg: Color(0xFF0F172A),
    card: Color(0xFF1E293B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textTertiary: Color(0xFF64748B),
    border: Color(0xFF334155),
  );
}

const kPinned = Color(0xFFFACC15);
const kPinnedBg = Color(0xFFFEF9C3);
const kPinnedBgDark = Color(0xFF2D1F00);

extension AppColorsExt on BuildContext {
  AC get ac => Theme.of(this).brightness == Brightness.dark ? AC.dark : AC.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ── ThemeData ─────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF185FA5),
        scaffoldBackgroundColor: const Color(0xFFF2F5F9),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF60ABEF),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      );
}
