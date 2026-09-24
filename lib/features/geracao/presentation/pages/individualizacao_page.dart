import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/section_header.dart';
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
        _variacao =
            vars.firstWhere((VariacaoDeProva v) => v.alunoId == _alunoId);
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Individualização')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: DropdownButtonFormField<String>(
                      key: const Key('select-aluno-individual'),
                      initialValue: _alunoId,
                      decoration: const InputDecoration(
                        labelText: 'Aluno',
                        hintText: 'Selecione o aluno',
                        helperText: 'Aluno para simular a individualização.',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
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
                      onChanged: _onAlunoChanged,
                    ),
                  ),
                ),
                const SectionHeader('Fluxo de geração'),
                _TimelineStep(
                  icon: Icons.person_outline,
                  label: 'Aluno',
                  value: aluno?.nome ?? '—',
                  caption:
                      aluno != null ? 'Matrícula ${aluno.matricula}' : null,
                ),
                _TimelineStep(
                  icon: Icons.shuffle,
                  label: 'Variação da prova',
                  value: _variacao?.id ?? '—',
                  caption: _variacao != null
                      ? '${_variacao!.ordemQuestoes.length} questões embaralhadas'
                      : null,
                ),
                const _TimelineStep(
                  icon: Icons.description_outlined,
                  label: 'Folha de respostas',
                  value: 'Prévia individualizada',
                ),
                _TimelineStep(
                  icon: Icons.qr_code_2,
                  label: 'QR Code',
                  value: 'Payload mock',
                  isLast: true,
                  trailing: _variacao == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: scheme.outline),
                              ),
                              child: QrImageView(
                                data:
                                    'MOCK|prova=${widget.provaId}|var=${_variacao!.id}|aluno=${_variacao!.alunoId}',
                                size: 140,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

/// Um passo da linha do tempo do fluxo de individualização, com um
/// indicador circular conectado por uma linha vertical de tamanho fixo
/// ao próximo passo.
class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.trailing,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Widget? trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Indicador: círculo com ícone + linha conectora de tamanho fixo.
        // (Não usamos IntrinsicHeight aqui: o QrImageView do passo final
        // usa LayoutBuilder internamente, e o Flutter não permite calcular
        // dimensões intrínsecas quando há um LayoutBuilder na subárvore.)
        SizedBox(
          width: 40,
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: scheme.outlineVariant,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label.toUpperCase(),
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: text.titleMedium),
                  if (caption != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      caption!,
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
