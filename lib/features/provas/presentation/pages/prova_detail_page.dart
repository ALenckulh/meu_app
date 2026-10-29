import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/confirm_delete_dialog.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/core/widgets/info_card.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/turma.dart';

class ProvaDetailPage extends ConsumerStatefulWidget {
  const ProvaDetailPage({super.key, required this.provaId});

  final String provaId;

  @override
  ConsumerState<ProvaDetailPage> createState() => _ProvaDetailPageState();
}

class _ProvaDetailPageState extends ConsumerState<ProvaDetailPage> {
  Prova? _prova;
  List<Turma> _turmas = <Turma>[];
  String? _turmaId;
  bool _loading = true;
  bool _salvandoTurma = false;

  /// Muda ao cancelar a troca, para o dropdown voltar à turma salva.
  int _turmaCancelada = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String? professorId = ref.read(authSessionProvider)?.id;
    final Prova? prova =
        await ref.read(provaRepositoryProvider).getById(widget.provaId);
    final List<Turma> turmas = professorId == null
        ? <Turma>[]
        : await ref.read(turmaRepositoryProvider).listByProfessor(professorId);

    String? turmaId = prova?.turmaId;
    if (turmaId != null && turmaId.isEmpty) {
      turmaId = null;
    }

    if (mounted) {
      setState(() {
        _prova = prova;
        _turmas = turmas;
        _turmaId = turmaId;
        _loading = false;
      });
    }
  }

  String get _turmaLabel {
    if (_turmaId == null) {
      return 'Sem turma';
    }
    for (final Turma t in _turmas) {
      if (t.id == _turmaId) {
        return '${t.nome} · ${t.disciplina}';
      }
    }
    return _turmaId!;
  }

  Future<void> _onTurmaChanged(String? turmaId) async {
    if (_prova == null || turmaId == null || turmaId == _turmaId) {
      return;
    }
    final int variacoes = (await ref
            .read(provaRepositoryProvider)
            .listVariacoes(widget.provaId))
        .length;
    if (variacoes > 0) {
      if (!mounted) {
        return;
      }
      final bool ok = await showConfirmDeleteDialog(
        context: context,
        title: 'Trocar a turma?',
        message: 'As $variacoes variação(ões) geradas para a turma atual serão '
            'apagadas e as folhas impressas deixam de valer.',
        confirmLabel: 'Trocar turma',
      );
      if (!ok) {
        setState(() => _turmaCancelada++);
        return;
      }
      await ref.read(provaRepositoryProvider).deleteVariacoes(widget.provaId);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _turmaId = turmaId;
      _salvandoTurma = true;
    });
    try {
      final Prova updated = _prova!.copyWith(turmaId: turmaId);
      await ref.read(provaRepositoryProvider).update(updated);
      ref.read(listVersionProvider.notifier).bump();
      if (!mounted) {
        return;
      }
      setState(() {
        _prova = updated;
        _salvandoTurma = false;
      });
      showSuccessSnackBar(context, 'Turma da prova atualizada.');
    } catch (e) {
      if (mounted) {
        setState(() => _salvandoTurma = false);
        showErrorSnackBar(context, 'Erro ao salvar turma: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Prova? prova = _prova;

    return Scaffold(
      appBar: AppBar(title: Text(prova?.titulo ?? 'Prova')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                InfoCard(
                  icon: Icons.assignment_outlined,
                  title: prova?.titulo ?? 'Prova',
                  subtitle:
                      '${prova?.questaoIds.length ?? 0} questões · $_turmaLabel',
                ),
                const SectionHeader('Turma'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          key: ValueKey<String>(
                              'select-prova-turma-${_turmaId ?? 'none'}-$_turmaCancelada'),
                          initialValue: _turmaId,
                          decoration: InputDecoration(
                            labelText: 'Turma da prova',
                            hintText: 'Selecione a turma',
                            helperText:
                                'Alunos desta turma usam as variações.',
                            prefixIcon: const Icon(Icons.groups_outlined),
                            suffixIcon: _salvandoTurma
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          items: _turmas
                              .map(
                                (Turma t) => DropdownMenuItem<String>(
                                  value: t.id,
                                  child: Text('${t.nome} · ${t.disciplina}'),
                                ),
                              )
                              .toList(),
                          onChanged:
                              _salvandoTurma ? null : _onTurmaChanged,
                        ),
                        if (_turmaId == null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Selecione uma turma antes de gerar variações.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SectionHeader('Montagem'),
                NavCard(
                  key: const Key('item-ordenar-questoes'),
                  icon: Icons.reorder,
                  title: 'Questões e ordem',
                  subtitle: 'Selecione e ordene as questões da prova',
                  onTap: () =>
                      context.push('/provas/${widget.provaId}/questoes'),
                ),
                const SizedBox(height: 12),
                NavCard(
                  key: const Key('item-variacoes'),
                  icon: Icons.shuffle,
                  title: 'Variações / embaralhamento',
                  subtitle:
                      'Gere versões com questões e alternativas trocadas',
                  onTap: () =>
                      context.push('/provas/${widget.provaId}/variacoes'),
                ),
                const SectionHeader('Saída'),
                NavCard(
                  key: const Key('item-gerar'),
                  icon: Icons.print_outlined,
                  title: 'Imprimir / PDF',
                  subtitle: 'Geral, folha ou por aluno / turma',
                  onTap: () =>
                      context.push('/provas/${widget.provaId}/gerar'),
                ),
              ],
            ),
    );
  }
}
