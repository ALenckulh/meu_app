import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/shared/models/prova.dart';

class ProvaDetailPage extends ConsumerWidget {
  const ProvaDetailPage({super.key, required this.provaId});

  final String provaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Prova?>(
      future: ref.read(provaRepositoryProvider).getById(provaId),
      builder: (BuildContext context, AsyncSnapshot<Prova?> snapshot) {
        final Prova? prova = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(prova?.titulo ?? 'Prova')),
          body: ListView(
            children: <Widget>[
              ListTile(
                key: const Key('item-ordenar-questoes'),
                leading: const Icon(Icons.reorder),
                title: const Text('Questões e ordem'),
                onTap: () => context.push('/provas/$provaId/questoes'),
              ),
              ListTile(
                key: const Key('item-variacoes'),
                leading: const Icon(Icons.shuffle),
                title: const Text('Variações / embaralhamento'),
                onTap: () => context.push('/provas/$provaId/variacoes'),
              ),
              ListTile(
                key: const Key('item-gerar'),
                leading: const Icon(Icons.print),
                title: const Text('Gerar / prévia de impressão'),
                onTap: () => context.push('/provas/$provaId/gerar'),
              ),
              ListTile(
                key: const Key('item-folha'),
                leading: const Icon(Icons.grid_on),
                title: const Text('Folha de respostas'),
                onTap: () => context.push('/provas/$provaId/folha'),
              ),
              ListTile(
                key: const Key('item-individual'),
                leading: const Icon(Icons.person),
                title: const Text('Individualização'),
                onTap: () => context.push('/provas/$provaId/individualizacao'),
              ),
            ],
          ),
        );
      },
    );
  }
}
