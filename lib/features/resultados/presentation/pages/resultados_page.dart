import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/theme/app_semantic_colors.dart';
import 'package:meu_app/core/widgets/empty_state.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/turma.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

class ResultadosPage extends ConsumerStatefulWidget {
  const ResultadosPage({super.key});

  @override
  ConsumerState<ResultadosPage> createState() => _ResultadosPageState();
}

class _ResultadoRow {
  const _ResultadoRow({
    required this.correcao,
    required this.aluno,
    this.prova,
  });

  final Correcao correcao;
  final Aluno aluno;
  final Prova? prova;
}

class _ResultadosPageState extends ConsumerState<ResultadosPage> {
  final Random _random = Random();
  bool _simulando = false;

  // Guardado para não recarregar tudo a cada setState (ex.: _simulando).
  Future<List<_ResultadoRow>>? _rows;
  int? _rowsVersion;

  Future<List<_ResultadoRow>> _loadRows() async {
    final List<Correcao> correcoes =
        await ref.read(correcaoRepositoryProvider).listAll();
    final Map<String, Prova> provaPorVariacao = <String, Prova>{};
    for (final Prova p in await ref.read(provaRepositoryProvider).listAll()) {
      for (final VariacaoDeProva v
          in await ref.read(provaRepositoryProvider).listVariacoes(p.id)) {
        provaPorVariacao[v.id] = p;
      }
    }
    final List<_ResultadoRow> rows = <_ResultadoRow>[];
    for (final Correcao c in correcoes) {
      final Aluno? aluno =
          await ref.read(alunoRepositoryProvider).getById(c.alunoId);
      if (aluno != null) {
        rows.add(_ResultadoRow(
          correcao: c,
          aluno: aluno,
          prova: provaPorVariacao[c.variacaoId],
        ));
      }
    }
    rows.sort((_ResultadoRow a, _ResultadoRow b) =>
        a.aluno.nome.toLowerCase().compareTo(b.aluno.nome.toLowerCase()));
    return rows;
  }

  Future<void> _simularResultado() async {
    final String? professorId = ref.read(authSessionProvider)?.id;
    if (professorId == null) {
      showErrorSnackBar(context, 'Sessão inválida. Faça login novamente.');
      return;
    }
    setState(() => _simulando = true);
    try {
      final List<Turma> turmas = await ref
          .read(turmaRepositoryProvider)
          .listByProfessor(professorId);
      final List<Aluno> todos = <Aluno>[];
      for (final Turma t in turmas) {
        todos.addAll(
          await ref.read(alunoRepositoryProvider).listByTurma(t.id),
        );
      }

      final List<Prova> provas = (await ref
              .read(provaRepositoryProvider)
              .listAll())
          .where((Prova p) => p.questaoIds.isNotEmpty)
          .toList();
      final Set<String> corrigidas = (await ref
              .read(correcaoRepositoryProvider)
              .listAll())
          .map((Correcao c) => c.variacaoId)
          .toSet();

      // Pares (aluno, prova da turma dele) que ainda não têm correção.
      final List<({Aluno aluno, Prova prova, VariacaoDeProva? variacao})>
          candidatos =
          <({Aluno aluno, Prova prova, VariacaoDeProva? variacao})>[];
      for (final Prova p in provas) {
        final List<VariacaoDeProva> vars =
            await ref.read(provaRepositoryProvider).listVariacoes(p.id);
        for (final Aluno a in todos.where((Aluno a) => a.turmaId == p.turmaId)) {
          VariacaoDeProva? variacao;
          for (final VariacaoDeProva v in vars) {
            if (v.alunoId == a.id) {
              variacao = v;
              break;
            }
          }
          if (variacao == null || !corrigidas.contains(variacao.id)) {
            candidatos.add((aluno: a, prova: p, variacao: variacao));
          }
        }
      }
      if (candidatos.isEmpty) {
        if (mounted) {
          showSuccessSnackBar(
            context,
            'Todos os alunos já têm correção nas provas da turma.',
          );
        }
        return;
      }

      final ({Aluno aluno, Prova prova, VariacaoDeProva? variacao}) escolhido =
          candidatos[_random.nextInt(candidatos.length)];
      final Aluno aluno = escolhido.aluno;
      final VariacaoDeProva variacao = escolhido.variacao ??
          await ref.read(provaRepositoryProvider).gerarVariacao(
                provaId: escolhido.prova.id,
                alunoId: aluno.id,
                embaralharQuestoes: true,
                embaralharAlternativas: true,
              );

      final List<int> respostas = List<int>.generate(
        variacao.ordemQuestoes.length,
        (_) => _random.nextInt(4),
      );

      final Correcao correcao =
          await ref.read(correcaoRepositoryProvider).corrigir(
                variacaoId: variacao.id,
                alunoId: aluno.id,
                professorId: professorId,
                respostas: respostas,
              );

      ref.read(listVersionProvider.notifier).bump();
      if (!mounted) {
        return;
      }
      showSuccessSnackBar(
        context,
        'Resultado simulado para ${aluno.nome}.',
      );
      await context.push('/mais/resultados/${correcao.id}');
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Erro ao simular: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _simulando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int version = ref.watch(listVersionProvider);
    if (_rows == null || _rowsVersion != version) {
      _rowsVersion = version;
      _rows = _loadRows();
    }
    return FutureBuilder<List<_ResultadoRow>>(
      future: _rows,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<_ResultadoRow>> snapshot,
      ) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final List<_ResultadoRow> rows = snapshot.data ?? <_ResultadoRow>[];
        final ThemeData theme = Theme.of(context);
        final ColorScheme colors = theme.colorScheme;

        final double media = rows.isEmpty
            ? 0
            : rows
                    .map((_ResultadoRow r) => r.correcao.nota)
                    .reduce((double a, double b) => a + b) /
                rows.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Resultados'),
            actions: <Widget>[
              Tooltip(
                message: 'Simular resultado',
                child: IconButton(
                  key: const Key('btn-simular-resultado'),
                  icon: _simulando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.casino_outlined),
                  onPressed: _simulando ? null : _simularResultado,
                ),
              ),
            ],
          ),
          body: rows.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const EmptyState(
                          icon: Icons.fact_check_outlined,
                          message: 'Nenhuma correção disponível.',
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          key: const Key('btn-simular-resultado-empty'),
                          onPressed: _simulando ? null : _simularResultado,
                          icon: const Icon(Icons.casino_outlined),
                          label: Text(
                            _simulando
                                ? 'Simulando...'
                                : 'Simular resultado',
                          ),
                        ),
                      ],
                    ),
                  ),
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
                              '${rows.length} prova(s) corrigida(s)',
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
                    const SectionHeader('Desempenho'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                        child: SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 10,
                              gridData: FlGridData(
                                drawVerticalLine: false,
                                horizontalInterval: 2,
                                getDrawingHorizontalLine: (double v) => FlLine(
                                  color: colors.outlineVariant,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    interval: 2,
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                      final int i = value.toInt();
                                      if (i < 0 || i >= rows.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final String nome = rows[i].aluno.nome;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          nome.length > 6
                                              ? '${nome.substring(0, 6)}…'
                                              : nome,
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: List<BarChartGroupData>.generate(
                                rows.length,
                                (int i) => BarChartGroupData(
                                  x: i,
                                  barRods: <BarChartRodData>[
                                    BarChartRodData(
                                      toY: rows[i].correcao.nota,
                                      color: colors.primary,
                                      width: 16,
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SectionHeader('Por aluno'),
                    ...rows.map((_ResultadoRow row) {
                      final Correcao c = row.correcao;
                      final Aluno aluno = row.aluno;
                      return Padding(
                        key: Key('resultado-${c.id}'),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: InkWell(
                            onTap: () =>
                                context.push('/mais/resultados/${c.id}'),
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
                                          aluno.nome,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${row.prova?.titulo ?? 'Prova removida'}'
                                          ' · ${c.acertos}/${c.totalQuestoes} acertos',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
      },
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
