import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/router/app_shell.dart';
import 'package:meu_app/features/alunos/presentation/pages/aluno_form_page.dart';
import 'package:meu_app/features/alunos/presentation/pages/importar_alunos_page.dart';
import 'package:meu_app/features/auth/presentation/pages/cadastro_page.dart';
import 'package:meu_app/features/auth/presentation/pages/login_page.dart';
import 'package:meu_app/features/correcao/presentation/pages/correcao_resultado_page.dart';
import 'package:meu_app/features/correcao/presentation/pages/corrigir_prova_page.dart';
import 'package:meu_app/features/geracao/presentation/pages/folha_respostas_page.dart';
import 'package:meu_app/features/geracao/presentation/pages/gerar_prova_page.dart';
import 'package:meu_app/features/geracao/presentation/pages/individualizacao_page.dart';
import 'package:meu_app/features/home/presentation/pages/dashboard_page.dart';
import 'package:meu_app/features/home/presentation/pages/mais_menu_page.dart';
import 'package:meu_app/features/provas/presentation/pages/prova_detail_page.dart';
import 'package:meu_app/features/provas/presentation/pages/prova_form_page.dart';
import 'package:meu_app/features/provas/presentation/pages/prova_questoes_page.dart';
import 'package:meu_app/features/provas/presentation/pages/prova_variacoes_page.dart';
import 'package:meu_app/features/provas/presentation/pages/provas_list_page.dart';
import 'package:meu_app/features/provas/presentation/pages/variacao_preview_page.dart';
import 'package:meu_app/features/questoes/presentation/pages/questao_form_page.dart';
import 'package:meu_app/features/questoes/presentation/pages/questoes_list_page.dart';
import 'package:meu_app/features/resultados/presentation/pages/estatisticas_page.dart';
import 'package:meu_app/features/resultados/presentation/pages/nota_aluno_page.dart';
import 'package:meu_app/features/resultados/presentation/pages/resultados_page.dart';
import 'package:meu_app/features/turmas/presentation/pages/turma_detail_page.dart';
import 'package:meu_app/features/turmas/presentation/pages/turma_form_page.dart';
import 'package:meu_app/features/turmas/presentation/pages/turmas_list_page.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((Ref ref) {
  final ProfessorAuthListenable authListenable =
      ProfessorAuthListenable(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    refreshListenable: authListenable,
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = ref.read(authSessionProvider) != null;
      final bool onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/cadastro';
      if (!loggedIn && !onAuth) {
        return '/login';
      }
      if (loggedIn && onAuth) {
        return '/home';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(),
      ),
      GoRoute(
        path: '/cadastro',
        builder: (BuildContext context, GoRouterState state) =>
            const CadastroPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) =>
                    const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/turmas',
                builder: (BuildContext context, GoRouterState state) =>
                    const TurmasListPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'nova',
                    builder: (BuildContext context, GoRouterState state) =>
                        const TurmaFormPage(),
                  ),
                  GoRoute(
                    path: ':turmaId',
                    builder: (BuildContext context, GoRouterState state) =>
                        TurmaDetailPage(
                      turmaId: state.pathParameters['turmaId']!,
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'editar',
                        builder: (BuildContext context, GoRouterState state) =>
                            TurmaFormPage(
                          turmaId: state.pathParameters['turmaId'],
                        ),
                      ),
                      GoRoute(
                        path: 'importar',
                        builder: (BuildContext context, GoRouterState state) =>
                            ImportarAlunosPage(
                          turmaId: state.pathParameters['turmaId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'alunos/novo',
                        builder: (BuildContext context, GoRouterState state) =>
                            AlunoFormPage(
                          turmaId: state.pathParameters['turmaId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'alunos/:alunoId/editar',
                        builder: (BuildContext context, GoRouterState state) =>
                            AlunoFormPage(
                          turmaId: state.pathParameters['turmaId']!,
                          alunoId: state.pathParameters['alunoId'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/questoes',
                builder: (BuildContext context, GoRouterState state) =>
                    const QuestoesListPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'nova',
                    builder: (BuildContext context, GoRouterState state) =>
                        const QuestaoFormPage(),
                  ),
                  GoRoute(
                    path: ':questaoId/editar',
                    builder: (BuildContext context, GoRouterState state) =>
                        QuestaoFormPage(
                      questaoId: state.pathParameters['questaoId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/provas',
                builder: (BuildContext context, GoRouterState state) =>
                    const ProvasListPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'nova',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ProvaFormPage(),
                  ),
                  GoRoute(
                    path: ':provaId',
                    builder: (BuildContext context, GoRouterState state) =>
                        ProvaDetailPage(
                      provaId: state.pathParameters['provaId']!,
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'questoes',
                        builder: (BuildContext context, GoRouterState state) =>
                            ProvaQuestoesPage(
                          provaId: state.pathParameters['provaId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'variacoes',
                        builder: (BuildContext context, GoRouterState state) =>
                            ProvaVariacoesPage(
                          provaId: state.pathParameters['provaId']!,
                        ),
                        routes: <RouteBase>[
                          GoRoute(
                            path: ':variacaoId',
                            builder:
                                (BuildContext context, GoRouterState state) =>
                                    VariacaoPreviewPage(
                              provaId: state.pathParameters['provaId']!,
                              variacaoId: state.pathParameters['variacaoId']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'gerar',
                        builder: (BuildContext context, GoRouterState state) =>
                            GerarProvaPage(
                          provaId: state.pathParameters['provaId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'folha',
                        builder: (BuildContext context, GoRouterState state) =>
                            FolhaRespostasPage(
                          provaId: state.pathParameters['provaId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'individualizacao',
                        builder: (BuildContext context, GoRouterState state) =>
                            IndividualizacaoPage(
                          provaId: state.pathParameters['provaId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/mais',
                builder: (BuildContext context, GoRouterState state) =>
                    const MaisMenuPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'correcao',
                    builder: (BuildContext context, GoRouterState state) =>
                        const CorrigirProvaPage(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'resultado/:correcaoId',
                        builder: (BuildContext context, GoRouterState state) =>
                            CorrecaoResultadoPage(
                          correcaoId: state.pathParameters['correcaoId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'resultados',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ResultadosPage(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: ':alunoId',
                        builder: (BuildContext context, GoRouterState state) =>
                            NotaAlunoPage(
                          alunoId: state.pathParameters['alunoId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'estatisticas',
                    builder: (BuildContext context, GoRouterState state) =>
                        const EstatisticasPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class ProfessorAuthListenable extends ChangeNotifier {
  ProfessorAuthListenable(this._ref) {
    _ref.listen<dynamic>(authSessionProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
