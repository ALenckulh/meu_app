import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String nome = ref.watch(authSessionProvider)?.nome ?? 'Professor';
    final ColorScheme colors = Theme.of(context).colorScheme;

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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: <Widget>[
          Text(
            'Olá, $nome',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fluxo N1: turmas → questões → provas → correção → resultados',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _ShortcutCard(
                keyName: 'card-turmas',
                icon: Icons.groups,
                label: 'Turmas',
                onTap: () => context.go('/turmas'),
              ),
              _ShortcutCard(
                keyName: 'card-questoes',
                icon: Icons.quiz,
                label: 'Questões',
                onTap: () => context.go('/questoes'),
              ),
              _ShortcutCard(
                keyName: 'card-provas',
                icon: Icons.assignment,
                label: 'Provas',
                onTap: () => context.go('/provas'),
              ),
              _ShortcutCard(
                keyName: 'card-correcao',
                icon: Icons.camera_alt,
                label: 'Corrigir',
                onTap: () => context.go('/mais/correcao'),
              ),
              _ShortcutCard(
                keyName: 'card-resultados',
                icon: Icons.bar_chart,
                label: 'Resultados',
                onTap: () => context.go('/mais/resultados'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Resumo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Material(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            elevation: 1.5,
            shadowColor: colors.shadow.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline, color: colors.onSecondaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          '2 turmas · 8 questões · 1 prova',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dados em memória — sem banco real (N1).',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 150,
      child: Material(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        elevation: 1.5,
        shadowColor: colors.shadow.withValues(alpha: 0.15),
        child: InkWell(
          key: Key(keyName),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colors.onPrimaryContainer, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}