import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:qr_flutter/qr_flutter.dart';

class IndividualizacaoPage extends ConsumerStatefulWidget {
  const IndividualizacaoPage({super.key, required this.provaId});

  final String provaId;

  @override
  ConsumerState<IndividualizacaoPage> createState() =>
      _IndividualizacaoPageState();
}

class _IndividualizacaoPageState extends ConsumerState<IndividualizacaoPage> {
  List<Aluno> _alunos = <Aluno>[];
  String? _alunoId;
  VariacaoDeProva? _variacao;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Aluno> alunos =
        await ref.read(alunoRepositoryProvider).listByTurma('turma-1');
    final List<VariacaoDeProva> vars =
        await ref.read(provaRepositoryProvider).listVariacoes(widget.provaId);
    _alunos = alunos;
    _alunoId = alunos.isNotEmpty ? alunos.first.id : null;
    if (_alunoId != null) {
      try {
        _variacao = vars.firstWhere((VariacaoDeProva v) => v.alunoId == _alunoId);
      } catch (_) {
        _variacao = vars.isNotEmpty ? vars.first : null;
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _onAlunoChanged(String? id) async {
    setState(() => _alunoId = id);
    if (id == null) {
      return;
    }
    final List<VariacaoDeProva> vars =
        await ref.read(provaRepositoryProvider).listVariacoes(widget.provaId);
    VariacaoDeProva? found;
    try {
      found = vars.firstWhere((VariacaoDeProva v) => v.alunoId == id);
    } catch (_) {
      found = await ref.read(provaRepositoryProvider).gerarVariacao(
            provaId: widget.provaId,
            alunoId: id,
            embaralharQuestoes: true,
            embaralharAlternativas: true,
          );
    }
    if (mounted) {
      setState(() => _variacao = found);
    }
  }

  @override
  Widget build(BuildContext context) {
    Aluno? aluno;
    for (final Aluno a in _alunos) {
      if (a.id == _alunoId) {
        aluno = a;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Individualização')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                DropdownButtonFormField<String>(
                  key: const Key('select-aluno-individual'),
                  initialValue: _alunoId,
                  decoration: const InputDecoration(
                    labelText: 'Aluno',
                    hintText: 'Selecione o aluno',
                    helperText: 'Aluno para simular a individualização.',
                  ),
                  items: _alunos
                      .map(
                        (Aluno a) => DropdownMenuItem<String>(
                          value: a.id,
                          child: Text(a.nome),
                        ),
                      )
                      .toList(),
                  onChanged: _onAlunoChanged,
                ),
                const SizedBox(height: 24),
                _ChainStep(label: 'Aluno', value: aluno?.nome ?? '—'),
                const Icon(Icons.arrow_downward),
                _ChainStep(
                  label: 'Variação da prova',
                  value: _variacao?.id ?? '—',
                ),
                const Icon(Icons.arrow_downward),
                const _ChainStep(
                  label: 'Folha de respostas',
                  value: 'Prévia individualizada',
                ),
                const Icon(Icons.arrow_downward),
                const _ChainStep(label: 'QR Code', value: 'Payload mock'),
                const SizedBox(height: 16),
                if (_variacao != null)
                  Center(
                    child: ColoredBox(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                      child: QrImageView(
                        data:
                            'MOCK|prova=${widget.provaId}|var=${_variacao!.id}|aluno=${_variacao!.alunoId}',
                        size: 140,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ChainStep extends StatelessWidget {
  const _ChainStep({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
    );
  }
}
