class Prova {
  const Prova({
    required this.id,
    required this.titulo,
    required this.questaoIds,
    this.quantidadeVariacoes = 2,
  });

  final String id;
  final String titulo;
  final List<String> questaoIds;
  final int quantidadeVariacoes;

  Prova copyWith({
    String? id,
    String? titulo,
    List<String>? questaoIds,
    int? quantidadeVariacoes,
  }) {
    return Prova(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      questaoIds: questaoIds ?? this.questaoIds,
      quantidadeVariacoes: quantidadeVariacoes ?? this.quantidadeVariacoes,
    );
  }
}
