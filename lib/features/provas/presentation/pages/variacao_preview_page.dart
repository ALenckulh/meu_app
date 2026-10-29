import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/theme/app_semantic_colors.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

class _PreviewDados {
  const _PreviewDados({required this.variacao, required this.questoes});

  final VariacaoDeProva? variacao;
  final Map<String, Questao> questoes;
}

final _previewProvider =
    FutureProvider.autoDispose.family<_PreviewDados, String>(
  (Ref ref, String variacaoId) async {
    final VariacaoDeProva? variacao =
        await ref.read(provaRepositoryProvider).getVariacaoById(variacaoId);
    final List<Questao> questoes =
        await ref.read(questaoRepositoryProvider).listAll();
    return _PreviewDados(
      variacao: variacao,
      questoes: <String, Questao>{for (final Questao q in questoes) q.id: q},
    );
  },
);

class VariacaoPreviewPage extends ConsumerWidget {
  const VariacaoPreviewPage({
    super.key,
    required this.provaId,
    required this.variacaoId,
  });

  final String provaId;
  final String variacaoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<_PreviewDados> async = ref.watch(_previewProvider(variacaoId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Prévia da variação')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => Scaffold(
        appBar: AppBar(title: const Text('Variação')),
        body: const Center(child: Text('Não foi possível carregar a variação.')),
      ),
      data: (_PreviewDados dados) {
        final VariacaoDeProva? variacao = dados.variacao;
        if (variacao == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Variação')),
            body: const Center(child: Text('Variação não encontrada.')),
          );
        }
        return _conteudo(context, variacao, dados.questoes);
      },
    );
  }

  Widget _conteudo(
    BuildContext context,
    VariacaoDeProva variacao,
    Map<String, Questao> questoes,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    const List<String> labels = <String>['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(title: const Text('Prévia da variação')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: variacao.ordemQuestoes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final String qId = variacao.ordemQuestoes[index];
          final Questao? questao = questoes[qId];
          if (questao == null) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Esta questão foi removida do banco.'),
              ),
            );
          }
          final List<int> perm =
              variacao.ordemAlternativas[qId] ?? <int>[0, 1, 2, 3];
          final int gabarito = variacao.gabaritoRemapeado[qId] ?? 0;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: colors.primaryContainer,
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          questao.enunciado,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List<Widget>.generate(4, (int i) {
                    final String texto = questao.alternativas[perm[i]];
                    final bool correta = i == gabarito;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: correta
                            ? context.semantic.successContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _Bubble(label: labels[i], filled: correta),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              texto,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: correta
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (correta)
                            Icon(Icons.check_circle,
                                size: 18, color: context.semantic.success),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color on = filled ? context.semantic.success : colors.outline;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? context.semantic.success : Colors.transparent,
        border: Border.all(color: on, width: 1.4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: filled ? context.semantic.onSuccess : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
