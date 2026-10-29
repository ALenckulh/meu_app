import 'dart:typed_data';

import 'package:meu_app/features/geracao/domain/qr_payload.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/turma.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Uma cópia da prova a ser impressa: questões já na ordem final, ordem das
/// alternativas e dados de identificação (aluno/turma/QR).
class CopiaProva {
  const CopiaProva({
    required this.questoes,
    required this.ordemAlternativas,
    required this.qr,
    this.aluno,
    this.turma,
  });

  /// Versão geral: ordem original das questões e alternativas, QR só com a
  /// prova.
  factory CopiaProva.geral({
    required Prova prova,
    required Map<String, Questao> banco,
    Turma? turma,
  }) {
    return CopiaProva(
      questoes: prova.questaoIds
          .map((String id) => banco[id])
          .whereType<Questao>()
          .toList(),
      ordemAlternativas: const <String, List<int>>{},
      qr: QrPayload(provaId: prova.id),
      turma: turma,
    );
  }

  /// Versão individual a partir de uma variação embaralhada (RF03/RF04).
  factory CopiaProva.individual({
    required VariacaoDeProva variacao,
    required Map<String, Questao> banco,
    Aluno? aluno,
    Turma? turma,
  }) {
    return CopiaProva(
      questoes: variacao.ordemQuestoes
          .map((String id) => banco[id])
          .whereType<Questao>()
          .toList(),
      ordemAlternativas: variacao.ordemAlternativas,
      qr: QrPayload(
        provaId: variacao.provaId,
        variacaoId: variacao.id,
        alunoId: variacao.alunoId,
      ),
      aluno: aluno,
      turma: turma,
    );
  }

  final List<Questao> questoes;
  final Map<String, List<int>> ordemAlternativas;
  final QrPayload qr;
  final Aluno? aluno;
  final Turma? turma;

  List<int> permutacao(Questao q) {
    final List<int>? perm = ordemAlternativas[q.id];
    if (perm != null && perm.length == q.alternativas.length) {
      return perm;
    }
    return List<int>.generate(q.alternativas.length, (int i) => i);
  }
}

/// Gera os PDFs de prova e folha de respostas (RF02, RF04, RF05).
///
/// Cada questão é um bloco único: se não couber no fim da página, vai
/// inteira para a próxima (enunciado e alternativas não ficam separados).
class ProvaPdfService {
  const ProvaPdfService();

  static const List<String> letras = <String>['A', 'B', 'C', 'D', 'E', 'F'];
  static const int _linhasPorColuna = 22;

  /// Monta um único PDF com todas as [copias] (uma por aluno ou uma geral).
  Future<Uint8List> gerar({
    required Prova prova,
    required List<CopiaProva> copias,
    bool incluirProva = true,
    bool incluirFolha = true,
  }) async {
    final pw.Document doc = pw.Document(
      title: _t(prova.titulo),
      author: 'App de Correção de Provas',
    );

    for (final CopiaProva copia in copias) {
      if (incluirProva) {
        doc.addPage(_paginaProva(prova, copia));
      }
      if (incluirFolha) {
        doc.addPage(_paginaFolha(prova, copia));
      }
    }
    return doc.save();
  }

  // ---------------------------------------------------------------- prova

  pw.MultiPage _paginaProva(Prova prova, CopiaProva copia) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
      footer: (pw.Context context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
      build: (pw.Context context) => <pw.Widget>[
        _cabecalho(prova, copia, titulo: _t(prova.titulo)),
        pw.SizedBox(height: 16),
        ...List<pw.Widget>.generate(copia.questoes.length, (int i) {
          return _blocoQuestao(i, copia.questoes[i], copia);
        }),
      ],
    );
  }

  pw.Widget _blocoQuestao(int indice, Questao questao, CopiaProva copia) {
    final List<int> perm = copia.permutacao(questao);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            '${indice + 1}. ${_t(questao.enunciado)}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...List<pw.Widget>.generate(perm.length, (int j) {
            final String letra = j < letras.length ? letras[j] : '${j + 1}';
            return pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14, bottom: 3),
              child: pw.Text(
                '($letra) ${_t(questao.alternativas[perm[j]])}',
                style: const pw.TextStyle(fontSize: 10.5),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- folha

  pw.MultiPage _paginaFolha(Prova prova, CopiaProva copia) {
    final int total = copia.questoes.length;
    final int maxAlternativas = copia.questoes.fold<int>(
      4,
      (int m, Questao q) => q.alternativas.length > m ? q.alternativas.length : m,
    );

    // Agrupa as linhas em colunas de até _linhasPorColuna questões e coloca
    // duas colunas lado a lado.
    final List<pw.Widget> blocos = <pw.Widget>[];
    for (int inicio = 0; inicio < total; inicio += _linhasPorColuna * 2) {
      final int fimEsq = _min(inicio + _linhasPorColuna, total);
      final int fimDir = _min(fimEsq + _linhasPorColuna, total);
      blocos.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(child: _colunaBolhas(inicio, fimEsq, maxAlternativas)),
            pw.SizedBox(width: 24),
            pw.Expanded(
              child: fimDir > fimEsq
                  ? _colunaBolhas(fimEsq, fimDir, maxAlternativas)
                  : pw.SizedBox(),
            ),
          ],
        ),
      );
    }

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
      build: (pw.Context context) => <pw.Widget>[
        _cabecalho(prova, copia, titulo: 'Folha de respostas', comQr: true),
        pw.SizedBox(height: 12),
        pw.Text(
          'Preencha completamente o círculo da alternativa escolhida, com '
          'caneta azul ou preta. Não rasure e não dobre esta folha.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 14),
        ...blocos,
      ],
    );
  }

  pw.Widget _colunaBolhas(int inicio, int fim, int alternativas) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: List<pw.Widget>.generate(fim - inicio, (int k) {
        final int numero = inicio + k + 1;
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            children: <pw.Widget>[
              pw.SizedBox(
                width: 26,
                child: pw.Text(
                  '$numero',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              ...List<pw.Widget>.generate(alternativas, (int j) {
                return pw.Container(
                  width: 18,
                  height: 18,
                  margin: const pw.EdgeInsets.only(right: 8),
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.grey800, width: 1),
                  ),
                  child: pw.Text(
                    j < letras.length ? letras[j] : '${j + 1}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------- comum

  pw.Widget _cabecalho(
    Prova prova,
    CopiaProva copia, {
    required String titulo,
    bool comQr = false,
  }) {
    final Aluno? aluno = copia.aluno;
    final Turma? turma = copia.turma;

    final pw.Widget dados = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          titulo,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        if (comQr)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              _t(prova.titulo),
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
            ),
          ),
        pw.SizedBox(height: 10),
        _campo('Nome', aluno?.nome),
        pw.SizedBox(height: 6),
        pw.Row(
          children: <pw.Widget>[
            pw.Expanded(child: _campo('Matrícula', aluno?.matricula)),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _campo(
                'Turma',
                turma == null ? null : '${turma.nome} · ${turma.disciplina}',
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        _campo('Data', null),
      ],
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: comQr
          ? pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Expanded(child: dados),
                pw.SizedBox(width: 14),
                pw.Column(
                  children: <pw.Widget>[
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: copia.qr.encode(),
                      width: 104,
                      height: 104,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      copia.qr.individual ? 'Folha individual' : 'Folha geral',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : dados,
    );
  }

  pw.Widget _campo(String rotulo, String? valor) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: <pw.Widget>[
        pw.Text(
          '$rotulo: ',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 1),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.6),
              ),
            ),
            child: pw.Text(
              valor == null ? ' ' : _t(valor),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  static int _min(int a, int b) => a < b ? a : b;

  /// A fonte padrão do PDF (Helvetica) só cobre caracteres latinos
  /// (Latin-1). Troca símbolos comuns fora dessa faixa por equivalentes e
  /// usa "?" para o resto, evitando erro na geração.
  static String _t(String texto) {
    const Map<String, String> trocas = <String, String>{
      '≥': '>=',
      '≤': '<=',
      '≠': '!=',
      '≈': '~',
      '√': 'raiz de ',
      'π': 'pi',
      '∞': 'infinito',
      '“': '"',
      '”': '"',
      '‘': "'",
      '’': "'",
      '–': '-',
      '—': '-',
      '…': '...',
      '•': '-',
      '→': '->',
      '←': '<-',
      '€': 'EUR',
    };
    final StringBuffer saida = StringBuffer();
    for (final int rune in texto.runes) {
      final String ch = String.fromCharCode(rune);
      if (rune <= 0xFF) {
        saida.write(ch);
      } else {
        saida.write(trocas[ch] ?? '?');
      }
    }
    return saida.toString();
  }
}
