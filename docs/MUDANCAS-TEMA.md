# Mudanças no tema compartilhado (para a Pessoa A)

Data: 2026-09-10 · arquivos:
`lib/core/theme/material_theme.dart`, `lib/core/theme/app_semantic_colors.dart`

Estilo baseado em um mock de referência (app de estudos, visual leve e
arredondado). **A paleta de cor mudou** — o app inteiro fica diferente.

## Paleta (light)

| Token | Antes (verde) | Agora (violeta) |
|---|---|---|
| `primary` | `#586421` oliva | `#5b4be0` violeta |
| `surface` (fundo) | `#fbfaed` | `#f9f0ec` creme rosado |
| `secondary` | verde-acinzentado | `#3f6fe5` azul |
| `tertiary` | verde-azulado | `#e9673c` coral |
| `error` | `#ba1a1a` | `#d64550` coral-vermelho |
| cards | — | branco `#ffffff` |

`themeMode` continua `ThemeMode.light` (o dark existe mas não é usado).

## Component themes

| Componente | Agora |
|---|---|
| `Card` | branco, cantos **24**, **sombra violeta suave** (sem borda) |
| `FilledButton` / `OutlinedButton` / `TextButton` | **formato pílula** (`StadiumBorder`), altura 52 |
| `FloatingActionButton` | pílula, violeta |
| Campos (`InputDecoration`) | preenchidos brancos, cantos 16, foco violeta 2px |
| `AppBar` | fundo creme, título **w800**, sem sombra |
| `NavigationBar` | fundo branco, **label só no item ativo**, altura 66 |
| `Chip` | pílula, sem borda |
| `SnackBar` | flutuante, cantos 16 |
| `Dialog` | cantos 28 |

## Cores semânticas — `app_semantic_colors.dart` (NOVO)

`ColorScheme` não tem "sucesso". Criado `AppSemanticColors` como `ThemeExtension`
com `success`/`onSuccess`/`successContainer` (verde) e `info` (azul). Já registrado
no tema. Nas telas: `context.semantic.success` (import
`package:meu_app/core/theme/app_semantic_colors.dart`).

Use isso para "acertou/completo". Vermelho de erro continua `colorScheme.error`.

## Impacto nas telas da Pessoa A

- **Login/Cadastro**: fundo creme, campos brancos arredondados, botão violeta pílula.
- **Dashboard, Turmas, Alunos, Questões**: cards brancos com sombra violeta e cantos
  grandes; botões viram pílula; navbar mostra label só no ativo.
- Nada de API quebrada. `flutter analyze` → **No issues found**.

## Widgets em `lib/core/widgets/`

| Arquivo | Mudança |
|---|---|
| `section_header.dart` | título Title Case em negrito (não mais CAIXA ALTA) |
| `stat_tile.dart` | `StatTile` agora com tinta pastel do accent; `StatTileRow` igual |
| `info_card.dart` | `InfoCard` com **gradiente pastel**; **API mudou**: só `accent` (removidos `background`/`foreground`). `NavCard` e `MetaChip` mantidos (chip virou pílula) |
| `status_icon.dart` | `success` e `info` agora usam `context.semantic.*` |

Não foram tocados: `empty_state.dart`, `feedback.dart`, `confirm_delete_dialog.dart`,
`ellipsis_text.dart`.

## Fundo em degradê (2ª rodada)

- `lib/core/theme/app_gradients.dart` (NOVO): `AppGradients.background` (fundo da
  tela), `AppGradients.softCard` (lavagem pastel de cards de destaque),
  `AppGradients.celebration` (brilho radial lavanda das telas de resultado).
- No tema, `scaffoldBackgroundColor` e `appBarTheme.backgroundColor` viraram
  **`Colors.transparent`**. O degradê é pintado uma vez pelo `builder:` do
  `MaterialApp.router` em `lib/app.dart`, atrás de **todos** os Scaffolds.
- `canvasColor` continua `surface` (menus de dropdown precisam de fundo opaco).
- Impacto Pessoa A: todas as telas ganham o fundo creme→lilás e a AppBar
  transparente automaticamente. Se algum Scaffold seu precisar de fundo sólido,
  use `Scaffold(backgroundColor: ...)` explícito naquela tela.
