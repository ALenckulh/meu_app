import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/shared/models/correcao.dart';

class EstatisticasPage extends ConsumerWidget {
  const EstatisticasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(listVersionProvider);
    final AppMockStore store = ref.watch(appMockStoreProvider);
    final List<Correcao> correcoes = store.correcoes;

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
    const List<String> labels = <String>['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Média da turma: ${media.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Alternativa mais marcada: ${labels[maisMarcada]} (${altCounts[maisMarcada]} vezes)',
          ),
          const SizedBox(height: 24),
          Text(
            'Desempenho por aluno',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: correcoes.isEmpty
                ? const Center(child: Text('Sem dados'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10,
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 28),
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
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final int i = value.toInt();
                              if (i < 0 || i >= correcoes.length) {
                                return const SizedBox.shrink();
                              }
                              return Text('A${i + 1}');
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
                              color: Theme.of(context).colorScheme.primary,
                              width: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            'Frequência de alternativas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...List<Widget>.generate(
            4,
            (int i) => ListTile(
              title: Text('Alternativa ${labels[i]}'),
              trailing: Text('${altCounts[i]}'),
            ),
          ),
        ],
      ),
    );
  }
}
