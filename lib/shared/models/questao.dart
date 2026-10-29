class Questao {
  const Questao({
    required this.id,
    required this.professorId,
    required this.enunciado,
    required this.alternativas,
    required this.gabaritoIndex,
    this.tags = const <String>[],
  });

  final String id;
  final String professorId;
  final String enunciado;

  /// Sempre 4 alternativas (A–D).
  final List<String> alternativas;

  /// Índice 0–3 da alternativa correta.
  final int gabaritoIndex;
  final List<String> tags;

  factory Questao.fromMap(String id, Map<dynamic, dynamic> map) {
    final List<dynamic> rawAlts =
        map['alternativas'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawTags = map['tags'] as List<dynamic>? ?? <dynamic>[];
    return Questao(
      id: id,
      professorId: map['professorId'] as String? ?? '',
      enunciado: map['enunciado'] as String? ?? '',
      alternativas: rawAlts.map((dynamic e) => e.toString()).toList(),
      gabaritoIndex: (map['gabaritoIndex'] as num?)?.toInt() ?? 0,
      tags: rawTags.map((dynamic e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'professorId': professorId,
      'enunciado': enunciado,
      'alternativas': alternativas,
      'gabaritoIndex': gabaritoIndex,
      'tags': tags,
    };
  }

  Questao copyWith({
    String? id,
    String? professorId,
    String? enunciado,
    List<String>? alternativas,
    int? gabaritoIndex,
    List<String>? tags,
  }) {
    return Questao(
      id: id ?? this.id,
      professorId: professorId ?? this.professorId,
      enunciado: enunciado ?? this.enunciado,
      alternativas: alternativas ?? this.alternativas,
      gabaritoIndex: gabaritoIndex ?? this.gabaritoIndex,
      tags: tags ?? this.tags,
    );
  }
}
