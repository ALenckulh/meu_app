import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/shared/models/prova.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FolhaRespostasPage extends ConsumerStatefulWidget {
  const FolhaRespostasPage({super.key, required this.provaId});

  final String provaId;

  @override
  ConsumerState<FolhaRespostasPage> createState() => _FolhaRespostasPageState();
}

class _FolhaRespostasPageState extends ConsumerState<FolhaRespostasPage> {
  Prova? _prova;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prova = await ref.read(provaRepositoryProvider).getById(widget.provaId);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['A', 'B', 'C', 'D'];
    final String qrPayload =
        'MOCK|prova=${widget.provaId}|var=var-1|aluno=aluno-1';

    return Scaffold(
      appBar: AppBar(title: const Text('Folha de respostas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  _prova?.titulo ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    child: QrImageView(
                      data: qrPayload,
                      size: 160,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'QR Code mock (N2: identificador real)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                ...List<Widget>.generate(
                  _prova?.questaoIds.length ?? 0,
                  (int index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 40,
                            child: Text('${index + 1}.'),
                          ),
                          ...labels.map(
                            (String label) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(label),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
