# Realtime Database Setup — meu_app

Projeto: `app-correcao-provas`  
Auth já existe. Dados: **Realtime Database** (não Firestore).

Schema lógico: [BANCO-DE-DADOS.md](BANCO-DE-DADOS.md) (mesmas entidades; RTDB = árvore JSON).

## 1. Criar o banco

1. Console → **Build** → **Realtime Database** → **Create Database**
2. Location: preferência BR (ex. `southamerica-east1`) se disponível
3. Security: **locked mode** (ajuste regras depois)

## 2. Importar seed (Console)

Arquivo: [`docs/seed/realtime-database-seed.json`](seed/realtime-database-seed.json)

1. Realtime Database → aba **Data**
2. Menu **⋮** (canto da raiz `/`) → **Import JSON**
3. Selecione `realtime-database-seed.json`
4. Confirme

**Atenção:** Import substitui os dados naquele path. Na raiz `/`, sobrescreve tudo.

### Limpar demo do seed (recomendado em multi-professor)

O JSON de demo inclui chaves fixas (`aluno-*`, `turma-*`, `corr-*`, `var-*`, `prova-1`, `q*`).  
Se outro professor não deve ver esses nós no Console (ou turmas/alunos legados), **apague** no Console (Data → nó → Delete) ou não importe a seção correspondente.

`correcoes.listAll` no app filtra por `professorId` = Auth uid. Nós `corr-*` sem `professorId` (ou de outro uid) **não** aparecem em Resultados.

## 3. Ligar ao Auth UID

O seed usa um `professorId` de exemplo. Troque pelo UID real:

1. **Authentication** → copie o `uid`
2. No Data, renomeie `professores/prof-1` → `professores/{uid}`
3. Em cada `turmas/*`, `questoes/*`, `provas/*`: campo `professorId` = esse `uid`

Ou edite o JSON antes do import (substituir todas as ocorrências de `prof-1`).

## 4. Regras — **obrigatório publicar**

Locked mode (`.read/.write: false`) faz o Auth parecer “quebrado” no app:
cadastro/login passam no Network, mas a gravação de `professores/{uid}` falha.

Console → Realtime Database → **Rules** → cole e **Publish** o conteúdo de [`database.rules.json`](../database.rules.json) (`auth != null` + `.indexOn` para queries).

Ou: `firebase deploy --only database`.

Sem Publish no Console, o arquivo do repo **não** vale. Sem `.indexOn`, listas falham com `index-not-defined`.

## 5. Flutter

App usa `firebase_database` + `*RtdbRepository` (ver [ARQUITETURA.md](ARQUITETURA.md)).

`databaseURL` em `lib/firebase_options.dart` deve ser a **API URL**  
(ex.: `https://app-correcao-provas-default-rtdb.firebaseio.com`),  
**não** o link da página do Console (`console.firebase.google.com/...`).

Cadastro/login gravam `professores/{Auth.uid}` automaticamente.

Deploy regras:

```bash
firebase deploy --only database
```
