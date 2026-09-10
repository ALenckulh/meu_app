import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/professor.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/turma.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

/// Store em memória para N1. // N2: substituir por Firestore.
class AppMockStore {
  AppMockStore._() {
    _seed();
  }

  static final AppMockStore instance = AppMockStore._();

  final List<Professor> professores = <Professor>[];
  final List<Turma> turmas = <Turma>[];
  final List<Aluno> alunos = <Aluno>[];
  final List<Questao> questoes = <Questao>[];
  final List<Prova> provas = <Prova>[];
  final List<VariacaoDeProva> variacoes = <VariacaoDeProva>[];
  final List<Correcao> correcoes = <Correcao>[];

  Professor? sessaoAtual;

  void _seed() {
    const professor = Professor(
      id: 'prof-1',
      nome: 'Ana Paula',
      email: 'ana@escola.com',
      senha: '123456',
    );
    professores.add(professor);

    const turma1 = Turma(
      id: 'turma-1',
      professorId: 'prof-1',
      nome: '3º Ano A',
      disciplina: 'Matemática',
      ano: 2026,
    );
    const turma2 = Turma(
      id: 'turma-2',
      professorId: 'prof-1',
      nome: '2º Ano B',
      disciplina: 'Física',
      ano: 2026,
    );
    turmas.addAll(<Turma>[turma1, turma2]);

    alunos.addAll(const <Aluno>[
      Aluno(id: 'aluno-1', turmaId: 'turma-1', nome: 'João Silva', matricula: '2026001'),
      Aluno(id: 'aluno-2', turmaId: 'turma-1', nome: 'Maria Souza', matricula: '2026002'),
      Aluno(id: 'aluno-3', turmaId: 'turma-1', nome: 'Pedro Lima', matricula: '2026003'),
      Aluno(id: 'aluno-4', turmaId: 'turma-2', nome: 'Carla Dias', matricula: '2026004'),
      Aluno(id: 'aluno-5', turmaId: 'turma-2', nome: 'Lucas Alves', matricula: '2026005'),
    ]);

    questoes.addAll(const <Questao>[
      Questao(
        id: 'q1',
        enunciado: 'Qual é o resultado de 2 + 2?',
        alternativas: <String>['3', '4', '5', '6'],
        gabaritoIndex: 1,
        tags: <String>['matemática', 'básico'],
      ),
      Questao(
        id: 'q2',
        enunciado: 'Qual é a raiz quadrada de 9?',
        alternativas: <String>['2', '3', '4', '9'],
        gabaritoIndex: 1,
        tags: <String>['matemática'],
      ),
      Questao(
        id: 'q3',
        enunciado: 'Quanto é 5 × 6?',
        alternativas: <String>['25', '30', '35', '40'],
        gabaritoIndex: 1,
        tags: <String>['matemática'],
      ),
      Questao(
        id: 'q4',
        enunciado: 'Qual unidade mede velocidade?',
        alternativas: <String>['kg', 'm/s', 'N', 'J'],
        gabaritoIndex: 1,
        tags: <String>['física'],
      ),
      Questao(
        id: 'q5',
        enunciado: 'Qual é a aceleração da gravidade aproximada?',
        alternativas: <String>['5 m/s²', '9,8 m/s²', '15 m/s²', '20 m/s²'],
        gabaritoIndex: 1,
        tags: <String>['física'],
      ),
      Questao(
        id: 'q6',
        enunciado: 'Quanto é 10% de 200?',
        alternativas: <String>['10', '20', '30', '40'],
        gabaritoIndex: 1,
        tags: <String>['matemática'],
      ),
      Questao(
        id: 'q7',
        enunciado: 'Qual é o oposto de +5?',
        alternativas: <String>['+5', '-5', '0', '1/5'],
        gabaritoIndex: 1,
        tags: <String>['matemática'],
      ),
      Questao(
        id: 'q8',
        enunciado: 'Energia cinética depende principalmente de:',
        alternativas: <String>['cor', 'massa e velocidade', 'temperatura', 'volume'],
        gabaritoIndex: 1,
        tags: <String>['física'],
      ),
    ]);

    provas.add(
      const Prova(
        id: 'prova-1',
        titulo: 'Prova Diagnóstica 1',
        questaoIds: <String>['q1', 'q2', 'q3', 'q6'],
        quantidadeVariacoes: 2,
      ),
    );

    variacoes.add(
      const VariacaoDeProva(
        id: 'var-1',
        provaId: 'prova-1',
        alunoId: 'aluno-1',
        ordemQuestoes: <String>['q1', 'q2', 'q3', 'q6'],
        ordemAlternativas: <String, List<int>>{
          'q1': <int>[0, 1, 2, 3],
          'q2': <int>[0, 1, 2, 3],
          'q3': <int>[0, 1, 2, 3],
          'q6': <int>[0, 1, 2, 3],
        },
        gabaritoRemapeado: <String, int>{
          'q1': 1,
          'q2': 1,
          'q3': 1,
          'q6': 1,
        },
      ),
    );

    correcoes.add(
      const Correcao(
        id: 'corr-1',
        variacaoId: 'var-1',
        alunoId: 'aluno-1',
        respostas: <int>[1, 1, 0, 1],
        nota: 7.5,
        acertos: 3,
        totalQuestoes: 4,
      ),
    );
    correcoes.add(
      const Correcao(
        id: 'corr-2',
        variacaoId: 'var-1',
        alunoId: 'aluno-2',
        respostas: <int>[1, 1, 1, 1],
        nota: 10.0,
        acertos: 4,
        totalQuestoes: 4,
      ),
    );
    correcoes.add(
      const Correcao(
        id: 'corr-3',
        variacaoId: 'var-1',
        alunoId: 'aluno-3',
        respostas: <int>[0, 1, 0, 0],
        nota: 2.5,
        acertos: 1,
        totalQuestoes: 4,
      ),
    );
  }
}
