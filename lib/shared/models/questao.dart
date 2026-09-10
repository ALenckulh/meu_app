class Questao {
  const Questao({
    required this.id,
    required this.enunciado,
    required this.alternativas,
    required this.gabaritoIndex,
    this.tags = const <String>[],
  });

  final String id;
  final String enunciado;

  /// Sempre 4 alternativas (A–D).
  final List<String> alternativas;

  /// Índice 0–3 da alternativa correta.
  final int gabaritoIndex;
  final List<String> tags;

  Questao copyWith({
    String? id,
    String? enunciado,
    List<String>? alternativas,
    int? gabaritoIndex,
    List<String>? tags,
  }) {
    return Questao(
      id: id ?? this.id,
      enunciado: enunciado ?? this.enunciado,
      alternativas: alternativas ?? this.alternativas,
      gabaritoIndex: gabaritoIndex ?? this.gabaritoIndex,
      tags: tags ?? this.tags,
    );
  }
}
