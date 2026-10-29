import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meu_app/core/data/rtdb.dart';
import 'package:meu_app/core/data/rtdb_paths.dart';
import 'package:meu_app/features/correcao/domain/repositories/correcao_repository.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:uuid/uuid.dart';

class CorrecaoRtdbRepository implements CorrecaoRepository {
  CorrecaoRtdbRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _db = database ?? rtdb,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<List<Correcao>> listAll() async {
    final String? uid = _uid;
    if (uid == null) {
      return <Correcao>[];
    }
    final DataSnapshot snap = await _db
        .ref(RtdbPaths.correcoes)
        .orderByChild('professorId')
        .equalTo(uid)
        .get();
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
    final String? uid = _uid;
    for (final MapEntry<dynamic, dynamic> e in map.entries) {
      final Correcao c = Correcao.fromMap(
        e.key.toString(),
        Map<dynamic, dynamic>.from(e.value as Map),
      );
      if (uid == null || c.professorId == uid || c.professorId.isEmpty) {
        return c;
      }
    }
    return null;
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
  Future<Correcao> corrigir({
    required String variacaoId,
    required String alunoId,
    required String professorId,
    required List<int> respostas,
  }) async {
    final VariacaoDeProva? variacao = await getVariacao(variacaoId);
    if (variacao == null) {
      throw StateError('Variação não encontrada: $variacaoId');
    }
    if (respostas.length != variacao.ordemQuestoes.length) {
      throw ArgumentError(
        'Respostas (${respostas.length}) ≠ questões '
        '(${variacao.ordemQuestoes.length}).',
      );
    }

    int acertos = 0;
    for (int i = 0; i < variacao.ordemQuestoes.length; i++) {
      final String questaoId = variacao.ordemQuestoes[i];
      final int gabarito = variacao.gabaritoRemapeado[questaoId] ?? 0;
      final int marcada = respostas[i];
      if (marcada < 0 || marcada > 3) {
        throw ArgumentError('Resposta inválida na posição $i: $marcada');
      }
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
      professorId: professorId,
      variacaoId: variacaoId,
      alunoId: alunoId,
      respostas: List<int>.from(respostas),
      nota: double.parse(nota.toStringAsFixed(1)),
      acertos: acertos,
      totalQuestoes: total,
    );
    await _db.ref(RtdbPaths.correcao(id)).set(correcao.toMap());
    return correcao;
  }
}
