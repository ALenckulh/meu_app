import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/confirm_delete_dialog.dart';
import 'package:meu_app/core/widgets/empty_state.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/turma.dart';

final turmaDetailProvider =
    FutureProvider.family<Turma?, String>((Ref ref, String id) async {
  ref.watch(listVersionProvider);
  return ref.read(turmaRepositoryProvider).getById(id);
});

final alunosByTurmaProvider =
    FutureProvider.family<List<Aluno>, String>((Ref ref, String turmaId) async {
  ref.watch(listVersionProvider);
  return ref.read(alunoRepositoryProvider).listByTurma(turmaId);
});

class TurmaDetailPage extends ConsumerWidget {
  const TurmaDetailPage({super.key, required this.turmaId});

  final String turmaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Turma?> turmaAsync =
        ref.watch(turmaDetailProvider(turmaId));
    final AsyncValue<List<Aluno>> alunosAsync =
        ref.watch(alunosByTurmaProvider(turmaId));

    return Scaffold(
      appBar: AppBar(
        title: turmaAsync.when(
          data: (Turma? t) => Text(t?.nome ?? 'Turma'),
          loading: () => const Text('Turma'),
          error: (Object error, StackTrace stackTrace) => const Text('Turma'),
        ),
        actions: <Widget>[
          Tooltip(
            message: 'Importar alunos',
            child: IconButton(
              key: const Key('btn-importar-alunos'),
              icon: const Icon(Icons.upload_file),
              onPressed: () => context.push('/turmas/$turmaId/importar'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('fab-criar-aluno'),
        tooltip: 'Cadastrar aluno',
        onPressed: () => context.push('/turmas/$turmaId/alunos/novo'),
        child: const Icon(Icons.person_add),
      ),
      body: alunosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Erro: $e')),
        data: (List<Aluno> alunos) {
          if (alunos.isEmpty) {
            return const EmptyState(
              message: 'Nenhum aluno nesta turma.',
              icon: Icons.person_off_outlined,
            );
          }
          return ListView.builder(
            itemCount: alunos.length,
            itemBuilder: (BuildContext context, int index) {
              final Aluno aluno = alunos[index];
              return ListTile(
                key: Key('aluno-${aluno.id}'),
                title: Text(aluno.nome),
                subtitle: Text('Matrícula: ${aluno.matricula}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Tooltip(
                      message: 'Editar',
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => context
                            .push('/turmas/$turmaId/alunos/${aluno.id}/editar'),
                      ),
                    ),
                    Tooltip(
                      message: 'Excluir',
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final bool ok = await showConfirmDeleteDialog(
                            context: context,
                            title: 'Excluir aluno "${aluno.nome}"?',
                            message:
                                'O aluno será removido da turma. Esta ação não pode ser desfeita.',
                          );
                          if (!ok) {
                            return;
                          }
                          await ref
                              .read(alunoRepositoryProvider)
                              .delete(aluno.id);
                          ref.read(listVersionProvider.notifier).bump();
                          if (context.mounted) {
                            showSuccessSnackBar(context, 'Aluno excluído.');
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
