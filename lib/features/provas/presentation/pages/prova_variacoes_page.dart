import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/core/widgets/info_card.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

class ProvaVariacoesPage extends ConsumerStatefulWidget {
  const ProvaVariacoesPage({super.key, required this.provaId});

  final String provaId;

  @override
  ConsumerState<ProvaVariacoesPage> createState() => _ProvaVariacoesPageState();
}

class _ProvaVariacoesPageState extends ConsumerState<ProvaVariacoesPage> {
  Prova? _prova;
  int _qtd = 2;
  bool _embaralharQuestoes = true;
  bool _embaralharAlternativas = true;
  String? _alunoId;
  List<Aluno> _alunos = <Aluno>[];
  VariacaoDeProva? _ultima;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Prova? prova =
        await ref.read(provaRepositoryProvider).getById(widget.provaId);
    final List<Aluno> alunos = await ref
        .read(alunoRepositoryProvider)
        .listByTurma('turma-1');
    _prova = prova;
    _qtd = prova?.quantidadeVariacoes ?? 2;
    _alunos = alunos;
    _alunoId = alunos.isNotEmpty ? alunos.first.id : null;
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _simular() async {
    if (_prova == null || _alunoId == null) {
      return;
    }
    await ref.read(provaRepositoryProvider).update(
          _prova!.copyWith(quantidadeVariacoes: _qtd),
        );
    final VariacaoDeProva variacao =
        await ref.read(provaRepositoryProvider).gerarVariacao(
              provaId: widget.provaId,
              alunoId: _alunoId!,
              embaralharQuestoes: _embaralharQuestoes,
              embaralharAlternativas: _embaralharAlternativas,
            );
    ref.read(listVersionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    setState(() => _ultima = variacao);
    showSuccessSnackBar(context, 'Variação simulada gerada.');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

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
                  subtitle:
                      'Gere versões embaralhadas para dificultar a cola.',
                ),
                const SectionHeader('Configuração'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          key: const Key('input-qtd-variacoes'),
                          initialValue: '$_qtd',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantidade de variações',
                            hintText: 'Informe a quantidade',
                            helperText:
                                'Número de versões a gerar (simulação N1).',
                            prefixIcon: Icon(Icons.tag),
                          ),
                          onChanged: (String v) {
                            final int? parsed = int.tryParse(v);
                            if (parsed != null && parsed > 0) {
                              _qtd = parsed;
                            }
                          },
                        ),
                        SwitchListTile(
                          key: const Key('switch-embaralhar-questoes'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Embaralhar questões'),
                          subtitle: const Text('Ordem diferente por versão'),
                          value: _embaralharQuestoes,
                          onChanged: (bool v) =>
                              setState(() => _embaralharQuestoes = v),
                        ),
                        SwitchListTile(
                          key: const Key('switch-embaralhar-alternativas'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Embaralhar alternativas'),
                          subtitle:
                              const Text('A/B/C/D em posições trocadas'),
                          value: _embaralharAlternativas,
                          onChanged: (bool v) =>
                              setState(() => _embaralharAlternativas = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SectionHeader('Simulação'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          key: const Key('select-aluno-variacao'),
                          initialValue: _alunoId,
                          decoration: const InputDecoration(
                            labelText: 'Aluno (simulação)',
                            hintText: 'Selecione o aluno',
                            helperText:
                                'Aluno vinculado à variação gerada.',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: _alunos
                              .map(
                                (Aluno a) => DropdownMenuItem<String>(
                                  value: a.id,
                                  child: Text(a.nome),
                                ),
                              )
                              .toList(),
                          onChanged: (String? v) =>
                              setState(() => _alunoId = v),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const Key('btn-simular-variacao'),
                          onPressed: _alunoId == null ? null : _simular,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Simular embaralhamento'),
                        ),
                        if (_alunoId == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Cadastre alunos na turma para simular.',
                              style: TextStyle(color: colors.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_ultima != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Card(
                    color: colors.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(Icons.check_circle,
                                  color: colors.onPrimaryContainer, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Variação gerada',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_ultima!.ordemQuestoes.length} questões nesta versão',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onPrimaryContainer
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key('btn-ver-variacao'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.onPrimaryContainer,
                              side: BorderSide(
                                  color: colors.onPrimaryContainer
                                      .withValues(alpha: 0.4)),
                            ),
                            onPressed: () => context.push(
                              '/provas/${widget.provaId}/variacoes/${_ultima!.id}',
                            ),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Visualizar variação gerada'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
