/// Professor autenticado no app.
///
/// `senha` só existe para o mock do N1 (AuthMockRepository). Com o Firebase Auth
/// a senha nunca fica no app depois do login e nunca é salva em lugar nenhum.
class Professor {
  const Professor({
    required this.id,
    required this.nome,
    required this.email,
    this.senha = '',
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
