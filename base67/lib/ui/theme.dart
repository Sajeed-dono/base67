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

  // Semantic B1 roles. Legacy colors above stay stable for existing painters.
  static const structuralSurface = paper;
  static const structuralRaised = Color(0xFFFFFCF6);
  static const structuralInset = Color(0xFFF0E8D9);
  static const onStructural = ink;
  static const architecturalAccent = rust;
  static const machinery = Color(0xFF596B7D);
  static const machineryHighlight = Color(0xFFBCCBD5);
  static const terrain = mars;
  static const terrainHighlight = sand;
  static const controlSurface = night;
  static const controlRaised = Color(0xFF23354A);
  static const controlOutline = Color(0xFF7B91A4);
  static const onControl = paper;
  static const onControlSecondary = machineryHighlight;
  static const information = teal;
  static const informationOnControl = tealLight;
  static const informationSurface = Color(0xFFEAF1F3);
  static const radioSurface = Color(0xFFF4E6CC);
  static const critical = danger;
  static const onCritical = paper;

  // Original colony scenery: one sun direction, cream modules and rust IDs.
  static const marsSky = Color(0xFFD7AA8B);
  static const marsSkyHigh = Color(0xFF8B9BA3);
  static const marsHaze = Color(0xFFEAC49A);
  static const marsGround = Color(0xFFC47D55);
  static const marsLit = Color(0xFFE2A573);
  static const marsRock = Color(0xFF875340);
  static const marsRockShade = Color(0xFF633D34);
  static const marsDistant = Color(0xFFB4826D);
  static const marsNight = Color(0xFF283647);
  static const solarGlass = Color(0xFF244F70);
  static const solarCellLine = Color(0xFF8CB1C2);
  static const moduleShade = Color(0xFFC7BCA9);
  static const workLight = Color(0xFFFFDC99);
}

abstract final class GameSpacing {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double compact = 12;
  static const double panelCompact = 14;
  static const double iconGap = 10;
  static const double sheetHorizontal = 20;
  static const double buttonVertical = 12;
  static const double primaryButtonHeight = 52;
  static const double secondaryButtonHeight = 50;
  static const double gaugeHeight = 12;
  static const double gaugeGap = 5;
  static const double resourceGap = 6;
  static const double page = 18;
  static const double messageViewport = 180;
  static const double missionMapHeight = 360;
  static const double missionCrewSize = 76;
  static const double contentMaxWidth = 720;
  static const double touchTarget = 48;
  static const double homeMapHeight = 400;
  static const double mapAstronaut = 32;
  static const double joystick = 144;
  static const double joystickKnob = 48;
  static const double telemetryWide = 560;
  static const double splashMaxWidth = 480;
}

/// Cosmetic navigation tuning in presentation world units; never Mars units.
abstract final class CrewMotion {
  static const double speed = 64;
  static const double grid = 8;
  static const double radius = 7;
  static const double separation = 16;
  static const double maxFrameSeconds = .05;
  static const double stride = .42;
}

abstract final class SettlementView {
  static const world = Size(900, 700);
  static const initialZoom = .9;
  static const maxZoom = 1.8;
  static const zoomStep = 1.2;
  static const followResponse = 8.0;
  static const cameraEpsilon = .2;
  static const inspectionMaxHeight = 440.0;
}

abstract final class GameRadii {
  static const double card = 22;
  static const double button = 18;
  static const double pill = 40;
  static const double panel = 16;
  static const double chip = 12;
}

abstract final class GameBorders {
  static const double subtle = 1;
  static const double standard = 1.5;
  static const double strong = 2;
}

abstract final class GameElevation {
  static const double flat = 0;
  static const double card = 2;
  static const double panel = 4;
}

abstract final class GameOpacity {
  static const double cardShadow = .08;
  static const double panelShadow = .30;
  static const double captionSurface = .88;
  static const double captionBorder = .45;
  static const double gaugeTrack = .45;
}

abstract final class GameIconSizes {
  static const double button = 20;
  static const double metric = 28;
  static const double facility = 30;
}

/// Font sizes remain unscaled: MediaQuery and the existing setting scale them.
abstract final class GameTypography {
  static const String family = 'Roboto';
  static const double displayLarge = 57;
  static const double displayMedium = 45;
  static const double displaySmall = 36;
  static const double headlineLarge = 32;
  static const double headlineMedium = 28;
  static const double headlineSmall = 24;
  static const double titleLarge = 22;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  static const double bodyLarge = 18;
  static const double body = 16;
  static const double caption = 14;
  static const double label = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 11;
  static const double bodyHeight = 1.35;
  static const double headingTracking = -.5;
  static const FontWeight headingWeight = FontWeight.w800;
  static const FontWeight titleWeight = FontWeight.w800;
  static const FontWeight labelWeight = FontWeight.w700;

  static TextTheme resolve(TextTheme base, Color foreground) => base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontSize: displayLarge,
      fontWeight: headingWeight,
      color: foreground,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontSize: displayMedium,
      fontWeight: headingWeight,
      color: foreground,
    ),
    displaySmall: base.displaySmall?.copyWith(
      fontSize: displaySmall,
      fontWeight: headingWeight,
      color: foreground,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontSize: headlineLarge,
      fontWeight: FontWeight.w900,
      letterSpacing: headingTracking,
      color: foreground,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: headlineMedium,
      fontWeight: headingWeight,
      color: foreground,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontSize: headlineSmall,
      fontWeight: headingWeight,
      color: foreground,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: titleLarge,
      fontWeight: titleWeight,
      color: foreground,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: titleMedium,
      fontWeight: titleWeight,
      color: foreground,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontSize: titleSmall,
      fontWeight: FontWeight.w700,
      color: foreground,
    ),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: bodyLarge, color: foreground),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: body,
      height: bodyHeight,
      color: foreground,
    ),
    bodySmall: base.bodySmall?.copyWith(fontSize: caption, color: foreground),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: label,
      fontWeight: labelWeight,
      color: foreground,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: labelMedium,
      fontWeight: labelWeight,
      color: foreground,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontSize: labelSmall,
      fontWeight: labelWeight,
      color: foreground,
    ),
  );
}

abstract final class GameMotion {
  static const Duration short = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration idle = Duration(milliseconds: 1800);
}

const textScaleOptions = <double>[0.9, 1.0, 1.2, 1.4];

class Base67Theme {
  const Base67Theme._();

  static ThemeData light() => _build(Brightness.light);

  /// Opt-in control surface; does not switch existing screens to a dark theme.
  static ThemeData missionControl() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final control = brightness == Brightness.dark;
    final surface = control
        ? GameColors.controlSurface
        : GameColors.structuralSurface;
    final raised = control
        ? GameColors.controlRaised
        : GameColors.structuralRaised;
    final foreground = control ? GameColors.onControl : GameColors.onStructural;
    final outline = control ? GameColors.controlOutline : GameColors.outline;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: GameColors.architecturalAccent,
          brightness: brightness,
          primary: GameColors.architecturalAccent,
          onPrimary: GameColors.paper,
          secondary: control
              ? GameColors.informationOnControl
              : GameColors.information,
          onSecondary: control ? GameColors.ink : GameColors.paper,
          surface: surface,
          onSurface: foreground,
          error: GameColors.critical,
          onError: GameColors.onCritical,
        ).copyWith(
          outline: outline,
          onSurfaceVariant: control
              ? GameColors.onControlSecondary
              : GameColors.machinery,
          surfaceContainerLow: raised,
          surfaceContainerHighest: control
              ? GameColors.controlRaised
              : GameColors.structuralInset,
        );
    final baseText = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: GameTypography.family,
    ).textTheme;
    final typography = GameTypography.resolve(baseText, foreground);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: GameTypography.family,
      scaffoldBackgroundColor: surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            GameSpacing.touchTarget,
            GameSpacing.touchTarget,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      iconTheme: IconThemeData(color: scheme.secondary),
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: GameBorders.subtle,
        space: GameSpacing.md,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(GameSpacing.md),
        labelStyle: typography.bodyMedium,
        hintStyle: typography.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GameRadii.button),
          borderSide: BorderSide(color: outline, width: GameBorders.subtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GameRadii.button),
          borderSide: BorderSide(color: outline, width: GameBorders.subtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GameRadii.button),
          borderSide: BorderSide(
            color: scheme.secondary,
            width: GameBorders.strong,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(GameRadii.card),
          ),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: scheme.secondary,
        collapsedIconColor: scheme.secondary,
        textColor: foreground,
        collapsedTextColor: foreground,
        childrenPadding: const EdgeInsets.all(GameSpacing.sm),
      ),
      textTheme: typography,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: GameElevation.flat,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: raised,
        surfaceTintColor: Colors.transparent,
        elevation: GameElevation.card,
        shadowColor: GameColors.ink.withValues(alpha: GameOpacity.cardShadow),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameRadii.card),
          side: BorderSide(color: outline, width: GameBorders.subtle),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            GameSpacing.touchTarget,
            GameSpacing.primaryButtonHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: GameSpacing.page,
            vertical: GameSpacing.buttonVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameRadii.button),
          ),
          textStyle: typography.bodyMedium?.copyWith(
            fontWeight: GameTypography.headingWeight,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            GameSpacing.touchTarget,
            GameSpacing.secondaryButtonHeight,
          ),
          foregroundColor: scheme.secondary,
          padding: const EdgeInsets.symmetric(
            horizontal: GameSpacing.page,
            vertical: GameSpacing.buttonVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameRadii.button),
          ),
          side: BorderSide(
            color: scheme.secondary,
            width: GameBorders.standard,
          ),
          textStyle: typography.bodyMedium?.copyWith(
            fontWeight: GameTypography.labelWeight,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            GameSpacing.touchTarget,
            GameSpacing.touchTarget,
          ),
          foregroundColor: scheme.secondary,
          textStyle: typography.bodyMedium?.copyWith(
            fontWeight: GameTypography.labelWeight,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
    );
  }
}

double textScaleFromSetting(Object? value) {
  final scale = value is num ? value.toDouble() : 1.0;
  return textScaleOptions.contains(scale) ? scale : 1.0;
}
