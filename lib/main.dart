import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/app.dart';
import 'package:meu_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Espera o Firebase restaurar a sessão salva (importante na web), para o
    // roteador já saber se existe professor logado na primeira tela.
    await FirebaseAuth.instance.authStateChanges().first;
  } catch (e) {
    runApp(_ErroInicializacao(erro: e));
    return;
  }

  runApp(
    const ProviderScope(
      child: AppCorrecaoApp(),
    ),
  );
}

/// Tela simples mostrada se o Firebase não conseguir iniciar
/// (ex.: `firebase_options.dart` ainda não foi gerado com `flutterfire configure`).
class _ErroInicializacao extends StatelessWidget {
  const _ErroInicializacao({required this.erro});

  final Object erro;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Não foi possível iniciar o Firebase.\n\n$erro',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
