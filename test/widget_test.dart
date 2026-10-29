import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/app.dart';
import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/core/di/providers.dart';
import 'package:meu_app/features/auth/data/repositories/auth_mock_repository.dart';

void main() {
  testWidgets('Login page renders', (WidgetTester tester) async {
    // Nos testes usamos o repositório mock, sem Firebase.
    AppMockStore.instance.sessaoAtual = null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(AuthMockRepository(AppMockStore.instance)),
        ],
        child: const AppCorrecaoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byKey(const Key('input-email')), findsOneWidget);
  });
}
