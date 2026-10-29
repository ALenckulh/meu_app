import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/brand_header.dart';
import 'package:meu_app/core/widgets/section_header.dart';

/// Totais do professor logado, para o resumo do início.
typedef _Resumo = ({int turmas, int questoes, int provas, int correcoes});

final _resumoProvider = FutureProvider.autoDispose<_Resumo>((Ref ref) async {
  ref.watch(listVersionProvider);
  final String? professorId = ref.watch(authSessionProvider)?.id;
  if (professorId == null) {
    return (turmas: 0, questoes: 0, provas: 0, correcoes: 0);
  }
  final List<int> totais = await Future.wait(<Future<int>>[
    ref
        .read(turmaRepositoryProvider)
        .listByProfessor(professorId)
        .then((List<dynamic> l) => l.length),
    ref.read(questaoRepositoryProvider).listAll().then((l) => l.length),
    ref.read(provaRepositoryProvider).listAll().then((l) => l.length),
    ref.read(correcaoRepositoryProvider).listAll().then((l) => l.length),
  ]);
  return (
    turmas: totais[0],
    questoes: totais[1],
    provas: totais[2],
    correcoes: totais[3],
  );
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String nome = ref.watch(authSessionProvider)?.nome ?? 'Professor';
    final AsyncValue<_Resumo> resumo = ref.watch(_resumoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: <Widget>[
          Tooltip(
            message: 'Sair',
            child: IconButton(
              key: const Key('btn-logout'),
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(authSessionProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          BrandHeader(
            icon: Icons.waving_hand_outlined,
            titulo: 'Olá, $nome',
            subtitulo: 'Turmas → questões → prova → imprimir → corrigir.',
            child: resumo.when(
              data: (_Resumo r) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _Numero(valor: r.turmas, rotulo: 'turmas'),
                  _Numero(valor: r.questoes, rotulo: 'questões'),
                  _Numero(valor: r.provas, rotulo: 'provas'),
                  _Numero(valor: r.correcoes, rotulo: 'correções'),
                ],
              ),
              loading: () => const SizedBox(height: 44),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          const SectionHeader('Acesso rápido'),
          GridView.extent(
            maxCrossAxisExtent: 180,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: <Widget>[
              _ShortcutCard(
                keyName: 'card-turmas',
                icon: Icons.groups_outlined,
                label: 'Turmas',
                onTap: () => context.go('/turmas'),
              ),
              _ShortcutCard(
                keyName: 'card-questoes',
                icon: Icons.quiz_outlined,
                label: 'Questões',
                onTap: () => context.go('/questoes'),
              ),
              _ShortcutCard(
                keyName: 'card-provas',
                icon: Icons.assignment_outlined,
                label: 'Provas',
                onTap: () => context.go('/provas'),
              ),
              _ShortcutCard(
                keyName: 'card-correcao',
                icon: Icons.camera_alt_outlined,
                label: 'Corrigir',
                onTap: () => context.go('/mais/correcao'),
              ),
              _ShortcutCard(
                keyName: 'card-resultados',
                icon: Icons.bar_chart_outlined,
                label: 'Resultados',
                onTap: () => context.push('/mais/resultados'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.valor, required this.rotulo});

  final int valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$valor ',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: rotulo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Card(
      child: InkWell(
        key: Key(keyName),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.primary, size: 24),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(label, style: theme.textTheme.titleSmall),
                  ),
                  Icon(Icons.arrow_forward, size: 18, color: colors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
