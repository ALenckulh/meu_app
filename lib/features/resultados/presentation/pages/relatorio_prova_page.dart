import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/theme/app_semantic_colors.dart';
import 'package:meu_app/core/widgets/confirm_delete_dialog.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/core/widgets/info_card.dart';
import 'package:meu_app/core/widgets/section_header.dart';
import 'package:meu_app/core/widgets/stat_tile.dart';
import 'package:meu_app/features/resultados/domain/relatorio_prova.dart';
import 'package:meu_app/shared/models/aluno.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:meu_app/shared/models/turma.dart';

/// Relatório pronto para a tela, com a turma e as questões da prova.
typedef DadosRelatorio = ({
  RelatorioProva relatorio,
  Turma? turma,
  Map<String, Questao> questoes,
});

/// Carrega o relatório de uma prova. Recarrega a cada correção salva.
final relatorioProvaProvider = FutureProvider.autoDispose
    .family<DadosRelatorio?, String>((Ref ref, String provaId) async {
  ref.watch(listVersionProvider);
  final Prova? prova = await ref.read(provaRepositoryProvider).getById(provaId);
  if (prova == null) {
    return null;
  }
  final Turma? turma = prova.turmaId.isEmpty
      ? null
      : await ref.read(turmaRepositoryProvider).getById(prova.turmaId);
  final List<Aluno> alunos = prova.turmaId.isEmpty
      ? <Aluno>[]
      : await ref.read(alunoRepositoryProvider).listByTurma(prova.turmaId);
  final List<Correcao> correcoes =
      await ref.read(correcaoRepositoryProvider).listAll();
  final List<Questao> banco =
      await ref.read(questaoRepositoryProvider).listAll();
  final RelatorioProva relatorio = RelatorioProva.montar(
    prova: prova,
    alunosDaTurma: alunos,
    correcoes: correcoes,
    variacoes: await ref.read(provaRepositoryProvider).listVariacoes(provaId),
  );
  return (
    relatorio: relatorio,
    turma: turma,
    questoes: <String, Questao>{for (final Questao q in banco) q.id: q},
  );
});

/// Cor do selo de status da prova.
Color corDoStatus(BuildContext context, StatusProva status) {
  final ColorScheme colors = Theme.of(context).colorScheme;
  return switch (status) {
    StatusProva.aguardandoCorrecao => colors.onSurfaceVariant,
    StatusProva.emCorrecao => colors.tertiary,
    StatusProva.finalizada => context.semantic.success,
  };
}

IconData iconeDoStatus(StatusProva status) => switch (status) {
      StatusProva.aguardandoCorrecao => Icons.hourglass_empty,
      StatusProva.emCorrecao => Icons.pending_actions_outlined,
      StatusProva.finalizada => Icons.task_alt,
    };

/// Status da prova depois das correções (item 9 da N3): quem já tem nota,
/// quem falta, médias e desempenho por questão.
class RelatorioProvaPage extends ConsumerWidget {
  const RelatorioProvaPage({super.key, required this.provaId});

  final String provaId;

  static const List<String> _letras = <String>['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DadosRelatorio?> dados =
        ref.watch(relatorioProvaProvider(provaId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status da prova'),
        actions: <Widget>[
          IconButton(
            key: const Key('btn-relatorio-corrigir'),
            tooltip: 'Corrigir folhas',
            onPressed: () => context.go('/mais/correcao'),
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      body: dados.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) =>
            Center(child: Text('Erro ao carregar o relatório: $e')),
        data: (DadosRelatorio? d) {
          if (d == null) {
            return const Center(child: Text('Prova não encontrada.'));
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(relatorioProvaProvider(provaId)),
            child: _Conteudo(dados: d, letras: _letras),
          );
        },
      ),
    );
  }
}

class _Conteudo extends ConsumerWidget {
  const _Conteudo({required this.dados, required this.letras});

  final DadosRelatorio dados;
  final List<String> letras;

  Future<void> _encerrar(
    BuildContext context,
    WidgetRef ref, {
    required bool encerrar,
  }) async {
    final RelatorioProva r = dados.relatorio;
    if (encerrar && r.pendentes > 0) {
      final bool ok = await showConfirmDeleteDialog(
        context: context,
        title: 'Encerrar a correção?',
        message: '${r.pendentes} aluno(s) ainda sem nota ficam como ausentes. '
            'Você pode reabrir e corrigir depois.',
        confirmLabel: 'Encerrar',
      );
      if (!ok) {
        return;
      }
    }
    try {
      await ref
          .read(provaRepositoryProvider)
          .update(r.prova.copyWith(correcaoEncerrada: encerrar));
      ref.read(listVersionProvider.notifier).bump();
      if (context.mounted) {
        showSuccessSnackBar(
          context,
          encerrar ? 'Correção encerrada.' : 'Correção reaberta.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Erro ao salvar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final RelatorioProva r = dados.relatorio;
    final Turma? turma = dados.turma;
    final Color corStatus = corDoStatus(context, r.status);
    final double progresso =
        r.totalAlunos == 0 ? 0 : r.corrigidos / r.totalAlunos;

    String nota(double? v) => v == null ? '—' : v.toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        InfoCard(
          icon: Icons.assessment_outlined,
          title: r.prova.titulo,
          subtitle: turma == null
              ? 'Prova sem turma'
              : '${turma.nome} · ${turma.disciplina}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  MetaChip(
                    key: const Key('status-prova'),
                    icon: iconeDoStatus(r.status),
                    label: r.status.rotulo,
                    color: corStatus,
                  ),
                  const Spacer(),
                  Text(
                    '${r.corrigidos} de ${r.totalAlunos} corrigida(s)',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 8,
                  color: corStatus,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              if (r.status == StatusProva.finalizada) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  r.temAusentes
                      ? 'Correção encerrada: ${r.pendentes} aluno(s) sem nota '
                          '(ausentes).'
                      : 'Todos os alunos da turma têm nota salva.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
              if (r.prova.correcaoEncerrada)
                TextButton.icon(
                  key: const Key('btn-reabrir-correcao'),
                  onPressed: () => _encerrar(context, ref, encerrar: false),
                  icon: const Icon(Icons.lock_open_outlined, size: 18),
                  label: const Text('Reabrir correção'),
                )
              else if (r.corrigidos > 0 && r.pendentes > 0) ...<Widget>[
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  key: const Key('btn-encerrar-correcao'),
                  onPressed: () => _encerrar(context, ref, encerrar: true),
                  icon: const Icon(Icons.task_alt, size: 18),
                  label: const Text('Encerrar correção'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatTileRow(
          tiles: <Widget>[
            StatTile(
              value: nota(r.media),
              label: 'média',
              icon: Icons.functions,
            ),
            StatTile(
              value: nota(r.maiorNota),
              label: 'maior nota',
              icon: Icons.arrow_upward,
              accent: context.semantic.success,
            ),
            StatTile(
              value: nota(r.menorNota),
              label: 'menor nota',
              icon: Icons.arrow_downward,
              accent: colors.error,
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatTileRow(
          tiles: <Widget>[
            StatTile(
              value: '${r.corrigidos}',
              label: 'corrigidas',
              icon: Icons.check_circle_outline,
              accent: context.semantic.success,
            ),
            StatTile(
              value: '${r.pendentes}',
              label: r.temAusentes ? 'ausentes' : 'pendentes',
              icon: r.temAusentes ? Icons.person_off_outlined : Icons.schedule,
              accent: colors.tertiary,
            ),
            StatTile(
              value: '${r.aprovados()}',
              label: 'com nota ≥ 6',
              icon: Icons.emoji_events_outlined,
              accent: colors.secondary,
            ),
          ],
        ),
        const SectionHeader('Alunos'),
        if (r.alunos.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                turma == null
                    ? 'Vincule uma turma à prova para acompanhar as correções.'
                    : 'A turma ainda não tem alunos.',
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < r.alunos.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, color: colors.outlineVariant),
                  _LinhaAluno(
                    situacao: r.alunos[i],
                    ausente: r.prova.correcaoEncerrada,
                  ),
                ],
              ],
            ),
          ),
        if (r.corrigidos > 0) ...<Widget>[
          const SectionHeader('Desempenho por questão'),
          for (final DesempenhoQuestao q in r.questoes)
            _LinhaQuestao(
              desempenho: q,
              questao: dados.questoes[q.questaoId],
              letras: letras,
            ),
        ],
      ],
    );
  }
}

class _LinhaAluno extends StatelessWidget {
  const _LinhaAluno({required this.situacao, required this.ausente});

  final SituacaoAluno situacao;

  /// Correção encerrada: quem está sem nota aparece como ausente.
  final bool ausente;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Correcao? c = situacao.correcao;
    final Color cor = c == null
        ? colors.onSurfaceVariant
        : (c.nota >= 6 ? context.semantic.success : colors.error);

    return ListTile(
      key: Key('relatorio-aluno-${situacao.aluno.id}'),
      leading: Icon(
        c == null ? Icons.radio_button_unchecked : Icons.check_circle,
        color: c == null ? colors.outline : context.semantic.success,
      ),
      title: Text(situacao.aluno.nome),
      subtitle: Text(
        c == null
            ? '${ausente ? 'Ausente' : 'Pendente'} · matrícula '
                '${situacao.aluno.matricula}'
            : 'Nota salva · ${c.acertos}/${c.totalQuestoes} acertos',
        style: theme.textTheme.bodySmall,
      ),
      trailing: c == null
          ? null
          : Text(
              c.nota.toStringAsFixed(1),
              style: theme.textTheme.titleMedium?.copyWith(
                color: cor,
                fontWeight: FontWeight.w800,
              ),
            ),
      onTap: c == null ? null : () => context.push('/mais/resultados/${c.id}'),
    );
  }
}

class _LinhaQuestao extends StatelessWidget {
  const _LinhaQuestao({
    required this.desempenho,
    required this.questao,
    required this.letras,
  });

  final DesempenhoQuestao desempenho;
  final Questao? questao;
  final List<String> letras;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DesempenhoQuestao d = desempenho;
    final int pct = (d.percentualAcerto * 100).round();
    final int? mais = d.maisMarcada;
    final int? correta = questao?.gabaritoIndex;
    final Color cor = pct >= 60 ? context.semantic.success : colors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'Questão ${d.numero}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '$pct% de acerto',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: cor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (questao != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                questao!.enunciado,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: d.percentualAcerto,
                minHeight: 6,
                color: cor,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${d.acertos} acerto(s) · ${d.erros} erro(s)'
              '${mais == null ? '' : ' · mais marcada: ${letras[mais]}'}'
              '${correta == null ? '' : ' · correta: ${letras[correta]}'}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
