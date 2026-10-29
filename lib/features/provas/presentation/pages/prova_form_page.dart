import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/turma.dart';

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
  List<Turma> _turmas = <Turma>[];
  String? _turmaId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? professorId = ref.read(authSessionProvider)?.id;
    final List<Questao> banco =
        await ref.read(questaoRepositoryProvider).listAll();
    final List<Turma> turmas = professorId == null
        ? <Turma>[]
        : await ref.read(turmaRepositoryProvider).listByProfessor(professorId);
    if (mounted) {
      setState(() {
        _banco = banco;
        _turmas = turmas;
        _turmaId = turmas.isNotEmpty ? turmas.first.id : null;
        _loading = false;
      });
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
    if (_turmaId == null || _turmaId!.isEmpty) {
      setState(() => _error = 'Selecione a turma da prova.');
      return;
    }
    final String? professorId = ref.read(authSessionProvider)?.id;
    if (professorId == null) {
      setState(() => _error = 'Sessão inválida. Faça login novamente.');
      return;
    }
    final Prova prova = await ref.read(provaRepositoryProvider).create(
          Prova(
            id: '',
            professorId: professorId,
            turmaId: _turmaId!,
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar prova')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      children: <Widget>[
                        if (_error != null) ...<Widget>[
                          FormErrorBanner(
                            message: _error!,
                            onClose: () => setState(() => _error = null),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: <Widget>[
                                TextFormField(
                                  key: const Key('input-prova-titulo'),
                                  controller: _tituloController,
                                  decoration: const InputDecoration(
                                    labelText: 'Título',
                                    hintText: 'Informe o título da prova',
                                    helperText:
                                        'Nome de identificação da prova.',
                                    prefixIcon: Icon(Icons.title),
                                  ),
                                  validator: (String? v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Informe o título'
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  key: const Key('select-prova-turma'),
                                  initialValue: _turmaId,
                                  decoration: const InputDecoration(
                                    labelText: 'Turma',
                                    hintText: 'Selecione a turma',
                                    helperText:
                                        'Alunos desta turma usam as variações.',
                                    prefixIcon: Icon(Icons.groups_outlined),
                                  ),
                                  items: _turmas
                                      .map(
                                        (Turma t) => DropdownMenuItem<String>(
                                          value: t.id,
                                          child: Text(
                                              '${t.nome} · ${t.disciplina}'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (String? v) =>
                                      setState(() => _turmaId = v),
                                  validator: (String? v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Selecione a turma'
                                          : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SectionHeader(
                          'Questões',
                          action: Text(
                            '${_selecionadas.length} selecionada(s)',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Card(
                          child: Column(
                            children: <Widget>[
                              for (int i = 0;
                                  i < _banco.length;
                                  i++) ...<Widget>[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    color: colors.outlineVariant,
                                  ),
                                _QuestaoCheck(
                                  questao: _banco[i],
                                  selected:
                                      _selecionadas.contains(_banco[i].id),
                                  onChanged: (bool v) {
                                    setState(() {
                                      if (v) {
                                        _selecionadas.add(_banco[i].id);
                                      } else {
                                        _selecionadas.remove(_banco[i].id);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BottomBar(
                    child: FilledButton.icon(
                      key: const Key('btn-salvar-prova'),
                      onPressed: _save,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Salvar e ordenar questões'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _QuestaoCheck extends StatelessWidget {
  const _QuestaoCheck({
    required this.questao,
    required this.selected,
    required this.onChanged,
  });

  final Questao questao;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return CheckboxListTile(
      key: Key('check-questao-${questao.id}'),
      value: selected,
      onChanged: (bool? v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      tileColor:
          selected ? colors.primaryContainer.withValues(alpha: 0.35) : null,
      title: Text(
        questao.enunciado,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: questao.tags.isEmpty
          ? null
          : Text(questao.tags.join(' · '),
              style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
