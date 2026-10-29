# Fluxos de usuário — jornadas (N2)

Fonte: [`app_router.dart`](../lib/core/router/app_router.dart).  
Dados: **Firebase Auth** + **Realtime Database**.

Barra inferior: **Início | Turmas | Questões | Provas | Corrigir**.

Convenção: passos = ações do usuário. Pré-requisitos evitam repetir jornadas.

---

## 1. Login

1. Abre o app → **Login**.
2. Digita **E-mail** e **Senha** → toca entrar → **Início**.

**Dados:** Auth + `professores/{uid}`.

---

## 2. Cadastro

1. No Login, toca cadastro → preenche **Nome**, **E-mail**, **Senha** → cadastrar → **Início**.

---

## 3. Logout

**Pré-requisito:** [§1](#1-login).

1. Em **Início**, toca **Sair** → Login.

---

## 4. Turma CRUD

1. Aba **Turmas** → FAB nova → preenche nome/disciplina/ano → **Salvar**.
2. Toca a turma → detalhe; editar/excluir pela lista ou detalhe.

**Dados:** `turmas`.

---

## 5. Aluno CRUD

**Pré-requisito:** [§4](#4-turma-crud) — detalhe da turma.

1. FAB aluno → nome/matrícula → salvar.
2. Editar/excluir na lista de alunos.

**Dados:** `alunos`.

---

## 6. Importar CSV

**Pré-requisito:** detalhe da turma.

1. Ícone upload → escolher CSV → prévia → importar válidos.

---

## 7. Questão CRUD

1. Aba **Questões** → campo **Buscar** (opcional).
2. FAB nova → enunciado, A–D, gabarito → salvar; editar/excluir na lista.

---

## 8. Prova

**Pré-requisito:** [§4](#4-turma-crud) + [§7](#7-questão-crud).

### 8.1 Criar (um passo até o detalhe)

1. **Provas** → FAB **Nova prova**.
2. Título + **Turma** + check questões → **Salvar prova** → **detalhe** (sem tela extra de ordem).
3. Se quiser reordenar depois: detalhe → **Questões e ordem**.

### 8.2 Turma / excluir

1. Detalhe → dropdown **Turma da prova** (única tela que edita turma).
2. Lista → lixeira → confirma exclusão.

---

## 9. Variações

**Pré-requisito:** prova com turma ([§8](#8-prova)) e alunos ([§5](#5-aluno-crud)/[§6](#6-importar-csv)).

1. Detalhe → **Variações / embaralhamento** (turma já vem da prova; sem reescolher).
2. Switches de embaralhar → marca alunos → **Gerar selecionados** ou **Gerar para toda a turma**.
3. Snackbar **Imprimir** → vai ao hub de PDF ([§10](#10-imprimir--pdf)); ou toca item → preview.

---

## 10. Imprimir / PDF

**Pré-requisito:** [§8](#8-prova).

1. Detalhe → **um** card **Imprimir / PDF**.
2. Na mesma tela:
   - **Prova + folha geral** → imprimir/compartilhar;
   - **Só folha geral** → imprimir;
   - **Por aluno / turma** → **Escolher aluno e imprimir** → individualização ([§11](#11-individualização)).

`/folha` redireciona para este hub.

---

## 11. Individualização

**Pré-requisito:** turma da prova definida no detalhe ([§8.2](#82-turma--excluir)).

1. Hub Imprimir → **Escolher aluno e imprimir** (ou rota direta).
2. Vê turma (somente leitura) → marca **aluno** (radio) → QR / **Copiar código**.
3. PDF deste aluno ou PDF da turma inteira.

---

## 12. Corrigir

**Pré-requisito:** folha individual ([§11](#11-individualização)).

1. Aba **Corrigir** (1 toque; sem menu Mais).
2. Câmera no QR **ou** **Digitar código** (código da §11).
3. Marca A–D → **Corrigir** → resultado.
4. AppBar → **Resultados** quando quiser a lista.

---

## 13. Resultados (+ estatísticas)

**Pré-requisito:** [§1](#1-login); correções via [§12](#12-corrigir) ou simular.

1. Card **Resultados** no Início **ou** AppBar em Corrigir → `/mais/resultados`.
2. Vê média, **gráfico de desempenho** e lista → toca aluno para detalhe.
3. **Simular resultado** (ícone) se quiser demo com aluno real sem correção.

`/mais/estatisticas` redireciona para esta tela.

---

## Índice de rotas

| Rota | Uso |
|------|-----|
| `/login`, `/cadastro` | Auth |
| `/home` | Atalhos |
| `/turmas…` | Turmas / CSV |
| `/questoes…` | Questões |
| `/provas…` | Prova / variações / imprimir |
| `/mais/correcao` | Aba Corrigir |
| `/mais/resultados` | Notas + gráfico |
