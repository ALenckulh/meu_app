import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';

class ProvaQuestoesPage extends ConsumerStatefulWidget {
  const ProvaQuestoesPage({super.key, required this.provaId});

  final String provaId;

  @override
  ConsumerState<ProvaQuestoesPage> createState() => _ProvaQuestoesPageState();
}

class _ProvaQuestoesPageState extends ConsumerState<ProvaQuestoesPage> {
  Prova? _prova;
  List<Questao> _ordenadas = <Questao>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Prova? prova =
        await ref.read(provaRepositoryProvider).getById(widget.provaId);
    if (prova == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }
    final List<Questao> todas =
        await ref.read(questaoRepositoryProvider).listAll();
    final Map<String, Questao> map = <String, Questao>{
      for (final Questao q in todas) q.id: q,
    };
    _prova = prova;
    _ordenadas = prova.questaoIds
        .map((String id) => map[id])
        .whereType<Questao>()
        .toList();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _salvarOrdem() async {
    if (_prova == null) {
      return;
    }
    await ref.read(provaRepositoryProvider).update(
          _prova!.copyWith(
            questaoIds: _ordenadas.map((Questao q) => q.id).toList(),
          ),
        );
    ref.read(listVersionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    showSuccessSnackBar(context, 'Ordem das questões salva.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_prova?.titulo ?? 'Questões da prova'),
        actions: <Widget>[
          Tooltip(
            message: 'Salvar ordem',
            child: IconButton(
              key: const Key('btn-salvar-ordem'),
              icon: const Icon(Icons.save),
              onPressed: _salvarOrdem,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Arraste para alterar a ordem das questões.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: _ordenadas.length,
                    onReorderItem: (int oldIndex, int newIndex) {
                      setState(() {
                        final Questao item = _ordenadas.removeAt(oldIndex);
                        _ordenadas.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final Questao q = _ordenadas[index];
                      return ListTile(
                        key: ValueKey<String>(q.id),
                        leading: Text('${index + 1}.'),
                        title: Text(q.enunciado, maxLines: 2),
                        trailing: const Icon(Icons.drag_handle),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      FilledButton(
                        key: const Key('btn-ir-variacoes'),
                        onPressed: () async {
                          await _salvarOrdem();
                          if (context.mounted) {
                            context.push('/provas/${widget.provaId}/variacoes');
                          }
                        },
                        child: const Text('Configurar variações'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const Key('btn-ir-gerar'),
                        onPressed: () =>
                            context.push('/provas/${widget.provaId}/gerar'),
                        child: const Text('Prévia de geração'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
