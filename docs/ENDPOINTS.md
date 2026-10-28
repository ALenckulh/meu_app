# Endpoints — meu_app

Operações Realtime Database / Auth usadas pelo app. Fonte: `lib/features/*/domain/repositories/`.

Auth: Firebase Auth. Dados: RTDB. Gerar variação / corrigir: client-side.

## Firebase Auth

Fonte: `AuthRepository`

| Método | Firebase | Params | Retorno |
|--------|----------|--------|---------|
| `login` | `signInWithEmailAndPassword` + read `professores/{uid}` | `email`, `senha` | `Professor?` |
| `register` | `createUserWithEmailAndPassword` + set `professores/{uid}` | `nome`, `email`, `senha` | `Professor` |
| `logout` | `signOut` | — | void |
| `currentUser` | `FirebaseAuth.instance.currentUser` | — | `Professor?` |

Senha nunca no RTDB.

---

## RTDB — `turmas`

| Método | Op | Path / query | Params | Retorno |
|--------|-----|--------------|--------|---------|
| `listByProfessor` | query | `turmas` orderByChild `professorId` | `professorId` | `List<Turma>` |
| `getById` | read | `turmas/{id}` | `id` | `Turma?` |
| `create` | write | `turmas/{id}` set | `Turma` | `Turma` |
| `update` | write | `turmas/{id}` update | `Turma` | `Turma` |
| `delete` | write | remove turma + alunos da turma | `id` | void |

---

## RTDB — `alunos`

| Método | Op | Path / query | Params | Retorno |
|--------|-----|--------------|--------|---------|
| `listByTurma` | query | `alunos` orderByChild `turmaId` | `turmaId` | `List<Aluno>` |
| `getById` | read | `alunos/{id}` | `id` | `Aluno?` |
| `create` / `update` / `delete` | write | `alunos/{id}` | — | — |
| `importMock` | multi-path update | `alunos/*` | `turmaId` | `List<Aluno>` |

---

## RTDB — `questoes`

| Método | Op | Path / query | Params | Retorno |
|--------|-----|--------------|--------|---------|
| `listAll` | query | `questoes` by `professorId` (+ filtro client) | `query?` | `List<Questao>` |
| `getById` / CRUD | — | `questoes/{id}` | — | — |

`professorId` obrigatório. `alternativas` length = 4; `gabaritoIndex` 0–3.

---

## RTDB — `provas`

| Método | Op | Path / query | Params | Retorno |
|--------|-----|--------------|--------|---------|
| `listAll` | query | `provas` by `professorId` | — | `List<Prova>` |
| CRUD | — | `provas/{id}` | — | — |
| `listVariacoes` | query | `variacoes_de_prova` by `provaId` | `provaId` | `List<VariacaoDeProva>` |
| `getVariacaoById` | read | `variacoes_de_prova/{id}` | `id` | `VariacaoDeProva?` |
| `gerarVariacao` | client + set | embaralha + escreve variação | flags shuffle | `VariacaoDeProva` |

---

## RTDB — `correcoes`

| Método | Op | Path / query | Params | Retorno |
|--------|-----|--------------|--------|---------|
| `listAll` | read | `correcoes` | — | `List<Correcao>` |
| `getById` | read | `correcoes/{id}` | `id` | `Correcao?` |
| `getByAluno` | query | by `alunoId` | `alunoId` | `Correcao?` |
| `simularLeitura` | client + set | lê variação, simula respostas, grava | `variacaoId`, `alunoId` | `Correcao` |

---

## Mapa tela → operação

| Tela / rota | Operações |
|-------------|-----------|
| `/login`, `/cadastro` | Auth `login` / `register` |
| `/turmas` | `turmas.listByProfessor` |
| `/turmas/nova`, `.../editar` | `turmas.create` / `update` |
| `/turmas/:id` | `turmas.getById` + `alunos.listByTurma` |
| `.../alunos/*`, `.../importar` | alunos CRUD / `importMock` |
| `/questoes` | `questoes.listAll` |
| `/questoes/nova`, `.../editar` | create / update |
| `/provas` | `provas.listAll` |
| `/provas/nova` | `provas.create` |
| `.../variacoes` | `listVariacoes` + `gerarVariacao` |
| `/mais/correcao` | `simularLeitura` |
| `/mais/resultados` | `correcoes.listAll` |
| `/mais/estatisticas` | `correcoes.listAll` |

## Fora do RTDB

- Export `.xlsx` / `.doc`
- Câmera / QR real (hoje simulado)

## Fonte

- Repos: `lib/features/*/data/repositories/*_rtdb_repository.dart`
- Schema: [BANCO-DE-DADOS.md](BANCO-DE-DADOS.md)
- Seed: [seed/realtime-database-seed.json](seed/realtime-database-seed.json)
