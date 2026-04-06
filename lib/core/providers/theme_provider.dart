import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeColors {
  final List<Color> bgGradient;
  final List<Color> glowColors;
  final Color primary;
  final Color buttonColor;
  final Color textColor;        // main text on background
  final Color subTextColor;     // secondary/hint text on background
  final Color buttonTextColor;  // text on button

  const AppThemeColors({
    required this.bgGradient,
    required this.glowColors,
    required this.primary,
    required this.buttonColor,
    required this.textColor,
    required this.subTextColor,
    required this.buttonTextColor,
  });
}

Color _textOn(Color bg) =>
    bg.computeLuminance() > 0.4 ? const Color(0xFF1A1A2E) : Colors.white;

Color _subTextOn(Color bg) => _textOn(bg).withOpacity(0.70);

/// Generates a full theme from a single hue value (0–360).
AppThemeColors themeFromHue(double hue) {
  Color hsl(double h, double s, double l) =>
      HSLColor.fromAHSL(1.0, h % 360, s, l).toColor();

  final bgMid    = hsl(hue, 0.88, 0.40);
  final btnColor  = hsl(hue, 0.60, 0.72);

  return AppThemeColors(
    bgGradient: [
      hsl(hue, 0.75, 0.60),
      bgMid,
      hsl(hue, 0.95, 0.18),
    ],
    glowColors: [
      hsl(hue + 25, 0.80, 0.68),
      hsl(hue - 20, 0.75, 0.60),
    ],
    primary:         hsl(hue, 0.82, 0.48),
    buttonColor:     btnColor,
    textColor:       _textOn(bgMid),
    subTextColor:    _subTextOn(bgMid),
    buttonTextColor: _textOn(btnColor),
  );
}

class HueNotifier extends StateNotifier<double> {
  static const _key = 'app_hue';

  HueNotifier() : super(270.0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_key);
    if (saved != null) state = saved;
  }

  void setHue(double hue) {
    state = hue.clamp(0.0, 360.0);
  }

  Future<void> saveHue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, state);
  }
}

final hueProvider = StateNotifierProvider<HueNotifier, double>(
  (ref) => HueNotifier(),
);

final appThemeColorsProvider = Provider<AppThemeColors>((ref) {
  return themeFromHue(ref.watch(hueProvider));
});
