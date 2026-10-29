import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/features/geracao/domain/qr_payload.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Correção via QR + entrada manual das respostas (N2).
/// OCR das marcações fica para N3.
class CorrigirProvaPage extends ConsumerStatefulWidget {
  const CorrigirProvaPage({super.key});

  @override
  ConsumerState<CorrigirProvaPage> createState() => _CorrigirProvaPageState();
}

class _FolhaIdentificada {
  const _FolhaIdentificada({
    required this.prova,
    required this.variacao,
    this.aluno,
  });

  final Prova prova;
  final VariacaoDeProva variacao;
  final Aluno? aluno;
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
  Map<String, Questao> _questoes = <String, Questao>{};

  /// Índice da alternativa (0–3) por posição na variação; null = sem resposta.
  List<int?> _respostas = <int?>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processando || _folha != null) {
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
        _falhar(
          'Folha geral da prova "${prova.titulo}". Ela não identifica o '
          'aluno — para a correção, imprima as folhas individuais '
          'em Provas → Gerar → Individualização.',
        );
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
      if (variacao == null) {
        _falhar('A versão da prova deste QR Code não foi encontrada.');
        return;
      }
      final VariacaoDeProva encontrada = variacao;

      final Aluno? aluno =
          await ref.read(alunoRepositoryProvider).getById(qr.alunoId!);

      final Map<String, Questao> questoes = <String, Questao>{};
      for (final String qid in encontrada.ordemQuestoes) {
        final Questao? q =
            await ref.read(questaoRepositoryProvider).getById(qid);
        if (q != null) {
          questoes[qid] = q;
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _folha = _FolhaIdentificada(
          prova: prova,
          variacao: encontrada,
          aluno: aluno,
        );
        _questoes = questoes;
        _respostas = List<int?>.filled(encontrada.ordemQuestoes.length, null);
        _processando = false;
      });
    } catch (e) {
      _falhar('Erro ao identificar a folha: $e');
    }
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
      _erro = null;
      _processando = false;
      _questoes = <String, Questao>{};
      _respostas = <int?>[];
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

  bool get _todasRespondidas =>
      _respostas.isNotEmpty && _respostas.every((int? r) => r != null);

  Future<void> _corrigir() async {
    final _FolhaIdentificada? folha = _folha;
    if (folha == null || !_todasRespondidas) {
      return;
    }
    final String? professorId = ref.read(authSessionProvider)?.id;
    if (professorId == null) {
      showSuccessSnackBar(context, 'Sessão inválida. Faça login novamente.');
      return;
    }
    setState(() => _corrigindo = true);
    try {
      final Correcao correcao =
          await ref.read(correcaoRepositoryProvider).corrigir(
                variacaoId: folha.variacao.id,
                alunoId: folha.variacao.alunoId,
                professorId: professorId,
                respostas: _respostas.cast<int>(),
              );
      ref.read(listVersionProvider.notifier).bump();
      if (!mounted) {
        return;
      }
      setState(() => _corrigindo = false);
      await context.push('/mais/correcao/resultado/${correcao.id}');
    } catch (e) {
      if (mounted) {
        setState(() => _corrigindo = false);
        showSuccessSnackBar(context, 'Erro ao corrigir: $e');
      }
    }
  }

  Future<void> _digitarCodigo() async {
    final TextEditingController campo = TextEditingController();
    final String? codigo = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Digitar código da folha'),
        content: TextField(
          key: const Key('input-codigo-qr'),
          controller: campo,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Código do QR',
            hintText: 'CPROVA|v1|p=...',
            helperText: 'Use quando a câmera não estiver disponível.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(campo.text),
            child: const Text('Identificar'),
          ),
        ],
      ),
    );
    campo.dispose();
    if (codigo != null && codigo.trim().isNotEmpty) {
      await _processarCodigo(codigo.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final _FolhaIdentificada? folha = _folha;

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
          if (_cameraSuportada && folha == null)
            IconButton(
              tooltip: 'Lanterna',
              onPressed: () => _controller.toggleTorch(),
              icon: const Icon(Icons.flashlight_on_outlined),
            ),
        ],
      ),
      body: folha == null
          ? _buildScanner()
          : _buildEntradaRespostas(folha),
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
                          Icon(Icons.check_circle, color: colors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Folha identificada',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
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
                      const SizedBox(height: 8),
                      Text(
                        'Informe a alternativa marcada em cada questão '
                        '(ordem desta variação).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < ordem.length; i++) ...<Widget>[
                _QuestaoRespostaCard(
                  indice: i,
                  questao: _questoes[ordem[i]],
                  questaoId: ordem[i],
                  ordemAlternativas:
                      folha.variacao.ordemAlternativas[ordem[i]] ??
                          const <int>[0, 1, 2, 3],
                  selecionada: _respostas[i],
                  letras: _letras,
                  onSelect: (int alt) {
                    setState(() => _respostas[i] = alt);
                  },
                ),
                const SizedBox(height: 10),
              ],
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
                FilledButton.icon(
                  key: const Key('btn-corrigir-folha'),
                  onPressed:
                      _corrigindo || !_todasRespondidas ? null : _corrigir,
                  icon: Icon(_corrigindo
                      ? Icons.hourglass_bottom
                      : Icons.fact_check_outlined),
                  label: Text(_corrigindo
                      ? 'Corrigindo...'
                      : 'Corrigir com respostas informadas'),
                ),
                if (!_todasRespondidas)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Selecione A–D em todas as questões.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.error),
                      textAlign: TextAlign.center,
                    ),
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

class _QuestaoRespostaCard extends StatelessWidget {
  const _QuestaoRespostaCard({
    required this.indice,
    required this.questao,
    required this.questaoId,
    required this.ordemAlternativas,
    required this.selecionada,
    required this.letras,
    required this.onSelect,
  });

  final int indice;
  final Questao? questao;
  final String questaoId;
  final List<int> ordemAlternativas;
  final int? selecionada;
  final List<String> letras;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<String> alts = questao?.alternativas ?? <String>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Questão ${indice + 1}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              questao?.enunciado ?? questaoId,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (int slot = 0; slot < 4; slot++)
                  ChoiceChip(
                    key: Key('chip-q$indice-alt$slot'),
                    selected: selecionada == slot,
                    label: Text(
                      alts.isEmpty || slot >= ordemAlternativas.length
                          ? letras[slot]
                          : '${letras[slot]}) ${_textoAlt(alts, ordemAlternativas, slot)}',
                    ),
                    onSelected: (_) => onSelect(slot),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _textoAlt(List<String> alts, List<int> ordem, int slot) {
    final int original = slot < ordem.length ? ordem[slot] : slot;
    if (original < 0 || original >= alts.length) {
      return '';
    }
    final String t = alts[original];
    return t.length > 28 ? '${t.substring(0, 28)}…' : t;
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
      borderRadius: BorderRadius.circular(24),
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
                  borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(14),
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
