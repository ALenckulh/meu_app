import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/core/utils/validators.dart';
import 'package:meu_app/core/widgets/feedback.dart';
import 'package:meu_app/features/auth/domain/repositories/auth_repository.dart';

class CadastroPage extends ConsumerStatefulWidget {
  const CadastroPage({super.key});

  @override
  ConsumerState<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends ConsumerState<CadastroPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _nomeController.dispose();
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
    try {
      await ref.read(authSessionProvider.notifier).register(
            nome: _nomeController.text.trim(),
            email: _emailController.text.trim(),
            senha: _senhaController.text,
          );
      if (!mounted) {
        return;
      }
      showSuccessSnackBar(context, 'Conta criada com sucesso.');
      context.go('/login');
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível criar a conta.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
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
                    if (_error != null) ...<Widget>[
                      FormErrorBanner(
                        message: _error!,
                        onClose: () => setState(() => _error = null),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      key: const Key('input-nome'),
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        hintText: 'Informe o nome',
                        helperText: 'Nome do professor.',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (String? v) {
                        final String nome = (v ?? '').trim();
                        if (nome.isEmpty) {
                          return 'Informe o nome';
                        }
                        if (nome.length > 80) {
                          return 'Nome muito longo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('input-email'),
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'Informe o e-mail',
                        helperText: 'E-mail usado no login.',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('input-senha'),
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        hintText: 'Informe a senha',
                        helperText: 'Mínimo de 8 caracteres, com letras e números.',
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_loading) {
                          _submit();
                        }
                      },
                      validator: Validators.senhaNova,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('btn-cadastrar'),
                      onPressed: _loading ? null : _submit,
                      child: const Text('Cadastrar'),
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
