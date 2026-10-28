import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/features/alunos/domain/csv_alunos_parser.dart';
import 'package:meu_app/shared/models/aluno.dart';

/// Importação de alunos a partir de um arquivo CSV (RF08).
///
/// Fluxo: escolher arquivo → prévia com validação linha a linha →
/// confirmar → cada aluno válido é salvo pelo `create()` do repositório
/// (funciona igual com o repositório mock e com o Firestore).
class ImportarAlunosPage extends ConsumerStatefulWidget {
  const ImportarAlunosPage({super.key, required this.turmaId});

  final String turmaId;

  @override
  ConsumerState<ImportarAlunosPage> createState() => _ImportarAlunosPageState();
}

class _ImportarAlunosPageState extends ConsumerState<ImportarAlunosPage> {
  String? _nomeArquivo;
  ResultadoImportacao? _resultado;
  bool _lendo = false;
  bool _importando = false;
  int _salvos = 0;
  String? _erro;

  Future<void> _escolherArquivo() async {
    setState(() => _erro = null);

    final List<PlatformFile> arquivos;
    try {
      arquivos = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['csv', 'txt'],
      );
    } catch (e) {
      setState(() => _erro = 'Não foi possível abrir o seletor de arquivos: $e');
      return;
    }
    if (arquivos.isEmpty) {
      return; // usuário cancelou
    }

    setState(() => _lendo = true);
    try {
      final PlatformFile arquivo = arquivos.first;
      final Uint8List bytes = await arquivo.readAsBytes();
      final String conteudo = CsvAlunosParser.decodificar(bytes);

      final List<Aluno> existentes =
          await ref.read(alunoRepositoryProvider).listByTurma(widget.turmaId);
      final Set<String> matriculas =
          existentes.map((Aluno a) => a.matricula).toSet();

      final ResultadoImportacao resultado = CsvAlunosParser.parse(
        conteudo,
        matriculasExistentes: matriculas,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _nomeArquivo = arquivo.name;
        _resultado = resultado;
        _erro = resultado.erroGeral;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _erro = 'Erro ao ler o arquivo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _lendo = false);
      }
    }
  }

  Future<void> _confirmar() async {
    final List<LinhaImportacao> validas =
        _resultado?.validas ?? <LinhaImportacao>[];
    if (validas.isEmpty) {
      return;
    }
    setState(() {
      _importando = true;
      _salvos = 0;
      _erro = null;
    });

    final List<String> falhas = <String>[];
    for (final LinhaImportacao linha in validas) {
      try {
        await ref.read(alunoRepositoryProvider).create(
              Aluno(
                id: '',
                turmaId: widget.turmaId,
                nome: linha.nome,
                matricula: linha.matricula,
              ),
            );
        if (mounted) {
          setState(() => _salvos++);
        }
      } catch (e) {
        falhas.add('${linha.nome} (linha ${linha.linha})');
      }
    }

    ref.read(listVersionProvider.notifier).bump();
    if (!mounted) {
      return;
    }

    if (falhas.isEmpty) {
      showSuccessSnackBar(context, '$_salvos alunos importados.');
      context.pop();
    } else {
      setState(() {
        _importando = false;
        _erro = '$_salvos alunos importados, mas ${falhas.length} falharam: '
            '${falhas.join(', ')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final ResultadoImportacao? resultado = _resultado;
    final int qtdValidas = resultado?.validas.length ?? 0;
    final int qtdProblemas = resultado?.comProblema.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Importar alunos')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: <Widget>[
                _InstrucoesCard(colors: colors, text: text),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('btn-escolher-csv'),
                  onPressed: (_lendo || _importando) ? null : _escolherArquivo,
                  icon: _lendo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    _nomeArquivo == null
                        ? 'Escolher arquivo CSV'
                        : 'Trocar arquivo ($_nomeArquivo)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_erro != null) ...<Widget>[
                  const SizedBox(height: 12),
                  FormErrorBanner(
                    message: _erro!,
                    onClose: () => setState(() => _erro = null),
                  ),
                ],
                if (resultado != null && resultado.erroGeral == null) ...<Widget>[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      Chip(
                        avatar: Icon(Icons.check_circle,
                            size: 18, color: colors.primary),
                        label: Text('$qtdValidas prontos para importar'),
                      ),
                      if (qtdProblemas > 0)
                        Chip(
                          avatar: Icon(Icons.warning,
                              size: 18, color: colors.error),
                          label: Text('$qtdProblemas serão ignorados'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...resultado.linhas.map(
                    (LinhaImportacao linha) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _LinhaPreview(linha: linha),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('btn-confirmar-importacao'),
                onPressed: (_importando || qtdValidas == 0) ? null : _confirmar,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  _importando
                      ? 'Importando... ($_salvos de $qtdValidas)'
                      : qtdValidas == 0
                          ? 'Importar lista'
                          : 'Importar $qtdValidas alunos',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstrucoesCard extends StatelessWidget {
  const _InstrucoesCard({required this.colors, required this.text});

  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 20, color: colors.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Use um arquivo .csv com as colunas nome e matrícula. '
                  'No Excel: Salvar como → CSV.',
                  style: text.bodyMedium
                      ?.copyWith(color: colors.onSecondaryContainer),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'nome;matricula\nJoão Silva;2026001\nMaria Souza;2026002',
                    style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaPreview extends StatelessWidget {
  const _LinhaPreview({required this.linha});

  final LinhaImportacao linha;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool ok = linha.valida;
    final String nome = linha.nome.isEmpty ? '(sem nome)' : linha.nome;

    return Material(
      color: ok ? colors.surfaceContainerHigh : colors.errorContainer,
      borderRadius: BorderRadius.circular(20),
      elevation: ok ? 1.5 : 0,
      shadowColor: colors.shadow.withValues(alpha: 0.15),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: CircleAvatar(
          backgroundColor: ok
              ? colors.tertiaryContainer
              : colors.error.withValues(alpha: 0.15),
          foregroundColor: ok ? colors.onTertiaryContainer : colors.error,
          child: ok
              ? Text(nome.substring(0, 1).toUpperCase())
              : const Icon(Icons.warning, size: 20),
        ),
        title: Text(
          nome,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          ok
              ? 'Matrícula: ${linha.matricula}'
              : 'Linha ${linha.linha}: ${linha.erro}',
          style: ok ? null : TextStyle(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}
