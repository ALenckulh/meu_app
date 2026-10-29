import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meu_app/core/data/rtdb.dart';
import 'package:meu_app/core/data/rtdb_paths.dart';
import 'package:meu_app/features/provas/domain/repositories/prova_repository.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:uuid/uuid.dart';

class ProvaRtdbRepository implements ProvaRepository {
  ProvaRtdbRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _db = database ?? rtdb,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<List<Prova>> listAll() async {
    final String? uid = _uid;
    if (uid == null) {
      return <Prova>[];
    }
    final DataSnapshot snap = await _db
        .ref(RtdbPaths.provas)
        .orderByChild('professorId')
        .equalTo(uid)
        .get();
    if (!snap.exists || snap.value == null) {
      return <Prova>[];
    }
    final Map<dynamic, dynamic> map =
        snap.value as Map<dynamic, dynamic>;
    return map.entries
        .map(
          (MapEntry<dynamic, dynamic> e) => Prova.fromMap(
            e.key.toString(),
            Map<dynamic, dynamic>.from(e.value as Map),
          ),
        )
        .toList();
  }

  @override
  Future<Prova?> getById(String id) async {
    final DataSnapshot snap = await _db.ref(RtdbPaths.prova(id)).get();
    if (!snap.exists || snap.value == null) {
      return null;
    }
    return Prova.fromMap(
      id,
      Map<dynamic, dynamic>.from(snap.value as Map),
    );
  }

  @override
  Future<Prova> create(Prova prova) async {
    final String id = prova.id.isEmpty ? _uuid.v4() : prova.id;
    final Prova created = prova.copyWith(id: id);
    await _db.ref(RtdbPaths.prova(id)).set(created.toMap());
    return created;
  }

  @override
  Future<Prova> update(Prova prova) async {
    await _db.ref(RtdbPaths.prova(prova.id)).update(prova.toMap());
    return prova;
  }

  @override
  Future<void> delete(String id) async {
    await _db.ref(RtdbPaths.prova(id)).remove();
    await deleteVariacoes(id);
  }

  @override
  Future<void> deleteVariacoes(String provaId) async {
    await _removerVariacoes(await listVariacoes(provaId));
  }

  Future<void> _removerVariacoes(Iterable<VariacaoDeProva> variacoes) async {
    final Map<String, dynamic> updates = <String, dynamic>{
      for (final VariacaoDeProva v in variacoes)
        '${RtdbPaths.variacoes}/${v.id}': null,
    };
    if (updates.isNotEmpty) {
      await _db.ref().update(updates);
    }
  }

  @override
  Future<VariacaoDeProva?> getVariacaoById(String id) async {
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
  Future<List<VariacaoDeProva>> listVariacoes(String provaId) async {
    final DataSnapshot snap = await _db
        .ref(RtdbPaths.variacoes)
        .orderByChild('provaId')
        .equalTo(provaId)
        .get();
    if (!snap.exists || snap.value == null) {
      return <VariacaoDeProva>[];
    }
    final Map<dynamic, dynamic> map =
        snap.value as Map<dynamic, dynamic>;
    return map.entries
        .map(
          (MapEntry<dynamic, dynamic> e) => VariacaoDeProva.fromMap(
            e.key.toString(),
            Map<dynamic, dynamic>.from(e.value as Map),
          ),
        )
        .toList();
  }

  @override
  Future<VariacaoDeProva> gerarVariacao({
    required String provaId,
    required String alunoId,
    required bool embaralharQuestoes,
    required bool embaralharAlternativas,
  }) async {
    final Prova? prova = await getById(provaId);
    if (prova == null) {
      throw StateError('Prova não encontrada: $provaId');
    }

    final List<String> ordemQuestoes = <String>[];
    final Map<String, List<int>> ordemAlternativas = <String, List<int>>{};
    final Map<String, int> gabaritoRemapeado = <String, int>{};

    for (final String questaoId in prova.questaoIds) {
      final DataSnapshot qSnap =
          await _db.ref(RtdbPaths.questao(questaoId)).get();
      // Questão excluída do banco não entra na folha (ficaria sem gabarito).
      if (!qSnap.exists || qSnap.value == null) {
        continue;
      }
      ordemQuestoes.add(questaoId);
      final Questao questao = Questao.fromMap(
        questaoId,
        Map<dynamic, dynamic>.from(qSnap.value as Map),
      );
      List<int> perm = <int>[0, 1, 2, 3];
      if (embaralharAlternativas) {
        perm = List<int>.from(perm)..shuffle(_random);
      }
      ordemAlternativas[questaoId] = perm;
      gabaritoRemapeado[questaoId] = perm.indexOf(questao.gabaritoIndex);
    }
    if (ordemQuestoes.isEmpty) {
      throw StateError('A prova não tem questões válidas.');
    }
    if (embaralharQuestoes) {
      ordemQuestoes.shuffle(_random);
    }

    final List<VariacaoDeProva> anteriores = (await listVariacoes(provaId))
        .where((VariacaoDeProva v) => v.alunoId == alunoId)
        .toList();

    final String id = _uuid.v4();
    final VariacaoDeProva variacao = VariacaoDeProva(
      id: id,
      provaId: provaId,
      alunoId: alunoId,
      ordemQuestoes: ordemQuestoes,
      ordemAlternativas: ordemAlternativas,
      gabaritoRemapeado: gabaritoRemapeado,
    );
    await _db.ref(RtdbPaths.variacao(id)).set(variacao.toMap());
    await _removerVariacoes(anteriores);
    return variacao;
  }
}
