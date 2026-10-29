import 'package:flutter/material.dart';
import 'package:meu_app/core/theme/app_semantic_colors.dart';

/// Tema do app no visual da Católica de Santa Catarina (catolicasc.org.br):
/// bordô institucional, dourado de acento, cinzas neutros, Poppins no texto,
/// Montserrat nos títulos, cantos de 10–12px e botões em pílula.
///
/// Papéis de cor:
/// - primary: bordô #9B1536 (identidade da marca)
/// - secondary: dourado #C0994F (acento; escurecido para texto legível)
/// - tertiary: azul institucional #12588A (apoio / informação)
/// - error: vermelho
class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static const String fonteTexto = 'Poppins';
  static const String fonteTitulo = 'Montserrat';

  /// Dourado original do site, para detalhes decorativos (não para texto).
  static const Color dourado = Color(0xffc0994f);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      // Bordô Católica SC
      primary: Color(0xff9b1536),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xfffbe5e8),
      onPrimaryContainer: Color(0xff790f2a),
      // Dourado — #C0994F no site; escurecido para contraste AA em texto
      secondary: Color(0xff8a6a2f),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfff5ead8),
      onSecondaryContainer: Color(0xff3d2d0f),
      // Azul institucional do site
      tertiary: Color(0xff12588a),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffd9e8f4),
      onTertiaryContainer: Color(0xff0a2f4b),
      error: Color(0xffb3261e),
      onError: Color(0xffffffff),
      errorContainer: Color(0xfffde3e0),
      onErrorContainer: Color(0xff5c0f0a),
      // Neutros do site: texto #282828, cinza #767676, bordas #E1E1E1
      surface: Color(0xffffffff),
      onSurface: Color(0xff282828),
      onSurfaceVariant: Color(0xff767676),
      outline: Color(0xff9e9e9e),
      outlineVariant: Color(0xffe1e1e1),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff282828),
      onInverseSurface: Color(0xfff6f6f6),
      inversePrimary: Color(0xfff3bbb7),
      surfaceTint: Color(0xff9b1536),
      surfaceDim: Color(0xffe1e1e1),
      surfaceBright: Color(0xffffffff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff6f6f6),
      surfaceContainer: Color(0xfff2f2f2),
      surfaceContainerHigh: Color(0xffeeedf0),
      surfaceContainerHighest: Color(0xffe1e1e1),
    );
  }

  ThemeData light() {
    return theme(lightScheme(), AppSemanticColors.light);
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff3bbb7),
      onPrimary: Color(0xff5c0b20),
      primaryContainer: Color(0xff790f2a),
      onPrimaryContainer: Color(0xffffd9dd),
      secondary: Color(0xffe3c48a),
      onSecondary: Color(0xff3d2d0f),
      secondaryContainer: Color(0xff5a4520),
      onSecondaryContainer: Color(0xffefdcc2),
      tertiary: Color(0xff9ccbee),
      onTertiary: Color(0xff00324f),
      tertiaryContainer: Color(0xff0f4a70),
      onTertiaryContainer: Color(0xffd9e8f4),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff1a1617),
      onSurface: Color(0xffece0e1),
      onSurfaceVariant: Color(0xffd3c3c5),
      outline: Color(0xff9c8d8f),
      outlineVariant: Color(0xff4f4345),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffece0e1),
      onInverseSurface: Color(0xff362f30),
      inversePrimary: Color(0xff9b1536),
      surfaceTint: Color(0xfff3bbb7),
      surfaceDim: Color(0xff1a1617),
      surfaceBright: Color(0xff413b3c),
      surfaceContainerLowest: Color(0xff141011),
      surfaceContainerLow: Color(0xff221d1e),
      surfaceContainer: Color(0xff262122),
      surfaceContainerHigh: Color(0xff312b2c),
      surfaceContainerHighest: Color(0xff3c3637),
    );
  }

  ThemeData dark() {
    return theme(darkScheme(), AppSemanticColors.dark);
  }

  /// Poppins em tudo; Montserrat nos estilos de título (display → titleLarge).
  static TextTheme _tipografia(TextTheme base) {
    TextStyle? titulo(TextStyle? s) =>
        s?.copyWith(fontFamily: fonteTitulo, fontWeight: FontWeight.w700);
    final TextTheme texto = base.apply(fontFamily: fonteTexto);
    return texto.copyWith(
      displayLarge: titulo(texto.displayLarge),
      displayMedium: titulo(texto.displayMedium),
      displaySmall: titulo(texto.displaySmall),
      headlineLarge: titulo(texto.headlineLarge),
      headlineMedium: titulo(texto.headlineMedium),
      headlineSmall: titulo(texto.headlineSmall),
      titleLarge: titulo(texto.titleLarge),
      titleMedium: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: texto.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  ThemeData theme(ColorScheme colorScheme, AppSemanticColors semantic) {
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final TextTheme text = _tipografia(textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      fontFamily: fonteTexto,
      textTheme: text,
      // Transparente: o fundo cinza-claro é pintado pelo `builder` do
      // MaterialApp (ver AppGradients.background), atrás de todos os Scaffolds.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: colorScheme.surface,
      extensions: <ThemeExtension<dynamic>>[semantic],
      // Barra branca com filete bordô embaixo, como o cabeçalho do site.
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(color: colorScheme.primary, width: 3),
        ),
        titleTextStyle: text.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 1.5,
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.10),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        iconColor: colorScheme.onSurfaceVariant,
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.primaryContainer,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 4,
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
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          return IconThemeData(
            color: s.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle:
            WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          final bool sel = s.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            color: sel ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: text.titleLarge,
      ),
    );
  }
}
