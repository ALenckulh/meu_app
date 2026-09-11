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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_prova?.titulo ?? 'Questões da prova'),
        actions: <Widget>[
          Tooltip(
            message: 'Salvar ordem',
            child: IconButton(
              key: const Key('btn-salvar-ordem'),
              icon: const Icon(Icons.save_outlined),
              onPressed: _salvarOrdem,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.drag_indicator,
                          size: 18, color: colors.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Arraste as questões para definir a ordem na prova.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _ordenadas.length,
                    buildDefaultDragHandles: false,
                    onReorderItem: (int oldIndex, int newIndex) {
                      setState(() {
                        final Questao item = _ordenadas.removeAt(oldIndex);
                        _ordenadas.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final Questao q = _ordenadas[index];
                      return Padding(
                        key: ValueKey<String>(q.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color:
                                    colors.primary.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: colors.primaryContainer,
                                child: Text(
                                  '${index + 1}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colors.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  q.enunciado,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ReorderableDragStartListener(
                                index: index,
                                child: Tooltip(
                                  message: 'Arrastar para reordenar',
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(Icons.drag_indicator,
                                        color: colors.onSurfaceVariant),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border:
                        Border(top: BorderSide(color: colors.outlineVariant)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        FilledButton.icon(
                          key: const Key('btn-ir-variacoes'),
                          onPressed: () async {
                            await _salvarOrdem();
                            if (context.mounted) {
                              context.push(
                                  '/provas/${widget.provaId}/variacoes');
                            }
                          },
                          icon: const Icon(Icons.shuffle),
                          label: const Text('Configurar variações'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const Key('btn-ir-gerar'),
                          onPressed: () => context
                              .push('/provas/${widget.provaId}/gerar'),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Prévia de geração'),
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
