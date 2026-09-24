import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/shared/models/correcao.dart';
import 'package:meu_app/shared/models/variacao_de_prova.dart';

class CorrigirProvaPage extends ConsumerStatefulWidget {
  const CorrigirProvaPage({super.key});

  @override
  ConsumerState<CorrigirProvaPage> createState() => _CorrigirProvaPageState();
}

class _CorrigirProvaPageState extends ConsumerState<CorrigirProvaPage> {
  bool _scanning = false;

  Future<void> _simular() async {
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final AppMockStore store = ref.read(appMockStoreProvider);
    final VariacaoDeProva variacao = store.variacoes.first;
    final Correcao correcao =
        await ref.read(correcaoRepositoryProvider).simularLeitura(
              variacaoId: variacao.id,
              alunoId: variacao.alunoId,
            );
    ref.read(listVersionProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    setState(() => _scanning = false);
    context.push('/mais/correcao/resultado/${correcao.id}');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Corrigir prova')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _scanning ? colors.primary : colors.outlineVariant,
                    width: _scanning ? 2 : 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary.withValues(alpha: 0.12),
                      ),
                      child: _scanning
                          ? SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: colors.primary,
                              ),
                            )
                          : Icon(Icons.qr_code_scanner,
                              size: 40, color: colors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _scanning
                          ? 'Lendo QR e respostas...'
                          : 'Área da câmera (simulada)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'N2: câmera real + detecção de QR e marcações',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('btn-simular-leitura'),
                onPressed: _scanning ? null : _simular,
                icon: Icon(_scanning
                    ? Icons.hourglass_bottom
                    : Icons.document_scanner_outlined),
                label: Text(_scanning ? 'Processando...' : 'Simular leitura'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
