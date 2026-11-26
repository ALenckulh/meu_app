# Backlog da N3

Planejamento do que falta para a N3 (sistema completo e validado). A base é a planilha "Status dos requisitos pós N2" do grupo; os itens marcados com ➕ não estavam na planilha e vieram do README/`docs/ENTREGAS.md`.

**Como usar:** o grupo define o **responsável** e o **prazo** de cada tarefa. O status muda conforme o trabalho anda: `A fazer` → `Em andamento` → `Em revisão (PR aberto)` → `Concluído`. Toda tarefa entra por commit → Pull Request → revisão de um colega → merge na `dev`.

## 1. Status dos requisitos pós N2

| Código | Tipo | Requisito | Status na N2 | O que falta (desenvolvimento / teste) |
|---|---|---|---|---|
| RF02 | Funcional | Emissão em formato editável (.doc) | Pendente N3 | Gerar e exportar a prova em formato editável (.doc/.docx) para o professor ajustar o layout. |
| RF06 | Funcional | Leitura e correção pela câmera (OMR) | Concluído na N3 | QR pela câmera e marcações A–D por foto da folha; o professor confere o que ficou em destaque. |
| RF07 | Funcional | Nota automática e feedback imediato | Concluído na N3 | A leitura óptica preenche as respostas e a nota é calculada e salva na hora. |
| RF09 | Funcional | Exportação de notas em planilha (.xlsx) | Pendente N3 | Exportar o relatório de notas da turma em Excel (.xlsx). |
| RF10 | Funcional | Detalhamento de respostas por aluno | Pendente N3 | Incluir nas exportações a alternativa marcada pelo aluno em cada questão (na tela de resultado isso já existe). |
| ➕ RF11 | Funcional | Análise estatística por questão | Concluído na N3 | Feito no Status da prova: % de acertos/erros, alternativa mais marcada e a correta em cada questão. |
| RF12 | Funcional | Acesso por perfil de uso (Web e Mobile) | Parcial | Ajustar a interface Web de gestão/montagem de provas e a sincronização com o app mobile de correção. |
| RNF03 | Não funcional | Precisão no processamento de imagem (OMR) | Parcial | Validado com 25 fotos simuladas a partir do PDF real (perspectiva, rotação, sombra, desfoque, lápis): 1.092/1.092 questões certas, fotos ruins recusadas. Falta testar com folhas impressas e fotografadas no celular. |
| RNF04 | Não funcional | Multiplataforma / portabilidade | Parcial | Garantir e testar a separação dos perfis de uso: Web (gestão) e Mobile (correção pela câmera). |
| RNF05 | Não funcional | Compatibilidade de exportação (.xlsx e .doc) | Pendente N3 | Validar as exportações em .xlsx e .doc. |
| ➕ RNF06 | Não funcional | Segurança de acesso | Parcial | Regras do Realtime Database por professor: cada um só lê e grava os próprios dados (hoje basta estar logado). |

## 2. Tarefas da N3

| # | Tarefa | Requisitos | Responsável | Prazo | Status |
|---|---|---|---|---|---|
| 1 | Leitura óptica (OMR) das marcações A–D pela câmera | RF06, RNF03 | Mirella | 25/11 | Concluído |
| 2 | Nota calculada automaticamente a partir da leitura OMR | RF07 | Mirella | 25/11 | Concluído |
| 3 | Teste de precisão da leitura (QR + marcações) com folhas impressas reais | RNF03 | | | A fazer (simulação feita; falta papel + celular) |
| 4 | Exportar a prova em .doc/.docx editável | RF02, RNF05 | | | A fazer |
| 5 | Exportar as notas da turma em .xlsx | RF09, RNF05 | | | A fazer |
| 6 | Incluir a alternativa marcada por questão na exportação | RF10 | | | A fazer |
| 7 | ➕ Estatística por questão (% acertos/erros e alternativa mais marcada) | RF11 | Mirella | 25/11 | Concluído |
| 8 | Ajustar a interface Web de gestão e testar a sincronização com o mobile | RF12, RNF04 | | | A fazer |
| 9 | ➕ Regras de segurança por professor no Realtime Database, testadas com duas contas | RNF06 | | | A fazer |
| 10 | ➕ Validar o layout de impressão (sem enunciado/alternativa cortados; QR legível) | RF02 | | | A fazer |
| 11 | ➕ Testes automatizados (embaralhamento/gabarito, cálculo da nota) | — | Mirella | 25/11 | Em andamento (nota, relatório, ordem da folha geral e fluxo da correção já cobertos) |
| 12 | ➕ Teste de desempenho: corrigir ~50 alunos em ~30 min | RNF01 | | | A fazer |
| 13 | README final (N3): Modelo de Dados, status dos RF/RNF e backlog da N3, sem apagar N1/N2 | — | | | A fazer |
| 14 | Diário de bordo individual da N3 | — | todos | | A fazer |
| 15 | APK final e .zip do código (sem a pasta `build`) | — | | | A fazer |
| 16 | ➕ Embaralhamento configurado na criação da prova e salvo nela (antes cada tela usava o próprio padrão) | Avaliação N3, item 5 | Mirella | 25/11 | Concluído |
| 17 | ➕ Detalhe da prova: editar título, ver as questões com gabarito, trocar o embaralhamento | Avaliação N3, item 6 | Mirella | 25/11 | Concluído |
| 18 | ➕ Correção pela folha geral (o app pede o aluno), grade A–D igual à folha e aviso de nota salva | Avaliação N3, item 8 | Mirella | 25/11 | Concluído |
| 19 | ➕ Status da prova (relatório): aguardando / em correção / finalizada, pendentes, médias e botão Encerrar correção | Avaliação N3, item 9 | Mirella | 25/11 | Concluído |
| 20 | ➕ Bug: "Digitar código" na correção travava o app ao fechar o diálogo | — | Mirella | 25/11 | Concluído |
| 21 | ➕ Questão em branco ou com duas marcações conta como erro (antes não dava para salvar a nota) | RF07 | Mirella | 25/11 | Concluído |

## 3. Avaliação N3: roteiro da apresentação

O documento da avaliação define 9 funcionalidades, demonstradas nesta ordem. A coluna "No app" diz onde cada uma está.

| # | Funcionalidade (pontos) | No app | Status |
|---|---|---|---|
| 1 | Criar conta de professor (0,5) | Login → **Criar conta** | ✅ |
| 2 | Fazer login (0,5) | Tela de login | ✅ |
| 3 | Criar turma/disciplina (0,75) | **Turmas** → Nova turma (nome + disciplina) | ✅ |
| 4 | Criar questões no banco (1,0) | **Questões** → Nova questão | ✅ |
| 5 | Gerar prova: escolher questões do banco e configurar o embaralhamento (1,25) | **Provas** → Nova prova: título, turma, chaves *Embaralhar questões* / *Embaralhar alternativas* e as questões | ✅ |
| 6 | Ver as provas criadas e abrir uma para conferir e editar (0,75) | **Provas** (lista) → toque na prova: editar título, turma, embaralhamento, questões e ordem | ✅ |
| 7 | Exportar PDF: prova + folha de respostas com QR em página separada (2,0) | Prova → **Imprimir / PDF** → *Imprimir prova + folha*, ou *Escolher aluno e imprimir* (folha individual) | ✅ |
| 8 | Corrigir pelo QR Code, mostrando e salvando a nota (2,5) | Aba **Corrigir**: aponta a câmera para o QR, *Ler marcações pela foto*, confere o que ficou em destaque, *Corrigir e salvar nota* | ✅ |
| 9 | Status da prova depois das correções (0,75) | Prova → **Status da prova (relatório)**, ou *Ver status da prova* no resultado | ✅ |

### Antes do dia da apresentação

- [ ] Ter questões já cadastradas no banco (o roteiro cadastra só uma na hora).
- [ ] Criar a prova que será corrigida ao vivo, com turma e alunos.
- [ ] Imprimir com a versão atual do app: a folha precisa ter os 4 quadrados pretos nos cantos da grade e o quadrado menor ao lado do de cima à esquerda. Folha antiga não é lida pela foto.
- [ ] Preencher as folhas impressas com caneta azul ou preta, pintando o círculo inteiro, e ensaiar a foto: de frente, com boa luz e os 4 quadrados aparecendo.
- [ ] Imprimir 1 caderno de questões e 2 folhas de respostas com QR. Recomendado: em *Escolher aluno e imprimir*, gerar a folha individual de 2 alunos, porque o QR já identifica o aluno. A folha geral também funciona: na correção o app pede o aluno.
- [ ] Não gerar de novo as variações dessa prova depois de imprimir: a folha impressa deixa de valer.
- [ ] O status só fica *Correções finalizadas* quando todos os alunos da turma têm nota. Use uma turma com os 2 alunos das folhas impressas, ou toque em **Encerrar correção** no Status da prova (quem ficou sem nota aparece como ausente).
- [ ] Testar a câmera do APK no celular que vai ser usado e levar o código da folha (botão *Copiar código do QR*) para usar em *Digitar código* se a câmera falhar.

### Roteiro (mesma ordem para todos os grupos)

1. Criar conta → 2. Login → 3. Nova turma → 4. Nova questão (já com outras cadastradas) → 5. Nova prova com questões do banco e embaralhamento → 6. Abrir a prova e editar algo (ex.: título) → 7. Imprimir / PDF, mostrando a prova e a folha com QR em página separada → 8. Pegar a folha já impressa → 9. Aba Corrigir: ler o QR, *Ler marcações pela foto*, conferir os destaques, ver a nota → 10. Mostrar o aviso "Nota salva" e o aluno em Resultados → 11. Abrir o Status da prova: *Correções finalizadas* (ou **Encerrar correção**), médias e estatística por questão.
