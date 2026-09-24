import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/shared/models/questao.dart';

class QuestaoFormPage extends ConsumerStatefulWidget {
  const QuestaoFormPage({super.key, this.questaoId});

  final String? questaoId;

  @override
  ConsumerState<QuestaoFormPage> createState() => _QuestaoFormPageState();
}

class _QuestaoFormPageState extends ConsumerState<QuestaoFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _enunciadoController = TextEditingController();
  final List<TextEditingController> _altControllers = List<TextEditingController>.generate(
    4,
    (_) => TextEditingController(),
  );
  int _gabarito = 0;
  bool _loading = true;
  String? _error;

  bool get _isEdit => widget.questaoId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isEdit) {
      final Questao? q =
          await ref.read(questaoRepositoryProvider).getById(widget.questaoId!);
      if (q != null) {
        _enunciadoController.text = q.enunciado;
        for (int i = 0; i < 4; i++) {
          _altControllers[i].text = q.alternativas[i];
        }
        _gabarito = q.gabaritoIndex;
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _enunciadoController.dispose();
    for (final TextEditingController c in _altControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final Questao questao = Questao(
      id: widget.questaoId ?? '',
      enunciado: _enunciadoController.text.trim(),
      alternativas: _altControllers.map((TextEditingController c) => c.text.trim()).toList(),
      gabaritoIndex: _gabarito,
    );
    if (_isEdit) {
      await ref.read(questaoRepositoryProvider).update(questao);
    } else {
      await ref.read(questaoRepositoryProvider).create(questao);
    }
    ref.read(listVersionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    showSuccessSnackBar(
      context,
      _isEdit ? 'Questão atualizada.' : 'Questão cadastrada.',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['A', 'B', 'C', 'D'];
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar questão' : 'Cadastrar questão'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_error != null) ...<Widget>[
                          FormErrorBanner(
                            message: _error!,
                            onClose: () => setState(() => _error = null),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          key: const Key('input-enunciado'),
                          controller: _enunciadoController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Enunciado',
                            hintText: 'Informe o enunciado da questão',
                            helperText: 'Texto principal da pergunta.',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.help_outline),
                          ),
                          validator: (String? v) =>
                              (v == null || v.isEmpty) ? 'Informe o enunciado' : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Alternativas',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selecione o rádio para marcar a alternativa correta.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 10),
                        RadioGroup<int>(
                          groupValue: _gabarito,
                          onChanged: (int? v) {
                            if (v != null) {
                              setState(() => _gabarito = v);
                            }
                          },
                          child: Column(
                            children: List<Widget>.generate(4, (int i) {
                              final bool isCorrect = i == _gabarito;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: isCorrect
                                      ? colors.primaryContainer.withValues(alpha: 0.55)
                                      : colors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(18),
                                  elevation: 1,
                                  shadowColor: colors.shadow.withValues(alpha: 0.12),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Row(
                                      children: <Widget>[
                                        Radio<int>(
                                          key: Key('radio-gabarito-$i'),
                                          value: i,
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            key: Key('input-alternativa-$i'),
                                            controller: _altControllers[i],
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              labelText: 'Alternativa ${labels[i]}',
                                              hintText:
                                                  'Informe a alternativa ${labels[i]}',
                                              helperText: isCorrect
                                                  ? 'Marcada como gabarito'
                                                  : null,
                                            ),
                                            validator: (String? v) =>
                                                (v == null || v.isEmpty)
                                                    ? 'Informe a alternativa'
                                                    : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          key: const Key('btn-salvar-questao'),
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}