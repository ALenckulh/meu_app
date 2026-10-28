import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/features/auth/presentation/pages/cadastro_page.dart';
import 'package:meu_app/shared/models/professor.dart';

class FakeAuthRepository implements AuthRepository {
  String? registeredNome;
  String? registeredEmail;
  String? registeredSenha;

  @override
  Professor? get currentUser => null;

  @override
  Future<Professor?> login(String email, String senha) async => null;

  @override
  Future<Professor> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    registeredNome = nome;
    registeredEmail = email;
    registeredSenha = senha;
    return Professor(
      id: 'test-id',
      nome: nome,
      email: email,
      senha: '',
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('Cadastro page renders and submits registration',
      (WidgetTester tester) async {
    final FakeAuthRepository fakeRepo = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: CadastroPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cadastro'), findsOneWidget);
    expect(find.byKey(const Key('input-nome')), findsOneWidget);
    expect(find.byKey(const Key('input-email')), findsOneWidget);
    expect(find.byKey(const Key('input-senha')), findsOneWidget);
    expect(find.byKey(const Key('btn-cadastrar')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('input-nome')), 'Professor Teste');
    await tester.enterText(
        find.byKey(const Key('input-email')), 'prof@teste.com');
    await tester.enterText(
        find.byKey(const Key('input-senha')), '123456');

    await tester.tap(find.byKey(const Key('btn-cadastrar')));
    await tester.pumpAndSettle();

    expect(fakeRepo.registeredNome, 'Professor Teste');
    expect(fakeRepo.registeredEmail, 'prof@teste.com');
    expect(fakeRepo.registeredSenha, '123456');
  });
}
