/// Paths do Realtime Database.
abstract final class RtdbPaths {
  static String professor(String uid) => 'professores/$uid';
  static String turma(String id) => 'turmas/$id';
  static const String turmas = 'turmas';
  static String aluno(String id) => 'alunos/$id';
  static const String alunos = 'alunos';
  static String questao(String id) => 'questoes/$id';
  static const String questoes = 'questoes';
  static String prova(String id) => 'provas/$id';
  static const String provas = 'provas';
  static String variacao(String id) => 'variacoes_de_prova/$id';
  static const String variacoes = 'variacoes_de_prova';
  static String correcao(String id) => 'correcoes/$id';
  static const String correcoes = 'correcoes';
}
