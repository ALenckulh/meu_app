import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/features/geracao/data/prova_pdf_service.dart';
import 'package:meu_app/features/geracao/domain/qr_payload.dart';
import 'package:meu_app/features/geracao/presentation/widgets/pdf_acoes.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/turma.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Gera provas individualizadas (RF04): cada aluno recebe uma variação
/// embaralhada e uma folha de respostas com QR Code que identifica a prova,
/// a variação e o aluno (RF05).
class IndividualizacaoPage extends ConsumerStatefulWidget {
  const IndividualizacaoPage({super.key, required this.provaId});

  final String provaId;

  @override
  ConsumerState<IndividualizacaoPage> createState() =>
      _IndividualizacaoPageState();
}

class _IndividualizacaoPageState extends ConsumerState<IndividualizacaoPage> {
  Prova? _prova;
  Map<String, Questao> _banco = <String, Questao>{};
  List<Turma> _turmas = <Turma>[];
  String? _turmaId;
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
    final Prova? prova =
        await ref.read(provaRepositoryProvider).getById(widget.provaId);
    final List<Questao> todas =
        await ref.read(questaoRepositoryProvider).listAll();
    final String? professorId = ref.read(authSessionProvider)?.id;
    final List<Turma> turmas = professorId == null
        ? <Turma>[]
        : await ref.read(turmaRepositoryProvider).listByProfessor(professorId);

    _prova = prova;
    _banco = <String, Questao>{for (final Questao q in todas) q.id: q};
    _turmas = turmas;

    String? turmaInicial = prova?.turmaId;
    if (turmaInicial != null && turmaInicial.isEmpty) {
      turmaInicial = null;
    }
    turmaInicial ??= turmas.isNotEmpty ? turmas.first.id : null;
    if (turmaInicial != null) {
      await _onTurmaChanged(turmaInicial, atualizar: false);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _onTurmaChanged(String? turmaId, {bool atualizar = true}) async {
    _turmaId = turmaId;
    _alunos = turmaId == null
        ? <Aluno>[]
        : await ref.read(alunoRepositoryProvider).listByTurma(turmaId);
    _alunoId = null;
    _variacao = null;
    if (_alunos.isNotEmpty) {
      await _onAlunoChanged(_alunos.first.id, atualizar: false);
    }
    if (atualizar && mounted) {
      setState(() {});
    }
  }

  Future<void> _onAlunoChanged(String? id, {bool atualizar = true}) async {
    _alunoId = id;
    _variacao = id == null ? null : await _variacaoDoAluno(id);
    if (atualizar && mounted) {
      setState(() {});
    }
  }

  /// Usa a variação já existente do aluno ou gera uma nova embaralhada.
  Future<VariacaoDeProva> _variacaoDoAluno(
    String alunoId, [
    List<VariacaoDeProva>? existentes,
  ]) async {
    final List<VariacaoDeProva> vars = existentes ??
        await ref.read(provaRepositoryProvider).listVariacoes(widget.provaId);
    for (final VariacaoDeProva v in vars) {
      if (v.alunoId == alunoId) {
        return v;
      }
    }
    return ref.read(provaRepositoryProvider).gerarVariacao(
          provaId: widget.provaId,
          alunoId: alunoId,
          embaralharQuestoes: true,
          embaralharAlternativas: true,
        );
  }

  Turma? get _turma {
    for (final Turma t in _turmas) {
      if (t.id == _turmaId) {
        return t;
      }
    }
    return null;
  }

  Aluno? get _aluno {
    for (final Aluno a in _alunos) {
      if (a.id == _alunoId) {
        return a;
      }
    }
    return null;
  }

  /// Uma cópia (prova + folha) para cada aluno da turma, num único PDF.
  Future<List<CopiaProva>> _copiasDaTurma() async {
    final List<VariacaoDeProva> vars =
        await ref.read(provaRepositoryProvider).listVariacoes(widget.provaId);
    final List<CopiaProva> copias = <CopiaProva>[];
    for (final Aluno aluno in _alunos) {
      final VariacaoDeProva variacao = await _variacaoDoAluno(aluno.id, vars);
      copias.add(
        CopiaProva.individual(
          variacao: variacao,
          banco: _banco,
          aluno: aluno,
          turma: _turma,
        ),
      );
    }
    return copias;
  }

  @override
  Widget build(BuildContext context) {
    final Aluno? aluno = _aluno;
    final Turma? turma = _turma;
    final VariacaoDeProva? variacao = _variacao;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String? payload = variacao == null
        ? null
        : QrPayload(
            provaId: widget.provaId,
            variacaoId: variacao.id,
            alunoId: variacao.alunoId,
          ).encode();

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
                    child: Column(
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          key: ValueKey<String>('select-turma-${_turmaId ?? ''}'),
                          initialValue: _turmaId,
                          decoration: const InputDecoration(
                            labelText: 'Turma',
                            hintText: 'Selecione a turma',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            prefixIcon: Icon(Icons.groups_outlined),
                          ),
                          items: _turmas
                              .map(
                                (Turma t) => DropdownMenuItem<String>(
                                  value: t.id,
                                  child: Text('${t.nome} · ${t.disciplina}'),
                                ),
                              )
                              .toList(),
                          onChanged: (String? id) => _onTurmaChanged(id),
                        ),
                        const Divider(height: 1),
                        DropdownButtonFormField<String>(
                          key: ValueKey<String>(
                            'select-aluno-individual-${_turmaId ?? ''}',
                          ),
                          initialValue: _alunoId,
                          decoration: const InputDecoration(
                            labelText: 'Aluno',
                            hintText: 'Selecione o aluno',
                            helperText: 'Prévia da prova deste aluno.',
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
                          onChanged: (String? id) => _onAlunoChanged(id),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_turmas.isEmpty || _alunos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _turmas.isEmpty
                          ? 'Cadastre uma turma com alunos para gerar provas individualizadas.'
                          : 'Esta turma ainda não tem alunos.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
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
                  value: variacao == null
                      ? '—'
                      : 'Versão ${variacao.id.length > 8 ? variacao.id.substring(0, 8) : variacao.id}',
                  caption: variacao != null
                      ? '${variacao.ordemQuestoes.length} questões e alternativas embaralhadas'
                      : null,
                ),
                const _TimelineStep(
                  icon: Icons.description_outlined,
                  label: 'Folha de respostas',
                  value: 'Com nome, matrícula e turma',
                ),
                _TimelineStep(
                  icon: Icons.qr_code_2,
                  label: 'QR Code',
                  value: 'Identifica prova, variação e aluno',
                  isLast: true,
                  trailing: payload == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: <Widget>[
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: scheme.outline),
                                  ),
                                  child: QrImageView(data: payload, size: 140),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                key: const Key('btn-copiar-codigo-qr'),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: payload),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Código copiado. Use "Digitar código" na tela de correção.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copiar código do QR'),
                              ),
                            ],
                          ),
                        ),
                ),
                const SectionHeader('Imprimir'),
                PdfAcoes(
                  nomeArquivo:
                      '${_prova?.titulo ?? 'prova'}_${aluno?.nome ?? 'aluno'}',
                  rotuloImprimir: 'PDF deste aluno (prova + folha)',
                  habilitado: _prova != null && variacao != null,
                  gerar: () => const ProvaPdfService().gerar(
                    prova: _prova!,
                    copias: <CopiaProva>[
                      CopiaProva.individual(
                        variacao: variacao!,
                        banco: _banco,
                        aluno: aluno,
                        turma: turma,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PdfAcoes(
                  nomeArquivo:
                      '${_prova?.titulo ?? 'prova'}_${turma?.nome ?? 'turma'}',
                  rotuloImprimir: 'PDF da turma inteira (${_alunos.length} alunos)',
                  habilitado: _prova != null && _alunos.isNotEmpty,
                  gerar: () async => const ProvaPdfService().gerar(
                    prova: _prova!,
                    copias: await _copiasDaTurma(),
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
