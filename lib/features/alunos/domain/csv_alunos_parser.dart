import 'dart:convert';
import 'dart:typed_data';

/// Uma linha lida do arquivo de importação, já validada.
class LinhaImportacao {
  const LinhaImportacao({
    required this.linha,
    required this.nome,
    required this.matricula,
    this.erro,
  });

  /// Número da linha no arquivo original (começa em 1).
  final int linha;
  final String nome;
  final String matricula;

  /// Motivo pelo qual a linha não será importada (null = linha válida).
  final String? erro;

  bool get valida => erro == null;

  LinhaImportacao comErro(String motivo) => LinhaImportacao(
        linha: linha,
        nome: nome,
        matricula: matricula,
        erro: motivo,
      );
}

/// Resultado da leitura do arquivo.
class ResultadoImportacao {
  const ResultadoImportacao({
    this.linhas = const <LinhaImportacao>[],
    this.erroGeral,
  });

  final List<LinhaImportacao> linhas;

  /// Erro que impede a leitura do arquivo inteiro (formato inválido etc.).
  final String? erroGeral;

  List<LinhaImportacao> get validas =>
      linhas.where((LinhaImportacao l) => l.valida).toList();

  List<LinhaImportacao> get comProblema =>
      linhas.where((LinhaImportacao l) => !l.valida).toList();
}

/// Lê listas de alunos em CSV (RF08).
///
/// Formatos aceitos:
/// - separador `;` (padrão do Excel em português), `,` ou tabulação;
/// - com ou sem cabeçalho. Com cabeçalho, as colunas podem estar em qualquer
///   ordem e são reconhecidas pelos nomes (`nome`/`aluno` e
///   `matrícula`/`matricula`/`RA`/`registro`/`código`);
/// - sem cabeçalho, a 1ª coluna é o nome e a 2ª a matrícula;
/// - arquivo em UTF-8 ou Windows-1252/Latin-1 (como o Excel costuma salvar).
class CsvAlunosParser {
  const CsvAlunosParser._();

  static bool _ehColunaNome(String c) => c.contains('nome') || c == 'aluno';

  static bool _ehColunaMatricula(String c) =>
      c.contains('matricula') ||
      c == 'ra' ||
      c.contains('registro') ||
      c.contains('codigo');

  /// Converte os bytes do arquivo em texto (UTF-8 com fallback para Latin-1).
  static String decodificar(Uint8List bytes) {
    List<int> dados = bytes;
    // Remove BOM UTF-8.
    if (dados.length >= 3 &&
        dados[0] == 0xEF &&
        dados[1] == 0xBB &&
        dados[2] == 0xBF) {
      dados = dados.sublist(3);
    }
    try {
      return utf8.decode(dados);
    } on FormatException {
      return latin1.decode(dados);
    }
  }

  /// Lê o [conteudo] e valida cada linha.
  ///
  /// [matriculasExistentes] são as matrículas já cadastradas na turma; essas
  /// linhas são marcadas como repetidas e não serão importadas.
  static ResultadoImportacao parse(
    String conteudo, {
    Set<String> matriculasExistentes = const <String>{},
  }) {
    final List<String> linhasBrutas = conteudo.split(RegExp(r'\r\n|\r|\n'));

    // Guarda o número original de cada linha não vazia.
    final List<MapEntry<int, String>> linhas = <MapEntry<int, String>>[];
    for (int i = 0; i < linhasBrutas.length; i++) {
      if (linhasBrutas[i].trim().isNotEmpty) {
        linhas.add(MapEntry<int, String>(i + 1, linhasBrutas[i]));
      }
    }

    if (linhas.isEmpty) {
      return const ResultadoImportacao(erroGeral: 'O arquivo está vazio.');
    }

    final String separador = _detectarSeparador(linhas.first.value);
    final List<String> primeira = _dividir(linhas.first.value, separador);

    int indiceNome = 0;
    int indiceMatricula = 1;
    int inicio = 0;

    final List<String> primeiraNormalizada = primeira.map(_normalizar).toList();
    final bool temCabecalho = primeiraNormalizada.any(
      (String c) => _ehColunaNome(c) || _ehColunaMatricula(c),
    );

    if (temCabecalho) {
      indiceMatricula = primeiraNormalizada.indexWhere(_ehColunaMatricula);
      indiceNome = primeiraNormalizada.indexWhere(
        (String c) => _ehColunaNome(c) && !_ehColunaMatricula(c),
      );
      if (indiceNome < 0 || indiceMatricula < 0) {
        return const ResultadoImportacao(
          erroGeral:
              'O cabeçalho precisa ter uma coluna "nome" e uma coluna "matrícula".',
        );
      }
      inicio = 1;
    } else if (primeira.length < 2) {
      return const ResultadoImportacao(
        erroGeral:
            'Não foi possível encontrar duas colunas (nome e matrícula). '
            'Separe as colunas com ponto e vírgula (;) ou vírgula (,).',
      );
    } else if (_pareceMatricula(primeira[0]) && !_pareceMatricula(primeira[1])) {
      // Arquivo sem cabeçalho com a matrícula na 1ª coluna.
      indiceNome = 1;
      indiceMatricula = 0;
    }

    final List<LinhaImportacao> resultado = <LinhaImportacao>[];
    final Map<String, int> vistas = <String, int>{};
    final Set<String> existentes =
        matriculasExistentes.map((String m) => m.trim().toLowerCase()).toSet();

    for (int i = inicio; i < linhas.length; i++) {
      final int numero = linhas[i].key;
      final List<String> campos = _dividir(linhas[i].value, separador);
      final String nome = _campo(campos, indiceNome);
      final String matricula = _campo(campos, indiceMatricula);

      LinhaImportacao item = LinhaImportacao(
        linha: numero,
        nome: nome,
        matricula: matricula,
      );

      final String chave = matricula.toLowerCase();
      if (nome.isEmpty) {
        item = item.comErro('Nome em branco');
      } else if (matricula.isEmpty) {
        item = item.comErro('Matrícula em branco');
      } else if (vistas.containsKey(chave)) {
        item = item.comErro(
          'Matrícula repetida no arquivo (linha ${vistas[chave]})',
        );
      } else if (existentes.contains(chave)) {
        item = item.comErro('Já cadastrado nesta turma');
      }

      if (matricula.isNotEmpty && !vistas.containsKey(chave)) {
        vistas[chave] = numero;
      }
      resultado.add(item);
    }

    if (resultado.isEmpty) {
      return const ResultadoImportacao(
        erroGeral: 'O arquivo só tem o cabeçalho, sem nenhum aluno.',
      );
    }

    return ResultadoImportacao(linhas: resultado);
  }

  static String _campo(List<String> campos, int indice) {
    if (indice < 0 || indice >= campos.length) {
      return '';
    }
    return campos[indice].trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _detectarSeparador(String linha) {
    final int pontoVirgula = ';'.allMatches(linha).length;
    final int virgula = ','.allMatches(linha).length;
    final int tab = '\t'.allMatches(linha).length;
    if (tab > pontoVirgula && tab > virgula) {
      return '\t';
    }
    return pontoVirgula >= virgula ? ';' : ',';
  }

  /// Divide uma linha respeitando campos entre aspas ("Silva, João").
  static List<String> _dividir(String linha, String separador) {
    final List<String> campos = <String>[];
    final StringBuffer atual = StringBuffer();
    bool entreAspas = false;

    for (int i = 0; i < linha.length; i++) {
      final String c = linha[i];
      if (c == '"') {
        if (entreAspas && i + 1 < linha.length && linha[i + 1] == '"') {
          atual.write('"');
          i++;
        } else {
          entreAspas = !entreAspas;
        }
      } else if (c == separador && !entreAspas) {
        campos.add(atual.toString());
        atual.clear();
      } else {
        atual.write(c);
      }
    }
    campos.add(atual.toString());
    return campos;
  }

  static bool _pareceMatricula(String valor) {
    final String v = valor.trim();
    return v.isNotEmpty && RegExp(r'^[0-9A-Za-z\-./]+$').hasMatch(v) &&
        RegExp(r'[0-9]').hasMatch(v);
  }

  static String _normalizar(String valor) {
    const String comAcento = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const String semAcento = 'aaaaaeeeeiiiiooooouuuuc';
    final StringBuffer saida = StringBuffer();
    for (final int rune in valor.trim().toLowerCase().runes) {
      final String ch = String.fromCharCode(rune);
      final int idx = comAcento.indexOf(ch);
      saida.write(idx >= 0 ? semAcento[idx] : ch);
    }
    return saida.toString().replaceAll(RegExp(r'[^a-z]'), '');
  }
}
