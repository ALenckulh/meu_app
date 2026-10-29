import 'package:flutter/material.dart';

/// Fundos reutilizáveis no visual da Católica SC: áreas em cinza-claro
/// (#F6F6F6), cards brancos e blocos de destaque em bordô. Sempre derivados
/// do [ColorScheme].
class AppGradients {
  const AppGradients._();

  /// Fundo da tela inteira — cinza-claro liso, como as seções do site.
  /// Fica atrás de todos os Scaffolds.
  static LinearGradient background(ColorScheme c) {
    return LinearGradient(
      colors: <Color>[c.surfaceContainerLow, c.surfaceContainerLow],
    );
  }

  /// Card de destaque / cabeçalho: branco dissolvendo num leve tom do
  /// [accent].
  static LinearGradient softCard(ColorScheme c, Color accent) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        c.surfaceContainerLowest,
        c.surfaceContainerLowest,
        Color.alphaBlend(
            accent.withValues(alpha: 0.08), c.surfaceContainerLowest),
      ],
      stops: const <double>[0.0, 0.5, 1.0],
    );
  }

  /// Bloco bordô institucional (cabeçalhos de login, início e resultado).
  /// Texto por cima usa `onPrimary`.
  static LinearGradient brand(ColorScheme c) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        c.primary,
        Color.alphaBlend(Colors.black.withValues(alpha: 0.22), c.primary),
      ],
    );
  }
}
