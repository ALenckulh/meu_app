import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/features/geracao/data/prova_pdf_service.dart';
import 'package:meu_app/features/geracao/domain/qr_payload.dart';
import 'package:meu_app/features/geracao/presentation/widgets/pdf_acoes.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FolhaRespostasPage extends ConsumerStatefulWidget {
  const FolhaRespostasPage({super.key, required this.provaId});

  final String provaId;

  @override
  ConsumerState<FolhaRespostasPage> createState() =>
      _FolhaRespostasPageState();
}

class _FolhaRespostasPageState extends ConsumerState<FolhaRespostasPage> {
  Prova? _prova;
  Map<String, Questao> _banco = <String, Questao>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prova = await ref.read(provaRepositoryProvider).getById(widget.provaId);
    final List<Questao> todas =
        await ref.read(questaoRepositoryProvider).listAll();
    _banco = <String, Questao>{for (final Questao q in todas) q.id: q};
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['A', 'B', 'C', 'D'];
    // Folha geral: o QR identifica a prova. A folha individual (com aluno e
    // variação no QR) é gerada na tela de Individualização.
    final String qrPayload = QrPayload(provaId: widget.provaId).encode();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final int quantidade = _prova?.questaoIds.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Folha de respostas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(_prova?.titulo ?? '',
                                  style: text.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 16),
                              _FieldLine(label: 'Nome', scheme: scheme, text: text),
                              const SizedBox(height: 14),
                              _FieldLine(label: 'Turma', scheme: scheme, text: text),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: scheme.outline),
                              ),
                              child: QrImageView(data: qrPayload, size: 96),
                            ),
                            const SizedBox(height: 4),
                            Text('Folha geral',
                                style: text.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Esta folha identifica a prova. Para o QR identificar '
                    'também o aluno, gere as folhas em Individualização.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: List<Widget>.generate(quantidade, (int index) {
                      final bool zebra = index.isEven;
                      return Container(
                        color: zebra
                            ? scheme.surfaceContainerLowest
                            : scheme.surfaceContainerLow,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 28,
                              child: Text('${index + 1}',
                                  style: text.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700)),
                            ),
                            ...labels.map(
                              (String label) => Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: scheme.outline, width: 1.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child:
                                      Text(label, style: text.bodyMedium),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                PdfAcoes(
                  nomeArquivo: 'folha_${_prova?.titulo ?? 'prova'}',
                  rotuloImprimir: 'Imprimir folha de respostas (PDF)',
                  habilitado: _prova != null && quantidade > 0,
                  gerar: () => const ProvaPdfService().gerar(
                    prova: _prova!,
                    incluirProva: false,
                    copias: <CopiaProva>[
                      CopiaProva.geral(prova: _prova!, banco: _banco),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _FieldLine extends StatelessWidget {
  const _FieldLine({
    required this.label,
    required this.scheme,
    required this.text,
  });

  final String label;
  final ColorScheme scheme;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label:', style: text.bodySmall),
        Container(
          margin: const EdgeInsets.only(top: 6),
          height: 1,
          color: scheme.outlineVariant,
        ),
      ],
    );
  }
}
