import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// PDF individual / turma. Turma vem só de [Prova.turmaId] (editar no detalhe).
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
  Turma? _turma;
  List<Aluno> _alunos = <Aluno>[];
  String? _alunoId;
  VariacaoDeProva? _variacao;
  bool _loading = true;
  bool _carregandoAluno = false;

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

    _prova = prova;
    _banco = <String, Questao>{for (final Questao q in todas) q.id: q};

    final String? turmaId =
        (prova?.turmaId != null && prova!.turmaId.isNotEmpty)
            ? prova.turmaId
            : null;
    if (turmaId != null) {
      _turma = await ref.read(turmaRepositoryProvider).getById(turmaId);
      _alunos = await ref.read(alunoRepositoryProvider).listByTurma(turmaId);
      if (_alunos.isNotEmpty) {
        await _onAlunoChanged(_alunos.first.id, atualizar: false);
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _onAlunoChanged(String? id, {bool atualizar = true}) async {
    _alunoId = id;
    _variacao = null;
    if (atualizar && mounted) {
      setState(() => _carregandoAluno = true);
    }
    if (id == null) {
      if (atualizar && mounted) {
        setState(() => _carregandoAluno = false);
      }
      return;
    }
    final VariacaoDeProva v = await _variacaoDoAluno(id);
    if (!mounted || _alunoId != id) {
      return;
    }
    setState(() {
      _variacao = v;
      _carregandoAluno = false;
    });
  }

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

  Aluno? get _aluno {
    for (final Aluno a in _alunos) {
      if (a.id == _alunoId) {
        return a;
      }
    }
    return null;
  }

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
    final bool semTurma = turma == null;
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
                if (semTurma)
                  Card(
                    color: scheme.errorContainer,
                    child: ListTile(
                      leading: Icon(Icons.warning_amber,
                          color: scheme.onErrorContainer),
                      title: Text(
                        'Prova sem turma',
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            context.go('/provas/${widget.provaId}'),
                        child: const Text('Alterar'),
                      ),
                    ),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: Text('${turma.nome} · ${turma.disciplina}'),
                    subtitle: const Text('Turma da prova (editar no detalhe)'),
                  ),
                const SectionHeader('Aluno'),
                Card(
                  child: _alunos.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            semTurma
                                ? 'Defina a turma no detalhe da prova.'
                                : 'Esta turma ainda não tem alunos.',
                            style: TextStyle(color: scheme.error),
                          ),
                        )
                      : Column(
                          children: <Widget>[
                            for (final Aluno a in _alunos)
                              ListTile(
                                key: Key('radio-aluno-${a.id}'),
                                selected: _alunoId == a.id,
                                leading: Icon(
                                  _alunoId == a.id
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                ),
                                title: Text(a.nome),
                                subtitle: Text('matrícula ${a.matricula}'),
                                onTap: () => _onAlunoChanged(a.id),
                              ),
                          ],
                        ),
                ),
                if (_carregandoAluno)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                const SectionHeader('Prévia'),
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
                      ? '${variacao.ordemQuestoes.length} questões embaralhadas'
                      : null,
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
                                          'Código copiado. Use "Digitar código" na correção.',
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
                  rotuloImprimir:
                      'PDF da turma inteira (${_alunos.length} alunos)',
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
                borderRadius: BorderRadius.circular(12),
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
