import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/features/auth/presentation/pages/login_page.dart';
import 'package:meu_app/shared/models/professor.dart';

/// Auth falso: o teste não inicializa o Firebase.
class _FakeAuthRepository implements AuthRepository {
  @override
  Professor? get currentUser => null;

  @override
  Future<Professor?> login(String email, String senha) async => null;

  @override
  Future<Professor> register({
    required String nome,
    required String email,
    required String senha,
  }) async =>
      Professor(id: 'test-id', nome: nome, email: email);

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('Login page renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byKey(const Key('input-email')), findsOneWidget);
  });
}
