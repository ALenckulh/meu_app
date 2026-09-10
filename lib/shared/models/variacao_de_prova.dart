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
}
