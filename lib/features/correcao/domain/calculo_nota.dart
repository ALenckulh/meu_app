/// Resultado do cálculo da nota de uma folha.
class ResultadoNota {
  const ResultadoNota({
    required this.acertos,
    required this.total,
    required this.nota,
  });

  final int acertos;
  final int total;

  /// Nota de 0 a 10, com uma casa decimal.
  final double nota;
}

/// Compara as [respostas] marcadas com o [gabarito] (mesma ordem, índices
/// 0–3; -1 = em branco, conta como erro) e devolve acertos e nota de 0 a 10
/// (RF07).
ResultadoNota calcularNota(List<int> respostas, List<int> gabarito) {
  if (respostas.length != gabarito.length) {
    throw ArgumentError(
      'Respostas (${respostas.length}) ≠ questões (${gabarito.length}).',
    );
  }
  int acertos = 0;
  for (int i = 0; i < respostas.length; i++) {
    final int marcada = respostas[i];
    if (marcada < -1 || marcada > 3) {
      throw ArgumentError('Resposta inválida na posição $i: $marcada');
    }
    if (marcada == gabarito[i]) {
      acertos++;
    }
  }
  final int total = gabarito.length;
  final double nota = total == 0 ? 0 : (acertos / total) * 10;
  return ResultadoNota(
    acertos: acertos,
    total: total,
    nota: double.parse(nota.toStringAsFixed(1)),
  );
}
