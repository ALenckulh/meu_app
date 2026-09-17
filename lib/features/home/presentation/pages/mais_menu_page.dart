import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MaisMenuPage extends StatelessWidget {
  const MaisMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _MaisMenuTile(
            keyName: 'item-correcao',
            icon: Icons.camera_alt,
            title: 'Corrigir prova',
            subtitle: 'Simular leitura de QR e respostas',
            onTap: () => context.push('/mais/correcao'),
          ),
          const SizedBox(height: 10),
          _MaisMenuTile(
            keyName: 'item-resultados',
            icon: Icons.bar_chart,
            title: 'Resultados',
            subtitle: 'Notas e estatísticas mockadas',
            onTap: () => context.push('/mais/resultados'),
          ),
          const SizedBox(height: 10),
          _MaisMenuTile(
            keyName: 'item-estatisticas',
            icon: Icons.analytics,
            title: 'Estatísticas',
            subtitle: 'Gráfico de desempenho',
            onTap: () => context.push('/mais/estatisticas'),
          ),
        ],
      ),
    );
  }
}

class _MaisMenuTile extends StatelessWidget {
  const _MaisMenuTile({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      elevation: 1.5,
      shadowColor: colors.shadow.withValues(alpha: 0.15),
      child: InkWell(
        key: Key(keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.onTertiaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}