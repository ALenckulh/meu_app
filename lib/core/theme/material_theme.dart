import 'package:flutter/material.dart';

/// Tema gerado a partir do Material Theme Builder (material-theme.zip).
class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff586421),
      surfaceTint: Color(0xff586421),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffdbea97),
      onPrimaryContainer: Color(0xff404c09),
      secondary: Color(0xff5c6145),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffe1e6c3),
      onSecondaryContainer: Color(0xff45492f),
      tertiary: Color(0xff3a665c),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffbdecdf),
      onTertiaryContainer: Color(0xff214e45),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffbfaed),
      onSurface: Color(0xff1b1c15),
      onSurfaceVariant: Color(0xff46483b),
      outline: Color(0xff77786a),
      outlineVariant: Color(0xffc7c7b7),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303129),
      inversePrimary: Color(0xffbfce7e),
      primaryFixed: Color(0xffdbea97),
      onPrimaryFixed: Color(0xff181e00),
      primaryFixedDim: Color(0xffbfce7e),
      onPrimaryFixedVariant: Color(0xff404c09),
      secondaryFixed: Color(0xffe1e6c3),
      onSecondaryFixed: Color(0xff191d08),
      secondaryFixedDim: Color(0xffc5c9a8),
      onSecondaryFixedVariant: Color(0xff45492f),
      tertiaryFixed: Color(0xffbdecdf),
      onTertiaryFixed: Color(0xff00201a),
      tertiaryFixedDim: Color(0xffa1d0c4),
      onTertiaryFixedVariant: Color(0xff214e45),
      surfaceDim: Color(0xffdbdbce),
      surfaceBright: Color(0xfffbfaed),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff5f4e7),
      surfaceContainer: Color(0xfff0eee2),
      surfaceContainerHigh: Color(0xffeae9dc),
      surfaceContainerHighest: Color(0xffe4e3d7),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffbfce7e),
      surfaceTint: Color(0xffbfce7e),
      onPrimary: Color(0xff2b3400),
      primaryContainer: Color(0xff404c09),
      onPrimaryContainer: Color(0xffdbea97),
      secondary: Color(0xffc5c9a8),
      onSecondary: Color(0xff2e331b),
      secondaryContainer: Color(0xff45492f),
      onSecondaryContainer: Color(0xffe1e6c3),
      tertiary: Color(0xffa1d0c4),
      onTertiary: Color(0xff04372f),
      tertiaryContainer: Color(0xff214e45),
      onTertiaryContainer: Color(0xffbdecdf),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff13140d),
      onSurface: Color(0xffe4e3d7),
      onSurfaceVariant: Color(0xffc7c7b7),
      outline: Color(0xff919283),
      outlineVariant: Color(0xff46483b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e3d7),
      inversePrimary: Color(0xff586421),
      primaryFixed: Color(0xffdbea97),
      onPrimaryFixed: Color(0xff181e00),
      primaryFixedDim: Color(0xffbfce7e),
      onPrimaryFixedVariant: Color(0xff404c09),
      secondaryFixed: Color(0xffe1e6c3),
      onSecondaryFixed: Color(0xff191d08),
      secondaryFixedDim: Color(0xffc5c9a8),
      onSecondaryFixedVariant: Color(0xff45492f),
      tertiaryFixed: Color(0xffbdecdf),
      onTertiaryFixed: Color(0xff00201a),
      tertiaryFixedDim: Color(0xffa1d0c4),
      onTertiaryFixedVariant: Color(0xff214e45),
      surfaceDim: Color(0xff13140d),
      surfaceBright: Color(0xff393a31),
      surfaceContainerLowest: Color(0xff0e0f08),
      surfaceContainerLow: Color(0xff1b1c15),
      surfaceContainer: Color(0xff1f2019),
      surfaceContainerHigh: Color(0xff2a2b23),
      surfaceContainerHighest: Color(0xff35352d),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  ThemeData theme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
