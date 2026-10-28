import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/features/alunos/domain/csv_alunos_parser.dart';

void main() {
  group('CsvAlunosParser.parse', () {
    test('lê CSV do Excel com ponto e vírgula e cabeçalho', () {
      final ResultadoImportacao r = CsvAlunosParser.parse(
        'Nome;Matrícula\nJoão Silva;2026001\nMaria Souza;2026002\n',
      );
      expect(r.erroGeral, isNull);
      expect(r.validas.length, 2);
      expect(r.validas.first.nome, 'João Silva');
      expect(r.validas.first.matricula, '2026001');
    });

    test('aceita colunas em outra ordem e separador vírgula', () {
      final ResultadoImportacao r = CsvAlunosParser.parse(
        'RA,Nome do aluno\n2026010,Ana Lima\n',
      );
      expect(r.validas.single.nome, 'Ana Lima');
      expect(r.validas.single.matricula, '2026010');
    });

    test('sem cabeçalho usa nome na 1ª coluna', () {
      final ResultadoImportacao r =
          CsvAlunosParser.parse('Pedro Lima;2026003\nCarla Dias;2026004');
      expect(r.validas.length, 2);
      expect(r.validas[1].nome, 'Carla Dias');
    });

    test('sem cabeçalho com matrícula na 1ª coluna', () {
      final ResultadoImportacao r =
          CsvAlunosParser.parse('2026003;Pedro Lima');
      expect(r.validas.single.nome, 'Pedro Lima');
      expect(r.validas.single.matricula, '2026003');
    });

    test('respeita aspas com separador dentro do campo', () {
      final ResultadoImportacao r =
          CsvAlunosParser.parse('nome,matricula\n"Silva, João",123\n');
      expect(r.validas.single.nome, 'Silva, João');
    });

    test('marca linhas com problema sem descartar as boas', () {
      final ResultadoImportacao r = CsvAlunosParser.parse(
        'nome;matricula\n'
        'Ana;1\n'
        ';2\n'
        'Bia;\n'
        'Caio;1\n'
        'Davi;99\n',
        matriculasExistentes: <String>{'99'},
      );
      expect(r.validas.map((LinhaImportacao l) => l.nome), <String>['Ana']);
      expect(r.comProblema.length, 4);
      expect(r.comProblema[0].erro, 'Nome em branco');
      expect(r.comProblema[1].erro, 'Matrícula em branco');
      expect(r.comProblema[2].erro, contains('repetida'));
      expect(r.comProblema[3].erro, 'Já cadastrado nesta turma');
      expect(r.comProblema[0].linha, 3);
    });

    test('erro geral para arquivo vazio ou cabeçalho incompleto', () {
      expect(CsvAlunosParser.parse('  \n\n').erroGeral, isNotNull);
      expect(CsvAlunosParser.parse('nome;turma\nAna;3A').erroGeral, isNotNull);
      expect(CsvAlunosParser.parse('nome;matricula\n').erroGeral, isNotNull);
    });
  });

  group('CsvAlunosParser.decodificar', () {
    test('UTF-8 com BOM', () {
      final Uint8List bytes = Uint8List.fromList(
        <int>[0xEF, 0xBB, 0xBF, ...utf8.encode('João')],
      );
      expect(CsvAlunosParser.decodificar(bytes), 'João');
    });

    test('Latin-1 (Excel Windows)', () {
      final Uint8List bytes = Uint8List.fromList(latin1.encode('João'));
      expect(CsvAlunosParser.decodificar(bytes), 'João');
    });
  });
}
