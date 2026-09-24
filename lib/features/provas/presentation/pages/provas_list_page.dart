import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/confirm_delete_dialog.dart';
import 'package:meu_app/core/widgets/empty_state.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/core/widgets/info_card.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fab-criar-prova'),
        tooltip: 'Criar prova',
        onPressed: () => context.push('/provas/nova'),
        icon: const Icon(Icons.add),
        label: const Text('Nova prova'),
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Erro: $e')),
        data: (List<Prova> provas) {
          if (provas.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_outlined,
              message:
                  'Nenhuma prova cadastrada.\nToque em "Nova prova" para começar.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: provas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final Prova prova = provas[index];
              return _ProvaCard(
                key: Key('prova-${prova.id}'),
                prova: prova,
                onTap: () => context.push('/provas/${prova.id}'),
                onDelete: () async {
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
              );
            },
          );
        },
      ),
    );
  }
}

class _ProvaCard extends StatelessWidget {
  const _ProvaCard({
    super.key,
    required this.prova,
    required this.onTap,
    required this.onDelete,
  });

  final Prova prova;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assignment_outlined,
                    color: colors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      prova.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        MetaChip(
                          icon: Icons.help_outline,
                          label: '${prova.questaoIds.length} questões',
                        ),
                        MetaChip(
                          icon: Icons.shuffle,
                          label: '${prova.quantidadeVariacoes} variações',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Excluir',
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
