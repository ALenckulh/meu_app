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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Prévia da prova')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                // Cabeçalho da prova
                Card(
                  elevation: 0,
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _prova?.titulo ?? '',
                          style: text.headlineSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.help_outline,
                              size: 16,
                              color: scheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_questoes.length} questões · Visualização antes da impressão (mock N1)',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Lista de questões
                ...List<Widget>.generate(_questoes.length, (int index) {
                  final Questao q = _questoes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: scheme.secondaryContainer,
                                child: Text(
                                  '${index + 1}',
                                  style: text.labelLarge?.copyWith(
                                    color: scheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  q.enunciado,
                                  style: text.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List<Widget>.generate(4, (int i) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 40,
                                bottom: 6,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: scheme.outline,
                                      ),
                                    ),
                                    child: Text(
                                      labels[i],
                                      style: text.labelSmall,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      q.alternativas[i],
                                      style: text.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('btn-folha-respostas'),
                  onPressed: () =>
                      context.push('/provas/${widget.provaId}/folha'),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Prévia da folha de respostas'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('btn-individualizacao'),
                  onPressed: () => context
                      .push('/provas/${widget.provaId}/individualizacao'),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Individualização por aluno'),
                ),
              ],
            ),
    );
  }
}
