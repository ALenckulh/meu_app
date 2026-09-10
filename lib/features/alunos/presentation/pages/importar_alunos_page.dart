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
    return Scaffold(
      appBar: AppBar(title: const Text('Importar alunos')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Prévia da lista mockada (N2: CSV/planilha real).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _preview.length,
              itemBuilder: (BuildContext context, int index) {
                final Map<String, String> row = _preview[index];
                return ListTile(
                  title: Text(row['nome']!),
                  subtitle: Text('Matrícula: ${row['matricula']}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              key: const Key('btn-confirmar-importacao'),
              onPressed: _importing ? null : _confirm,
              child: Text(_importing ? 'Importando...' : 'Importar lista'),
            ),
          ),
        ],
      ),
    );
  }
}
