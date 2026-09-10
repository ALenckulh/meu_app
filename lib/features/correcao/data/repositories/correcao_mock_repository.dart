import 'dart:math';

import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/features/correcao/domain/repositories/correcao_repository.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:uuid/uuid.dart';

class CorrecaoMockRepository implements CorrecaoRepository {
  CorrecaoMockRepository(this._store);

  final AppMockStore _store;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  @override
  Future<List<Correcao>> listAll() async => List<Correcao>.from(_store.correcoes);

  @override
  Future<Correcao?> getByAluno(String alunoId) async {
    try {
      return _store.correcoes.firstWhere((Correcao c) => c.alunoId == alunoId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Correcao> simularLeitura({
    required String variacaoId,
    required String alunoId,
  }) async {
    // N2: câmera + QR real + OCR da folha.
    final VariacaoDeProva variacao =
        _store.variacoes.firstWhere((VariacaoDeProva v) => v.id == variacaoId);

    final List<int> respostas = <int>[];
    int acertos = 0;
    for (final String questaoId in variacao.ordemQuestoes) {
      final int gabarito = variacao.gabaritoRemapeado[questaoId] ?? 0;
      // ~75% de chance de acerto no mock.
      final int marcada =
          _random.nextDouble() < 0.75 ? gabarito : _random.nextInt(4);
      respostas.add(marcada);
      if (marcada == gabarito) {
        acertos++;
      }
    }

    final int total = variacao.ordemQuestoes.length;
    final double nota = total == 0 ? 0 : (acertos / total) * 10;

    final Correcao correcao = Correcao(
      id: _uuid.v4(),
      variacaoId: variacaoId,
      alunoId: alunoId,
      respostas: respostas,
      nota: double.parse(nota.toStringAsFixed(1)),
      acertos: acertos,
      totalQuestoes: total,
    );
    _store.correcoes.removeWhere((Correcao c) => c.alunoId == alunoId);
    _store.correcoes.add(correcao);
    return correcao;
  }
}
