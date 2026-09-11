import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/theme/app_semantic_colors.dart';
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final double media = correcoes.isEmpty
        ? 0
        : correcoes.map((Correcao c) => c.nota).reduce((double a, double b) => a + b) /
            correcoes.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        actions: <Widget>[
          Tooltip(
            message: 'Estatísticas',
            child: IconButton(
              key: const Key('btn-ir-estatisticas'),
              icon: const Icon(Icons.insights_outlined),
              onPressed: () => context.push('/mais/estatisticas'),
            ),
          ),
        ],
      ),
      body: correcoes.isEmpty
          ? const EmptyState(
              icon: Icons.fact_check_outlined,
              message: 'Nenhuma correção disponível.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.groups_outlined,
                          color: colors.onSecondaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${correcoes.length} prova(s) corrigida(s)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                      Text(
                        'média ${media.toStringAsFixed(1)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...correcoes.map((Correcao c) {
                  Aluno? aluno;
                  try {
                    aluno =
                        store.alunos.firstWhere((Aluno a) => a.id == c.alunoId);
                  } catch (_) {
                    aluno = null;
                  }
                  return Padding(
                    key: Key('resultado-${c.id}'),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: InkWell(
                        onTap: () =>
                            context.push('/mais/resultados/${c.alunoId}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: <Widget>[
                              _ScoreBadge(nota: c.nota),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      aluno?.nome ?? c.alunoId,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${c.acertos}/${c.totalQuestoes} acertos',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: colors.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.nota});

  final double nota;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accent = nota >= 6
        ? context.semantic.success
        : (nota >= 4 ? colors.tertiary : colors.error);

    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        nota.toStringAsFixed(1),
        style: theme.textTheme.titleMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
