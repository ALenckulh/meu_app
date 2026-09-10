import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_app/core/router/app_router.dart';
import 'package:meu_app/core/theme/material_theme.dart';
import 'package:meu_app/l10n/app_localizations.dart';

class AppCorrecaoApp extends ConsumerWidget {
  const AppCorrecaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final TextTheme textTheme = ThemeData.light().textTheme;
    final MaterialTheme materialTheme = MaterialTheme(textTheme);

    return MaterialApp.router(
      title: 'Correção de Provas',
      debugShowCheckedModeBanner: false,
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.light,
      locale: const Locale('pt'),
      supportedLocales: const <Locale>[
        Locale('pt'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
