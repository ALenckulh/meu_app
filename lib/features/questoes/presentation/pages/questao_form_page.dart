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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar questão' : 'Cadastrar questão'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      key: const Key('input-enunciado'),
                      controller: _enunciadoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Enunciado',
                        hintText: 'Informe o enunciado da questão',
                        helperText: 'Texto principal da pergunta.',
                      ),
                      validator: (String? v) =>
                          (v == null || v.isEmpty) ? 'Informe o enunciado' : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Alternativas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<int>(
                      groupValue: _gabarito,
                      onChanged: (int? v) {
                        if (v != null) {
                          setState(() => _gabarito = v);
                        }
                      },
                      child: Column(
                        children: List<Widget>.generate(4, (int i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
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
                                      labelText: 'Alternativa ${labels[i]}',
                                      hintText:
                                          'Informe a alternativa ${labels[i]}',
                                      helperText: i == _gabarito
                                          ? 'Marcada como gabarito'
                                          : 'Selecione o rádio para definir o gabarito',
                                    ),
                                    validator: (String? v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Informe a alternativa'
                                            : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('btn-salvar-questao'),
                      onPressed: _save,
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
