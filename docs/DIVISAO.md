# Divisão de trabalho — melhorias de UI (N1 → polimento)

Arquitetura é *feature-first*: cada pessoa mexe nas suas pastas de `lib/features/` e
os conflitos de merge ficam mínimos.

## Pessoa A — Cadastros e entrada (11 telas)

| Área | Pasta |
|---|---|
| Auth | `lib/features/auth/` |
| Home | `lib/features/home/` |
| Turmas | `lib/features/turmas/` |
| Alunos | `lib/features/alunos/` |
| Questões | `lib/features/questoes/` |

Pessoa A é **dona de `lib/core/`** (tema, widgets compartilhados, router, l10n).

## Pessoa B — Provas, geração e resultados (14 telas)

| Área | Pasta |
|---|---|
| Provas | `lib/features/provas/` |
| Geração | `lib/features/geracao/` |
| Correção | `lib/features/correcao/` |
| Resultados | `lib/features/resultados/` |

## Arquivos compartilhados (combinar antes de mexer)

- `lib/core/theme/material_theme.dart`
- `lib/core/widgets/*`
- `lib/core/router/app_router.dart`
- `lib/l10n/app_pt.arb`
- `lib/core/di/providers.dart`

Regra: mudança em `core/` vai em commit pequeno e separado, avisado à outra pessoa,
e entra **antes** do trabalho de tela.

## Fluxo Git

1. `git init` + primeiro commit + repo privado no GitHub.
2. Branch por área: `feat/provas-ui`, `feat/turmas-ui`, ...
3. Pull Request → revisão da outra pessoa → merge.
4. `flutter pub get` depois de todo `git pull` que toque no `pubspec`.

## Estado atual (2026-09-10)

- Pessoa B: 14 telas repaginadas no estilo "SaaS / dashboard".
- `core/theme/material_theme.dart`: component themes adicionados (cards, inputs,
  botões, navbar, snackbar). Muda o visual das telas da Pessoa A também — ver
  `docs/MUDANCAS-TEMA.md`.
- Novos widgets em `core/widgets/`: `section_header.dart`, `stat_tile.dart`,
  `info_card.dart` (aditivos, não alteram os existentes).
