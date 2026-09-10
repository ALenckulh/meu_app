import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';

class ProvaFormPage extends ConsumerStatefulWidget {
  const ProvaFormPage({super.key});

  @override
  ConsumerState<ProvaFormPage> createState() => _ProvaFormPageState();
}

class _ProvaFormPageState extends ConsumerState<ProvaFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final Set<String> _selecionadas = <String>{};
  List<Questao> _banco = <Questao>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _banco = await ref.read(questaoRepositoryProvider).listAll();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selecionadas.isEmpty) {
      setState(() => _error = 'Selecione ao menos uma questão.');
      return;
    }
    final Prova prova = await ref.read(provaRepositoryProvider).create(
          Prova(
            id: '',
            titulo: _tituloController.text.trim(),
            questaoIds: _selecionadas.toList(),
          ),
        );
    ref.read(listVersionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    showSuccessSnackBar(context, 'Prova criada.');
    context.go('/provas/${prova.id}/questoes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar prova')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        if (_error != null) ...<Widget>[
                          FormErrorBanner(
                            message: _error!,
                            onClose: () => setState(() => _error = null),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          key: const Key('input-prova-titulo'),
                          controller: _tituloController,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            hintText: 'Informe o título da prova',
                            helperText: 'Nome de identificação da prova.',
                          ),
                          validator: (String? v) =>
                              (v == null || v.isEmpty) ? 'Informe o título' : null,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _banco.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Questao q = _banco[index];
                        final bool selected = _selecionadas.contains(q.id);
                        return CheckboxListTile(
                          key: Key('check-questao-${q.id}'),
                          value: selected,
                          title: Text(q.enunciado, maxLines: 2),
                          onChanged: (bool? v) {
                            setState(() {
                              if (v == true) {
                                _selecionadas.add(q.id);
                              } else {
                                _selecionadas.remove(q.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      key: const Key('btn-salvar-prova'),
                      onPressed: _save,
                      child: const Text('Salvar e ordenar questões'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
