import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/core/widgets/info_card.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/turma.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

class ProvaVariacoesPage extends ConsumerStatefulWidget {
  const ProvaVariacoesPage({super.key, required this.provaId});

  final String provaId;

  @override
  ConsumerState<ProvaVariacoesPage> createState() => _ProvaVariacoesPageState();
}

class _ProvaVariacoesPageState extends ConsumerState<ProvaVariacoesPage> {
  Prova? _prova;
  Turma? _turma;
  bool _embaralharQuestoes = true;
  bool _embaralharAlternativas = true;
  List<Aluno> _alunos = <Aluno>[];
  final Set<String> _selecionados = <String>{};
  List<VariacaoDeProva> _geradas = <VariacaoDeProva>[];
  bool _loading = true;
  bool _gerando = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Prova? prova =
        await ref.read(provaRepositoryProvider).getById(widget.provaId);
    final String? turmaId =
        (prova?.turmaId != null && prova!.turmaId.isNotEmpty)
            ? prova.turmaId
            : null;

    Turma? turma;
    List<Aluno> alunos = <Aluno>[];
    if (turmaId != null) {
      turma = await ref.read(turmaRepositoryProvider).getById(turmaId);
      alunos = await ref.read(alunoRepositoryProvider).listByTurma(turmaId);
    }

    if (mounted) {
      setState(() {
        _prova = prova;
        _turma = turma;
        _alunos = alunos;
        _selecionados
          ..clear()
          ..addAll(alunos.map((Aluno a) => a.id));
        _loading = false;
      });
    }
  }

  void _toggleAluno(String id, bool selected) {
    setState(() {
      if (selected) {
        _selecionados.add(id);
      } else {
        _selecionados.remove(id);
      }
    });
  }

  void _selecionarTodos() {
    setState(() {
      _selecionados
        ..clear()
        ..addAll(_alunos.map((Aluno a) => a.id));
    });
  }

  void _limparSelecao() {
    setState(() => _selecionados.clear());
  }

  Future<void> _gerarPara(Iterable<String> alunoIds) async {
    if (_prova == null) {
      return;
    }
    final List<String> ids = alunoIds.toList();
    if (ids.isEmpty) {
      showSuccessSnackBar(context, 'Selecione ao menos um aluno.');
      return;
    }
    setState(() => _gerando = true);
    try {
      await ref.read(provaRepositoryProvider).update(
            _prova!.copyWith(quantidadeVariacoes: ids.length),
          );
      final List<VariacaoDeProva> geradas = <VariacaoDeProva>[];
      for (final String alunoId in ids) {
        final VariacaoDeProva v =
            await ref.read(provaRepositoryProvider).gerarVariacao(
                  provaId: widget.provaId,
                  alunoId: alunoId,
                  embaralharQuestoes: _embaralharQuestoes,
                  embaralharAlternativas: _embaralharAlternativas,
                );
        geradas.add(v);
      }
      ref.read(listVersionProvider.notifier).bump();
      if (!mounted) {
        return;
      }
      setState(() {
        _geradas = geradas;
        _gerando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${geradas.length} variação(ões) gerada(s).'),
          action: SnackBarAction(
            label: 'Imprimir',
            onPressed: () =>
                context.push('/provas/${widget.provaId}/gerar'),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _gerando = false);
        showSuccessSnackBar(context, 'Erro ao gerar: $e');
      }
    }
  }

  String _nomeAluno(String alunoId) {
    for (final Aluno a in _alunos) {
      if (a.id == alunoId) {
        return a.nome;
      }
    }
    return alunoId;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool semTurma = _turma == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Variações da prova')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                InfoCard(
                  icon: Icons.shuffle,
                  title: _prova?.titulo ?? 'Prova',
                  subtitle: semTurma
                      ? 'Defina a turma no detalhe da prova.'
                      : 'Turma: ${_turma!.nome} · ${_turma!.disciplina}',
                ),
                if (semTurma) ...<Widget>[
                  const SizedBox(height: 12),
                  Card(
                    color: colors.errorContainer,
                    child: ListTile(
                      leading: Icon(Icons.warning_amber,
                          color: colors.onErrorContainer),
                      title: Text(
                        'Prova sem turma',
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                      subtitle: Text(
                        'Escolha a turma no detalhe da prova para listar alunos.',
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            context.go('/provas/${widget.provaId}'),
                        child: const Text('Alterar'),
                      ),
                    ),
                  ),
                ],
                const SectionHeader('Configuração'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      children: <Widget>[
                        SwitchListTile(
                          key: const Key('switch-embaralhar-questoes'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Embaralhar questões'),
                          subtitle: const Text('Ordem diferente por versão'),
                          value: _embaralharQuestoes,
                          onChanged: _gerando || semTurma
                              ? null
                              : (bool v) =>
                                  setState(() => _embaralharQuestoes = v),
                        ),
                        SwitchListTile(
                          key: const Key('switch-embaralhar-alternativas'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Embaralhar alternativas'),
                          subtitle:
                              const Text('A/B/C/D em posições trocadas'),
                          value: _embaralharAlternativas,
                          onChanged: _gerando || semTurma
                              ? null
                              : (bool v) => setState(
                                    () => _embaralharAlternativas = v,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                SectionHeader(
                  'Alunos da turma',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextButton(
                        key: const Key('btn-selecionar-todos'),
                        onPressed: _gerando || _alunos.isEmpty
                            ? null
                            : _selecionarTodos,
                        child: const Text('Todos'),
                      ),
                      TextButton(
                        key: const Key('btn-limpar-selecao'),
                        onPressed: _gerando || _selecionados.isEmpty
                            ? null
                            : _limparSelecao,
                        child: const Text('Limpar'),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: _alunos.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            semTurma
                                ? 'Sem turma vinculada.'
                                : 'Cadastre alunos nesta turma para gerar variações.',
                            style: TextStyle(color: colors.error),
                          ),
                        )
                      : Column(
                          children: <Widget>[
                            for (int i = 0; i < _alunos.length; i++) ...<Widget>[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  color: colors.outlineVariant,
                                ),
                              CheckboxListTile(
                                key: Key('check-aluno-${_alunos[i].id}'),
                                value: _selecionados.contains(_alunos[i].id),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(_alunos[i].nome),
                                subtitle: Text(
                                  'matrícula ${_alunos[i].matricula}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                onChanged: _gerando
                                    ? null
                                    : (bool? v) => _toggleAluno(
                                          _alunos[i].id,
                                          v ?? false,
                                        ),
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('btn-gerar-selecionados'),
                  onPressed: _gerando || _selecionados.isEmpty
                      ? null
                      : () => _gerarPara(_selecionados),
                  icon: Icon(
                    _gerando ? Icons.hourglass_bottom : Icons.play_arrow,
                  ),
                  label: Text(
                    _gerando
                        ? 'Gerando...'
                        : 'Gerar para selecionados (${_selecionados.length})',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('btn-gerar-turma'),
                  onPressed: _gerando || _alunos.isEmpty
                      ? null
                      : () => _gerarPara(_alunos.map((Aluno a) => a.id)),
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Gerar para toda a turma'),
                ),
                if (_geradas.isNotEmpty) ...<Widget>[
                  const SectionHeader('Variações geradas'),
                  Card(
                    color: colors.primaryContainer,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < _geradas.length; i++) ...<Widget>[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: colors.onPrimaryContainer
                                  .withValues(alpha: 0.2),
                            ),
                          ListTile(
                            key: Key('gerada-${_geradas[i].id}'),
                            leading: Icon(
                              Icons.check_circle,
                              color: colors.onPrimaryContainer,
                            ),
                            title: Text(
                              _nomeAluno(_geradas[i].alunoId),
                              style: TextStyle(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${_geradas[i].ordemQuestoes.length} questões embaralhadas',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onPrimaryContainer
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                            trailing: Icon(
                              Icons.visibility_outlined,
                              color: colors.onPrimaryContainer,
                            ),
                            onTap: () => context.push(
                              '/provas/${widget.provaId}/variacoes/${_geradas[i].id}',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
