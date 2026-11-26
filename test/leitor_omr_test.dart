import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meu_app/features/correcao/domain/calculo_nota.dart';
import 'package:meu_app/features/correcao/domain/leitor_omr.dart';
import 'package:meu_app/features/geracao/domain/layout_folha.dart';

/// Desenha a grade da folha (mesmo [LayoutFolha] do PDF) numa "foto"
/// girada de [graus], com as [marcadas] (questão → alternativas) pintadas.
Uint8List _fotoSintetica({
  required int questoes,
  required Map<int, List<int>> marcadas,
  double graus = 0,
  bool semCantoInferiorDireito = false,
}) {
  final LayoutFolha layout = LayoutFolha(questoes);
  const double escala = 1.8; // px por ponto
  final double ang = graus * math.pi / 180;
  final img.Image foto = img.Image(width: 1400, height: 1400);
  img.fill(foto, color: img.ColorRgb8(235, 235, 228));
  final double cx = 700, cy = 700;
  final double ox = LayoutFolha.largura / 2, oy = layout.altura / 2;

  ({int x, int y}) mapa(double x, double y) {
    final double dx = (x - ox) * escala, dy = (y - oy) * escala;
    return (
      x: (cx + dx * math.cos(ang) - dy * math.sin(ang)).round(),
      y: (cy + dx * math.sin(ang) + dy * math.cos(ang)).round(),
    );
  }

  void quadrado(Ponto c, double lado) {
    final double m = lado / 2;
    img.fillPolygon(
      foto,
      vertices: <img.Point>[
        for (final (double, double) d in <(double, double)>[
          (-m, -m),
          (m, -m),
          (m, m),
          (-m, m),
        ])
          img.Point(mapa(c.x + d.$1, c.y + d.$2).x, mapa(c.x + d.$1, c.y + d.$2).y),
      ],
      color: img.ColorRgb8(15, 15, 15),
    );
  }

  final List<Ponto> cantos = layout.centrosMarcadores;
  for (int i = 0; i < 4; i++) {
    if (semCantoInferiorDireito && i == 2) {
      continue;
    }
    quadrado(cantos[i], LayoutFolha.marcador);
  }
  quadrado(layout.centroOrientacao, LayoutFolha.orientacao);

  final int raio = (LayoutFolha.raioBolha * escala).round();
  for (int q = 0; q < questoes; q++) {
    for (int a = 0; a < 4; a++) {
      final Ponto c = layout.centroBolha(q, a);
      final ({int x, int y}) p = mapa(c.x, c.y);
      for (final int r in <int>[raio, raio - 1]) {
        img.drawCircle(foto,
            x: p.x, y: p.y, radius: r, color: img.ColorRgb8(60, 60, 60));
      }
      if (marcadas[q]?.contains(a) ?? false) {
        img.fillCircle(foto,
            x: p.x,
            y: p.y,
            radius: raio - 2,
            color: img.ColorRgb8(30, 50, 150));
      }
    }
  }
  return img.encodeJpg(foto, quality: 85);
}

void main() {
  group('LeitorOmr', () {
    final Map<int, List<int>> marcadas = <int, List<int>>{
      0: <int>[1],
      1: <int>[0],
      2: <int>[3],
      // 3 em branco
      4: <int>[2],
      5: <int>[0, 2], // duas marcadas
      6: <int>[1],
    };

    void conferir(LeituraOmr l) {
      expect(l.respostas, <int?>[1, 0, 3, null, 2, null, 1]);
      expect(l.situacoes[3], SituacaoLeitura.emBranco);
      expect(l.situacoes[5], SituacaoLeitura.duvida);
      expect(l.lidas, 5);
    }

    test('lê a folha levemente girada', () {
      conferir(lerFolhaDeBytes((
        bytes: _fotoSintetica(questoes: 7, marcadas: marcadas, graus: 6),
        totalQuestoes: 7,
      )));
    });

    test('lê a folha de cabeça para baixo (marcador de orientação)', () {
      conferir(lerFolhaDeBytes((
        bytes: _fotoSintetica(questoes: 7, marcadas: marcadas, graus: 177),
        totalQuestoes: 7,
      )));
    });

    test('lê a folha deitada (90°) com duas colunas', () {
      final Map<int, List<int>> muitas = <int, List<int>>{
        for (int q = 0; q < 30; q++) q: <int>[(q * 3) % 4],
      };
      final LeituraOmr l = lerFolhaDeBytes((
        bytes: _fotoSintetica(questoes: 30, marcadas: muitas, graus: 92),
        totalQuestoes: 30,
      ));
      expect(l.respostas, <int?>[for (int q = 0; q < 30; q++) (q * 3) % 4]);
    });

    test('recusa a foto sem um dos cantos em vez de chutar', () {
      expect(
        () => lerFolhaDeBytes((
          bytes: _fotoSintetica(
            questoes: 7,
            marcadas: marcadas,
            semCantoInferiorDireito: true,
          ),
          totalQuestoes: 7,
        )),
        throwsA(isA<FalhaLeituraOmr>()),
      );
    });

    test('decidir: em branco, dúvida e marcada', () {
      expect(LeitorOmr.decidir(<double>[0.05, 0.1, 0.02, 0.0]).situacao,
          SituacaoLeitura.emBranco);
      expect(LeitorOmr.decidir(<double>[0.9, 0.05, 0.8, 0.0]).situacao,
          SituacaoLeitura.duvida);
      expect(LeitorOmr.decidir(<double>[0.1, 0.85, 0.05, 0.0]).resposta, 1);
    });
  });

  test('questão em branco (-1) conta como erro na nota', () {
    final ResultadoNota r = calcularNota(<int>[1, -1, 2, 0], <int>[1, 3, 2, 1]);
    expect(r.acertos, 2);
    expect(r.nota, 5.0);
  });
}
