/// Conteúdo do QR Code impresso na folha de respostas (RF05).
///
/// Formato (texto simples, fácil de ler em qualquer leitor de QR):
///
/// ```text
/// CPROVA|v1|p=<provaId>|v=<variacaoId>|a=<alunoId>
/// ```
///
/// - Folha **geral** (mesma para a turma): só `p`.
/// - Folha **individual**: `p`, `v` e `a` — a leitura identifica prova,
///   variação embaralhada e aluno sem nenhuma digitação.
class QrPayload {
  const QrPayload({
    required this.provaId,
    this.variacaoId,
    this.alunoId,
  });

  static const String prefixo = 'CPROVA';
  static const String versao = 'v1';

  final String provaId;
  final String? variacaoId;
  final String? alunoId;

  /// `true` quando o QR identifica um aluno e uma variação específicos.
  bool get individual =>
      variacaoId != null &&
      variacaoId!.isNotEmpty &&
      alunoId != null &&
      alunoId!.isNotEmpty;

  String encode() {
    final List<String> partes = <String>[
      prefixo,
      versao,
      'p=${Uri.encodeComponent(provaId)}',
      if (variacaoId != null) 'v=${Uri.encodeComponent(variacaoId!)}',
      if (alunoId != null) 'a=${Uri.encodeComponent(alunoId!)}',
    ];
    return partes.join('|');
  }

  /// Lê o texto de um QR. Retorna `null` se não for um QR gerado pelo app.
  static QrPayload? decode(String? raw) {
    if (raw == null) {
      return null;
    }
    final List<String> partes = raw.trim().split('|');
    if (partes.length < 3 || partes[0] != prefixo || partes[1] != versao) {
      return null;
    }

    final Map<String, String> campos = <String, String>{};
    for (final String parte in partes.skip(2)) {
      final int igual = parte.indexOf('=');
      if (igual <= 0) {
        continue;
      }
      try {
        campos[parte.substring(0, igual)] =
            Uri.decodeComponent(parte.substring(igual + 1));
      } catch (_) {
        return null;
      }
    }

    final String? provaId = campos['p'];
    if (provaId == null || provaId.isEmpty) {
      return null;
    }
    return QrPayload(
      provaId: provaId,
      variacaoId: campos['v'],
      alunoId: campos['a'],
    );
  }

  @override
  String toString() => encode();
}
