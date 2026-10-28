import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Função que monta os bytes do PDF sob demanda.
typedef GeradorPdf = Future<Uint8List> Function();

/// Botões "Imprimir / salvar PDF" e "Compartilhar" usados nas telas de
/// geração. O PDF só é montado quando o professor toca em um dos botões.
class PdfAcoes extends StatefulWidget {
  const PdfAcoes({
    super.key,
    required this.gerar,
    required this.nomeArquivo,
    this.rotuloImprimir = 'Imprimir / salvar PDF',
    this.habilitado = true,
  });

  final GeradorPdf gerar;

  /// Nome do arquivo sem extensão.
  final String nomeArquivo;
  final String rotuloImprimir;
  final bool habilitado;

  @override
  State<PdfAcoes> createState() => _PdfAcoesState();
}

class _PdfAcoesState extends State<PdfAcoes> {
  bool _gerando = false;

  String get _arquivo => '${_nomeSeguro(widget.nomeArquivo)}.pdf';

  Future<void> _executar({required bool compartilhar}) async {
    setState(() => _gerando = true);
    try {
      final Uint8List bytes = await widget.gerar();
      if (compartilhar) {
        await Printing.sharePdf(bytes: bytes, filename: _arquivo);
      } else {
        await Printing.layoutPdf(
          name: _arquivo,
          onLayout: (PdfPageFormat _) async => bytes,
        );
      }
    } catch (e) {
      if (mounted) {
        showSuccessSnackBar(context, 'Não foi possível gerar o PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _gerando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool ativo = widget.habilitado && !_gerando;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          key: Key('btn-pdf-imprimir-${widget.nomeArquivo}'),
          onPressed: ativo ? () => _executar(compartilhar: false) : null,
          icon: _gerando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print_outlined),
          label: Text(_gerando ? 'Gerando PDF...' : widget.rotuloImprimir),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: Key('btn-pdf-compartilhar-${widget.nomeArquivo}'),
          onPressed: ativo ? () => _executar(compartilhar: true) : null,
          icon: const Icon(Icons.share_outlined),
          label: const Text('Compartilhar PDF'),
        ),
      ],
    );
  }

  static String _nomeSeguro(String nome) {
    final String limpo = nome
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áàâãéêíóôõúç]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return limpo.isEmpty ? 'prova' : limpo;
  }
}
