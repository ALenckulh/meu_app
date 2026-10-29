import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:meu_app/core/data/rtdb.dart';
import 'package:meu_app/core/data/rtdb_paths.dart';
import 'package:meu_app/features/correcao/domain/repositories/correcao_repository.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:uuid/uuid.dart';

class CorrecaoRtdbRepository implements CorrecaoRepository {
  CorrecaoRtdbRepository({FirebaseDatabase? database})
      : _db = database ?? rtdb;

  final FirebaseDatabase _db;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  @override
  Future<List<Correcao>> listAll() async {
    final DataSnapshot snap = await _db.ref(RtdbPaths.correcoes).get();
    if (!snap.exists || snap.value == null) {
      return <Correcao>[];
    }
    final Map<dynamic, dynamic> map =
        snap.value as Map<dynamic, dynamic>;
    return map.entries
        .map(
          (MapEntry<dynamic, dynamic> e) => Correcao.fromMap(
            e.key.toString(),
            Map<dynamic, dynamic>.from(e.value as Map),
          ),
        )
        .toList();
  }

  @override
  Future<Correcao?> getByAluno(String alunoId) async {
    final DataSnapshot snap = await _db
        .ref(RtdbPaths.correcoes)
        .orderByChild('alunoId')
        .equalTo(alunoId)
        .get();
    if (!snap.exists || snap.value == null) {
      return null;
    }
    final Map<dynamic, dynamic> map =
        snap.value as Map<dynamic, dynamic>;
    final MapEntry<dynamic, dynamic> first = map.entries.first;
    return Correcao.fromMap(
      first.key.toString(),
      Map<dynamic, dynamic>.from(first.value as Map),
    );
  }

  @override
  Future<Correcao?> getById(String id) async {
    final DataSnapshot snap = await _db.ref(RtdbPaths.correcao(id)).get();
    if (!snap.exists || snap.value == null) {
      return null;
    }
    return Correcao.fromMap(
      id,
      Map<dynamic, dynamic>.from(snap.value as Map),
    );
  }

  Future<VariacaoDeProva?> getVariacao(String id) async {
    final DataSnapshot snap = await _db.ref(RtdbPaths.variacao(id)).get();
    if (!snap.exists || snap.value == null) {
      return null;
    }
    return VariacaoDeProva.fromMap(
      id,
      Map<dynamic, dynamic>.from(snap.value as Map),
    );
  }

  @override
  Future<Correcao> simularLeitura({
    required String variacaoId,
    required String alunoId,
  }) async {
    final VariacaoDeProva? variacao = await getVariacao(variacaoId);
    if (variacao == null) {
      throw StateError('Variação não encontrada: $variacaoId');
    }

    final List<int> respostas = <int>[];
    int acertos = 0;
    for (final String questaoId in variacao.ordemQuestoes) {
      final int gabarito = variacao.gabaritoRemapeado[questaoId] ?? 0;
      final int marcada =
          _random.nextDouble() < 0.75 ? gabarito : _random.nextInt(4);
      respostas.add(marcada);
      if (marcada == gabarito) {
        acertos++;
      }
    }

    final int total = variacao.ordemQuestoes.length;
    final double nota = total == 0 ? 0 : (acertos / total) * 10;

    final Correcao? existing = await getByAluno(alunoId);
    final String id = existing?.id ?? _uuid.v4();
    final Correcao correcao = Correcao(
      id: id,
      variacaoId: variacaoId,
      alunoId: alunoId,
      respostas: respostas,
      nota: double.parse(nota.toStringAsFixed(1)),
      acertos: acertos,
      totalQuestoes: total,
    );
    await _db.ref(RtdbPaths.correcao(id)).set(correcao.toMap());
    return correcao;
  }
}
