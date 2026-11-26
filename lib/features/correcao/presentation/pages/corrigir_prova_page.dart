import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/theme/app_semantic_colors.dart';
import 'package:meu_app/core/widgets/confirm_delete_dialog.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/core/widgets/text_input_dialog.dart';
import 'package:meu_app/features/correcao/domain/leitor_omr.dart';
import 'package:meu_app/features/geracao/domain/layout_folha.dart';
import 'package:meu_app/features/geracao/domain/qr_payload.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Correção pela leitura do QR Code da folha de respostas (item 8 da N3).
///
/// 1. A câmera lê o QR e identifica prova, variação e aluno. Na folha
///    **geral** (QR só com a prova) o professor escolhe o aluno.
/// 2. O professor fotografa a folha e a leitura óptica (OMR) preenche as
///    respostas; o que ficou em branco ou em dúvida aparece destacado. Dá
///    para ajustar tocando nas bolhas (ou marcar tudo à mão).
/// 3. A nota é calculada, salva no banco e exibida.
class CorrigirProvaPage extends ConsumerStatefulWidget {
  const CorrigirProvaPage({super.key});

  @override
  ConsumerState<CorrigirProvaPage> createState() => _CorrigirProvaPageState();
}

class _FolhaIdentificada {
  const _FolhaIdentificada({
    required this.prova,
    required this.variacao,
    required this.geral,
    this.aluno,
    this.anterior,
  });

  final Prova prova;
  final VariacaoDeProva variacao;
  final Aluno? aluno;

  /// `true` quando a folha lida é a geral (ordem original da prova).
  final bool geral;

  /// Correção já salva deste aluno nesta prova — corrigir de novo substitui.
  final Correcao? anterior;
}

/// Folha geral lida: falta escolher de qual aluno ela é.
class _EscolhaDeAluno {
  const _EscolhaDeAluno({
    required this.prova,
    required this.alunos,
    required this.notas,
  });

  final Prova prova;
  final List<Aluno> alunos;

  /// Nota já salva por aluno nesta prova.
  final Map<String, double> notas;
}

class _CorrigirProvaPageState extends ConsumerState<CorrigirProvaPage> {
  static bool get _cameraSuportada =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static const List<String> _letras = <String>['A', 'B', 'C', 'D'];

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  bool _processando = false;
  bool _corrigindo = false;
  String? _erro;
  _FolhaIdentificada? _folha;
  _EscolhaDeAluno? _escolha;
  Map<String, Questao> _questoes = <String, Questao>{};

  /// Índice da alternativa (0–3) por posição na folha; null = sem resposta.
  List<int?> _respostas = <int?>[];

  /// Como a leitura óptica viu cada questão (null = não houve leitura).
  List<SituacaoLeitura>? _leitura;
  bool _lendoFoto = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processando || _folha != null || _escolha != null) {
      return;
    }
    for (final Barcode barcode in capture.barcodes) {
      final String? valor = barcode.rawValue;
      if (valor != null && valor.isNotEmpty) {
        _processarCodigo(valor);
        return;
      }
    }
  }

  Future<void> _processarCodigo(String raw) async {
    setState(() {
      _processando = true;
      _erro = null;
    });
    await _pararCamera();

    try {
      final QrPayload? qr = QrPayload.decode(raw);
      if (qr == null) {
        _falhar(
            'QR Code não reconhecido. Use uma folha de respostas gerada pelo app.');
        return;
      }

      final Prova? prova =
          await ref.read(provaRepositoryProvider).getById(qr.provaId);
      if (prova == null) {
        _falhar('A prova deste QR Code não foi encontrada.');
        return;
      }

      if (!qr.individual) {
        await _pedirAluno(prova);
        return;
      }

      final List<VariacaoDeProva> variacoes =
          await ref.read(provaRepositoryProvider).listVariacoes(prova.id);
      VariacaoDeProva? variacao;
      for (final VariacaoDeProva v in variacoes) {
        if (v.id == qr.variacaoId) {
          variacao = v;
          break;
        }
      }
      if (variacao == null || variacao.alunoId != qr.alunoId) {
        _falhar(
          'Esta folha não vale mais: a prova "${prova.titulo}" foi gerada '
          'de novo para este aluno. Imprima a folha atual em '
          'Provas → Imprimir / PDF.',
        );
        return;
      }
      await _abrirFolha(prova, variacao, geral: false);
    } catch (e) {
      _falhar('Erro ao identificar a folha: $e');
    }
  }

  /// Folha geral: lista os alunos da turma para o professor escolher.
  Future<void> _pedirAluno(Prova prova) async {
    if (prova.turmaId.isEmpty) {
      _falhar(
        'A prova "${prova.titulo}" não tem turma. Vincule uma turma no '
        'detalhe da prova para corrigir.',
      );
      return;
    }
    final List<Aluno> alunos =
        await ref.read(alunoRepositoryProvider).listByTurma(prova.turmaId);
    if (alunos.isEmpty) {
      _falhar('A turma desta prova ainda não tem alunos.');
      return;
    }
    alunos.sort((Aluno a, Aluno b) =>
        a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    final Map<String, double> notas = await _notasDaProva(prova);
    if (!mounted) {
      return;
    }
    setState(() {
      _escolha = _EscolhaDeAluno(prova: prova, alunos: alunos, notas: notas);
      _processando = false;
    });
  }

  Future<Map<String, double>> _notasDaProva(Prova prova) async {
    final Set<String> variacoes = (await ref
            .read(provaRepositoryProvider)
            .listVariacoes(prova.id))
        .map((VariacaoDeProva v) => v.id)
        .toSet();
    return <String, double>{
      for (final Correcao c
          in await ref.read(correcaoRepositoryProvider).listAll())
        if (c.provaId == prova.id || variacoes.contains(c.variacaoId))
          c.alunoId: c.nota,
    };
  }

  Future<void> _escolherAluno(Prova prova, Aluno aluno) async {
    final List<VariacaoDeProva> doAluno = (await ref
            .read(provaRepositoryProvider)
            .listVariacoes(prova.id))
        .where((VariacaoDeProva v) => v.alunoId == aluno.id)
        .toList();
    final bool temIndividual = doAluno.any(
      (VariacaoDeProva v) => !v.emOrdemOriginal(prova),
    );
    if (temIndividual) {
      if (!mounted) {
        return;
      }
      final bool ok = await showConfirmDeleteDialog(
        context: context,
        title: 'Corrigir pela folha geral?',
        message: '${aluno.nome} tem uma folha individual embaralhada. Se ele '
            'respondeu a folha geral, continue: a folha individual dele deixa '
            'de valer na correção.',
        confirmLabel: 'Continuar',
      );
      if (!ok) {
        return;
      }
    }
    setState(() => _processando = true);
    try {
      final VariacaoDeProva variacao = await ref
          .read(provaRepositoryProvider)
          .variacaoFolhaGeral(provaId: prova.id, alunoId: aluno.id);
      await _abrirFolha(prova, variacao, geral: true, aluno: aluno);
    } catch (e) {
      _falhar('Erro ao preparar a folha: $e');
    }
  }

  /// Carrega as questões e mostra a grade de respostas da folha.
  Future<void> _abrirFolha(
    Prova prova,
    VariacaoDeProva variacao, {
    required bool geral,
    Aluno? aluno,
  }) async {
    final Aluno? doAluno =
        aluno ?? await ref.read(alunoRepositoryProvider).getById(variacao.alunoId);

    Correcao? anterior;
    for (final Correcao c
        in await ref.read(correcaoRepositoryProvider).listAll()) {
      if (c.alunoId == variacao.alunoId &&
          (c.variacaoId == variacao.id || c.provaId == prova.id)) {
        anterior = c;
        if (c.variacaoId == variacao.id) {
          break;
        }
      }
    }

    final Map<String, Questao> questoes = <String, Questao>{};
    for (final String qid in variacao.ordemQuestoes) {
      final Questao? q = await ref.read(questaoRepositoryProvider).getById(qid);
      if (q != null) {
        questoes[qid] = q;
      }
    }

    if (!mounted) {
      return;
    }
    final bool mesmaFolha = anterior?.variacaoId == variacao.id;
    setState(() {
      _escolha = null;
      _folha = _FolhaIdentificada(
        prova: prova,
        variacao: variacao,
        geral: geral,
        aluno: doAluno,
        anterior: anterior,
      );
      _questoes = questoes;
      _leitura = null;
      _respostas = List<int?>.generate(
        variacao.ordemQuestoes.length,
        (int i) => mesmaFolha &&
                i < anterior!.respostas.length &&
                anterior.respostas[i] >= 0
            ? anterior.respostas[i]
            : null,
      );
      _processando = false;
    });
  }

  void _falhar(String mensagem) {
    if (!mounted) {
      return;
    }
    setState(() {
      _erro = mensagem;
      _processando = false;
    });
  }

  Future<void> _lerOutra() async {
    setState(() {
      _folha = null;
      _escolha = null;
      _erro = null;
      _processando = false;
      _questoes = <String, Questao>{};
      _respostas = <int?>[];
      _leitura = null;
    });
    await _iniciarCamera();
  }

  Future<void> _pararCamera() async {
    if (!_cameraSuportada) {
      return;
    }
    try {
      await _controller.stop();
    } catch (_) {}
  }

  Future<void> _iniciarCamera() async {
    if (!_cameraSuportada) {
      return;
    }
    try {
      await _controller.start();
    } catch (_) {}
  }

  int get _respondidas => _respostas.where((int? r) => r != null).length;

  bool get _todasRespondidas =>
      _respostas.isNotEmpty && _respondidas == _respostas.length;

  Future<void> _corrigir() async {
    final _FolhaIdentificada? folha = _folha;
    if (folha == null || _respostas.isEmpty) {
      return;
    }
    final int semResposta = _respostas.length - _respondidas;
    if (semResposta > 0) {
      final bool ok = await showConfirmDeleteDialog(
        context: context,
        title: 'Salvar com questões em branco?',
        message: '$semResposta questão(ões) sem alternativa marcada contam '
            'como erradas (em branco ou com mais de uma marcação).',
        confirmLabel: 'Salvar nota',
      );
      if (!ok || !mounted) {
        return;
      }
    }
    final String? professorId = ref.read(authSessionProvider)?.id;
    if (professorId == null) {
      showErrorSnackBar(context, 'Sessão inválida. Faça login novamente.');
      return;
    }
    setState(() => _corrigindo = true);
    try {
      final Correcao correcao =
          await ref.read(correcaoRepositoryProvider).corrigir(
                variacaoId: folha.variacao.id,
                alunoId: folha.variacao.alunoId,
                professorId: professorId,
                respostas: <int>[
                  for (final int? r in _respostas) r ?? Correcao.emBranco,
                ],
              );
      ref.read(listVersionProvider.notifier).bump();
      if (!mounted) {
        return;
      }
      setState(() => _corrigindo = false);
      await context.push('/mais/correcao/resultado/${correcao.id}');
      // Voltou do resultado: já deixa o leitor pronto para a próxima folha.
      if (mounted) {
        await _lerOutra();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _corrigindo = false);
        showErrorSnackBar(context, 'Erro ao corrigir: $e');
      }
    }
  }

  static bool get _temCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Fotografa a folha e preenche as respostas pela leitura óptica.
  Future<void> _lerMarcacoes() async {
    final _FolhaIdentificada? folha = _folha;
    if (folha == null || _lendoFoto) {
      return;
    }
    ImageSource origem = ImageSource.gallery;
    if (_temCamera) {
      final ImageSource? escolhida = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                key: const Key('opcao-tirar-foto'),
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar foto da folha'),
                subtitle: const Text(
                    'De frente, com os 4 quadrados pretos aparecendo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                key: const Key('opcao-galeria'),
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher foto da galeria'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (escolhida == null) {
        return;
      }
      origem = escolhida;
    }

    setState(() => _lendoFoto = true);
    try {
      final XFile? foto = await ImagePicker().pickImage(
        source: origem,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
      if (foto == null) {
        return;
      }
      final LeituraOmr leitura = await compute(
        lerFolhaDeBytes,
        (
          bytes: await foto.readAsBytes(),
          totalQuestoes: folha.variacao.ordemQuestoes.length,
        ),
      );
      if (!mounted || _folha != folha) {
        return;
      }
      setState(() {
        _respostas = List<int?>.from(leitura.respostas);
        _leitura = List<SituacaoLeitura>.from(leitura.situacoes);
      });
      final int conferir = leitura.emBranco + leitura.emDuvida;
      showSuccessSnackBar(
        context,
        conferir == 0
            ? '${leitura.lidas} respostas lidas. Confira e salve a nota.'
            : '${leitura.lidas} respostas lidas; $conferir para conferir '
                '(destacadas).',
      );
    } on FalhaLeituraOmr catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e.mensagem);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Não foi possível ler a foto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _lendoFoto = false);
      }
    }
  }

  Future<void> _digitarCodigo() async {
    final String? codigo = await showTextInputDialog(
      context: context,
      title: 'Digitar código da folha',
      label: 'Código do QR',
      hintText: 'CPROVA|v1|p=...',
      helperText: 'Use quando a câmera não estiver disponível.',
      confirmLabel: 'Identificar',
      fieldKey: const Key('input-codigo-qr'),
      confirmKey: const Key('btn-identificar-codigo'),
    );
    if (codigo != null && codigo.trim().isNotEmpty) {
      await _processarCodigo(codigo.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final _FolhaIdentificada? folha = _folha;
    final _EscolhaDeAluno? escolha = _escolha;

    final Widget corpo;
    if (folha != null) {
      corpo = _buildEntradaRespostas(folha);
    } else if (escolha != null) {
      corpo = _buildEscolhaAluno(escolha);
    } else {
      corpo = _buildScanner();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corrigir prova'),
        actions: <Widget>[
          IconButton(
            key: const Key('btn-ir-resultados'),
            tooltip: 'Resultados',
            onPressed: () => context.push('/mais/resultados'),
            icon: const Icon(Icons.bar_chart_outlined),
          ),
          if (_cameraSuportada && folha == null && escolha == null)
            IconButton(
              tooltip: 'Lanterna',
              onPressed: () => _controller.toggleTorch(),
              icon: const Icon(Icons.flashlight_on_outlined),
            ),
        ],
      ),
      body: corpo,
    );
  }

  Widget _buildScanner() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Expanded(
            child: _AreaCamera(
              controller: _controller,
              cameraSuportada: _cameraSuportada,
              processando: _processando,
              erro: _erro,
              onDetect: _onDetect,
            ),
          ),
          const SizedBox(height: 16),
          if (_erro != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('btn-tentar-novamente'),
                onPressed: _lerOutra,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ),
          TextButton.icon(
            key: const Key('btn-digitar-codigo'),
            onPressed: _processando ? null : _digitarCodigo,
            icon: const Icon(Icons.keyboard_outlined),
            label: const Text('Digitar código'),
          ),
        ],
      ),
    );
  }

  Widget _buildEscolhaAluno(_EscolhaDeAluno escolha) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(Icons.qr_code_2, color: colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Folha geral lida',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(escolha.prova.titulo,
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Esta folha não traz o aluno no QR. Toque no nome '
                        'escrito na folha.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < escolha.alunos.length; i++) ...<Widget>[
                      if (i > 0)
                        Divider(height: 1, color: colors.outlineVariant),
                      _linhaAluno(escolha, escolha.alunos[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('btn-cancelar-escolha'),
              onPressed: _processando ? null : _lerOutra,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Ler outra folha'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _linhaAluno(_EscolhaDeAluno escolha, Aluno aluno) {
    final double? nota = escolha.notas[aluno.id];
    return ListTile(
      key: Key('escolher-aluno-${aluno.id}'),
      enabled: !_processando,
      leading: Icon(
        nota == null ? Icons.person_outline : Icons.check_circle,
        color: nota == null ? null : context.semantic.success,
      ),
      title: Text(aluno.nome),
      subtitle: Text(
        nota == null
            ? 'matrícula ${aluno.matricula}'
            : 'matrícula ${aluno.matricula} · já corrigido (nota '
                '${nota.toStringAsFixed(1)})',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _escolherAluno(escolha.prova, aluno),
    );
  }

  Widget _buildEntradaRespostas(_FolhaIdentificada folha) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Aluno? aluno = folha.aluno;
    final List<String> ordem = folha.variacao.ordemQuestoes;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(Icons.check_circle,
                              color: context.semantic.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              folha.geral
                                  ? 'Folha geral · aluno escolhido'
                                  : 'Folha identificada pelo QR Code',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(folha.prova.titulo,
                          style: theme.textTheme.titleSmall),
                      Text(
                        aluno == null
                            ? 'Aluno id ${folha.variacao.alunoId}'
                            : '${aluno.nome} · matrícula ${aluno.matricula}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (folha.anterior != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Icon(Icons.info, size: 18, color: colors.tertiary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Já corrigida (nota '
                                '${folha.anterior!.nota.toStringAsFixed(1)}). '
                                'Corrigir de novo substitui a nota.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        ordem.length <= LayoutFolha.maxQuestoes
                            ? 'Fotografe a folha para ler as marcações, ou '
                                'toque nas bolhas para marcar à mão.'
                            : 'Toque na alternativa que o aluno marcou em '
                                'cada questão. A leitura pela foto vai até '
                                '${LayoutFolha.maxQuestoes} questões.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (ordem.length <= LayoutFolha.maxQuestoes) ...<Widget>[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('btn-ler-marcacoes'),
                            onPressed: _lendoFoto || _corrigindo
                                ? null
                                : _lerMarcacoes,
                            icon: _lendoFoto
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.document_scanner_outlined),
                            label: Text(_lendoFoto
                                ? 'Lendo marcações...'
                                : _leitura == null
                                    ? 'Ler marcações pela foto'
                                    : 'Ler de novo pela foto'),
                          ),
                        ),
                      ],
                      if (_leitura != null) ...<Widget>[
                        const SizedBox(height: 8),
                        _ResumoLeitura(situacoes: _leitura!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < ordem.length; i++) ...<Widget>[
                        if (i > 0)
                          Divider(height: 1, color: colors.outlineVariant),
                        _LinhaResposta(
                          indice: i,
                          questao: _questoes[ordem[i]],
                          ordemAlternativas:
                              folha.variacao.ordemAlternativas[ordem[i]] ??
                                  const <int>[0, 1, 2, 3],
                          selecionada: _respostas[i],
                          leitura: _leitura?[i],
                          letras: _letras,
                          onSelect: _corrigindo
                              ? null
                              : (int alt) => setState(() {
                                    // Tocar de novo na marcada limpa.
                                    _respostas[i] =
                                        _respostas[i] == alt ? null : alt;
                                    if (_leitura != null) {
                                      _leitura![i] = SituacaoLeitura.marcada;
                                    }
                                  }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: _respostas.isEmpty
                        ? 0
                        : _respondidas / _respostas.length,
                    minHeight: 6,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _todasRespondidas
                      ? 'Todas as ${_respostas.length} questões marcadas.'
                      : '$_respondidas de ${_respostas.length} questões '
                          'marcadas · sem marcação conta como erro',
                  key: const Key('contador-respondidas'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _todasRespondidas
                        ? colors.onSurfaceVariant
                        : colors.error,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const Key('btn-corrigir-folha'),
                  onPressed: _corrigindo || _lendoFoto || _respondidas == 0
                      ? null
                      : _corrigir,
                  icon: Icon(_corrigindo
                      ? Icons.hourglass_bottom
                      : Icons.fact_check_outlined),
                  label: Text(
                      _corrigindo ? 'Salvando nota...' : 'Corrigir e salvar nota'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('btn-ler-outra'),
                  onPressed: _corrigindo ? null : _lerOutra,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Ler outra folha'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Uma linha da folha de respostas: número, bolhas A–D e o enunciado.
class _LinhaResposta extends StatelessWidget {
  const _LinhaResposta({
    required this.indice,
    required this.questao,
    required this.ordemAlternativas,
    required this.selecionada,
    required this.letras,
    required this.onSelect,
    this.leitura,
  });

  final int indice;
  final Questao? questao;
  final List<int> ordemAlternativas;
  final int? selecionada;

  /// Situação vista pela leitura óptica; em branco ou em dúvida destaca.
  final SituacaoLeitura? leitura;
  final List<String> letras;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<String> alts = questao?.alternativas ?? <String>[];
    final String? aviso = switch (leitura) {
      SituacaoLeitura.emBranco => 'Em branco na foto: confira',
      SituacaoLeitura.duvida => 'Mais de uma marcação: confira',
      _ => null,
    };

    return Container(
      key: Key('linha-resposta-$indice'),
      color: aviso == null ? null : colors.tertiaryContainer,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (aviso != null)
            Padding(
              padding: const EdgeInsets.only(left: 34, bottom: 4),
              child: Text(
                aviso,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Row(
            children: <Widget>[
              SizedBox(
                width: 34,
                child: Text(
                  '${indice + 1}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (int slot = 0; slot < 4; slot++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Tooltip(
                    message: _textoAlt(alts, slot),
                    child: _Bolha(
                      key: Key('chip-q$indice-alt$slot'),
                      letra: letras[slot],
                      marcada: selecionada == slot,
                      onTap: onSelect == null ? null : () => onSelect!(slot),
                    ),
                  ),
                ),
            ],
          ),
          if (questao != null)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 4),
              child: Text(
                questao!.enunciado,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  String _textoAlt(List<String> alts, int slot) {
    final int original =
        slot < ordemAlternativas.length ? ordemAlternativas[slot] : slot;
    if (original < 0 || original >= alts.length) {
      return letras[slot];
    }
    return '${letras[slot]}) ${alts[original]}';
  }
}

/// Bolha A–D tocável, no formato do círculo impresso na folha.
class _Bolha extends StatelessWidget {
  const _Bolha({
    super.key,
    required this.letra,
    required this.marcada,
    required this.onTap,
  });

  final String letra;
  final bool marcada;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: marcada,
      label: 'Alternativa $letra',
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: marcada ? colors.primary : colors.surface,
            border: Border.all(
              color: marcada ? colors.primary : colors.outline,
              width: 1.5,
            ),
          ),
          child: Text(
            letra,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: marcada ? colors.onPrimary : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaCamera extends StatelessWidget {
  const _AreaCamera({
    required this.controller,
    required this.cameraSuportada,
    required this.processando,
    required this.erro,
    required this.onDetect,
  });

  final MobileScannerController controller;
  final bool cameraSuportada;
  final bool processando;
  final String? erro;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final String mensagem = erro ??
        (processando
            ? 'Identificando folha...'
            : cameraSuportada
                ? 'Aponte a câmera para o QR Code da folha de respostas'
                : 'Câmera indisponível nesta plataforma. Use "Digitar código".');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (cameraSuportada)
              MobileScanner(
                controller: controller,
                onDetect: onDetect,
              )
            else
              Container(color: colors.surfaceContainerLowest),
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: erro != null ? colors.error : colors.primary,
                    width: 3,
                  ),
                ),
                child: processando
                    ? const Center(child: CircularProgressIndicator())
                    : null,
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: erro != null
                      ? colors.errorContainer
                      : Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  mensagem,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: erro != null
                        ? colors.onErrorContainer
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resumo da leitura óptica: quantas lidas e quantas para conferir.
class _ResumoLeitura extends StatelessWidget {
  const _ResumoLeitura({required this.situacoes});

  final List<SituacaoLeitura> situacoes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    int lidas = 0;
    int conferir = 0;
    for (final SituacaoLeitura s in situacoes) {
      if (s == SituacaoLeitura.marcada) {
        lidas++;
      } else {
        conferir++;
      }
    }
    return Row(
      key: const Key('resumo-leitura'),
      children: <Widget>[
        Icon(
          conferir == 0 ? Icons.check_circle : Icons.info_outline,
          size: 18,
          color: conferir == 0 ? context.semantic.success : colors.tertiary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            conferir == 0
                ? 'Leitura pela foto: $lidas de ${situacoes.length} lidas.'
                : 'Leitura pela foto: $lidas lidas, $conferir para conferir '
                    '(em destaque).',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
