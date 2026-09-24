import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/theme/app_semantic_colors.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/core/widgets/stat_tile.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

class NotaAlunoPage extends ConsumerWidget {
  const NotaAlunoPage({super.key, required this.alunoId});

  final String alunoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppMockStore store = ref.watch(appMockStoreProvider);
    Correcao? correcao;
    try {
      correcao = store.correcoes.firstWhere((Correcao c) => c.alunoId == alunoId);
    } catch (_) {
      correcao = null;
    }
    Aluno? aluno;
    try {
      aluno = store.alunos.firstWhere((Aluno a) => a.id == alunoId);
    } catch (_) {
      aluno = null;
    }

    if (correcao == null) {
      return Scaffold(
        appBar: AppBar(title: Text(aluno?.nome ?? 'Aluno')),
        body: const Center(child: Text('Sem correção para este aluno.')),
      );
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
    final Color notaAccent = correcao.nota >= 6
        ? context.semantic.success
        : (correcao.nota >= 4 ? colors.tertiary : colors.error);

    return Scaffold(
      appBar: AppBar(title: Text(aluno?.nome ?? 'Aluno')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  colors.surfaceContainerLowest,
                  Color.alphaBlend(notaAccent.withValues(alpha: 0.18),
                      colors.surfaceContainerLowest),
                  Color.alphaBlend(notaAccent.withValues(alpha: 0.08),
                      colors.surfaceContainerLowest),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: notaAccent.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('NOTA FINAL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    )),
                const SizedBox(height: 4),
                Text(
                  correcao.nota.toStringAsFixed(1),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: notaAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${correcao.acertos} de ${correcao.totalQuestoes} questões corretas',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
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
            ],
          ),
          const SectionHeader('Gabarito por questão'),
          ...List<Widget>.generate(correcao.respostas.length, (int i) {
            final int marcada = correcao!.respostas[i];
            final String? qId = variacao?.ordemQuestoes[i];
            final int? gabarito =
                qId == null ? null : variacao?.gabaritoRemapeado[qId];
            final bool ok = gabarito != null && marcada == gabarito;
            final Color accent = ok ? context.semantic.success : colors.error;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(ok ? Icons.check_circle : Icons.cancel,
                      color: accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Questão ${i + 1}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Text(
                    gabarito != null
                        ? 'Marcada ${labels[marcada]} · Correta ${labels[gabarito]}'
                        : 'Marcada ${labels[marcada]}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
