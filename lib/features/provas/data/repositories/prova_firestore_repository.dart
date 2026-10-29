import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meu_app/core/data/firestore_helpers.dart';
import 'package:meu_app/features/provas/domain/repositories/prova_repository.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

/// Provas e variações no Firestore, coleções `provas` e `variacoes`.
///
/// A prova guarda só os IDs das questões. A variação guarda a ordem das
/// questões, a permutação das alternativas e o gabarito já remapeado, então
/// uma variação impressa continua correta mesmo que o banco de questões mude.
class ProvaFirestoreRepository implements ProvaRepository {
  ProvaFirestoreRepository({
    required String? Function() professorId,
    FirebaseFirestore? firestore,
    Random? random,
  })  : _professorId = professorId,
        _db = firestore ?? FirebaseFirestore.instance,
        _random = random ?? Random();

  final String? Function() _professorId;
  final FirebaseFirestore _db;
  final Random _random;

  CollectionReference<Map<String, dynamic>> get _provas =>
      _db.collection('provas');
  CollectionReference<Map<String, dynamic>> get _variacoes =>
      _db.collection('variacoes');
  CollectionReference<Map<String, dynamic>> get _questoes =>
      _db.collection('questoes');

  String get _uid {
    final String? id = _professorId();
    if (id == null) {
      throw StateError('Nenhum professor autenticado.');
    }
    return id;
  }

  // ---------------------------------------------------------------- provas

  @override
  Future<List<Prova>> listAll() async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _provas.where('professorId', isEqualTo: _uid).get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
        snap.docs.toList()
          ..sort((a, b) => compararPorCriacao(a.data(), b.data()));
    return docs.map(_provaFromDoc).toList();
  }

  @override
  Future<Prova?> getById(String id) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _provas.doc(id).get();
      if (!doc.exists) {
        return null;
      }
      if (doc.data()!['professorId'] != _uid) {
        return null;
      }
      return _provaFromDoc(doc);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Prova> create(Prova prova) async {
    final DocumentReference<Map<String, dynamic>> ref = _provas.doc();
    await ref.set(<String, dynamic>{
      'professorId': _uid,
      'titulo': prova.titulo,
      'questaoIds': prova.questaoIds,
      'quantidadeVariacoes': prova.quantidadeVariacoes,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    return prova.copyWith(id: ref.id);
  }

  @override
  Future<Prova> update(Prova prova) async {
    await _provas.doc(prova.id).update(<String, dynamic>{
      'titulo': prova.titulo,
      'questaoIds': prova.questaoIds,
      'quantidadeVariacoes': prova.quantidadeVariacoes,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    return prova;
  }

  @override
  Future<void> delete(String id) async {
    // Remove a prova e todas as variações dela, juntas.
    final QuerySnapshot<Map<String, dynamic>> vars = await _variacoes
        .where('professorId', isEqualTo: _uid)
        .where('provaId', isEqualTo: id)
        .get();
    final WriteBatch batch = _db.batch();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> v in vars.docs) {
      batch.delete(v.reference);
    }
    batch.delete(_provas.doc(id));
    await batch.commit();
  }

  // -------------------------------------------------------------- variações

  @override
  Future<List<VariacaoDeProva>> listVariacoes(String provaId) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _variacoes
        .where('professorId', isEqualTo: _uid)
        .where('provaId', isEqualTo: provaId)
        .get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
        snap.docs.toList()
          ..sort((a, b) => compararPorCriacao(a.data(), b.data()));
    return docs.map(_variacaoFromDoc).toList();
  }

  @override
  Future<VariacaoDeProva?> getVariacaoById(String id) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _variacoes.doc(id).get();
      if (!doc.exists) {
        return null;
      }
      if (doc.data()!['professorId'] != _uid) {
        return null;
      }
      return _variacaoFromDoc(doc);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<VariacaoDeProva> gerarVariacao({
    required String provaId,
    required String alunoId,
    required bool embaralharQuestoes,
    required bool embaralharAlternativas,
  }) async {
    final String uid = _uid;
    final Prova? prova = await getById(provaId);
    if (prova == null) {
      throw StateError('Prova não encontrada.');
    }

    // Gabarito original de cada questão do banco deste professor.
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _questoes.where('professorId', isEqualTo: uid).get();
    final Map<String, int> gabaritoOriginal = <String, int>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snap.docs)
        d.id: paraInt(d.data()['gabaritoIndex']),
    };

    // Ignora IDs de questões que não existem mais.
    final List<String> ordemQuestoes =
        prova.questaoIds.where(gabaritoOriginal.containsKey).toList();
    if (embaralharQuestoes) {
      ordemQuestoes.shuffle(_random);
    }

    final Map<String, List<int>> ordemAlternativas = <String, List<int>>{};
    final Map<String, int> gabaritoRemapeado = <String, int>{};

    for (final String questaoId in ordemQuestoes) {
      final List<int> perm = <int>[0, 1, 2, 3];
      if (embaralharAlternativas) {
        perm.shuffle(_random);
      }
      ordemAlternativas[questaoId] = perm;
      // Nova posição da alternativa que era a correta.
      gabaritoRemapeado[questaoId] = perm.indexOf(gabaritoOriginal[questaoId]!);
    }

    final DocumentReference<Map<String, dynamic>> ref = _variacoes.doc();
    await ref.set(<String, dynamic>{
      'professorId': uid,
      'provaId': provaId,
      'alunoId': alunoId,
      'ordemQuestoes': ordemQuestoes,
      'ordemAlternativas': ordemAlternativas,
      'gabaritoRemapeado': gabaritoRemapeado,
      'criadoEm': FieldValue.serverTimestamp(),
    });

    return VariacaoDeProva(
      id: ref.id,
      provaId: provaId,
      alunoId: alunoId,
      ordemQuestoes: ordemQuestoes,
      ordemAlternativas: ordemAlternativas,
      gabaritoRemapeado: gabaritoRemapeado,
    );
  }

  // -------------------------------------------------------------- conversão

  Prova _provaFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data()!;
    return Prova(
      id: doc.id,
      titulo: d['titulo'] as String? ?? '',
      questaoIds: (d['questaoIds'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
      quantidadeVariacoes: paraInt(d['quantidadeVariacoes'] ?? 2),
    );
  }

  VariacaoDeProva _variacaoFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data()!;
    final Map<String, dynamic> alternativas = Map<String, dynamic>.from(
      (d['ordemAlternativas'] as Map<dynamic, dynamic>?) ??
          <String, dynamic>{},
    );
    final Map<String, dynamic> gabarito = Map<String, dynamic>.from(
      (d['gabaritoRemapeado'] as Map<dynamic, dynamic>?) ??
          <String, dynamic>{},
    );
    return VariacaoDeProva(
      id: doc.id,
      provaId: d['provaId'] as String? ?? '',
      alunoId: d['alunoId'] as String? ?? '',
      ordemQuestoes: (d['ordemQuestoes'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
      ordemAlternativas: <String, List<int>>{
        for (final MapEntry<String, dynamic> e in alternativas.entries)
          e.key: (e.value as List<dynamic>).map(paraInt).toList(),
      },
      gabaritoRemapeado: <String, int>{
        for (final MapEntry<String, dynamic> e in gabarito.entries)
          e.key: paraInt(e.value),
      },
    );
  }
}
