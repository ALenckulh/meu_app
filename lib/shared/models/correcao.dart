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
}
