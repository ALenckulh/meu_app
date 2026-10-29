import 'package:firebase_database/firebase_database.dart';
import 'package:meu_app/core/data/rtdb.dart';
import 'package:meu_app/core/data/rtdb_paths.dart';
import 'package:meu_app/features/alunos/domain/repositories/aluno_repository.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:uuid/uuid.dart';

class AlunoRtdbRepository implements AlunoRepository {
  AlunoRtdbRepository({FirebaseDatabase? database})
      : _db = database ?? rtdb;

  final FirebaseDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Aluno>> listByTurma(String turmaId) async {
    final DataSnapshot snap = await _db
        .ref(RtdbPaths.alunos)
        .orderByChild('turmaId')
        .equalTo(turmaId)
        .get();
    if (!snap.exists || snap.value == null) {
      return <Aluno>[];
    }
    final Map<dynamic, dynamic> map =
        snap.value as Map<dynamic, dynamic>;
    return map.entries
        .map(
          (MapEntry<dynamic, dynamic> e) => Aluno.fromMap(
            e.key.toString(),
            Map<dynamic, dynamic>.from(e.value as Map),
          ),
        )
        .toList();
  }

  @override
  Future<Aluno?> getById(String id) async {
    final DataSnapshot snap = await _db.ref(RtdbPaths.aluno(id)).get();
    if (!snap.exists || snap.value == null) {
      return null;
    }
    return Aluno.fromMap(
      id,
      Map<dynamic, dynamic>.from(snap.value as Map),
    );
  }

  @override
  Future<Aluno> create(Aluno aluno) async {
    final String id = aluno.id.isEmpty ? _uuid.v4() : aluno.id;
    final Aluno created = aluno.copyWith(id: id);
    await _db.ref(RtdbPaths.aluno(id)).set(created.toMap());
    return created;
  }

  @override
  Future<Aluno> update(Aluno aluno) async {
    await _db.ref(RtdbPaths.aluno(aluno.id)).update(aluno.toMap());
    return aluno;
  }

  @override
  Future<void> delete(String id) async {
    await _db.ref(RtdbPaths.aluno(id)).remove();
  }
}
