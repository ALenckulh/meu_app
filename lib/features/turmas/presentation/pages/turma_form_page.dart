import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/shared/models/turma.dart';

class TurmaFormPage extends ConsumerStatefulWidget {
  const TurmaFormPage({super.key, this.turmaId});

  final String? turmaId;

  @override
  ConsumerState<TurmaFormPage> createState() => _TurmaFormPageState();
}

class _TurmaFormPageState extends ConsumerState<TurmaFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _disciplinaController = TextEditingController();
  final TextEditingController _anoController =
      TextEditingController(text: '2026');
  String? _error;
  bool _loading = true;

  bool get _isEdit => widget.turmaId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isEdit) {
      final Turma? turma =
          await ref.read(turmaRepositoryProvider).getById(widget.turmaId!);
      if (turma != null) {
        _nomeController.text = turma.nome;
        _disciplinaController.text = turma.disciplina;
        _anoController.text = '${turma.ano}';
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _disciplinaController.dispose();
    _anoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String? professorId = ref.read(authSessionProvider)?.id;
    if (professorId == null) {
      setState(() => _error = 'Sessão expirada. Faça login novamente.');
      return;
    }
    final Turma turma = Turma(
      id: widget.turmaId ?? '',
      professorId: professorId,
      nome: _nomeController.text.trim(),
      disciplina: _disciplinaController.text.trim(),
      ano: int.parse(_anoController.text.trim()),
    );
    if (_isEdit) {
      await ref.read(turmaRepositoryProvider).update(turma);
    } else {
      await ref.read(turmaRepositoryProvider).create(turma);
    }
    ref.read(listVersionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    showSuccessSnackBar(
      context,
      _isEdit ? 'Turma atualizada.' : 'Turma criada.',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar turma' : 'Criar turma'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
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
                          key: const Key('input-turma-nome'),
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            hintText: 'Informe o nome da turma',
                            helperText: 'Ex.: 3º Ano A',
                            prefixIcon: Icon(Icons.groups_outlined),
                          ),
                          validator: (String? v) =>
                              (v == null || v.isEmpty) ? 'Informe o nome' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('input-turma-disciplina'),
                          controller: _disciplinaController,
                          decoration: const InputDecoration(
                            labelText: 'Disciplina',
                            hintText: 'Informe a disciplina',
                            helperText: 'Disciplina principal da turma.',
                            prefixIcon: Icon(Icons.menu_book_outlined),
                          ),
                          validator: (String? v) => (v == null || v.isEmpty)
                              ? 'Informe a disciplina'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('input-turma-ano'),
                          controller: _anoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ano',
                            hintText: 'Informe o ano letivo',
                            helperText: 'Ano letivo da turma.',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (String? v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe o ano';
                            }
                            if (int.tryParse(v) == null) {
                              return 'Ano inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          key: const Key('btn-salvar-turma'),
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