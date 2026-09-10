import 'package:flutter/material.dart';

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

  Color _color(ColorScheme scheme) {
    switch (kind) {
      case StatusKind.error:
        return scheme.error;
      case StatusKind.warning:
        return scheme.tertiary;
      case StatusKind.success:
        return scheme.primary;
      case StatusKind.info:
        return scheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Icon(_icon, color: _color(Theme.of(context).colorScheme)),
    );
  }
}
