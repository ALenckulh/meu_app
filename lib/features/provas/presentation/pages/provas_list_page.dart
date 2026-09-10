import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/confirm_delete_dialog.dart';
import 'package:meu_app/core/widgets/empty_state.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/shared/models/prova.dart';

final provasListProvider = FutureProvider<List<Prova>>((Ref ref) async {
  ref.watch(listVersionProvider);
  return ref.read(provaRepositoryProvider).listAll();
});

class ProvasListPage extends ConsumerWidget {
  const ProvasListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Prova>> asyncList = ref.watch(provasListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Provas')),
      floatingActionButton: FloatingActionButton(
        key: const Key('fab-criar-prova'),
        tooltip: 'Criar prova',
        onPressed: () => context.push('/provas/nova'),
        child: const Icon(Icons.add),
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Erro: $e')),
        data: (List<Prova> provas) {
          if (provas.isEmpty) {
            return const EmptyState(message: 'Nenhuma prova cadastrada.');
          }
          return ListView.builder(
            itemCount: provas.length,
            itemBuilder: (BuildContext context, int index) {
              final Prova prova = provas[index];
              return ListTile(
                key: Key('prova-${prova.id}'),
                title: Text(prova.titulo),
                subtitle: Text(
                  '${prova.questaoIds.length} questões · ${prova.quantidadeVariacoes} variações',
                ),
                onTap: () => context.push('/provas/${prova.id}'),
                trailing: Tooltip(
                  message: 'Excluir',
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final bool ok = await showConfirmDeleteDialog(
                        context: context,
                        title: 'Excluir prova "${prova.titulo}"?',
                        message:
                            'A prova e suas variações serão removidas. Esta ação não pode ser desfeita.',
                      );
                      if (!ok) {
                        return;
                      }
                      await ref.read(provaRepositoryProvider).delete(prova.id);
                      ref.read(listVersionProvider.notifier).bump();
                      if (context.mounted) {
                        showSuccessSnackBar(context, 'Prova excluída.');
                      }
                    },
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
