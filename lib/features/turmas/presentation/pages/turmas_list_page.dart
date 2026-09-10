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
          return ListView.builder(
            itemCount: turmas.length,
            itemBuilder: (BuildContext context, int index) {
              final Turma turma = turmas[index];
              return ListTile(
                key: Key('turma-${turma.id}'),
                title: EllipsisText(turma.nome),
                subtitle: Text('${turma.disciplina} · ${turma.ano}'),
                onTap: () => context.push('/turmas/${turma.id}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Tooltip(
                      message: 'Editar',
                      child: IconButton(
                        key: Key('btn-editar-turma-${turma.id}'),
                        icon: const Icon(Icons.edit),
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
              );
            },
          );
        },
      ),
    );
  }
}
