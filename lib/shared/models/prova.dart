class Prova {
  const Prova({
    required this.id,
    required this.professorId,
    required this.titulo,
    required this.questaoIds,
    this.turmaId = '',
    this.quantidadeVariacoes = 2,
    this.embaralharQuestoes = true,
    this.embaralharAlternativas = true,
    this.correcaoEncerrada = false,
  });

  final String id;
  final String professorId;
  final String titulo;
  final List<String> questaoIds;

  /// Turma vinculada (alunos para variações / folhas individuais).
  final String turmaId;
  final int quantidadeVariacoes;

  /// Configuração de embaralhamento usada ao gerar as folhas dos alunos.
  final bool embaralharQuestoes;
  final bool embaralharAlternativas;

  /// O professor encerrou a correção: quem ficou sem nota é tratado como
  /// ausente e a prova aparece como finalizada.
  final bool correcaoEncerrada;

  factory Prova.fromMap(String id, Map<dynamic, dynamic> map) {
    final List<dynamic> rawIds =
        map['questaoIds'] as List<dynamic>? ?? <dynamic>[];
    return Prova(
      id: id,
      professorId: map['professorId'] as String? ?? '',
      titulo: map['titulo'] as String? ?? '',
      questaoIds: rawIds.map((dynamic e) => e.toString()).toList(),
      turmaId: map['turmaId'] as String? ?? '',
      quantidadeVariacoes: (map['quantidadeVariacoes'] as num?)?.toInt() ?? 2,
      embaralharQuestoes: map['embaralharQuestoes'] as bool? ?? true,
      embaralharAlternativas: map['embaralharAlternativas'] as bool? ?? true,
      correcaoEncerrada: map['correcaoEncerrada'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'professorId': professorId,
      'titulo': titulo,
      'questaoIds': questaoIds,
      'turmaId': turmaId,
      'quantidadeVariacoes': quantidadeVariacoes,
      'embaralharQuestoes': embaralharQuestoes,
      'embaralharAlternativas': embaralharAlternativas,
      'correcaoEncerrada': correcaoEncerrada,
    };
  }

  Prova copyWith({
    String? id,
    String? professorId,
    String? titulo,
    List<String>? questaoIds,
    String? turmaId,
    int? quantidadeVariacoes,
    bool? embaralharQuestoes,
    bool? embaralharAlternativas,
    bool? correcaoEncerrada,
  }) {
    return Prova(
      id: id ?? this.id,
      professorId: professorId ?? this.professorId,
      titulo: titulo ?? this.titulo,
      questaoIds: questaoIds ?? this.questaoIds,
      turmaId: turmaId ?? this.turmaId,
      quantidadeVariacoes: quantidadeVariacoes ?? this.quantidadeVariacoes,
      embaralharQuestoes: embaralharQuestoes ?? this.embaralharQuestoes,
      embaralharAlternativas:
          embaralharAlternativas ?? this.embaralharAlternativas,
      correcaoEncerrada: correcaoEncerrada ?? this.correcaoEncerrada,
    );
  }
}
