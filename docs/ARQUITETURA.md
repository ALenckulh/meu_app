# Arquitetura — meu_app

Feature-first + camadas (adaptação do guia Systextil para Flutter).

## Camadas

```text
presentation (pages/widgets/providers)
    → domain (entities/repository interfaces)
    → data (RTDB repositories)
```

- Domain não importa Flutter UI.
- UI acessa dados só via providers → repository interfaces.

## Pastas

```text
lib/
  core/          # theme, router, widgets, di, rtdb_paths
  features/      # auth, home, turmas, alunos, questoes, provas, geracao, correcao, resultados
  shared/models/ # entidades + fromMap/toMap
  l10n/          # ARB pt
```

## Estado e rotas

- Riverpod: sessão, repositórios, versão de listas.
- go_router: auth redirect + `StatefulShellRoute` (NavigationBar).

## Dependências

```text
pages → providers → repository interface → *RtdbRepository → Firebase Realtime Database
auth → Firebase Auth + node professores/{uid}
```

Gerar variação e simular correção rodam no client (sem Cloud Functions).
