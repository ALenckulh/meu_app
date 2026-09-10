# Normas UX — adaptação Material 3

Base: normas Systextil → equivalentes Flutter/M3.

| Norma Systextil | Flutter / M3 |
|-----------------|--------------|
| Design system | Material 3 (`FilledButton`, `TextField`, `NavigationBar`, `AlertDialog`) |
| Cores | Só `ColorScheme` do tema (material-theme.zip) |
| Primária em ações | Botões/links; estáticos em `onSurface`/`outline` |
| Confirmação delete | `AlertDialog` — título de negócio; botões Excluir / Cancelar |
| Ícones status | `Icons.cancel` / `warning` / `check_circle` / `info` |
| Tooltip ícone | `Tooltip` + `Semantics` / Key estável |
| Campos | `labelText`, `hintText` (Informe/Selecione), `helperText` |
| Disabled | Explicar motivo (helper/tooltip) |
| Overflow | `TextOverflow.ellipsis` + `Tooltip` |
| Feedback | Sucesso: `SnackBar`; erro em form: banner no topo |
| Acessibilidade | `Key` estáveis (`btn-salvar`, `input-email`) |

Não usar hex solto nas telas — apenas tokens do `ColorScheme`.
