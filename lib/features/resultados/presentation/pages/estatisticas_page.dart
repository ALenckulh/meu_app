import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/core/widgets/stat_tile.dart';
import 'package:meu_app/shared/models/correcao.dart';

class EstatisticasPage extends ConsumerWidget {
  const EstatisticasPage({super.key});

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

    final List<int> altCounts = <int>[0, 0, 0, 0];
    for (final Correcao c in correcoes) {
      for (final int r in c.respostas) {
        if (r >= 0 && r < 4) {
          altCounts[r]++;
        }
      }
    }
    int maisMarcada = 0;
    for (int i = 1; i < 4; i++) {
      if (altCounts[i] > altCounts[maisMarcada]) {
        maisMarcada = i;
      }
    }
    final int totalMarcacoes =
        altCounts.fold<int>(0, (int a, int b) => a + b);
    const List<String> labels = <String>['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          StatTileRow(
            tiles: <Widget>[
              StatTile(
                value: media.toStringAsFixed(1),
                label: 'média da turma',
                icon: Icons.trending_up,
                accent: colors.primary,
              ),
              StatTile(
                value: labels[maisMarcada],
                label: 'alternativa + marcada',
                icon: Icons.radio_button_checked,
                accent: colors.tertiary,
              ),
              StatTile(
                value: '${correcoes.length}',
                label: 'provas',
                icon: Icons.fact_check_outlined,
                accent: colors.secondary,
              ),
            ],
          ),
          const SectionHeader('Desempenho por aluno'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
              child: SizedBox(
                height: 220,
                child: correcoes.isEmpty
                    ? const Center(child: Text('Sem dados'))
                    : BarChart(
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
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => colors.inverseSurface,
                              getTooltipItem: (BarChartGroupData group, int _,
                                  BarChartRodData rod, int _) {
                                return BarTooltipItem(
                                  rod.toY.toStringAsFixed(1),
                                  TextStyle(
                                    color: colors.onInverseSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 28, interval: 2),
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
                                  if (i < 0 || i >= correcoes.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('A${i + 1}',
                                        style: theme.textTheme.labelSmall),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: List<BarChartGroupData>.generate(
                            correcoes.length,
                            (int i) => BarChartGroupData(
                              x: i,
                              barRods: <BarChartRodData>[
                                BarChartRodData(
                                  toY: correcoes[i].nota,
                                  color: colors.primary,
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: 10,
                                    color: colors.surfaceContainerHighest,
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
          const SectionHeader('Frequência de alternativas'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List<Widget>.generate(4, (int i) {
                  final double frac =
                      totalMarcacoes == 0 ? 0 : altCounts[i] / totalMarcacoes;
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == 3 ? 0 : 14),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 20,
                          child: Text(labels[i],
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: frac,
                              minHeight: 10,
                              backgroundColor:
                                  colors.surfaceContainerHighest,
                              color: i == maisMarcada
                                  ? colors.primary
                                  : colors.primary.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 28,
                          child: Text('${altCounts[i]}',
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
