class Aluno {
  const Aluno({
    required this.id,
    required this.turmaId,
    required this.nome,
    required this.matricula,
  });

  final String id;
  final String turmaId;
  final String nome;
  final String matricula;

  Aluno copyWith({
    String? id,
    String? turmaId,
    String? nome,
    String? matricula,
  }) {
    return Aluno(
      id: id ?? this.id,
      turmaId: turmaId ?? this.turmaId,
      nome: nome ?? this.nome,
      matricula: matricula ?? this.matricula,
    );
  }
}
