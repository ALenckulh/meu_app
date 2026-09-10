import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/empty_state.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';

class ResultadosPage extends ConsumerWidget {
  const ResultadosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(listVersionProvider);
    final AppMockStore store = ref.watch(appMockStoreProvider);
    final List<Correcao> correcoes = store.correcoes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        actions: <Widget>[
          Tooltip(
            message: 'Estatísticas',
            child: IconButton(
              key: const Key('btn-ir-estatisticas'),
              icon: const Icon(Icons.analytics),
              onPressed: () => context.push('/mais/estatisticas'),
            ),
          ),
        ],
      ),
      body: correcoes.isEmpty
          ? const EmptyState(message: 'Nenhuma correção disponível.')
          : ListView.builder(
              itemCount: correcoes.length,
              itemBuilder: (BuildContext context, int index) {
                final Correcao c = correcoes[index];
                Aluno? aluno;
                try {
                  aluno =
                      store.alunos.firstWhere((Aluno a) => a.id == c.alunoId);
                } catch (_) {
                  aluno = null;
                }
                return ListTile(
                  key: Key('resultado-${c.id}'),
                  title: Text(aluno?.nome ?? c.alunoId),
                  subtitle: Text(
                    '${c.acertos}/${c.totalQuestoes} acertos',
                  ),
                  trailing: Text(
                    c.nota.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () => context.push('/mais/resultados/${c.alunoId}'),
                );
              },
            ),
    );
  }
}
