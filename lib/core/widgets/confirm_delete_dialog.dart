import 'package:flutter/material.dart';

Future<bool> showConfirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Excluir',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        key: const Key('dialog-confirm-delete'),
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            key: const Key('btn-cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('btn-excluir'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
