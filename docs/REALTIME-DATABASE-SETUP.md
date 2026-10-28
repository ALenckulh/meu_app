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

## 3. Ligar ao Auth UID

O seed usa `prof-1`. Troque pelo UID real:

1. **Authentication** → copie o `uid`
2. No Data, renomeie `professores/prof-1` → `professores/{uid}`
3. Em cada `turmas/*`, `questoes/*`, `provas/*`: campo `professorId` = esse `uid`

Ou edite o JSON antes do import (substituir todas as ocorrências de `prof-1`).

## 4. Regras mínimas (temporário)

Em **Rules**, para testar import + Auth:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

Aperte depois por path (`professores/$uid`, `turmas` com `professorId`, etc.).

## 5. Flutter

App usa `firebase_database` + `*RtdbRepository` (ver [ARQUITETURA.md](ARQUITETURA.md)).

Confirme `databaseURL` em `lib/firebase_options.dart` igual à URL do Console.

Deploy regras:

```bash
firebase deploy --only database
```
