import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

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
    final AppMockStore store = ref.watch(appMockStoreProvider);
    VariacaoDeProva? variacao;
    try {
      variacao = store.variacoes.firstWhere((VariacaoDeProva v) => v.id == variacaoId);
    } catch (_) {
      variacao = null;
    }

    if (variacao == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Variação')),
        body: const Center(child: Text('Variação não encontrada.')),
      );
    }

    const List<String> labels = <String>['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(title: const Text('Prévia da variação')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: variacao.ordemQuestoes.length,
        itemBuilder: (BuildContext context, int index) {
          final String qId = variacao!.ordemQuestoes[index];
          final Questao questao =
              store.questoes.firstWhere((Questao q) => q.id == qId);
          final List<int> perm =
              variacao.ordemAlternativas[qId] ?? <int>[0, 1, 2, 3];
          final int gabarito = variacao.gabaritoRemapeado[qId] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${index + 1}. ${questao.enunciado}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...List<Widget>.generate(4, (int i) {
                    final String texto = questao.alternativas[perm[i]];
                    final bool correta = i == gabarito;
                    return Text(
                      '${labels[i]}) $texto${correta ? '  ✓' : ''}',
                      style: TextStyle(
                        fontWeight:
                            correta ? FontWeight.bold : FontWeight.normal,
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
