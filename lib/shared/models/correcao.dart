class Correcao {
  const Correcao({
    required this.id,
    required this.variacaoId,
    required this.alunoId,
    required this.respostas,
    required this.nota,
    required this.acertos,
    required this.totalQuestoes,
  });

  final String id;
  final String variacaoId;
  final String alunoId;

  /// Alternativa marcada (0–3) por índice da questão na variação.
  final List<int> respostas;
  final double nota;
  final int acertos;
  final int totalQuestoes;

  factory Correcao.fromMap(String id, Map<dynamic, dynamic> map) {
    final List<dynamic> rawResp =
        map['respostas'] as List<dynamic>? ?? <dynamic>[];
    return Correcao(
      id: id,
      variacaoId: map['variacaoId'] as String? ?? '',
      alunoId: map['alunoId'] as String? ?? '',
      respostas: rawResp.map((dynamic e) => (e as num).toInt()).toList(),
      nota: (map['nota'] as num?)?.toDouble() ?? 0,
      acertos: (map['acertos'] as num?)?.toInt() ?? 0,
      totalQuestoes: (map['totalQuestoes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'variacaoId': variacaoId,
      'alunoId': alunoId,
      'respostas': respostas,
      'nota': nota,
      'acertos': acertos,
      'totalQuestoes': totalQuestoes,
    };
  }
}
