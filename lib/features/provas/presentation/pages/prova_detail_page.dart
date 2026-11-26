import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/confirm_delete_dialog.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/core/widgets/info_card.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/core/widgets/text_input_dialog.dart';
import 'package:meu_app/features/resultados/domain/relatorio_prova.dart';
import 'package:meu_app/features/resultados/presentation/pages/relatorio_prova_page.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
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
  List<Questao> _questoes = <Questao>[];
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
    final List<Questao> todas =
        await ref.read(questaoRepositoryProvider).listAll();
    final Map<String, Questao> banco = <String, Questao>{
      for (final Questao q in todas) q.id: q,
    };

    String? turmaId = prova?.turmaId;
    if (turmaId != null && turmaId.isEmpty) {
      turmaId = null;
    }

    if (mounted) {
      setState(() {
        _prova = prova;
        _turmas = turmas;
        _questoes = (prova?.questaoIds ?? <String>[])
            .map((String id) => banco[id])
            .whereType<Questao>()
            .toList();
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

  Future<void> _salvarProva(Prova atualizada, String mensagem) async {
    try {
      await ref.read(provaRepositoryProvider).update(atualizada);
      ref.read(listVersionProvider.notifier).bump();
      if (!mounted) {
        return;
      }
      setState(() => _prova = atualizada);
      showSuccessSnackBar(context, mensagem);
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Erro ao salvar: $e');
      }
    }
  }

  Future<void> _editarTitulo() async {
    final Prova? prova = _prova;
    if (prova == null) {
      return;
    }
    final String? titulo = await showTextInputDialog(
      context: context,
      title: 'Editar título',
      label: 'Título da prova',
      initialValue: prova.titulo,
      confirmLabel: 'Salvar',
      fieldKey: const Key('input-editar-titulo-prova'),
      confirmKey: const Key('btn-salvar-titulo-prova'),
    );
    final String novo = titulo?.trim() ?? '';
    if (novo.isEmpty || novo == prova.titulo) {
      return;
    }
    await _salvarProva(prova.copyWith(titulo: novo), 'Título atualizado.');
  }

  Future<void> _alterarEmbaralhamento({bool? questoes, bool? alternativas}) {
    return _salvarProva(
      _prova!.copyWith(
        embaralharQuestoes: questoes,
        embaralharAlternativas: alternativas,
      ),
      'Embaralhamento salvo. Vale para as próximas folhas geradas.',
    );
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('btn-editar-titulo-prova'),
                      onPressed: prova == null ? null : _editarTitulo,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar título'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _StatusCard(provaId: widget.provaId),
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
                const SectionHeader('Embaralhamento'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Column(
                      children: <Widget>[
                        SwitchListTile(
                          key: const Key('switch-detalhe-embaralhar-questoes'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Embaralhar questões'),
                          value: prova?.embaralharQuestoes ?? true,
                          onChanged: prova == null
                              ? null
                              : (bool v) =>
                                  _alterarEmbaralhamento(questoes: v),
                        ),
                        SwitchListTile(
                          key: const Key(
                              'switch-detalhe-embaralhar-alternativas'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Embaralhar alternativas'),
                          value: prova?.embaralharAlternativas ?? true,
                          onChanged: prova == null
                              ? null
                              : (bool v) =>
                                  _alterarEmbaralhamento(alternativas: v),
                        ),
                      ],
                    ),
                  ),
                ),
                SectionHeader(
                  'Questões da prova',
                  action: TextButton.icon(
                    key: const Key('item-ordenar-questoes'),
                    onPressed: () async {
                      await context.push('/provas/${widget.provaId}/questoes');
                      await _load();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                ),
                Card(
                  child: _questoes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Nenhuma questão na prova.'),
                        )
                      : Column(
                          children: <Widget>[
                            for (int i = 0; i < _questoes.length; i++)
                              _QuestaoResumo(
                                numero: i + 1,
                                questao: _questoes[i],
                              ),
                          ],
                        ),
                ),
                const SectionHeader('Montagem'),
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
                const SizedBox(height: 12),
                NavCard(
                  key: const Key('item-relatorio'),
                  icon: Icons.assessment_outlined,
                  title: 'Status da prova (relatório)',
                  subtitle: 'Notas salvas, pendentes e desempenho por questão',
                  onTap: () =>
                      context.push('/provas/${widget.provaId}/relatorio'),
                ),
              ],
            ),
    );
  }
}

/// Resumo do status da correção, com atalho para o relatório.
class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.provaId});

  final String provaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DadosRelatorio? dados =
        ref.watch(relatorioProvaProvider(provaId)).valueOrNull;
    final RelatorioProva? r = dados?.relatorio;
    if (r == null) {
      return const SizedBox.shrink();
    }
    final Color cor = corDoStatus(context, r.status);
    final String media =
        r.media == null ? '' : ' · média ${r.media!.toStringAsFixed(1)}';
    return Card(
      child: ListTile(
        key: const Key('card-status-prova'),
        leading: Icon(iconeDoStatus(r.status), color: cor),
        title: Text(
          r.status.rotulo,
          style: TextStyle(color: cor, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${r.corrigidos} de ${r.totalAlunos} aluno(s) com nota$media',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/provas/$provaId/relatorio'),
      ),
    );
  }
}

/// Uma questão da prova na prévia do detalhe, com o gabarito.
class _QuestaoResumo extends StatelessWidget {
  const _QuestaoResumo({required this.numero, required this.questao});

  final int numero;
  final Questao questao;

  static const List<String> _letras = <String>['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final int g = questao.gabaritoIndex;
    final String gabarito = g >= 0 && g < questao.alternativas.length
        ? '${_letras[g.clamp(0, 3)]}) ${questao.alternativas[g]}'
        : '—';
    return ListTile(
      key: Key('detalhe-questao-${questao.id}'),
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        child: Text('$numero', style: const TextStyle(fontSize: 12)),
      ),
      title: Text(
        questao.enunciado,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Gabarito: $gabarito',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
