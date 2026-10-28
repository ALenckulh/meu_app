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
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Correção via câmera (RF06 — parte 1).
///
/// 1. A câmera lê o QR Code da folha de respostas individual.
/// 2. O app identifica a prova, a variação e o aluno pelo QR.
/// 3. A leitura das marcações ainda é simulada (próxima etapa: OMR).
class CorrigirProvaPage extends ConsumerStatefulWidget {
  const CorrigirProvaPage({super.key});

  @override
  ConsumerState<CorrigirProvaPage> createState() => _CorrigirProvaPageState();
}

/// Folha reconhecida a partir do QR.
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
  /// Plataformas em que o mobile_scanner tem câmera disponível.
  static bool get _cameraSuportada =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  bool _processando = false;
  bool _corrigindo = false;
  String? _erro;
  _FolhaIdentificada? _folha;

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
        _falhar('QR Code não reconhecido. Use uma folha de respostas gerada pelo app.');
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
          'aluno — para a correção automática, imprima as folhas individuais '
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

      if (!mounted) {
        return;
      }
      setState(() {
        _folha = _FolhaIdentificada(
          prova: prova,
          variacao: encontrada,
          aluno: aluno,
        );
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
    });
    await _iniciarCamera();
  }

  Future<void> _pararCamera() async {
    if (!_cameraSuportada) {
      return;
    }
    try {
      await _controller.stop();
    } catch (_) {
      // Câmera já parada ou sem permissão: nada a fazer.
    }
  }

  Future<void> _iniciarCamera() async {
    if (!_cameraSuportada) {
      return;
    }
    try {
      await _controller.start();
    } catch (_) {
      // Já iniciada ou sem permissão: o widget mostra o erro.
    }
  }

  Future<void> _corrigir() async {
    final _FolhaIdentificada? folha = _folha;
    if (folha == null) {
      return;
    }
    setState(() => _corrigindo = true);
    try {
      // Leitura das marcações ainda simulada — o QR já é real.
      final Correcao correcao =
          await ref.read(correcaoRepositoryProvider).simularLeitura(
                variacaoId: folha.variacao.id,
                alunoId: folha.variacao.alunoId,
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
          if (_cameraSuportada && folha == null)
            IconButton(
              tooltip: 'Lanterna',
              onPressed: () => _controller.toggleTorch(),
              icon: const Icon(Icons.flashlight_on_outlined),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Expanded(
              // A câmera fica sempre na árvore (só é pausada) para não
              // reinicializar o scanner a cada leitura.
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _AreaCamera(
                    controller: _controller,
                    cameraSuportada: _cameraSuportada,
                    processando: _processando,
                    erro: _erro,
                    onDetect: _onDetect,
                  ),
                  if (folha != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: _FolhaCard(folha: folha),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (folha != null) ...<Widget>[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('btn-corrigir-folha'),
                  onPressed: _corrigindo ? null : _corrigir,
                  icon: Icon(_corrigindo
                      ? Icons.hourglass_bottom
                      : Icons.fact_check_outlined),
                  label: Text(_corrigindo
                      ? 'Corrigindo...'
                      : 'Ler marcações e corrigir (simulado)'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('btn-ler-outra'),
                  onPressed: _corrigindo ? null : _lerOutra,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Ler outra folha'),
                ),
              ),
            ] else ...<Widget>[
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
          ],
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
            // Moldura de mira.
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

class _FolhaCard extends StatelessWidget {
  const _FolhaCard({required this.folha});

  final _FolhaIdentificada folha;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Aluno? aluno = folha.aluno;

    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 16),
              _Linha(
                icone: Icons.description_outlined,
                rotulo: 'Prova',
                valor: folha.prova.titulo,
              ),
              _Linha(
                icone: Icons.person_outline,
                rotulo: 'Aluno',
                valor: aluno == null
                    ? 'Aluno não encontrado (id ${folha.variacao.alunoId})'
                    : '${aluno.nome} · matrícula ${aluno.matricula}',
              ),
              _Linha(
                icone: Icons.shuffle,
                rotulo: 'Versão',
                valor:
                    '${folha.variacao.ordemQuestoes.length} questões embaralhadas',
              ),
              const SizedBox(height: 8),
              Text(
                'O QR Code foi lido pela câmera. A leitura das marcações '
                'ainda é simulada nesta versão.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icone, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(rotulo, style: theme.textTheme.labelMedium),
                Text(valor, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
