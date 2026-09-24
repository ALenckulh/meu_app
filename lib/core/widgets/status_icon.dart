import 'package:flutter/material.dart';
import 'package:meu_app/core/theme/app_semantic_colors.dart';

enum StatusKind { error, warning, success, info }

class StatusIcon extends StatelessWidget {
  const StatusIcon({
    super.key,
    required this.kind,
    required this.tooltip,
  });

  final StatusKind kind;
  final String tooltip;

  IconData get _icon {
    switch (kind) {
      case StatusKind.error:
        return Icons.cancel;
      case StatusKind.warning:
        return Icons.warning;
      case StatusKind.success:
        return Icons.check_circle;
      case StatusKind.info:
        return Icons.info;
    }
  }

  Color _color(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (kind) {
      case StatusKind.error:
        return scheme.error;
      case StatusKind.warning:
        return scheme.tertiary;
      case StatusKind.success:
        return context.semantic.success;
      case StatusKind.info:
        return context.semantic.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Icon(_icon, color: _color(context)),
    );
  }
}
