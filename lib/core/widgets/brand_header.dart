import 'package:flutter/material.dart';
import 'package:meu_app/core/theme/app_gradients.dart';
import 'package:meu_app/core/theme/material_theme.dart';

/// Bloco bordô com filete dourado — destaque institucional no estilo do
/// site da Católica SC (login, início).
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.icon = Icons.fact_check_outlined,
    this.child,
  });

  final String titulo;
  final String? subtitulo;
  final IconData icon;

  /// Conteúdo extra abaixo do subtítulo (ex.: resumo em números).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: AppGradients.brand(colors),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: colors.onPrimary, size: 30),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 48, height: 3, color: MaterialTheme.dourado),
          if (subtitulo != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              subtitulo!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (child != null) ...<Widget>[
            const SizedBox(height: 16),
            child!,
          ],
        ],
      ),
    );
  }
}
