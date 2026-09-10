# Arquitetura — meu_app

Feature-first + camadas (adaptação do guia Systextil para Flutter).

## Camadas

```text
presentation (pages/widgets/providers)
    → domain (entities/repository interfaces)
    → data (mock repositories/datasources)
```

- Domain não importa Flutter UI.
- UI não acessa `AppMockStore` diretamente (exceto telas de leitura que já usam store via providers/repositórios).
- // N2: trocar `*MockRepository` por Firestore sem reescrever páginas.

## Pastas

```text
lib/
  core/          # theme, router, widgets, di, mock store
  features/      # auth, home, turmas, alunos, questoes, provas, geracao, correcao, resultados
  shared/models/ # entidades compartilhadas
  l10n/          # ARB pt
```

## Estado e rotas

- Riverpod: sessão, repositórios, versão de listas.
- go_router: auth redirect + `StatefulShellRoute` (NavigationBar).

## Dependências

pages → providers → repository interface → mock repository → AppMockStore
