import 'package:flutter/material.dart';

/// Diálogo com um campo de texto. Devolve o texto confirmado, ou null se o
/// usuário cancelar.
///
/// O próprio diálogo cria e descarta o controller: descartar logo depois do
/// `showDialog` quebra o app, porque o campo ainda é desenhado durante a
/// animação de fechar.
Future<String?> showTextInputDialog({
  required BuildContext context,
  required String title,
  required String label,
  required String confirmLabel,
  String initialValue = '',
  String? hintText,
  String? helperText,
  Key? fieldKey,
  Key? confirmKey,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => _TextInputDialog(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      hintText: hintText,
      helperText: helperText,
      fieldKey: fieldKey,
      confirmKey: confirmKey,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.initialValue,
    this.hintText,
    this.helperText,
    this.fieldKey,
    this.confirmKey,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String initialValue;
  final String? hintText;
  final String? helperText;
  final Key? fieldKey;
  final Key? confirmKey;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _campo =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _confirmar() => Navigator.of(context).pop(_campo.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _campo,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          helperText: widget.helperText,
        ),
        onSubmitted: (_) => _confirmar(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: widget.confirmKey,
          onPressed: _confirmar,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
