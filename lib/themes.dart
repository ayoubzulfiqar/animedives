import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Monochrome gradient used for card borders and logo placeholders. It adapts to
/// the active theme (white -> gray in dark, black -> gray in light) so the UI
/// stays strictly grayscale with no chromatic accents.
LinearGradient animedivesBorderGradient(BuildContext context) {
  final s = Theme.of(context).colorScheme;
  return LinearGradient(
    colors: [s.onSurface, s.outline],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Extra design tokens from the reference site that do not map onto the standard
/// [ColorScheme] (muted foreground, borders, destructive, etc.). Attached to the
/// theme via [ThemeExtension] so light and dark modes expose them consistently.
@immutable
class AnimedivesColors extends ThemeExtension<AnimedivesColors> {
  final Color mutedForeground;
  final Color border;
  final Color input;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;

  const AnimedivesColors({
    required this.mutedForeground,
    required this.border,
    required this.input,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
  });

  @override
  AnimedivesColors copyWith({
    Color? mutedForeground,
    Color? border,
    Color? input,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
  }) =>
      AnimedivesColors(
        mutedForeground: mutedForeground ?? this.mutedForeground,
        border: border ?? this.border,
        input: input ?? this.input,
        accent: accent ?? this.accent,
        accentForeground: accentForeground ?? this.accentForeground,
        destructive: destructive ?? this.destructive,
        destructiveForeground:
            destructiveForeground ?? this.destructiveForeground,
      );

  @override
  AnimedivesColors lerp(ThemeExtension<AnimedivesColors>? other, double t) {
    if (other is! AnimedivesColors) return this;
    return AnimedivesColors(
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(accentForeground, other.accentForeground, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground:
          Color.lerp(destructiveForeground, other.destructiveForeground, t)!,
    );
  }
}

const AnimedivesColors _lightAnimedives = AnimedivesColors(
  mutedForeground: Color(0xFF525252),
  border: Color(0xFFe4e4e4),
  input: Color(0xFFebebeb),
  accent: Color(0xFFebebeb),
  accentForeground: Color(0xFF000000),
  destructive: Color(0xFFe54b4f),
  destructiveForeground: Color(0xFFffffff),
);

const AnimedivesColors _darkAnimedives = AnimedivesColors(
  mutedForeground: Color(0xFFa4a4a4),
  border: Color(0xFF242424),
  input: Color(0xFF333333),
  accent: Color(0xFF333333),
  accentForeground: Color(0xFFffffff),
  destructive: Color(0xFFff5b5b),
  destructiveForeground: Color(0xFF000000),
);

/// Applies the Bricolage Grotesque font family to a base [TextTheme].
TextTheme _bricolage(TextTheme base) =>
    GoogleFonts.bricolageGrotesqueTextTheme(base);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFfcfcfc),
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF000000),
    onPrimary: const Color(0xFFffffff),
    secondary: const Color(0xFFebebeb),
    onSecondary: const Color(0xFF000000),
    surface: const Color(0xFFffffff),
    onSurface: const Color(0xFF000000),
    surfaceContainerHighest: const Color(0xFFf5f5f5),
    error: const Color(0xFFe54b4f),
    onError: const Color(0xFFffffff),
    outline: const Color(0xFFe4e4e4),
    outlineVariant: const Color(0xFFebebeb),
    inverseSurface: const Color(0xFF000000),
    inversePrimary: const Color(0xFFffffff),
  ),
  extensions: const <ThemeExtension<dynamic>>[_lightAnimedives],
  textTheme: _bricolage(Typography.material2021().black),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Color(0xFF000000),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Color(0xFFffffff),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: Color(0xFFffffff),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  // True AMOLED: pure black background and surfaces so pixels can switch off.
  scaffoldBackgroundColor: const Color(0xFF000000),
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFFffffff),
    onPrimary: const Color(0xFF000000),
    secondary: const Color(0xFF1a1a1a),
    onSecondary: const Color(0xFFffffff),
    surface: const Color(0xFF000000),
    onSurface: const Color(0xFFffffff),
    surfaceContainerHighest: const Color(0xFF121212),
    error: const Color(0xFFff5b5b),
    onError: const Color(0xFF000000),
    outline: const Color(0xFF242424),
    outlineVariant: const Color(0xFF333333),
    inverseSurface: const Color(0xFFffffff),
    inversePrimary: const Color(0xFF000000),
  ),
  extensions: const <ThemeExtension<dynamic>>[_darkAnimedives],
  textTheme: _bricolage(Typography.material2021().white),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Color(0xFFffffff),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFffffff),
      foregroundColor: Color(0xFF000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: Color(0xFF000000),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),
);
