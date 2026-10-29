/// Professor autenticado no app.
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

  /// Não persistido no RTDB; só Firebase Auth.
  final String senha;

  factory Professor.fromMap(String id, Map<dynamic, dynamic> map) {
    return Professor(
      id: id,
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nome': nome,
      'email': email,
    };
  }

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
