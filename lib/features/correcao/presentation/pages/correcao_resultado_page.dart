import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/status_icon.dart';
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

    const List<String> labels = <String>['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado da correção')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ListTile(
            leading: const StatusIcon(
              kind: StatusKind.success,
              tooltip: 'Leitura simulada concluída',
            ),
            title: Text(aluno?.nome ?? correcao.alunoId),
            subtitle: Text('QR: ${correcao.variacaoId}'),
          ),
          Text(
            'Nota: ${correcao.nota.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            '${correcao.acertos}/${correcao.totalQuestoes} acertos',
            textAlign: TextAlign.center,
          ),
          const Divider(height: 32),
          Text(
            'Respostas identificadas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...List<Widget>.generate(correcao.respostas.length, (int i) {
            final int marcada = correcao!.respostas[i];
            final String? qId = variacao?.ordemQuestoes[i];
            final int? gabarito =
                qId == null ? null : variacao?.gabaritoRemapeado[qId];
            final bool ok = gabarito != null && marcada == gabarito;
            return ListTile(
              leading: StatusIcon(
                kind: ok ? StatusKind.success : StatusKind.error,
                tooltip: ok ? 'Acertou' : 'Errou',
              ),
              title: Text('Questão ${i + 1}'),
              subtitle: Text(
                'Marcada: ${labels[marcada]}'
                '${gabarito != null ? ' · Gabarito: ${labels[gabarito]}' : ''}',
              ),
            );
          }),
        ],
      ),
    );
  }
}
