import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/features/alunos/domain/repositories/aluno_repository.dart';
import 'package:meu_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/features/correcao/domain/calculo_nota.dart';
import 'package:meu_app/features/correcao/domain/repositories/correcao_repository.dart';
import 'package:meu_app/features/correcao/presentation/pages/corrigir_prova_page.dart';
import 'package:meu_app/features/geracao/domain/qr_payload.dart';
import 'package:meu_app/features/provas/domain/repositories/prova_repository.dart';
import 'package:meu_app/features/questoes/domain/repositories/questao_repository.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/professor.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

// Repositórios em memória: a tela roda inteira sem Firebase.

class _Auth implements AuthRepository {
  @override
  Professor? get currentUser =>
      const Professor(id: 'prof', nome: 'Prof', email: 'p@x.com', senha: '');
  @override
  Future<Professor?> login(String email, String senha) async => currentUser;
  @override
  Future<Professor> register({
    required String nome,
    required String email,
    required String senha,
  }) async =>
      currentUser!;
  @override
  Future<void> logout() async {}
}

const List<Questao> _banco = <Questao>[
  Questao(
    id: 'q1',
    professorId: 'prof',
    enunciado: 'Quanto é 2 + 2?',
    alternativas: <String>['3', '4', '5', '6'],
    gabaritoIndex: 1,
  ),
  Questao(
    id: 'q2',
    professorId: 'prof',
    enunciado: 'Capital do Brasil?',
    alternativas: <String>['Rio', 'SP', 'Salvador', 'Brasília'],
    gabaritoIndex: 3,
  ),
];

class _Questoes implements QuestaoRepository {
  @override
  Future<List<Questao>> listAll({String? query}) async => _banco;
  @override
  Future<Questao?> getById(String id) async =>
      _banco.where((Questao q) => q.id == id).firstOrNull;
  @override
  Future<Questao> create(Questao questao) async => questao;
  @override
  Future<Questao> update(Questao questao) async => questao;
  @override
  Future<void> delete(String id) async {}
}

class _Alunos implements AlunoRepository {
  static const List<Aluno> todos = <Aluno>[
    Aluno(id: 'a1', turmaId: 't1', nome: 'Ana Souza', matricula: '101'),
    Aluno(id: 'a2', turmaId: 't1', nome: 'Bruno Lima', matricula: '102'),
  ];
  @override
  Future<List<Aluno>> listByTurma(String turmaId) async =>
      todos.where((Aluno a) => a.turmaId == turmaId).toList();
  @override
  Future<Aluno?> getById(String id) async =>
      todos.where((Aluno a) => a.id == id).firstOrNull;
  @override
  Future<Aluno> create(Aluno aluno) async => aluno;
  @override
  Future<Aluno> update(Aluno aluno) async => aluno;
  @override
  Future<void> delete(String id) async {}
}

class _Provas implements ProvaRepository {
  final Prova prova = const Prova(
    id: 'p1',
    professorId: 'prof',
    titulo: 'Avaliação de teste',
    questaoIds: <String>['q1', 'q2'],
    turmaId: 't1',
  );
  final List<VariacaoDeProva> variacoes = <VariacaoDeProva>[];

  @override
  Future<List<Prova>> listAll() async => <Prova>[prova];
  @override
  Future<Prova?> getById(String id) async => id == prova.id ? prova : null;
  @override
  Future<Prova> create(Prova p) async => p;
  @override
  Future<Prova> update(Prova p) async => p;
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> deleteVariacoes(String provaId) async => variacoes.clear();
  @override
  Future<List<VariacaoDeProva>> listVariacoes(String provaId) async =>
      variacoes.where((VariacaoDeProva v) => v.provaId == provaId).toList();
  @override
  Future<VariacaoDeProva?> getVariacaoById(String id) async =>
      variacoes.where((VariacaoDeProva v) => v.id == id).firstOrNull;
  @override
  Future<VariacaoDeProva> gerarVariacao({
    required String provaId,
    required String alunoId,
    required bool embaralharQuestoes,
    required bool embaralharAlternativas,
  }) async {
    variacoes.removeWhere((VariacaoDeProva v) => v.alunoId == alunoId);
    final VariacaoDeProva v = VariacaoDeProva(
      id: 'v-$alunoId',
      provaId: provaId,
      alunoId: alunoId,
      ordemQuestoes: prova.questaoIds,
      ordemAlternativas: <String, List<int>>{
        for (final String id in prova.questaoIds) id: <int>[0, 1, 2, 3],
      },
      gabaritoRemapeado: <String, int>{
        for (final Questao q in _banco) q.id: q.gabaritoIndex,
      },
    );
    variacoes.add(v);
    return v;
  }

  @override
  Future<VariacaoDeProva> variacaoFolhaGeral({
    required String provaId,
    required String alunoId,
  }) async {
    for (final VariacaoDeProva v in variacoes) {
      if (v.alunoId == alunoId && v.emOrdemOriginal(prova)) {
        return v;
      }
    }
    return gerarVariacao(
      provaId: provaId,
      alunoId: alunoId,
      embaralharQuestoes: false,
      embaralharAlternativas: false,
    );
  }
}

class _Correcoes implements CorrecaoRepository {
  _Correcoes(this.provas);

  final _Provas provas;
  final List<Correcao> salvas = <Correcao>[];

  @override
  Future<List<Correcao>> listAll() async => salvas;
  @override
  Future<Correcao?> getById(String id) async =>
      salvas.where((Correcao c) => c.id == id).firstOrNull;
  @override
  Future<Correcao?> getByVariacao(String variacaoId) async =>
      salvas.where((Correcao c) => c.variacaoId == variacaoId).firstOrNull;
  @override
  Future<Correcao> corrigir({
    required String variacaoId,
    required String alunoId,
    required String professorId,
    required List<int> respostas,
  }) async {
    final VariacaoDeProva v = (await provas.getVariacaoById(variacaoId))!;
    final List<int> gabarito = <int>[
      for (final String q in v.ordemQuestoes) v.gabaritoRemapeado[q]!,
    ];
    final ResultadoNota r = calcularNota(respostas, gabarito);
    final Correcao c = Correcao(
      id: 'c-$alunoId',
      professorId: professorId,
      variacaoId: variacaoId,
      alunoId: alunoId,
      provaId: v.provaId,
      respostas: respostas,
      gabarito: gabarito,
      nota: r.nota,
      acertos: r.acertos,
      totalQuestoes: r.total,
    );
    salvas
      ..removeWhere((Correcao x) => x.alunoId == alunoId)
      ..add(c);
    return c;
  }
}

void main() {
  testWidgets(
      'folha geral: lê o código, escolhe o aluno, marca e salva a nota',
      (WidgetTester tester) async {
    // Sem câmera no teste: a tela usa "Digitar código".
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final _Provas provas = _Provas();
    final _Correcoes correcoes = _Correcoes(provas);

    final GoRouter router = GoRouter(
      initialLocation: '/mais/correcao',
      routes: <RouteBase>[
        GoRoute(
          path: '/mais/correcao',
          builder: (_, _) => const CorrigirProvaPage(),
          routes: <RouteBase>[
            GoRoute(
              path: 'resultado/:id',
              builder: (_, GoRouterState s) =>
                  Scaffold(body: Text('resultado ${s.pathParameters['id']}')),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_Auth()),
          provaRepositoryProvider.overrideWithValue(provas),
          correcaoRepositoryProvider.overrideWithValue(correcoes),
          alunoRepositoryProvider.overrideWithValue(_Alunos()),
          questaoRepositoryProvider.overrideWithValue(_Questoes()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Código do QR da folha geral (só a prova).
    await tester.tap(find.byKey(const Key('btn-digitar-codigo')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input-codigo-qr')),
      const QrPayload(provaId: 'p1').encode(),
    );
    await tester.tap(find.text('Identificar'));
    await tester.pumpAndSettle();

    // 2. Escolhe o aluno da turma.
    expect(find.text('Folha geral lida'), findsOneWidget);
    await tester.tap(find.byKey(const Key('escolher-aluno-a2')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bruno Lima'), findsOneWidget);

    // Botão só libera com todas as questões marcadas.
    final Finder salvar = find.byKey(const Key('btn-corrigir-folha'));
    expect(tester.widget<FilledButton>(salvar).onPressed, isNull);

    // 3. Marca B (certa) na 1 e A (errada) na 2.
    await tester.tap(find.byKey(const Key('chip-q0-alt1')));
    await tester.tap(find.byKey(const Key('chip-q1-alt0')));
    await tester.pump();
    expect(find.text('Todas as 2 questões marcadas.'), findsOneWidget);

    await tester.tap(salvar);
    await tester.pumpAndSettle();

    // 4. Nota salva e tela de resultado aberta.
    expect(correcoes.salvas, hasLength(1));
    expect(correcoes.salvas.single.alunoId, 'a2');
    expect(correcoes.salvas.single.nota, 5.0);
    expect(correcoes.salvas.single.provaId, 'p1');
    expect(find.text('resultado c-a2'), findsOneWidget);

    debugDefaultTargetPlatformOverride = null;
  });
}
