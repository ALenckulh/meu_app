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
    final ColorScheme colors = Theme.of(context).colorScheme;
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
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.camera_alt,
                      size: 72,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _scanning
                          ? 'Lendo QR e respostas...'
                          : 'Área da câmera (simulada)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'N2: câmera real + detecção de QR',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('btn-simular-leitura'),
              onPressed: _scanning ? null : _simular,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(_scanning ? 'Processando...' : 'Simular leitura'),
            ),
          ],
        ),
      ),
    );
  }
}
