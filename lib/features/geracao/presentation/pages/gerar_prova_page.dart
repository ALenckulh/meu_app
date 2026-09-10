import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';

class GerarProvaPage extends ConsumerStatefulWidget {
  const GerarProvaPage({super.key, required this.provaId});

  final String provaId;

  @override
  ConsumerState<GerarProvaPage> createState() => _GerarProvaPageState();
}

class _GerarProvaPageState extends ConsumerState<GerarProvaPage> {
  Prova? _prova;
  List<Questao> _questoes = <Questao>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Prova? prova =
        await ref.read(provaRepositoryProvider).getById(widget.provaId);
    final List<Questao> todas =
        await ref.read(questaoRepositoryProvider).listAll();
    final Map<String, Questao> map = <String, Questao>{
      for (final Questao q in todas) q.id: q,
    };
    _prova = prova;
    _questoes = (prova?.questaoIds ?? <String>[])
        .map((String id) => map[id])
        .whereType<Questao>()
        .toList();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['A', 'B', 'C', 'D'];
    return Scaffold(
      appBar: AppBar(title: const Text('Prévia da prova')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  _prova?.titulo ?? '',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Visualização antes da impressão (mock N1)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Divider(height: 32),
                ...List<Widget>.generate(_questoes.length, (int index) {
                  final Questao q = _questoes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${index + 1}. ${q.enunciado}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        ...List<Widget>.generate(
                          4,
                          (int i) => Text('${labels[i]}) ${q.alternativas[i]}'),
                        ),
                      ],
                    ),
                  );
                }),
                FilledButton(
                  key: const Key('btn-folha-respostas'),
                  onPressed: () =>
                      context.push('/provas/${widget.provaId}/folha'),
                  child: const Text('Prévia da folha de respostas'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('btn-individualizacao'),
                  onPressed: () => context
                      .push('/provas/${widget.provaId}/individualizacao'),
                  child: const Text('Individualização por aluno'),
                ),
              ],
            ),
    );
  }
}
