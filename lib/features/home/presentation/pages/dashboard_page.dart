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
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Olá, $nome',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Fluxo N1: turmas → questões → provas → correção → resultados',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 24),
          Text('Resumo (mock)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.info, color: colors.secondary),
            title: const Text('2 turmas · 8 questões · 1 prova'),
            subtitle: const Text('Dados em memória — sem banco real (N1).'),
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key(keyName),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Icon(icon, color: colors.primary, size: 32),
                const SizedBox(height: 8),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
