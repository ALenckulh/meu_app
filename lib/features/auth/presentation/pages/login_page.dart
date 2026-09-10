import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/widgets/feedback.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController =
      TextEditingController(text: 'ana@escola.com');
  final TextEditingController _senhaController =
      TextEditingController(text: '123456');
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final bool ok = await ref.read(authSessionProvider.notifier).login(
          _emailController.text.trim(),
          _senhaController.text,
        );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    if (ok) {
      context.go('/home');
    } else {
      setState(() => _error = 'E-mail ou senha inválidos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Correção de Provas',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'N1 — protótipo com dados mockados',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) ...<Widget>[
                      FormErrorBanner(
                        message: _error!,
                        onClose: () => setState(() => _error = null),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      key: const Key('input-email'),
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'Informe o e-mail',
                        helperText: 'Use o e-mail da conta do professor.',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (String? v) =>
                          (v == null || v.isEmpty) ? 'Informe o e-mail' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('input-senha'),
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        hintText: 'Informe a senha',
                        helperText: 'Senha de acesso ao aplicativo.',
                      ),
                      validator: (String? v) =>
                          (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('btn-entrar'),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    TextButton(
                      key: const Key('btn-ir-cadastro'),
                      onPressed: () => context.push('/cadastro'),
                      child: const Text('Criar conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
