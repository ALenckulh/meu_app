import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/shared/models/aluno.dart';

class ImportarAlunosPage extends ConsumerStatefulWidget {
  const ImportarAlunosPage({super.key, required this.turmaId});

  final String turmaId;

  @override
  ConsumerState<ImportarAlunosPage> createState() => _ImportarAlunosPageState();
}

class _ImportarAlunosPageState extends ConsumerState<ImportarAlunosPage> {
  final List<Map<String, String>> _preview = const <Map<String, String>>[
    <String, String>{'nome': 'Aluno Importado 1', 'matricula': 'IMP001'},
    <String, String>{'nome': 'Aluno Importado 2', 'matricula': 'IMP002'},
    <String, String>{'nome': 'Aluno Importado 3', 'matricula': 'IMP003'},
  ];
  bool _importing = false;

  Future<void> _confirm() async {
    setState(() => _importing = true);
    final List<Aluno> imported =
        await ref.read(alunoRepositoryProvider).importMock(widget.turmaId);
    ref.read(listVersionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    showSuccessSnackBar(
      context,
      '${imported.length} alunos importados (mock).',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Importar alunos')),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.info_outline, size: 20, color: colors.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prévia da lista mockada (N2: CSV/planilha real).',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSecondaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _preview.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final Map<String, String> row = _preview[index];
                return Material(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 1.5,
                  shadowColor: colors.shadow.withValues(alpha: 0.15),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: colors.tertiaryContainer,
                      foregroundColor: colors.onTertiaryContainer,
                      child: Text(row['nome']!.isNotEmpty ? row['nome']![0] : '?'),
                    ),
                    title: Text(row['nome']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('Matrícula: ${row['matricula']}'),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              key: const Key('btn-confirmar-importacao'),
              onPressed: _importing ? null : _confirm,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: Text(_importing ? 'Importando...' : 'Importar lista'),
            ),
          ),
        ],
      ),
    );
  }
}