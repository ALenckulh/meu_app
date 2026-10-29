import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meu_app/core/data/firestore_helpers.dart';
import 'package:meu_app/features/questoes/domain/repositories/questao_repository.dart';
import 'package:meu_app/shared/models/questao.dart';

/// Banco de questões no Firestore, coleção `questoes`.
///
/// Cada documento guarda o `professorId` de quem criou. Toda leitura filtra por
/// ele e as regras do Firestore (firestore.rules) impedem acessar questões de
/// outro professor.
class QuestaoFirestoreRepository implements QuestaoRepository {
  QuestaoFirestoreRepository({
    required String? Function() professorId,
    FirebaseFirestore? firestore,
  })  : _professorId = professorId,
        _db = firestore ?? FirebaseFirestore.instance;

  final String? Function() _professorId;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('questoes');

  String get _uid {
    final String? id = _professorId();
    if (id == null) {
      throw StateError('Nenhum professor autenticado.');
    }
    return id;
  }

  @override
  Future<List<Questao>> listAll({String? query}) async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('professorId', isEqualTo: _uid).get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
        snap.docs.toList()
          ..sort((a, b) => compararPorCriacao(a.data(), b.data()));

    Iterable<Questao> list = docs.map(_fromDoc);
    if (query != null && query.trim().isNotEmpty) {
      final String q = query.trim().toLowerCase();
      list = list.where((Questao item) {
        return item.enunciado.toLowerCase().contains(q) ||
            item.tags.any((String t) => t.toLowerCase().contains(q));
      });
    }
    return list.toList();
  }

  @override
  Future<Questao?> getById(String id) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _col.doc(id).get();
      if (!doc.exists) {
        return null;
      }
      if (doc.data()!['professorId'] != _uid) {
        return null;
      }
      return _fromDoc(doc);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Questao> create(Questao questao) async {
    final DocumentReference<Map<String, dynamic>> ref = _col.doc();
    await ref.set(<String, dynamic>{
      'professorId': _uid,
      'enunciado': questao.enunciado,
      'alternativas': questao.alternativas,
      'gabaritoIndex': questao.gabaritoIndex,
      'tags': questao.tags,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    return questao.copyWith(id: ref.id);
  }

  @override
  Future<Questao> update(Questao questao) async {
    // As tags não são editadas no formulário, então não são sobrescritas aqui.
    await _col.doc(questao.id).update(<String, dynamic>{
      'enunciado': questao.enunciado,
      'alternativas': questao.alternativas,
      'gabaritoIndex': questao.gabaritoIndex,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    return questao;
  }

  @override
  Future<void> delete(String id) async {
    final WriteBatch batch = _db.batch();

    // Tira a questão das provas que a usam, para nenhuma prova ficar
    // apontando para uma questão que não existe mais.
    final QuerySnapshot<Map<String, dynamic>> provas = await _db
        .collection('provas')
        .where('professorId', isEqualTo: _uid)
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> p in provas.docs) {
      final List<dynamic> ids =
          p.data()['questaoIds'] as List<dynamic>? ?? <dynamic>[];
      if (ids.contains(id)) {
        batch.update(p.reference, <String, dynamic>{
          'questaoIds': FieldValue.arrayRemove(<String>[id]),
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }
    }

    batch.delete(_col.doc(id));
    await batch.commit();
  }

  Questao _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data()!;
    return Questao(
      id: doc.id,
      enunciado: d['enunciado'] as String? ?? '',
      alternativas: (d['alternativas'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic a) => a.toString())
          .toList(),
      gabaritoIndex: paraInt(d['gabaritoIndex'] ?? 0),
      tags: (d['tags'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic t) => t.toString())
          .toList(),
    );
  }
}
