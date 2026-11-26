import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/features/geracao/data/prova_pdf_service.dart';
import 'package:meu_app/features/geracao/domain/qr_payload.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';

void main() {
  test('gera o PDF da turma inteira (caderno + folha por aluno)', () async {
    final List<Questao> qs = List<Questao>.generate(
      14,
      (int i) => Questao(
        id: 'q$i',
        professorId: 'p',
        enunciado: 'Questão ${i + 1} com um enunciado um pouco mais longo '
            'para ocupar espaço na página do caderno de questões?',
        alternativas: const <String>['um', 'dois', 'três', 'quatro'],
        gabaritoIndex: 0,
      ),
    );
    final Prova prova = Prova(
      id: 'p1',
      professorId: 'p',
      titulo: 'Prova',
      questaoIds: qs.map((Questao q) => q.id).toList(),
    );
    CopiaProva copia(String aluno) => CopiaProva(
          questoes: qs,
          ordemAlternativas: const <String, List<int>>{},
          qr: QrPayload(provaId: 'p1', variacaoId: 'v$aluno', alunoId: aluno),
        );
    final Uint8List pdf = await const ProvaPdfService()
        .gerar(prova: prova, copias: <CopiaProva>[copia('a'), copia('b')]);
    expect(pdf.isNotEmpty, isTrue);
    final String? dir = Platform.environment['PDF_DIR'];
    if (dir != null) {
      File('$dir/turma_teste.pdf').writeAsBytesSync(pdf);
    }
  });
}
