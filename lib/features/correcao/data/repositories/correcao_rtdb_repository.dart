import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meu_app/core/data/rtdb.dart';
import 'package:meu_app/core/data/rtdb_paths.dart';
import 'package:meu_app/features/correcao/domain/repositories/correcao_repository.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/questao.dart';
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
  Future<Correcao?> getByVariacao(String variacaoId) async {
    for (final Correcao c in await listAll()) {
      if (c.variacaoId == variacaoId) {
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

    // Gabarito vem da questão atual (não do snapshot da variação), para que
    // corrigir o gabarito de uma questão valha para as próximas correções.
    final List<int> gabarito = <int>[];
    int acertos = 0;
    for (int i = 0; i < variacao.ordemQuestoes.length; i++) {
      final String questaoId = variacao.ordemQuestoes[i];
      final int marcada = respostas[i];
      if (marcada < 0 || marcada > 3) {
        throw ArgumentError('Resposta inválida na posição $i: $marcada');
      }
      final int correta = await _gabaritoAtual(variacao, questaoId);
      gabarito.add(correta);
      if (marcada == correta) {
        acertos++;
      }
    }

    final int total = variacao.ordemQuestoes.length;
    final double nota = total == 0 ? 0 : (acertos / total) * 10;

    final Correcao? existing = await getByVariacao(variacaoId);
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
      gabarito: gabarito,
    );
    await _db.ref(RtdbPaths.correcao(id)).set(correcao.toMap());
    return correcao;
  }

  Future<int> _gabaritoAtual(VariacaoDeProva variacao, String questaoId) async {
    final int salvo = variacao.gabaritoRemapeado[questaoId] ?? 0;
    final DataSnapshot snap = await _db.ref(RtdbPaths.questao(questaoId)).get();
    if (!snap.exists || snap.value == null) {
      return salvo;
    }
    final Questao questao = Questao.fromMap(
      questaoId,
      Map<dynamic, dynamic>.from(snap.value as Map),
    );
    final List<int> perm =
        variacao.ordemAlternativas[questaoId] ?? const <int>[0, 1, 2, 3];
    final int idx = perm.indexOf(questao.gabaritoIndex);
    return idx < 0 ? salvo : idx;
  }
}
