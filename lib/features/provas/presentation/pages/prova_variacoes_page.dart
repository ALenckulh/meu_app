import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Variações da prova')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  _prova?.titulo ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('input-qtd-variacoes'),
                  initialValue: '$_qtd',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de variações',
                    hintText: 'Informe a quantidade',
                    helperText: 'Número de versões a gerar (simulação N1).',
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
                  title: const Text('Embaralhar questões'),
                  value: _embaralharQuestoes,
                  onChanged: (bool v) => setState(() => _embaralharQuestoes = v),
                ),
                SwitchListTile(
                  key: const Key('switch-embaralhar-alternativas'),
                  title: const Text('Embaralhar alternativas'),
                  value: _embaralharAlternativas,
                  onChanged: (bool v) =>
                      setState(() => _embaralharAlternativas = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const Key('select-aluno-variacao'),
                  initialValue: _alunoId,
                  decoration: const InputDecoration(
                    labelText: 'Aluno (simulação)',
                    hintText: 'Selecione o aluno',
                    helperText: 'Aluno vinculado à variação gerada.',
                  ),
                  items: _alunos
                      .map(
                        (Aluno a) => DropdownMenuItem<String>(
                          value: a.id,
                          child: Text(a.nome),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) => setState(() => _alunoId = v),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('btn-simular-variacao'),
                  onPressed: _alunoId == null ? null : _simular,
                  child: const Text('Simular embaralhamento'),
                ),
                if (_alunoId == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Cadastre alunos na turma para simular.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_ultima != null) ...<Widget>[
                  const SizedBox(height: 24),
                  OutlinedButton(
                    key: const Key('btn-ver-variacao'),
                    onPressed: () => context.push(
                      '/provas/${widget.provaId}/variacoes/${_ultima!.id}',
                    ),
                    child: const Text('Visualizar variação gerada'),
                  ),
                ],
              ],
            ),
    );
  }
}
