import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/shared/models/aluno.dart';

class AlunoFormPage extends ConsumerStatefulWidget {
  const AlunoFormPage({
    super.key,
    required this.turmaId,
    this.alunoId,
  });

  final String turmaId;
  final String? alunoId;

  @override
  ConsumerState<AlunoFormPage> createState() => _AlunoFormPageState();
}

class _AlunoFormPageState extends ConsumerState<AlunoFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  bool _loading = true;

  bool get _isEdit => widget.alunoId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isEdit) {
      final Aluno? aluno =
          await ref.read(alunoRepositoryProvider).getById(widget.alunoId!);
      if (aluno != null) {
        _nomeController.text = aluno.nome;
        _matriculaController.text = aluno.matricula;
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _matriculaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final Aluno aluno = Aluno(
      id: widget.alunoId ?? '',
      turmaId: widget.turmaId,
      nome: _nomeController.text.trim(),
      matricula: _matriculaController.text.trim(),
    );
    if (_isEdit) {
      await ref.read(alunoRepositoryProvider).update(aluno);
    } else {
      await ref.read(alunoRepositoryProvider).create(aluno);
    }
    ref.read(listVersionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    showSuccessSnackBar(
      context,
      _isEdit ? 'Aluno atualizado.' : 'Aluno cadastrado.',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar aluno' : 'Cadastrar aluno'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextFormField(
                          key: const Key('input-aluno-nome'),
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            hintText: 'Informe o nome do aluno',
                            helperText: 'Nome completo do aluno.',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (String? v) =>
                              (v == null || v.isEmpty) ? 'Informe o nome' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('input-aluno-matricula'),
                          controller: _matriculaController,
                          decoration: const InputDecoration(
                            labelText: 'Matrícula',
                            hintText: 'Informe a matrícula',
                            helperText: 'Identificador único do aluno na turma.',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (String? v) => (v == null || v.isEmpty)
                              ? 'Informe a matrícula'
                              : null,
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          key: const Key('btn-salvar-aluno'),
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