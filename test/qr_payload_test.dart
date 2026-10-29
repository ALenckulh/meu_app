import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/features/geracao/domain/qr_payload.dart';

void main() {
  test('folha individual: ida e volta', () {
    const QrPayload qr = QrPayload(
      provaId: 'prova-1',
      variacaoId: 'var-1',
      alunoId: 'aluno-1',
    );
    final String texto = qr.encode();
    expect(texto, 'CPROVA|v1|p=prova-1|v=var-1|a=aluno-1');

    final QrPayload? lido = QrPayload.decode(texto);
    expect(lido, isNotNull);
    expect(lido!.provaId, 'prova-1');
    expect(lido.variacaoId, 'var-1');
    expect(lido.alunoId, 'aluno-1');
    expect(lido.individual, isTrue);
  });

  test('folha geral só tem a prova', () {
    final QrPayload? lido =
        QrPayload.decode(const QrPayload(provaId: 'p|x').encode());
    expect(lido!.provaId, 'p|x');
    expect(lido.individual, isFalse);
  });

  test('rejeita QR de outra origem', () {
    expect(QrPayload.decode(null), isNull);
    expect(QrPayload.decode('https://example.com'), isNull);
    expect(QrPayload.decode('MOCK|prova=1'), isNull);
    expect(QrPayload.decode('CPROVA|v1|v=1'), isNull);
  });
}
