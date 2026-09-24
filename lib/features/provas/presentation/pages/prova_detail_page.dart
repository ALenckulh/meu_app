import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/info_card.dart';
import 'package:meu_app/core/widgets/section_header.dart';
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
        final bool loading =
            snapshot.connectionState == ConnectionState.waiting;

        return Scaffold(
          appBar: AppBar(title: Text(prova?.titulo ?? 'Prova')),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: <Widget>[
                    InfoCard(
                      icon: Icons.assignment_outlined,
                      title: prova?.titulo ?? 'Prova',
                      subtitle:
                          '${prova?.questaoIds.length ?? 0} questões · ${prova?.quantidadeVariacoes ?? 0} variações',
                    ),
                    const SectionHeader('Montagem'),
                    NavCard(
                      key: const Key('item-ordenar-questoes'),
                      icon: Icons.reorder,
                      title: 'Questões e ordem',
                      subtitle: 'Selecione e ordene as questões da prova',
                      onTap: () => context.push('/provas/$provaId/questoes'),
                    ),
                    const SizedBox(height: 12),
                    NavCard(
                      key: const Key('item-variacoes'),
                      icon: Icons.shuffle,
                      title: 'Variações / embaralhamento',
                      subtitle: 'Gere versões com questões e alternativas trocadas',
                      onTap: () => context.push('/provas/$provaId/variacoes'),
                    ),
                    const SectionHeader('Saída'),
                    NavCard(
                      key: const Key('item-gerar'),
                      icon: Icons.print_outlined,
                      title: 'Gerar / prévia de impressão',
                      subtitle: 'Veja a prova como será impressa',
                      onTap: () => context.push('/provas/$provaId/gerar'),
                    ),
                    const SizedBox(height: 12),
                    NavCard(
                      key: const Key('item-folha'),
                      icon: Icons.grid_on_outlined,
                      title: 'Folha de respostas',
                      subtitle: 'Cartão-resposta com QR Code',
                      onTap: () => context.push('/provas/$provaId/folha'),
                    ),
                    const SizedBox(height: 12),
                    NavCard(
                      key: const Key('item-individual'),
                      icon: Icons.person_outline,
                      title: 'Individualização',
                      subtitle: 'Prévia por aluno',
                      onTap: () =>
                          context.push('/provas/$provaId/individualizacao'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
