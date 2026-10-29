/// Versão embaralhada de uma prova vinculada a um aluno.
class VariacaoDeProva {
  const VariacaoDeProva({
    required this.id,
    required this.provaId,
    required this.alunoId,
    required this.ordemQuestoes,
    required this.ordemAlternativas,
    required this.gabaritoRemapeado,
  });

  final String id;
  final String provaId;
  final String alunoId;

  /// IDs das questões na ordem desta variação.
  final List<String> ordemQuestoes;

  /// Para cada questão: permutação dos índices das alternativas (0–3).
  final Map<String, List<int>> ordemAlternativas;

  /// Índice da alternativa correta após embaralhamento, por questão.
  final Map<String, int> gabaritoRemapeado;

  factory VariacaoDeProva.fromMap(String id, Map<dynamic, dynamic> map) {
    final List<dynamic> rawOrdem =
        map['ordemQuestoes'] as List<dynamic>? ?? <dynamic>[];
    final Map<dynamic, dynamic> rawAlts =
        map['ordemAlternativas'] as Map<dynamic, dynamic>? ??
            <dynamic, dynamic>{};
    final Map<dynamic, dynamic> rawGab =
        map['gabaritoRemapeado'] as Map<dynamic, dynamic>? ??
            <dynamic, dynamic>{};

    final Map<String, List<int>> ordemAlternativas = <String, List<int>>{};
    rawAlts.forEach((dynamic key, dynamic value) {
      final List<dynamic> list = value as List<dynamic>? ?? <dynamic>[];
      ordemAlternativas[key.toString()] =
          list.map((dynamic e) => (e as num).toInt()).toList();
    });

    final Map<String, int> gabaritoRemapeado = <String, int>{};
    rawGab.forEach((dynamic key, dynamic value) {
      gabaritoRemapeado[key.toString()] = (value as num).toInt();
    });

    return VariacaoDeProva(
      id: id,
      provaId: map['provaId'] as String? ?? '',
      alunoId: map['alunoId'] as String? ?? '',
      ordemQuestoes: rawOrdem.map((dynamic e) => e.toString()).toList(),
      ordemAlternativas: ordemAlternativas,
      gabaritoRemapeado: gabaritoRemapeado,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'provaId': provaId,
      'alunoId': alunoId,
      'ordemQuestoes': ordemQuestoes,
      'ordemAlternativas': ordemAlternativas,
      'gabaritoRemapeado': gabaritoRemapeado,
    };
  }
}
