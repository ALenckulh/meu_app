import 'package:flutter/material.dart';
import 'package:meu_app/core/theme/app_semantic_colors.dart';

/// Tema do app — paleta violeta com acento verde-azulado (teal), cantos
/// generosos, botões em formato pílula e cards brancos com sombra suave.
///
/// Papéis de cor:
/// - primary: violeta (identidade da marca)
/// - secondary: lavanda acinzentada (apoio discreto, derivada do violeta)
/// - tertiary: verde-azulado (acento de contraste ao violeta)
/// - error: vermelho
class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      // Violeta — mantido
      primary: Color(0xff5b4be0),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffe7e2ff),
      onPrimaryContainer: Color(0xff1b1147),
      // Lavanda acinzentada — apoio que não compete com o primário
      secondary: Color(0xff625b87),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffe8e3f8),
      onSecondaryContainer: Color(0xff1e1a3d),
      // Verde-azulado — acento de contraste ao violeta
      tertiary: Color(0xff007f6d),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffc5f1e6),
      onTertiaryContainer: Color(0xff00201a),
      // Vermelho — levemente escurecido para atingir contraste AA com branco
      error: Color(0xffc93a47),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffe1e1),
      onErrorContainer: Color(0xff5a1015),
      surface: Color(0xffffffff),
      onSurface: Color(0xff1c1b1f),
      onSurfaceVariant: Color(0xff5a5563),
      outline: Color(0xff8a8592),
      outlineVariant: Color(0xffe4e1e9),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313036),
      onInverseSurface: Color(0xfff3f0f6),
      inversePrimary: Color(0xffc7bfff),
      surfaceTint: Color(0xff5b4be0),
      surfaceDim: Color(0xffe6e3ec),
      surfaceBright: Color(0xffffffff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff8f7fb),
      surfaceContainer: Color(0xfff3f1f7),
      surfaceContainerHigh: Color(0xffedebf3),
      surfaceContainerHighest: Color(0xffe7e4ee),
    );
  }

  ThemeData light() {
    return theme(lightScheme(), AppSemanticColors.light);
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffc7bfff),
      onPrimary: Color(0xff2a1d66),
      primaryContainer: Color(0xff42359c),
      onPrimaryContainer: Color(0xffe7e2ff),
      secondary: Color(0xffcbc3ec),
      onSecondary: Color(0xff332d55),
      secondaryContainer: Color(0xff4a436e),
      onSecondaryContainer: Color(0xffe8e3f8),
      tertiary: Color(0xff6fdac3),
      onTertiary: Color(0xff00382f),
      tertiaryContainer: Color(0xff005144),
      onTertiaryContainer: Color(0xffc5f1e6),
      error: Color(0xffffb3b6),
      onError: Color(0xff680014),
      errorContainer: Color(0xff8c2f37),
      onErrorContainer: Color(0xffffe1e1),
      surface: Color(0xff151319),
      onSurface: Color(0xffe9e4ee),
      onSurfaceVariant: Color(0xffc9c2d3),
      outline: Color(0xff938d9d),
      outlineVariant: Color(0xff48434f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e4ee),
      onInverseSurface: Color(0xff33303a),
      inversePrimary: Color(0xff5b4be0),
      surfaceTint: Color(0xffc7bfff),
      surfaceDim: Color(0xff151319),
      surfaceBright: Color(0xff3b3740),
      surfaceContainerLowest: Color(0xff100e14),
      surfaceContainerLow: Color(0xff1d1a22),
      surfaceContainer: Color(0xff211e26),
      surfaceContainerHigh: Color(0xff2b2831),
      surfaceContainerHighest: Color(0xff36323c),
    );
  }

  ThemeData dark() {
    return theme(darkScheme(), AppSemanticColors.dark);
  }

  ThemeData theme(ColorScheme colorScheme, AppSemanticColors semantic) {
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final TextTheme text = textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: text,
      // Transparente: o degradê de fundo é pintado pelo `builder` do
      // MaterialApp (ver AppGradients.background), atrás de todos os Scaffolds.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: colorScheme.surface,
      extensions: <ThemeExtension<dynamic>>[semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.primary.withValues(alpha: isDark ? 0.0 : 0.14),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        iconColor: colorScheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 6,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest,
        border: inputBorder(colorScheme.outlineVariant),
        enabledBorder: inputBorder(colorScheme.outlineVariant),
        focusedBorder: inputBorder(colorScheme.primary, 2),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}