import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:meu_app/features/geracao/domain/layout_folha.dart';

/// Como a leitura óptica viu uma questão.
enum SituacaoLeitura {
  /// Uma alternativa marcada, sem dúvida.
  marcada,

  /// Nenhuma bolha preenchida.
  emBranco,

  /// Mais de uma bolha preenchida (ou preenchimentos parecidos).
  duvida,
}

/// Resultado da leitura óptica de uma folha de respostas.
class LeituraOmr {
  const LeituraOmr({
    required this.respostas,
    required this.situacoes,
    required this.preenchimento,
  });

  /// Alternativa lida (0–3) por questão; null quando em branco ou em dúvida.
  final List<int?> respostas;
  final List<SituacaoLeitura> situacoes;

  /// Fração escura de cada bolha (0 a 1), por questão e alternativa.
  final List<List<double>> preenchimento;

  int get lidas =>
      situacoes.where((SituacaoLeitura s) => s == SituacaoLeitura.marcada).length;
  int get emBranco =>
      situacoes.where((SituacaoLeitura s) => s == SituacaoLeitura.emBranco).length;
  int get emDuvida =>
      situacoes.where((SituacaoLeitura s) => s == SituacaoLeitura.duvida).length;
}

/// A foto não permitiu ler a folha (ex.: marcadores fora do enquadramento).
class FalhaLeituraOmr implements Exception {
  const FalhaLeituraOmr(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Argumentos de [lerFolhaDeBytes], num só objeto para rodar em isolate.
typedef PedidoLeitura = ({Uint8List bytes, int totalQuestoes});

/// Decodifica a foto (JPEG/PNG) e lê as marcações. Função de topo para
/// poder rodar com `compute` sem travar a tela.
LeituraOmr lerFolhaDeBytes(PedidoLeitura pedido) {
  final img.Image? foto = img.decodeImage(pedido.bytes);
  if (foto == null) {
    throw const FalhaLeituraOmr('Não foi possível abrir a imagem.');
  }
  return LeitorOmr(pedido.totalQuestoes).ler(img.bakeOrientation(foto));
}

/// Leitura óptica das bolhas A–D da folha de respostas (RF06).
///
/// 1. Reduz a foto e separa o que é escuro com um limiar local (aguenta
///    sombra e luz desigual).
/// 2. Acha os 4 marcadores dos cantos: as 4 maiores manchas sólidas.
/// 3. Descobre qual lado é o de cima pelo marcador de orientação.
/// 4. Corrige a perspectiva e mede quanto de cada bolha está escuro.
class LeitorOmr {
  LeitorOmr(int totalQuestoes) : layout = LayoutFolha(totalQuestoes);

  final LayoutFolha layout;

  /// Lado maior da imagem depois de reduzida.
  static const int ladoMaximo = 1600;

  /// Pixel é escuro se for mais escuro que esta fração da média local.
  static const double fatorLimiar = 0.78;

  /// Bolha conta como marcada a partir desta fração escura.
  static const double minimoMarcada = 0.38;

  /// Diferença mínima entre a mais e a segunda mais preenchida.
  static const double folgaDuvida = 0.22;

  LeituraOmr ler(img.Image foto) {
    final img.Image reduzida = _reduzir(foto);
    final int w = reduzida.width;
    final int h = reduzida.height;
    final Uint8List escuro = _binarizar(reduzida);

    final List<_Mancha> marcadores = _acharMarcadores(escuro, w, h);
    final List<Ponto> cantos = _ordenarHorario(
      marcadores.map((_Mancha m) => (x: m.cx, y: m.cy)).toList(),
    );

    // Testa as 4 rotações e fica com a que põe o marcador de orientação
    // numa região escura com os vãos dos dois lados claros. Só "escuro" não
    // basta: numa rotação errada o ponto pode cair dentro de um marcador.
    final Ponto orientacao = layout.normalizar(layout.centroOrientacao);
    const double yMarca = LayoutFolha.marcador / 2;
    final Ponto vaoAntes = layout.normalizar((
      x: LayoutFolha.marcador + LayoutFolha.folgaOrientacao / 2,
      y: yMarca,
    ));
    final Ponto vaoDepois = layout.normalizar((
      x: layout.centroOrientacao.x +
          LayoutFolha.orientacao / 2 +
          LayoutFolha.folgaOrientacao / 2,
      y: yMarca,
    ));
    final double raioOrientacao = (LayoutFolha.orientacao / 2) /
        (LayoutFolha.largura - LayoutFolha.marcador);
    final double raioVao = (LayoutFolha.folgaOrientacao / 4) /
        (LayoutFolha.largura - LayoutFolha.marcador);
    _Homografia? melhor;
    double melhorFill = -1;
    for (int k = 0; k < 4; k++) {
      final _Homografia hgr = _Homografia.doQuadrado(<Ponto>[
        for (int i = 0; i < 4; i++) cantos[(i + k) % 4],
      ]);
      final double marca =
          _preenchimento(escuro, w, h, hgr, orientacao, raioOrientacao * 0.7);
      final double vaos = math.max(
        _preenchimento(escuro, w, h, hgr, vaoAntes, raioVao),
        _preenchimento(escuro, w, h, hgr, vaoDepois, raioVao),
      );
      final double fill = marca - vaos;
      if (fill > melhorFill) {
        melhorFill = fill;
        melhor = hgr;
      }
    }
    if (melhor == null || melhorFill < 0.5) {
      throw const FalhaLeituraOmr(
        'Não encontrei o marcador de orientação. Fotografe a folha inteira, '
        'de frente e com boa luz.',
      );
    }

    _validarMarcadores(marcadores, melhor);
    _validarGrade(escuro, w, h, melhor);

    final List<int?> respostas = <int?>[];
    final List<SituacaoLeitura> situacoes = <SituacaoLeitura>[];
    final List<List<double>> preenchimento = <List<double>>[];
    final double raio = layout.raioNormalizado * 0.55;
    for (int q = 0; q < layout.totalQuestoes; q++) {
      final List<double> fills = <double>[
        for (int a = 0; a < LayoutFolha.alternativas; a++)
          _preenchimento(
            escuro,
            w,
            h,
            melhor,
            layout.normalizar(layout.centroBolha(q, a)),
            raio,
          ),
      ];
      preenchimento.add(fills);
      final ({int? resposta, SituacaoLeitura situacao}) d = decidir(fills);
      respostas.add(d.resposta);
      situacoes.add(d.situacao);
    }
    return LeituraOmr(
      respostas: respostas,
      situacoes: situacoes,
      preenchimento: preenchimento,
    );
  }

  /// Cada marcador precisa ter o tamanho que a perspectiva prevê. Se uma
  /// bolha pintada foi tomada por marcador (canto fora da foto), ela é bem
  /// menor que o previsto.
  void _validarMarcadores(List<_Mancha> marcadores, _Homografia hgr) {
    final double meioX =
        (LayoutFolha.marcador / 2) / (LayoutFolha.largura - LayoutFolha.marcador);
    final double meioY = (LayoutFolha.marcador / 2) /
        (layout.altura - LayoutFolha.marcador);
    for (final Ponto canto in <Ponto>[
      (x: 0, y: 0),
      (x: 1, y: 0),
      (x: 1, y: 1),
      (x: 0, y: 1),
    ]) {
      final List<Ponto> q = <Ponto>[
        hgr.aplicar((x: canto.x - meioX, y: canto.y - meioY)),
        hgr.aplicar((x: canto.x + meioX, y: canto.y - meioY)),
        hgr.aplicar((x: canto.x + meioX, y: canto.y + meioY)),
        hgr.aplicar((x: canto.x - meioX, y: canto.y + meioY)),
      ];
      double area = 0;
      for (int i = 0; i < 4; i++) {
        area += q[i].x * q[(i + 1) % 4].y - q[(i + 1) % 4].x * q[i].y;
      }
      area = area.abs() / 2;
      final Ponto centro = hgr.aplicar(canto);
      _Mancha? perto;
      double melhor = double.infinity;
      for (final _Mancha m in marcadores) {
        final double d = math.pow(m.cx - centro.x, 2) +
            math.pow(m.cy - centro.y, 2).toDouble();
        if (d < melhor) {
          melhor = d;
          perto = m;
        }
      }
      final double razao = perto!.area / area;
      if (razao < 0.55 || razao > 1.8) {
        throw const FalhaLeituraOmr(
          'Os quadrados pretos dos cantos não conferem. Fotografe a grade '
          'inteira, com os 4 cantos aparecendo.',
        );
      }
    }
  }

  /// Os contornos impressos das bolhas precisam cair onde a grade diz.
  /// Com a grade desalinhada, quase nenhum contorno é encontrado.
  void _validarGrade(Uint8List escuro, int w, int h, _Homografia hgr) {
    final double r = layout.raioNormalizado;
    int amostras = 0;
    int acertos = 0;
    for (int q = 0; q < layout.totalQuestoes; q++) {
      for (int a = 0; a < LayoutFolha.alternativas; a++) {
        final Ponto c = layout.normalizar(layout.centroBolha(q, a));
        for (int k = 0; k < 16; k++) {
          final double ang = k * math.pi / 8;
          bool achou = false;
          for (final double f in const <double>[0.8, 0.9, 1.0, 1.1, 1.2]) {
            final Ponto p = hgr.aplicar((
              x: c.x + math.cos(ang) * r * f,
              y: c.y + math.sin(ang) * r * f * _proporcao,
            ));
            final int x = p.x.round();
            final int y = p.y.round();
            if (x >= 0 && y >= 0 && x < w && y < h && escuro[y * w + x] == 1) {
              achou = true;
              break;
            }
          }
          amostras++;
          if (achou) {
            acertos++;
          }
        }
      }
    }
    if (amostras == 0 || acertos / amostras < 0.6) {
      throw const FalhaLeituraOmr(
        'Não consegui enxergar a grade de bolhas: a foto pode estar tremida, '
        'fora de foco ou cortada. Tire outra, de frente, com a grade inteira.',
      );
    }
  }

  /// Escolhe a alternativa a partir do preenchimento das bolhas.
  static ({int? resposta, SituacaoLeitura situacao}) decidir(
    List<double> fills,
  ) {
    int maior = 0;
    for (int i = 1; i < fills.length; i++) {
      if (fills[i] > fills[maior]) {
        maior = i;
      }
    }
    double segunda = 0;
    for (int i = 0; i < fills.length; i++) {
      if (i != maior && fills[i] > segunda) {
        segunda = fills[i];
      }
    }
    if (fills[maior] < minimoMarcada) {
      return (resposta: null, situacao: SituacaoLeitura.emBranco);
    }
    if (segunda >= minimoMarcada || fills[maior] - segunda < folgaDuvida) {
      return (resposta: null, situacao: SituacaoLeitura.duvida);
    }
    return (resposta: maior, situacao: SituacaoLeitura.marcada);
  }

  // --------------------------------------------------------------- imagem

  img.Image _reduzir(img.Image foto) {
    final int lado = math.max(foto.width, foto.height);
    if (lado <= ladoMaximo) {
      return foto;
    }
    final bool larga = foto.width >= foto.height;
    return img.copyResize(
      foto,
      width: larga ? ladoMaximo : null,
      height: larga ? null : ladoMaximo,
      interpolation: img.Interpolation.average,
    );
  }

  /// 1 = escuro, 0 = claro, com limiar pela média da vizinhança.
  Uint8List _binarizar(img.Image imagem) {
    final int w = imagem.width;
    final int h = imagem.height;
    final Uint8List cinza = Uint8List(w * h);
    for (final img.Pixel p in imagem) {
      cinza[p.y * w + p.x] = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b)
          .round()
          .clamp(0, 255);
    }

    // Imagem integral para a média de cada janela em tempo constante.
    final Float64List integral = Float64List((w + 1) * (h + 1));
    for (int y = 0; y < h; y++) {
      double linha = 0;
      for (int x = 0; x < w; x++) {
        linha += cinza[y * w + x];
        integral[(y + 1) * (w + 1) + (x + 1)] =
            integral[y * (w + 1) + (x + 1)] + linha;
      }
    }

    final int r = math.max(7, math.min(w, h) ~/ 24);
    final Uint8List escuro = Uint8List(w * h);
    for (int y = 0; y < h; y++) {
      final int y0 = math.max(0, y - r);
      final int y1 = math.min(h, y + r + 1);
      for (int x = 0; x < w; x++) {
        final int x0 = math.max(0, x - r);
        final int x1 = math.min(w, x + r + 1);
        final double soma = integral[y1 * (w + 1) + x1] -
            integral[y0 * (w + 1) + x1] -
            integral[y1 * (w + 1) + x0] +
            integral[y0 * (w + 1) + x0];
        final double media = soma / ((x1 - x0) * (y1 - y0));
        if (cinza[y * w + x] < media * fatorLimiar) {
          escuro[y * w + x] = 1;
        }
      }
    }
    return escuro;
  }

  // ----------------------------------------------------------- marcadores

  List<_Mancha> _acharMarcadores(Uint8List escuro, int w, int h) {
    final List<_Mancha> manchas = _manchas(escuro, w, h);
    final double areaMinima = w * h * 0.00015;
    final double areaMaxima = w * h * 0.02;
    final List<_Mancha> solidas = manchas
        .where((_Mancha m) =>
            m.area >= areaMinima &&
            m.area <= areaMaxima &&
            !m.tocaBorda &&
            m.compacta)
        .toList()
      ..sort((_Mancha a, _Mancha b) => b.area.compareTo(a.area));
    if (solidas.length < 4) {
      throw const FalhaLeituraOmr(
        'Não encontrei os 4 quadrados pretos dos cantos da grade. '
        'Enquadre a grade inteira na foto.',
      );
    }
    final List<_Mancha> quatro = solidas.take(4).toList();
    // Bolhas pintadas são bem menores que os marcadores: se a 4ª maior
    // mancha for muito menor, faltou um marcador na foto.
    if (quatro.last.area < quatro.first.area * 0.45) {
      throw const FalhaLeituraOmr(
        'Um dos quadrados pretos dos cantos ficou de fora ou apagado. '
        'Fotografe a grade inteira.',
      );
    }
    return quatro;
  }

  /// Componentes conexas (vizinhança 4) dos pixels escuros.
  List<_Mancha> _manchas(Uint8List escuro, int w, int h) {
    final Int32List rotulo = Int32List(w * h);
    final Int32List pilha = Int32List(w * h);
    final List<_Mancha> manchas = <_Mancha>[];
    for (int inicio = 0; inicio < w * h; inicio++) {
      if (escuro[inicio] == 0 || rotulo[inicio] != 0) {
        continue;
      }
      final _Mancha m = _Mancha();
      final int id = manchas.length + 1;
      int topo = 0;
      pilha[topo++] = inicio;
      rotulo[inicio] = id;
      while (topo > 0) {
        final int i = pilha[--topo];
        final int x = i % w;
        final int y = i ~/ w;
        m.adicionar(x, y);
        if (x == 0 || y == 0 || x == w - 1 || y == h - 1) {
          m.tocaBorda = true;
        }
        if (x > 0 && escuro[i - 1] == 1 && rotulo[i - 1] == 0) {
          rotulo[i - 1] = id;
          pilha[topo++] = i - 1;
        }
        if (x < w - 1 && escuro[i + 1] == 1 && rotulo[i + 1] == 0) {
          rotulo[i + 1] = id;
          pilha[topo++] = i + 1;
        }
        if (y > 0 && escuro[i - w] == 1 && rotulo[i - w] == 0) {
          rotulo[i - w] = id;
          pilha[topo++] = i - w;
        }
        if (y < h - 1 && escuro[i + w] == 1 && rotulo[i + w] == 0) {
          rotulo[i + w] = id;
          pilha[topo++] = i + w;
        }
      }
      manchas.add(m);
    }
    return manchas;
  }

  /// Ordena 4 pontos no sentido horário (na imagem, y para baixo).
  List<Ponto> _ordenarHorario(List<Ponto> pontos) {
    final double cx =
        pontos.map((Ponto p) => p.x).reduce((double a, double b) => a + b) / 4;
    final double cy =
        pontos.map((Ponto p) => p.y).reduce((double a, double b) => a + b) / 4;
    return List<Ponto>.from(pontos)
      ..sort((Ponto a, Ponto b) => math
          .atan2(a.y - cy, a.x - cx)
          .compareTo(math.atan2(b.y - cy, b.x - cx)));
  }

  // ------------------------------------------------------------ amostras

  /// Fração de pixels escuros num disco de raio [raio] (normalizado) em
  /// volta de [centro] (normalizado).
  double _preenchimento(
    Uint8List escuro,
    int w,
    int h,
    _Homografia hgr,
    Ponto centro,
    double raio,
  ) {
    int total = 0;
    int escuros = 0;
    const int passos = 9;
    for (int j = -passos; j <= passos; j++) {
      for (int i = -passos; i <= passos; i++) {
        final double du = i / passos;
        final double dv = j / passos;
        if (du * du + dv * dv > 1) {
          continue;
        }
        // O raio é medido no eixo x; no eixo y a escala normalizada é
        // outra, por isso a correção pela proporção do quadro.
        final Ponto p = hgr.aplicar((
          x: centro.x + du * raio,
          y: centro.y + dv * raio * _proporcao,
        ));
        final int x = p.x.round();
        final int y = p.y.round();
        if (x < 0 || y < 0 || x >= w || y >= h) {
          continue;
        }
        total++;
        escuros += escuro[y * w + x];
      }
    }
    return total == 0 ? 0 : escuros / total;
  }

  double get _proporcao =>
      (LayoutFolha.largura - LayoutFolha.marcador) /
      (layout.altura - LayoutFolha.marcador);
}

class _Mancha {
  int area = 0;
  double _sx = 0;
  double _sy = 0;
  double _sxx = 0;
  double _syy = 0;
  bool tocaBorda = false;

  void adicionar(int x, int y) {
    area++;
    _sx += x;
    _sy += y;
    _sxx += x * x.toDouble();
    _syy += y * y.toDouble();
  }

  double get cx => _sx / area;
  double get cy => _sy / area;

  /// Momento de inércia dividido pela área ao quadrado. Vale 1/6 ≈ 0,167
  /// para um quadrado cheio (em qualquer rotação) e 0,159 para um disco;
  /// manchas vazadas ou espalhadas (QR Code, texto, contornos) dão mais.
  bool get compacta {
    final double inercia =
        (_sxx - _sx * _sx / area) + (_syy - _sy * _sy / area);
    final double j = inercia / (area.toDouble() * area);
    return j >= 0.150 && j <= 0.200;
  }
}

/// Transformação projetiva do quadrado unitário para um quadrilátero
/// (Heckbert, "Fundamentals of Texture Mapping", 1989).
class _Homografia {
  _Homografia(this.a, this.b, this.c, this.d, this.e, this.f, this.g, this.h);

  /// [cantos] na ordem (0,0), (1,0), (1,1), (0,1).
  factory _Homografia.doQuadrado(List<Ponto> cantos) {
    final double x0 = cantos[0].x, y0 = cantos[0].y;
    final double x1 = cantos[1].x, y1 = cantos[1].y;
    final double x2 = cantos[2].x, y2 = cantos[2].y;
    final double x3 = cantos[3].x, y3 = cantos[3].y;
    final double dx1 = x1 - x2, dy1 = y1 - y2;
    final double dx2 = x3 - x2, dy2 = y3 - y2;
    final double dx3 = x0 - x1 + x2 - x3, dy3 = y0 - y1 + y2 - y3;
    double g = 0, h = 0;
    if (dx3.abs() > 1e-9 || dy3.abs() > 1e-9) {
      final double den = dx1 * dy2 - dx2 * dy1;
      g = (dx3 * dy2 - dx2 * dy3) / den;
      h = (dx1 * dy3 - dx3 * dy1) / den;
    }
    return _Homografia(
      x1 - x0 + g * x1,
      x3 - x0 + h * x3,
      x0,
      y1 - y0 + g * y1,
      y3 - y0 + h * y3,
      y0,
      g,
      h,
    );
  }

  final double a, b, c, d, e, f, g, h;

  Ponto aplicar(Ponto p) {
    final double z = g * p.x + h * p.y + 1;
    return (
      x: (a * p.x + b * p.y + c) / z,
      y: (d * p.x + e * p.y + f) / z,
    );
  }
}
