import 'dart:math';

import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/features/provas/domain/repositories/prova_repository.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:uuid/uuid.dart';

class ProvaMockRepository implements ProvaRepository {
  ProvaMockRepository(this._store);

  final AppMockStore _store;
  final Uuid _uuid = const Uuid();
  final Random _random = Random(42);

  @override
  Future<List<Prova>> listAll() async => List<Prova>.from(_store.provas);

  @override
  Future<Prova?> getById(String id) async {
    try {
      return _store.provas.firstWhere((Prova p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Prova> create(Prova prova) async {
    final Prova created = prova.copyWith(id: _uuid.v4());
    _store.provas.add(created);
    return created;
  }

  @override
  Future<Prova> update(Prova prova) async {
    final int index = _store.provas.indexWhere((Prova p) => p.id == prova.id);
    if (index >= 0) {
      _store.provas[index] = prova;
    }
    return prova;
  }

  @override
  Future<void> delete(String id) async {
    _store.provas.removeWhere((Prova p) => p.id == id);
    _store.variacoes.removeWhere((VariacaoDeProva v) => v.provaId == id);
  }

  @override
  Future<List<VariacaoDeProva>> listVariacoes(String provaId) async {
    return _store.variacoes
        .where((VariacaoDeProva v) => v.provaId == provaId)
        .toList();
  }

  @override
  Future<VariacaoDeProva> gerarVariacao({
    required String provaId,
    required String alunoId,
    required bool embaralharQuestoes,
    required bool embaralharAlternativas,
  }) async {
    final Prova prova =
        _store.provas.firstWhere((Prova p) => p.id == provaId);
    final List<String> ordemQuestoes = List<String>.from(prova.questaoIds);
    if (embaralharQuestoes) {
      ordemQuestoes.shuffle(_random);
    }

    final Map<String, List<int>> ordemAlternativas = <String, List<int>>{};
    final Map<String, int> gabaritoRemapeado = <String, int>{};

    for (final String questaoId in ordemQuestoes) {
      final Questao questao =
          _store.questoes.firstWhere((Questao q) => q.id == questaoId);
      List<int> perm = <int>[0, 1, 2, 3];
      if (embaralharAlternativas) {
        perm = List<int>.from(perm)..shuffle(_random);
      }
      ordemAlternativas[questaoId] = perm;
      gabaritoRemapeado[questaoId] = perm.indexOf(questao.gabaritoIndex);
    }

    final VariacaoDeProva variacao = VariacaoDeProva(
      id: _uuid.v4(),
      provaId: provaId,
      alunoId: alunoId,
      ordemQuestoes: ordemQuestoes,
      ordemAlternativas: ordemAlternativas,
      gabaritoRemapeado: gabaritoRemapeado,
    );
    _store.variacoes.add(variacao);
    return variacao;
  }
}
