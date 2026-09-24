import 'package:flutter/material.dart';

/// Título de seção: rótulo curto em negrito na cor de texto principal,
/// com uma ação opcional alinhada à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(4, 24, 4, 12),
  });

  final String title;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
