/// Professor autenticado no app (N1: mock).
class Professor {
  const Professor({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
  });

  final String id;
  final String nome;
  final String email;
  final String senha;

  Professor copyWith({
    String? id,
    String? nome,
    String? email,
    String? senha,
  }) {
    return Professor(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      senha: senha ?? this.senha,
    );
  }
}
