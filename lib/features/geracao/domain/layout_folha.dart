/// Um ponto em pontos do PDF (1/72 pol) ou em coordenadas normalizadas.
typedef Ponto = ({double x, double y});

/// Geometria fixa da grade de bolhas da folha de respostas.
///
/// O PDF desenha a grade com estas medidas e a leitura óptica (OMR) usa as
/// mesmas medidas para achar cada bolha na foto. Mudar um número aqui muda
/// os dois lados juntos.
///
/// A grade fica dentro de um "quadro" com um quadrado preto em cada canto
/// (os marcadores) e um quadrado menor à direita do marcador de cima à
/// esquerda (o marcador de orientação, que diz qual lado é o de cima).
/// Não há linhas ligando os marcadores: na foto eles precisam ser manchas
/// separadas.
class LayoutFolha {
  const LayoutFolha(this.totalQuestoes)
      : assert(totalQuestoes > 0 && totalQuestoes <= maxQuestoes);

  /// Largura do quadro: a largura útil de uma página A4 com margem de 40.
  static const double largura = 515;

  /// Lado dos marcadores dos cantos.
  static const double marcador = 22;

  /// Lado do marcador de orientação e distância dele até o marcador.
  static const double orientacao = 10;
  static const double folgaOrientacao = 8;

  /// Raio das bolhas e espessura do contorno.
  static const double raioBolha = 8;
  static const double contornoBolha = 1;

  static const double alturaLinha = 22;
  static const int linhasPorColuna = 22;
  static const int alternativas = 4;
  static const int maxQuestoes = linhasPorColuna * 2;

  /// Centro vertical da linha de letras A–D e da primeira questão.
  static const double yLetras = 22;
  static const double yPrimeira = 44;
  static const double margemInferior = 30;

  /// Distância da borda da coluna ao número e às bolhas.
  static const double xColuna = 34;
  static const double xPrimeiraBolha = 46;
  static const double passoBolha = 30;

  final int totalQuestoes;

  int get colunas => totalQuestoes > linhasPorColuna ? 2 : 1;
  int get linhas => (totalQuestoes / colunas).ceil();
  double get larguraColuna => (largura - xColuna) / 2;

  double get altura =>
      yPrimeira + (linhas - 1) * alturaLinha + margemInferior;

  /// Coluna e linha da questão [indice] (0 = primeira).
  ({int coluna, int linha}) posicao(int indice) =>
      (coluna: indice ~/ linhas, linha: indice % linhas);

  /// Canto esquerdo da coluna.
  double xDaColuna(int coluna) => xColuna + coluna * larguraColuna;

  /// Centro da bolha [alternativa] (0–3) da questão [indice], em pontos.
  Ponto centroBolha(int indice, int alternativa) {
    final ({int coluna, int linha}) p = posicao(indice);
    return (
      x: xDaColuna(p.coluna) +
          xPrimeiraBolha +
          alternativa * passoBolha +
          raioBolha,
      y: yPrimeira + p.linha * alturaLinha,
    );
  }

  /// Centro da letra [alternativa] na linha de cabeçalho da [coluna].
  Ponto centroLetra(int coluna, int alternativa) => (
        x: xDaColuna(coluna) +
            xPrimeiraBolha +
            alternativa * passoBolha +
            raioBolha,
        y: yLetras,
      );

  /// Centros dos marcadores: cima-esquerda, cima-direita, baixo-direita,
  /// baixo-esquerda (sentido horário).
  List<Ponto> get centrosMarcadores => <Ponto>[
        (x: marcador / 2, y: marcador / 2),
        (x: largura - marcador / 2, y: marcador / 2),
        (x: largura - marcador / 2, y: altura - marcador / 2),
        (x: marcador / 2, y: altura - marcador / 2),
      ];

  Ponto get centroOrientacao => (
        x: marcador + folgaOrientacao + orientacao / 2,
        y: marcador / 2,
      );

  /// Converte pontos do quadro para o sistema dos marcadores: (0,0) no
  /// centro do marcador de cima à esquerda e (1,1) no de baixo à direita.
  Ponto normalizar(Ponto p) => (
        x: (p.x - marcador / 2) / (largura - marcador),
        y: (p.y - marcador / 2) / (altura - marcador),
      );

  /// Raio da bolha no sistema normalizado (no eixo x).
  double get raioNormalizado => raioBolha / (largura - marcador);
}
