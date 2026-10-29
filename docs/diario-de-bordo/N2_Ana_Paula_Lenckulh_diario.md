# Diário de bordo — Ana Paula Lenckulh

**Aluna:** Ana Paula Lenckulh  
**Git / GitHub:** `anaPaulaSystextil` (`ana.paula@systextil.com.br`) · repositório `ALenckulh/meu_app`  
**Projeto:** App de Correção Automática de Provas  

Este diário separa **N1** e **N2**. Tarefas listadas a partir dos commits atribuídos à conta acima. Trabalho de colegas (Auth UI Karoliny, CSV/PDF Letícia, etc.) só aparece quando houve **merge/integração** nos meus commits — não como tarefa exclusiva minha.

---

## N1 — Protótipo navegável

### Tarefas

| Data | Commit | Tarefa |
|------|--------|--------|
| 2026-09-09 | `377fdb8` | Commit inicial: protótipo Flutter N1 (telas, navegação, fluxo mock) |
| 2026-09-24 | `f6bde90`, `62aefe4`, `b892945`, `5014356`, `255fa3c` | Scripts e configuração de deploy na Vercel (build web) |
| 2026-09-24 | merges `78ba066`, `bf8023b`, `3d2e409`, `7e77c0e` | Integração com `origin/main` / alinhamento da branch |
| 2026-09-24 | `80b3b65` | Melhoria da paleta de cores do app |

### Evidências N1

> Colar prints aqui (telas N1, PRs N1 se houver).

- [ ] Print tela(s) do protótipo  
- [ ] Print PR / review / merge (se aplicável na N1)  

---

## N2 — Integração com banco real

**Banco usado:** Firebase Auth + **Realtime Database** (não Firestore). Motivo técnico: árvore JSON + repos `*RtdbRepository` já definidos no app; documentado em `docs/REALTIME-DATABASE-SETUP.md` e `docs/BANCO-DE-DADOS.md`.

### Tarefas (commits meus)

| Data | Commit | O que fiz |
|------|--------|-----------|
| 2026-10-28 | `fde4e19`, `19f1e20` | WIP de integração com banco / endpoints (preparação RTDB) |
| 2026-10-29 | `1ce1a09` | **Integrar endpoints e banco:** Auth ↔ perfil professor no RTDB, `databaseURL` / `rtdb` nos repos, regras e seed, `main` com `instanceFor` |
| 2026-10-29 | `3e35d77` | **Merge** de `origin/main` (CSV / PDF / QR da câmera — trabalho do grupo, esp. Letícia) na branch `dev` com RTDB |
| 2026-10-29 | `4ba121f` | **Fechar N2 dados reais:** `Correcao.professorId` + filtro por uid; `Prova.turmaId` (form, detalhe, lista, variações multi-aluno); correção manual A–D pós-QR; simular resultado com aluno real sem correção; docs ENTREGAS/ENDPOINTS/seed; remoção `importMock` |
| 2026-10-29 | push `dev` | Publicar commits locais (incl. `lib/core/data/rtdb.dart`) para corrigir build Vercel (`Undefined name 'rtdb'`) |
| 2026-10-29 | `a628fd3` | UX: turma única, hub Imprimir, aba Corrigir, stats em Resultados |
| 2026-10-29 | branch `feat/n2-entrega` | **README v2** + ENTREGAS + abertura do PR N2 (rastro review/merge) |

### Integração com o grupo (não é commit só meu de feature)

- Auth/cadastro Firebase na UI: commits de Karoliny (ex. PR #4 mergeado no histórico).  
- Importação CSV + PDF/QR + `mobile_scanner`: commits de Leticia-Waismann — **incorporados** por mim no merge `3e35d77`.  
- Tentativas Firestore (Vitor): não são minha entrega; o app consolidou em **RTDB**.

### Cruzamento com backlog N2

| Item combinado (resumo) | Status | Observação |
|-------------------------|--------|------------|
| Conectar banco real e tirar mock das telas centrais | Feito | RTDB + Auth; CRUD via `*RtdbRepository` |
| Docs de banco / endpoints / setup | Feito | `BANCO-DE-DADOS`, `ENDPOINTS`, `REALTIME-DATABASE-SETUP` |
| Integração CSV/PDF/QR no `dev` | Feito (merge) | Feature originária do grupo |
| Escopo por professor + turma na prova + correção real | Feito | `4ba121f` |
| OMR da folha | Fora / N3 | Respostas A–D manuais após QR |
| Desvio Firestore → RTDB | Justificado | Firebase real; README v2 + este diário |
| README v2 + PR N2 | Feito / em review | branch `feat/n2-entrega` → `main` |

### Evidências N2

> Colar prints: abertura do PR → review/aprovação → merge (rastro completo exigido em N2.md).

- [ ] Print PR aberto  
- [ ] Print review / aprovação  
- [ ] Print merge  
- [ ] Print app com dados no Console RTDB (turmas/alunos/provas/correções)  
- [ ] Print Vercel deploy OK (após push com `rtdb.dart`)  

### Pesquisa / alinhamento

- Definição Auth uid = `professorId`  
- URL da RTDB (API root, não link do Console)  
- `.indexOn` nas Rules (Publish obrigatório)  
- Fluxo N2 vs ENTREGAS (OMR = N3)

---

## Observações finais

- Commits listados: `git log --author=anaPaulaSystextil`.  
- Fluxos de tela atuais: [docs/FLUXOS-USUARIO.md](../FLUXOS-USUARIO.md).  
- README v2 no repositório (`README.md`). Entrega Moodle (grupo): APK, zip sem `build/`, diários dos demais alunos + prints PR aberto → review → merge deste PR `feat/n2-entrega`.
