import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

/// Situação da prova na correção.
enum StatusProva {
  /// Nenhuma folha corrigida ainda.
  aguardandoCorrecao,

  /// Parte dos alunos da turma já tem nota.
  emCorrecao,

  /// Todos os alunos da turma têm nota, ou o professor encerrou a correção.
  finalizada;

  String get rotulo => switch (this) {
        StatusProva.aguardandoCorrecao => 'Aguardando correção',
        StatusProva.emCorrecao => 'Em correção',
        StatusProva.finalizada => 'Correções finalizadas',
      };
}

/// Linha do relatório: um aluno da turma e sua correção (se houver).
class SituacaoAluno {
  const SituacaoAluno({required this.aluno, this.correcao});

  final Aluno aluno;
  final Correcao? correcao;

  bool get corrigido => correcao != null;
}

/// Desempenho da turma em uma questão (RF11).
class DesempenhoQuestao {
  const DesempenhoQuestao({
    required this.numero,
    required this.questaoId,
    required this.respostas,
    required this.acertos,
    required this.marcacoes,
  });

  /// Posição da questão na prova original (1, 2, ...).
  final int numero;
  final String questaoId;

  /// Quantos alunos responderam esta questão.
  final int respostas;
  final int acertos;

  /// Quantas vezes cada alternativa ORIGINAL (0–3) foi marcada.
  final List<int> marcacoes;

  int get erros => respostas - acertos;
  double get percentualAcerto => respostas == 0 ? 0 : acertos / respostas;

  /// Alternativa original mais marcada, ou null se ninguém respondeu.
  int? get maisMarcada {
    if (respostas == 0) {
      return null;
    }
    int melhor = 0;
    for (int i = 1; i < marcacoes.length; i++) {
      if (marcacoes[i] > marcacoes[melhor]) {
        melhor = i;
      }
    }
    return melhor;
  }
}

/// Relatório de uma prova: quem já foi corrigido, médias e status (item 9
/// da N3).
class RelatorioProva {
  RelatorioProva._({
    required this.prova,
    required this.alunos,
    required this.questoes,
  });

  /// Monta o relatório a partir dos dados já carregados.
  ///
  /// [correcoes] podem incluir correções de outras provas: só entram as que
  /// apontam para esta prova (por `provaId` ou por uma das [variacoes]).
  factory RelatorioProva.montar({
    required Prova prova,
    required List<Aluno> alunosDaTurma,
    required List<Correcao> correcoes,
    required List<VariacaoDeProva> variacoes,
  }) {
    final Map<String, VariacaoDeProva> porId = <String, VariacaoDeProva>{
      for (final VariacaoDeProva v in variacoes) v.id: v,
    };
    final Iterable<Correcao> daProva = correcoes.where(
      (Correcao c) => c.provaId == prova.id || porId.containsKey(c.variacaoId),
    );

    // Uma nota por aluno: se houver mais de uma, vale a da variação atual.
    final Map<String, Correcao> porAluno = <String, Correcao>{};
    for (final Correcao c in daProva) {
      final Correcao? atual = porAluno[c.alunoId];
      if (atual == null ||
          (!porId.containsKey(atual.variacaoId) &&
              porId.containsKey(c.variacaoId))) {
        porAluno[c.alunoId] = c;
      }
    }

    final List<Aluno> ordenados = List<Aluno>.from(alunosDaTurma)
      ..sort((Aluno a, Aluno b) =>
          a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    final List<SituacaoAluno> situacoes = ordenados
        .map((Aluno a) => SituacaoAluno(aluno: a, correcao: porAluno[a.id]))
        .toList();

    // Estatística por questão, na ordem original da prova.
    final Map<String, List<int>> marcacoes = <String, List<int>>{
      for (final String id in prova.questaoIds) id: <int>[0, 0, 0, 0],
    };
    final Map<String, int> acertos = <String, int>{
      for (final String id in prova.questaoIds) id: 0,
    };
    final Map<String, int> respondidas = <String, int>{
      for (final String id in prova.questaoIds) id: 0,
    };
    for (final SituacaoAluno s in situacoes) {
      final Correcao? c = s.correcao;
      final VariacaoDeProva? v = c == null ? null : porId[c.variacaoId];
      if (c == null || v == null) {
        continue;
      }
      for (int i = 0;
          i < c.respostas.length && i < v.ordemQuestoes.length;
          i++) {
        final String qid = v.ordemQuestoes[i];
        if (!marcacoes.containsKey(qid)) {
          continue;
        }
        final int slot = c.respostas[i];
        final List<int> perm =
            v.ordemAlternativas[qid] ?? const <int>[0, 1, 2, 3];
        if (slot >= 0) {
          final int original = slot < perm.length ? perm[slot] : slot;
          if (original >= 0 && original < 4) {
            marcacoes[qid]![original]++;
          }
        }
        respondidas[qid] = respondidas[qid]! + 1;
        final int? correta = i < c.gabarito.length
            ? c.gabarito[i]
            : v.gabaritoRemapeado[qid];
        if (correta != null && slot == correta) {
          acertos[qid] = acertos[qid]! + 1;
        }
      }
    }
    final List<DesempenhoQuestao> questoes = <DesempenhoQuestao>[
      for (int i = 0; i < prova.questaoIds.length; i++)
        DesempenhoQuestao(
          numero: i + 1,
          questaoId: prova.questaoIds[i],
          respostas: respondidas[prova.questaoIds[i]]!,
          acertos: acertos[prova.questaoIds[i]]!,
          marcacoes: marcacoes[prova.questaoIds[i]]!,
        ),
    ];

    return RelatorioProva._(
      prova: prova,
      alunos: situacoes,
      questoes: questoes,
    );
  }

  final Prova prova;
  final List<SituacaoAluno> alunos;
  final List<DesempenhoQuestao> questoes;

  List<Correcao> get correcoes => <Correcao>[
        for (final SituacaoAluno s in alunos)
          if (s.correcao != null) s.correcao!,
      ];

  int get totalAlunos => alunos.length;
  int get corrigidos => correcoes.length;
  int get pendentes => totalAlunos - corrigidos;

  StatusProva get status {
    if (prova.correcaoEncerrada || (totalAlunos > 0 && pendentes == 0)) {
      return StatusProva.finalizada;
    }
    return corrigidos == 0
        ? StatusProva.aguardandoCorrecao
        : StatusProva.emCorrecao;
  }

  /// Encerrada pelo professor com alunos sem nota (ausentes).
  bool get temAusentes => prova.correcaoEncerrada && pendentes > 0;

  double? get media {
    final List<Correcao> cs = correcoes;
    if (cs.isEmpty) {
      return null;
    }
    return cs.map((Correcao c) => c.nota).reduce((double a, double b) => a + b) /
        cs.length;
  }

  double? get maiorNota => correcoes.isEmpty
      ? null
      : correcoes.map((Correcao c) => c.nota).reduce((double a, double b) =>
          a > b ? a : b);

  double? get menorNota => correcoes.isEmpty
      ? null
      : correcoes.map((Correcao c) => c.nota).reduce((double a, double b) =>
          a < b ? a : b);

  /// Alunos com nota maior ou igual a [minima] (padrão 6,0).
  int aprovados([double minima = 6]) =>
      correcoes.where((Correcao c) => c.nota >= minima).length;
}
