import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/confirm_delete_dialog.dart';
import 'package:meu_app/core/widgets/ellipsis_text.dart';
import 'package:meu_app/core/widgets/empty_state.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/shared/models/turma.dart';

final turmasListProvider = FutureProvider<List<Turma>>((Ref ref) async {
  ref.watch(listVersionProvider);
  final String? professorId = ref.watch(authSessionProvider)?.id;
  if (professorId == null) {
    return <Turma>[];
  }
  return ref.read(turmaRepositoryProvider).listByProfessor(professorId);
});

class TurmasListPage extends ConsumerWidget {
  const TurmasListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Turma>> asyncTurmas = ref.watch(turmasListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Turmas')),
      floatingActionButton: FloatingActionButton(
        key: const Key('fab-criar-turma'),
        tooltip: 'Criar turma',
        onPressed: () => context.push('/turmas/nova'),
        child: const Icon(Icons.add),
      ),
      body: asyncTurmas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Erro: $e')),
        data: (List<Turma> turmas) {
          if (turmas.isEmpty) {
            return const EmptyState(message: 'Nenhuma turma cadastrada.');
          }
          final ColorScheme colors = Theme.of(context).colorScheme;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: turmas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final Turma turma = turmas[index];
              return Material(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                elevation: 1.5,
                shadowColor: colors.shadow.withValues(alpha: 0.15),
                child: InkWell(
                  key: Key('turma-${turma.id}'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/turmas/${turma.id}'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.groups, color: colors.onPrimaryContainer),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              EllipsisText(
                                turma.nome,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${turma.disciplina} · ${turma.ano}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Tooltip(
                          message: 'Editar',
                          child: IconButton(
                            key: Key('btn-editar-turma-${turma.id}'),
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                context.push('/turmas/${turma.id}/editar'),
                          ),
                        ),
                        Tooltip(
                          message: 'Excluir',
                          child: IconButton(
                            key: Key('btn-excluir-turma-${turma.id}'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final bool ok = await showConfirmDeleteDialog(
                                context: context,
                                title: 'Excluir turma "${turma.nome}"?',
                                message:
                                    'Os alunos desta turma também serão removidos. Esta ação não pode ser desfeita.',
                              );
                              if (!ok) {
                                return;
                              }
                              await ref.read(turmaRepositoryProvider).delete(turma.id);
                              ref.read(listVersionProvider.notifier).bump();
                              if (context.mounted) {
                                showSuccessSnackBar(context, 'Turma excluída.');
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
    );
  }
}