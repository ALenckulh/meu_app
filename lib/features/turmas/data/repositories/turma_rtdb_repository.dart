import 'package:firebase_database/firebase_database.dart';
import 'package:meu_app/core/data/rtdb.dart';
import 'package:meu_app/core/data/rtdb_paths.dart';
import 'package:meu_app/features/turmas/domain/repositories/turma_repository.dart';
import 'package:meu_app/shared/models/turma.dart';
import 'package:uuid/uuid.dart';

class TurmaRtdbRepository implements TurmaRepository {
  TurmaRtdbRepository({FirebaseDatabase? database})
      : _db = database ?? rtdb;

  final FirebaseDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Turma>> listByProfessor(String professorId) async {
    final DataSnapshot snap = await _db
        .ref(RtdbPaths.turmas)
        .orderByChild('professorId')
        .equalTo(professorId)
        .get();
    if (!snap.exists || snap.value == null) {
      return <Turma>[];
    }
    final Map<dynamic, dynamic> map =
        snap.value as Map<dynamic, dynamic>;
    return map.entries
        .map(
          (MapEntry<dynamic, dynamic> e) => Turma.fromMap(
            e.key.toString(),
            Map<dynamic, dynamic>.from(e.value as Map),
          ),
        )
        .toList();
  }

  @override
  Future<Turma?> getById(String id) async {
    final DataSnapshot snap = await _db.ref(RtdbPaths.turma(id)).get();
    if (!snap.exists || snap.value == null) {
      return null;
    }
    return Turma.fromMap(
      id,
      Map<dynamic, dynamic>.from(snap.value as Map),
    );
  }

  @override
  Future<Turma> create(Turma turma) async {
    final String id = turma.id.isEmpty ? _uuid.v4() : turma.id;
    final Turma created = turma.copyWith(id: id);
    await _db.ref(RtdbPaths.turma(id)).set(created.toMap());
    return created;
  }

  @override
  Future<Turma> update(Turma turma) async {
    await _db.ref(RtdbPaths.turma(turma.id)).update(turma.toMap());
    return turma;
  }

  @override
  Future<void> delete(String id) async {
    await _db.ref(RtdbPaths.turma(id)).remove();
    final DataSnapshot alunos = await _db
        .ref(RtdbPaths.alunos)
        .orderByChild('turmaId')
        .equalTo(id)
        .get();
    if (!alunos.exists || alunos.value == null) {
      return;
    }
    final Map<dynamic, dynamic> map =
        alunos.value as Map<dynamic, dynamic>;
    final Map<String, dynamic> updates = <String, dynamic>{};
    for (final dynamic key in map.keys) {
      updates['${RtdbPaths.alunos}/$key'] = null;
    }
    await _db.ref().update(updates);
  }
}
