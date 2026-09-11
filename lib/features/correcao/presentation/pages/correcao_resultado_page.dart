import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/theme/app_gradients.dart';
import 'package:meu_app/core/theme/app_semantic_colors.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/core/widgets/stat_tile.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

class CorrecaoResultadoPage extends ConsumerWidget {
  const CorrecaoResultadoPage({super.key, required this.correcaoId});

  final String correcaoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppMockStore store = ref.watch(appMockStoreProvider);
    Correcao? correcao;
    try {
      correcao = store.correcoes.firstWhere((Correcao c) => c.id == correcaoId);
    } catch (_) {
      correcao = null;
    }

    if (correcao == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado')),
        body: const Center(child: Text('Correção não encontrada.')),
      );
    }

    Aluno? aluno;
    try {
      aluno = store.alunos.firstWhere((Aluno a) => a.id == correcao!.alunoId);
    } catch (_) {
      aluno = null;
    }

    VariacaoDeProva? variacao;
    try {
      variacao = store.variacoes
          .firstWhere((VariacaoDeProva v) => v.id == correcao!.variacaoId);
    } catch (_) {
      variacao = null;
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    const List<String> labels = <String>['A', 'B', 'C', 'D'];
    final int erros = correcao.totalQuestoes - correcao.acertos;
    final int pct = correcao.totalQuestoes == 0
        ? 0
        : ((correcao.acertos / correcao.totalQuestoes) * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado da correção')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.celebration(colors),
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          colors.onPrimaryContainer.withValues(alpha: 0.15),
                      child: Icon(Icons.check, color: colors.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            aluno?.nome ?? correcao.alunoId,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Leitura simulada · QR ${correcao.variacaoId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  correcao.nota.toStringAsFixed(1),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'nota final · $pct% de acerto',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StatTileRow(
            tiles: <Widget>[
              StatTile(
                value: '${correcao.acertos}',
                label: 'acertos',
                icon: Icons.check_circle_outline,
                accent: context.semantic.success,
              ),
              StatTile(
                value: '$erros',
                label: 'erros',
                icon: Icons.cancel_outlined,
                accent: colors.error,
              ),
              StatTile(
                value: '${correcao.totalQuestoes}',
                label: 'questões',
                icon: Icons.help_outline,
                accent: colors.secondary,
              ),
            ],
          ),
          const SectionHeader('Respostas identificadas'),
          ...List<Widget>.generate(correcao.respostas.length, (int i) {
            final int marcada = correcao!.respostas[i];
            final String? qId = variacao?.ordemQuestoes[i];
            final int? gabarito =
                qId == null ? null : variacao?.gabaritoRemapeado[qId];
            final bool ok = gabarito != null && marcada == gabarito;
            return _RespostaRow(
              numero: i + 1,
              ok: ok,
              marcada: labels[marcada],
              gabarito: gabarito != null ? labels[gabarito] : null,
            );
          }),
        ],
      ),
    );
  }
}

class _RespostaRow extends StatelessWidget {
  const _RespostaRow({
    required this.numero,
    required this.ok,
    required this.marcada,
    this.gabarito,
  });

  final int numero;
  final bool ok;
  final String marcada;
  final String? gabarito;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accent = ok ? context.semantic.success : colors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(ok ? Icons.check_circle : Icons.cancel, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Questão $numero',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Text(
            gabarito == null
                ? 'Marcada $marcada'
                : 'Marcada $marcada · Gabarito $gabarito',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
