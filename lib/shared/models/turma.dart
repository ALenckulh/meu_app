class Turma {
  const Turma({
    required this.id,
    required this.professorId,
    required this.nome,
    required this.disciplina,
    required this.ano,
  });

  final String id;
  final String professorId;
  final String nome;
  final String disciplina;
  final int ano;

  Turma copyWith({
    String? id,
    String? professorId,
    String? nome,
    String? disciplina,
    int? ano,
  }) {
    return Turma(
      id: id ?? this.id,
      professorId: professorId ?? this.professorId,
      nome: nome ?? this.nome,
      disciplina: disciplina ?? this.disciplina,
      ano: ano ?? this.ano,
    );
  }
}
