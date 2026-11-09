import 'package:flutter/material.dart';

/// Shared visual tokens for the warm, map-led BASE 67 interface.
abstract final class GameColors {
  static const ink = Color(0xFF111B2B);
  static const night = Color(0xFF18263A);
  static const rust = Color(0xFFB84E32);
  static const mars = Color(0xFFC9754F);
  static const sand = Color(0xFFF3D5A1);
  static const paper = Color(0xFFFFF8EB);
  static const teal = Color(0xFF167F78);
  static const tealLight = Color(0xFFB9E4D8);
  static const danger = Color(0xFFAD3D44);
  static const gold = Color(0xFFE8B54D);
  static const muted = Color(0xFF617083);
  static const outline = Color(0xFFD6C7AE);
  static const colorBlindSafeBlue = Color(0xFF2878A5);
  static const colorBlindSafeOrange = Color(0xFFE69F00);
}

abstract final class GameSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double page = 18;
  static const double messageViewport = 180;
}

abstract final class GameRadii {
  static const double card = 22;
  static const double button = 18;
  static const double pill = 40;
}

abstract final class GameMotion {
  static const Duration short = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration idle = Duration(milliseconds: 1800);
}

const textScaleOptions = <double>[0.9, 1.0, 1.2, 1.4];

class Base67Theme {
  const Base67Theme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: GameColors.rust,
      brightness: Brightness.light,
      primary: GameColors.rust,
      secondary: GameColors.teal,
      surface: GameColors.paper,
      error: GameColors.danger,
    );
    final baseText = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'Roboto',
    ).textTheme;
    final scaled = baseText;
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: GameColors.paper,
      textTheme: scaled.copyWith(
        headlineSmall: scaled.headlineSmall?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: GameColors.ink,
        ),
        headlineLarge: scaled.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: GameColors.ink,
          letterSpacing: -0.5,
        ),
        headlineMedium: scaled.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: GameColors.ink,
        ),
        titleLarge: scaled.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: GameColors.ink,
        ),
        bodyLarge: scaled.bodyLarge?.copyWith(
          fontSize: 18,
          color: GameColors.ink,
        ),
        bodyMedium: scaled.bodyMedium?.copyWith(
          fontSize: 16,
          color: GameColors.ink,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GameColors.paper,
        foregroundColor: GameColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: GameColors.ink.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameRadii.card),
          side: const BorderSide(color: GameColors.outline, width: 0.7),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameRadii.button),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameRadii.button),
          ),
          side: const BorderSide(color: GameColors.teal, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

double textScaleFromSetting(Object? value) {
  final scale = value is num ? value.toDouble() : 1.0;
  return textScaleOptions.contains(scale) ? scale : 1.0;
}
