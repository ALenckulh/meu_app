import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/features/correcao/domain/calculo_nota.dart';
import 'package:meu_app/features/resultados/domain/relatorio_prova.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

const Prova _prova = Prova(
  id: 'p1',
  professorId: 'prof',
  titulo: 'Prova 1',
  questaoIds: <String>['q1', 'q2'],
  turmaId: 't1',
);

const List<Aluno> _alunos = <Aluno>[
  Aluno(id: 'a1', turmaId: 't1', nome: 'Bruna', matricula: '1'),
  Aluno(id: 'a2', turmaId: 't1', nome: 'Ana', matricula: '2'),
];

/// Variação embaralhada: q2 vem primeiro e as alternativas de q2 estão
/// invertidas (posição 0 = alternativa original 3).
const VariacaoDeProva _embaralhada = VariacaoDeProva(
  id: 'v1',
  provaId: 'p1',
  alunoId: 'a1',
  ordemQuestoes: <String>['q2', 'q1'],
  ordemAlternativas: <String, List<int>>{
    'q1': <int>[0, 1, 2, 3],
    'q2': <int>[3, 2, 1, 0],
  },
  gabaritoRemapeado: <String, int>{'q1': 1, 'q2': 0},
);

const VariacaoDeProva _original = VariacaoDeProva(
  id: 'v2',
  provaId: 'p1',
  alunoId: 'a2',
  ordemQuestoes: <String>['q1', 'q2'],
  ordemAlternativas: <String, List<int>>{
    'q1': <int>[0, 1, 2, 3],
    'q2': <int>[0, 1, 2, 3],
  },
  gabaritoRemapeado: <String, int>{'q1': 1, 'q2': 3},
);

Correcao _correcao({
  required String id,
  required String alunoId,
  required String variacaoId,
  required List<int> respostas,
  required List<int> gabarito,
  String provaId = 'p1',
}) {
  final ResultadoNota r = calcularNota(respostas, gabarito);
  return Correcao(
    id: id,
    professorId: 'prof',
    variacaoId: variacaoId,
    alunoId: alunoId,
    provaId: provaId,
    respostas: respostas,
    gabarito: gabarito,
    nota: r.nota,
    acertos: r.acertos,
    totalQuestoes: r.total,
  );
}

void main() {
  group('calcularNota', () {
    test('nota proporcional aos acertos, de 0 a 10', () {
      final ResultadoNota r =
          calcularNota(<int>[0, 1, 2, 3], <int>[0, 1, 0, 0]);
      expect(r.acertos, 2);
      expect(r.total, 4);
      expect(r.nota, 5.0);
    });

    test('arredonda para uma casa decimal', () {
      expect(calcularNota(<int>[0, 0, 1], <int>[0, 1, 0]).nota, 3.3);
    });

    test('recusa quantidade diferente de questões', () {
      expect(() => calcularNota(<int>[0], <int>[0, 1]), throwsArgumentError);
    });

    test('recusa alternativa fora de A–D', () {
      expect(() => calcularNota(<int>[4], <int>[0]), throwsArgumentError);
    });
  });

  group('VariacaoDeProva.emOrdemOriginal', () {
    test('reconhece a ordem da folha geral', () {
      expect(_original.emOrdemOriginal(_prova), isTrue);
    });

    test('variação embaralhada não está na ordem original', () {
      expect(_embaralhada.emOrdemOriginal(_prova), isFalse);
    });
  });

  group('RelatorioProva', () {
    test('sem correções: aguardando correção, todos pendentes', () {
      final RelatorioProva r = RelatorioProva.montar(
        prova: _prova,
        alunosDaTurma: _alunos,
        correcoes: <Correcao>[],
        variacoes: <VariacaoDeProva>[_embaralhada, _original],
      );
      expect(r.status, StatusProva.aguardandoCorrecao);
      expect(r.pendentes, 2);
      expect(r.media, isNull);
      // Ordenado por nome.
      expect(r.alunos.first.aluno.nome, 'Ana');
    });

    test('parte corrigida: em correção', () {
      final RelatorioProva r = RelatorioProva.montar(
        prova: _prova,
        alunosDaTurma: _alunos,
        correcoes: <Correcao>[
          _correcao(
            id: 'c1',
            alunoId: 'a1',
            variacaoId: 'v1',
            respostas: <int>[0, 1],
            gabarito: <int>[0, 1],
          ),
        ],
        variacoes: <VariacaoDeProva>[_embaralhada, _original],
      );
      expect(r.status, StatusProva.emCorrecao);
      expect(r.corrigidos, 1);
      expect(r.pendentes, 1);
    });

    test('todos corrigidos: finalizada, com médias e estatística por questão',
        () {
      final RelatorioProva r = RelatorioProva.montar(
        prova: _prova,
        alunosDaTurma: _alunos,
        correcoes: <Correcao>[
          // a1 acertou as duas (folha embaralhada).
          _correcao(
            id: 'c1',
            alunoId: 'a1',
            variacaoId: 'v1',
            respostas: <int>[0, 1],
            gabarito: <int>[0, 1],
          ),
          // a2 acertou q1 e marcou C (original 2) em q2, que era D.
          _correcao(
            id: 'c2',
            alunoId: 'a2',
            variacaoId: 'v2',
            respostas: <int>[1, 2],
            gabarito: <int>[1, 3],
          ),
          // Correção de outra prova não entra.
          _correcao(
            id: 'c3',
            alunoId: 'a2',
            variacaoId: 'x',
            provaId: 'outra',
            respostas: <int>[0],
            gabarito: <int>[1],
          ),
        ],
        variacoes: <VariacaoDeProva>[_embaralhada, _original],
      );
      expect(r.status, StatusProva.finalizada);
      expect(r.media, 7.5);
      expect(r.maiorNota, 10.0);
      expect(r.menorNota, 5.0);
      expect(r.aprovados(), 1);

      final DesempenhoQuestao q1 = r.questoes[0];
      expect(q1.questaoId, 'q1');
      expect(q1.acertos, 2);
      expect(q1.percentualAcerto, 1.0);

      final DesempenhoQuestao q2 = r.questoes[1];
      expect(q2.questaoId, 'q2');
      expect(q2.respostas, 2);
      expect(q2.acertos, 1);
      // a1 marcou a posição 0 da folha embaralhada = alternativa original 3.
      expect(q2.marcacoes, <int>[0, 0, 1, 1]);
    });
  });

  test('correção encerrada pelo professor: finalizada com ausentes', () {
    final RelatorioProva r = RelatorioProva.montar(
      prova: _prova.copyWith(correcaoEncerrada: true),
      alunosDaTurma: _alunos,
      correcoes: <Correcao>[
        _correcao(
          id: 'c1',
          alunoId: 'a1',
          variacaoId: 'v1',
          respostas: <int>[0, 1],
          gabarito: <int>[0, 1],
        ),
      ],
      variacoes: <VariacaoDeProva>[_embaralhada, _original],
    );
    expect(r.status, StatusProva.finalizada);
    expect(r.temAusentes, isTrue);
    expect(r.pendentes, 1);
  });

  group('Modelos', () {
    test('Prova guarda a configuração de embaralhamento', () {
      final Prova p = Prova.fromMap(
        'p1',
        _prova
            .copyWith(embaralharQuestoes: false, embaralharAlternativas: true)
            .toMap(),
      );
      expect(p.embaralharQuestoes, isFalse);
      expect(p.embaralharAlternativas, isTrue);
    });

    test('Prova antiga (sem o campo) embaralha por padrão', () {
      final Prova p = Prova.fromMap('p1', <String, dynamic>{'titulo': 'x'});
      expect(p.embaralharQuestoes, isTrue);
      expect(p.embaralharAlternativas, isTrue);
    });

    test('Correcao guarda prova e data da correção', () {
      final DateTime quando = DateTime(2026, 11, 25, 14, 30);
      final Correcao c = Correcao.fromMap(
        'c1',
        Correcao(
          id: 'c1',
          professorId: 'prof',
          variacaoId: 'v1',
          alunoId: 'a1',
          provaId: 'p1',
          respostas: const <int>[0],
          nota: 10,
          acertos: 1,
          totalQuestoes: 1,
          corrigidaEm: quando,
        ).toMap(),
      );
      expect(c.provaId, 'p1');
      expect(c.corrigidaEm, quando);
    });
  });
}
