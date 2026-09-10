import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MaisMenuPage extends StatelessWidget {
  const MaisMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        children: <Widget>[
          ListTile(
            key: const Key('item-correcao'),
            leading: const Icon(Icons.camera_alt),
            title: const Text('Corrigir prova'),
            subtitle: const Text('Simular leitura de QR e respostas'),
            onTap: () => context.push('/mais/correcao'),
          ),
          ListTile(
            key: const Key('item-resultados'),
            leading: const Icon(Icons.bar_chart),
            title: const Text('Resultados'),
            subtitle: const Text('Notas e estatísticas mockadas'),
            onTap: () => context.push('/mais/resultados'),
          ),
          ListTile(
            key: const Key('item-estatisticas'),
            leading: const Icon(Icons.analytics),
            title: const Text('Estatísticas'),
            subtitle: const Text('Gráfico de desempenho'),
            onTap: () => context.push('/mais/estatisticas'),
          ),
        ],
      ),
    );
  }
}
