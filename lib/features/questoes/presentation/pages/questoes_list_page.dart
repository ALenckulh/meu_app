import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/confirm_delete_dialog.dart';
import 'package:meu_app/core/widgets/ellipsis_text.dart';
import 'package:meu_app/core/widgets/empty_state.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/shared/models/questao.dart';

final questaoQueryProvider = StateProvider<String>((Ref ref) => '');

final questoesListProvider = FutureProvider<List<Questao>>((Ref ref) async {
  ref.watch(listVersionProvider);
  final String query = ref.watch(questaoQueryProvider);
  return ref.read(questaoRepositoryProvider).listAll(query: query);
});

class QuestoesListPage extends ConsumerWidget {
  const QuestoesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Questao>> asyncList = ref.watch(questoesListProvider);
    final List<String> labels = const <String>['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(title: const Text('Banco de Questões')),
      floatingActionButton: FloatingActionButton(
        key: const Key('fab-criar-questao'),
        tooltip: 'Cadastrar questão',
        onPressed: () => context.push('/questoes/nova'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: const Key('input-busca-questao'),
              decoration: InputDecoration(
                labelText: 'Buscar',
                hintText: 'Informe parte do enunciado ou tag',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (String value) {
                ref.read(questaoQueryProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: asyncList.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace _) => Center(child: Text('Erro: $e')),
              data: (List<Questao> questoes) {
                if (questoes.isEmpty) {
                  return const EmptyState(message: 'Nenhuma questão encontrada.');
                }
                final ColorScheme colors = Theme.of(context).colorScheme;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: questoes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final Questao q = questoes[index];
                    return Material(
                      color: colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 1.5,
                      shadowColor: colors.shadow.withValues(alpha: 0.15),
                      child: InkWell(
                        key: Key('questao-${q.id}'),
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => context.push('/questoes/${q.id}/editar'),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    EllipsisText(q.enunciado, maxLines: 2),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Gabarito: ${labels[q.gabaritoIndex]}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: colors.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Tooltip(
                                message: 'Excluir',
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final bool ok = await showConfirmDeleteDialog(
                                      context: context,
                                      title: 'Excluir questão?',
                                      message:
                                          'A questão será removida do banco. Esta ação não pode ser desfeita.',
                                    );
                                    if (!ok) {
                                      return;
                                    }
                                    await ref
                                        .read(questaoRepositoryProvider)
                                        .delete(q.id);
                                    ref.read(listVersionProvider.notifier).bump();
                                    if (context.mounted) {
                                      showSuccessSnackBar(
                                        context,
                                        'Questão excluída.',
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}