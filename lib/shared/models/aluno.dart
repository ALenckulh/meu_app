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

  factory Aluno.fromMap(String id, Map<dynamic, dynamic> map) {
    return Aluno(
      id: id,
      turmaId: map['turmaId'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      matricula: map['matricula'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'turmaId': turmaId,
      'nome': nome,
      'matricula': matricula,
    };
  }

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
