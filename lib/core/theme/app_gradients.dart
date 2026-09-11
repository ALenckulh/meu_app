import 'package:flutter/material.dart';

/// Degradês reutilizáveis no estilo do mock de referência: lavagens pastel
/// bem sutis (creme → lilás → azul), sempre derivadas do [ColorScheme].
class AppGradients {
  const AppGradients._();

  /// Fundo da tela inteira — branco, com só um sopro de lilás frio no rodapé
  /// (nada de tom quente). Fica atrás de todos os Scaffolds.
  static LinearGradient background(ColorScheme c) {
    final bool dark = c.brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: dark
          ? <Color>[
              c.surface,
              Color.alphaBlend(c.primary.withValues(alpha: 0.05), c.surface),
              c.surface,
            ]
          : <Color>[
              c.surfaceContainerLowest,
              c.surfaceContainerLowest,
              Color.alphaBlend(c.primary.withValues(alpha: 0.035),
                  c.surfaceContainerLowest),
            ],
      stops: const <double>[0.0, 0.62, 1.0],
    );
  }

  /// Card de destaque / cabeçalho: branco no canto superior esquerdo,
  /// dissolvendo em tinta pastel do [accent] e um toque de azul.
  static LinearGradient softCard(ColorScheme c, Color accent) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        c.surfaceContainerLowest,
        Color.alphaBlend(
            accent.withValues(alpha: 0.12), c.surfaceContainerLowest),
        Color.alphaBlend(
            c.secondary.withValues(alpha: 0.10), c.surfaceContainerLowest),
      ],
    );
  }

  /// Fundo comemorativo (telas de resultado): brilho radial em lavanda,
  /// como a tela "TREMENDOUS" da referência.
  static RadialGradient celebration(ColorScheme c) {
    return RadialGradient(
      center: const Alignment(0, -0.7),
      radius: 1.2,
      colors: <Color>[
        Color.alphaBlend(
            c.primary.withValues(alpha: 0.28), c.surfaceContainerLowest),
        Color.alphaBlend(
            c.primary.withValues(alpha: 0.12), c.surfaceContainerLowest),
        Color.alphaBlend(
            c.secondary.withValues(alpha: 0.10), c.surfaceContainerLowest),
      ],
      stops: const <double>[0.0, 0.55, 1.0],
    );
  }
}
