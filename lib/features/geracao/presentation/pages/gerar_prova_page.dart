import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/info_card.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/features/geracao/data/prova_pdf_service.dart';
import 'package:meu_app/features/geracao/domain/qr_payload.dart';
import 'package:meu_app/features/geracao/presentation/widgets/pdf_acoes.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Hub único de impressão: prova geral, folha geral e atalho individual/turma.
class GerarProvaPage extends ConsumerStatefulWidget {
  const GerarProvaPage({super.key, required this.provaId});

  final String provaId;

  @override
  ConsumerState<GerarProvaPage> createState() => _GerarProvaPageState();
}

class _GerarProvaPageState extends ConsumerState<GerarProvaPage> {
  Prova? _prova;
  List<Questao> _questoes = <Questao>[];
  Map<String, Questao> _banco = <String, Questao>{};
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
    final Map<String, Questao> map = <String, Questao>{
      for (final Questao q in todas) q.id: q,
    };
    _prova = prova;
    _banco = map;
    _questoes = (prova?.questaoIds ?? <String>[])
        .map((String id) => map[id])
        .whereType<Questao>()
        .toList();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['A', 'B', 'C', 'D'];
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final String qrGeral = QrPayload(provaId: widget.provaId).encode();

    return Scaffold(
      appBar: AppBar(title: const Text('Imprimir / PDF')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                InfoCard(
                  icon: Icons.print_outlined,
                  title: _prova?.titulo ?? '',
                  subtitle:
                      '${_questoes.length} questões · PDF geral, folha ou por aluno',
                ),
                const SectionHeader('1. Prova + folha (versão geral)'),
                ...List<Widget>.generate(
                  _questoes.length.clamp(0, 3),
                  (int index) {
                    final Questao q = _questoes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          '${index + 1}. ${q.enunciado}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          labels
                              .asMap()
                              .entries
                              .map((MapEntry<int, String> e) =>
                                  '${e.value}) ${q.alternativas[e.key]}')
                              .join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ),
                    );
                  },
                ),
                if (_questoes.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '+ ${_questoes.length - 3} questão(ões) no PDF completo',
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                PdfAcoes(
                  nomeArquivo: _prova?.titulo ?? 'prova',
                  rotuloImprimir: 'Imprimir prova + folha (PDF)',
                  habilitado: _prova != null && _questoes.isNotEmpty,
                  gerar: () => const ProvaPdfService().gerar(
                    prova: _prova!,
                    copias: <CopiaProva>[
                      CopiaProva.geral(prova: _prova!, banco: _banco),
                    ],
                  ),
                ),
                const SectionHeader('2. Só folha de respostas (geral)'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Cartão A–D com QR da prova (sem aluno).',
                            style: text.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          color: Colors.white,
                          child: QrImageView(data: qrGeral, size: 72),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PdfAcoes(
                  nomeArquivo: 'folha_${_prova?.titulo ?? 'prova'}',
                  rotuloImprimir: 'Imprimir folha de respostas (PDF)',
                  habilitado: _prova != null && _questoes.isNotEmpty,
                  gerar: () => const ProvaPdfService().gerar(
                    prova: _prova!,
                    incluirProva: false,
                    copias: <CopiaProva>[
                      CopiaProva.geral(prova: _prova!, banco: _banco),
                    ],
                  ),
                ),
                const SectionHeader('3. Por aluno / turma inteira'),
                Text(
                  'PDF com variação e QR individual (p + v + a).',
                  style: text.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('btn-abrir-individualizacao'),
                  onPressed: () => context.push(
                    '/provas/${widget.provaId}/individualizacao',
                  ),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Escolher aluno e imprimir'),
                ),
              ],
            ),
    );
  }
}
