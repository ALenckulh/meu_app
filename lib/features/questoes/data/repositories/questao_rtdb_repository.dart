import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meu_app/core/data/rtdb.dart';
import 'package:meu_app/core/data/rtdb_paths.dart';
import 'package:meu_app/features/questoes/domain/repositories/questao_repository.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:uuid/uuid.dart';

class QuestaoRtdbRepository implements QuestaoRepository {
  QuestaoRtdbRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _db = database ?? rtdb,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<List<Questao>> listAll({String? query}) async {
    final String? uid = _uid;
    if (uid == null) {
      return <Questao>[];
    }
    final DataSnapshot snap = await _db
        .ref(RtdbPaths.questoes)
        .orderByChild('professorId')
        .equalTo(uid)
        .get();
    if (!snap.exists || snap.value == null) {
      return <Questao>[];
    }
    final Map<dynamic, dynamic> map =
        snap.value as Map<dynamic, dynamic>;
    List<Questao> list = map.entries
        .map(
          (MapEntry<dynamic, dynamic> e) => Questao.fromMap(
            e.key.toString(),
            Map<dynamic, dynamic>.from(e.value as Map),
          ),
        )
        .toList();
    if (query != null && query.trim().isNotEmpty) {
      final String q = query.trim().toLowerCase();
      list = list
          .where(
            (Questao item) =>
                item.enunciado.toLowerCase().contains(q) ||
                item.tags.any((String t) => t.toLowerCase().contains(q)),
          )
          .toList();
    }
    return list;
  }

  @override
  Future<Questao?> getById(String id) async {
    final DataSnapshot snap = await _db.ref(RtdbPaths.questao(id)).get();
    if (!snap.exists || snap.value == null) {
      return null;
    }
    return Questao.fromMap(
      id,
      Map<dynamic, dynamic>.from(snap.value as Map),
    );
  }

  @override
  Future<Questao> create(Questao questao) async {
    final String id = questao.id.isEmpty ? _uuid.v4() : questao.id;
    final Questao created = questao.copyWith(id: id);
    await _db.ref(RtdbPaths.questao(id)).set(created.toMap());
    return created;
  }

  @override
  Future<Questao> update(Questao questao) async {
    await _db.ref(RtdbPaths.questao(questao.id)).update(questao.toMap());
    return questao;
  }

  @override
  Future<void> delete(String id) async {
    await _db.ref(RtdbPaths.questao(id)).remove();
  }
}
