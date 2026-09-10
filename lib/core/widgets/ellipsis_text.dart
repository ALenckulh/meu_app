import 'package:flutter/material.dart';

/// Texto com ellipsis e tooltip do conteúdo completo.
class EllipsisText extends StatelessWidget {
  const EllipsisText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
