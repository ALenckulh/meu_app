import 'package:flutter/material.dart';

/// Bloco de métrica no estilo do mock: retângulo com tinta pastel do
/// [accent], número grande e forte, legenda curta em cinza.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accent,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accentColor = accent ?? colors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(height: 10),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distribui vários [StatTile] em uma linha com larguras iguais e a mesma
/// altura.
class StatTileRow extends StatelessWidget {
  const StatTileRow({super.key, required this.tiles, this.spacing = 12});

  final List<Widget> tiles;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < tiles.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}
