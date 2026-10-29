# App de Correção Automática de Provas

**N2 — sistema funcional:** Flutter + **Firebase Auth** + **Realtime Database**. Telas centrais leem e gravam dados reais (`*RtdbRepository`). Sem mock nas operações de CRUD / provas / correção / resultados.

> **Banco:** o enunciado N2 cita Firestore; este app usa **Realtime Database** (árvore JSON + repos já definidos). Setup: [docs/REALTIME-DATABASE-SETUP.md](docs/REALTIME-DATABASE-SETUP.md).

## N1 (histórico)

Protótipo navegável com interface, navegação e fluxo completo com **dados mockados** (base da N2).

## N2 — estado atual

- Auth: cadastro / login Firebase; perfil em `professores/{uid}`
- CRUD real: turmas, alunos, questões, provas
- Importação CSV de alunos (`file_picker` + validação)
- Variações / embaralhamento com `prova.turmaId` e gabarito remapeado
- PDF + QR (`CPROVA|v1|…`); hub **Imprimir** na prova
- Correção: scan QR + respostas **A–D manuais** (OMR = N3); aba **Corrigir**
- Resultados + estatísticas no app
- Seed opcional no RTDB = dados pré-cadastrados no banco (permitido na N2), não mock in-app

## Executar

```bash
flutter pub get
flutter run
```

1. Configure Firebase / `databaseURL` e Rules — [docs/REALTIME-DATABASE-SETUP.md](docs/REALTIME-DATABASE-SETUP.md)
2. (Opcional) Importe [docs/seed/realtime-database-seed.json](docs/seed/realtime-database-seed.json) e alinhe `professorId` ao seu Auth uid
3. Abra o app → **cadastre** ou faça **login** com conta Firebase Auth (não há login mock)

## APK (entrega N2)

```bash
flutter build apk --release
```

Saída: `build/app/outputs/flutter-apk/app-release.apk`  
(Não versionar `build/` nem o `.apk` no git; entram no zip Moodle.)

## Telas principais

Shell: **Home** · **Turmas** · **Questões** · **Provas** · **Corrigir**  
Resultados / stats: Home ou fluxo pós-correção.  
Jornadas: [docs/FLUXOS-USUARIO.md](docs/FLUXOS-USUARIO.md)

## Documentação

- [docs/ARQUITETURA.md](docs/ARQUITETURA.md)
- [docs/NORMAS-UX.md](docs/NORMAS-UX.md)
- [docs/ENTREGAS.md](docs/ENTREGAS.md) — checklist N1 / N2 / N3
- [docs/N2.md](docs/N2.md) — critérios oficiais da disciplina
- [docs/BANCO-DE-DADOS.md](docs/BANCO-DE-DADOS.md)
- [docs/ENDPOINTS.md](docs/ENDPOINTS.md)
- [docs/REALTIME-DATABASE-SETUP.md](docs/REALTIME-DATABASE-SETUP.md)
- [docs/FLUXOS-USUARIO.md](docs/FLUXOS-USUARIO.md)
- [docs/diario-de-bordo/N2_Ana_Paula_Lenckulh_diario.md](docs/diario-de-bordo/N2_Ana_Paula_Lenckulh_diario.md)
- [Vídeo demonstrativo do sistema](https://www.youtube.com/watch?v=Y0RQv2h-qpc)

## Escopo N1

Fluxo navegável: Login → Turmas/Alunos → Questões → Provas → Variações → Folha/QR → Correção simulada → Resultados.

## Status dos RF/RNF na N2

| Cód. | N2 | Nota |
|------|----|------|
| RF01 | OK | CRUD questões no RTDB |
| RF02 | N3 | PDF (não .doc editável) |
| RF03 | OK | Embaralhamento / variações |
| RF04 | OK | Prova geral + individualizada |
| RF05 | OK | Folha + QR |
| RF06 | Parcial | QR via câmera; marcações OMR = N3 (A–D manuais) |
| RF07 | Parcial | Nota após respostas manuais / simular |
| RF08 | OK | Import CSV |
| RF09–RF10 | N3 | Excel / detalhe export |
| RF11 | OK | Stats em Resultados |
| RF12 | Parcial | Mobile + web (Vercel); foco mobile na correção |
| RNF01–RNF02 | Em uso | |
| RNF03 | N3 | Precisão OMR |
| RNF04 | Parcial | Web gestão / mobile correção |
| RNF05 | N3 | xlsx / doc |

## Requisitos Funcionais e Não Funcionais

Esses são os requisitos funcionais:  
Banco de questões e elaboração de provas  
RF01 - Cadastrar banco de questões: O sistema deve permitir que o professor cadastre e armazene questões com suas respectivas alternativas e indicação da resposta correta.  
RF02 - Emissão em formato editável O sistema deve gerar as provas em formato editável, como .doc, permitindo ao professor ajustar o layout para evitar que enunciados e alternativas fiquem cortados entre páginas.  
RF03 - Embaralhamento de questões e alternativas (Randomização): O sistema deve permitir a geração de provas embaralhando a ordem das questões e a ordem das alternativas.  
RF04 - Gerar provas gerais e individualizadas: O sistema deve permitir a geração de modelos de provas iguais para a turma ou exames individualizados (com identificação do nome do aluno e folha de resposta/gabarito associada).  
  
Gestão de alunos e turmas  
RF05 - Geração de folha de respostas com QR Code: O sistema deve gerar a folha de respostas/gabarito contendo um código de identificação (QR Code) para vinculação à prova e ao aluno.  
RF06 - Leitura e correção via câmera do aplicativo: O sistema deve utilizar a câmera do dispositivo móvel para escanear o QR Code e as marcações nos campos da folha de resposta.  
RF07 - Cálculo automático de nota e feedback imediato: O sistema deve processar a folha de respostas lida, calcular a nota automaticamente e permitir a visualização imediata do resultado.  
RF08 - Importação de lista de alunos: O sistema deve permitir a importação de listas de alunos para vinculação às turmas e às avaliações.  

Relatórios e análise estatística  
RF09 - Exportação de notas em planilha: O sistema deve exportar o relatório final de notas em formato de planilha excel  para facilitar o lançamento no sistema acadêmico.  
RF10 - Relatório de detalhamento de respostas por aluno: O relatório exportado deve indicar não apenas acerto/erro, mas qual alternativa específica o aluno marcou em cada questão.  
RF11 - Análise estatística pedagógica por questão: O sistema deve gerar relatórios estatísticos mostrando o percentual de acertos/erros e qual foi a alternativa mais assinalada pela turma em cada questão.  

Multiplataforma  
RF12 - Acesso por perfil de uso (Web e Mobile): O sistema deve oferecer interface Web para o cadastro de questões e montagem/formatação de provas, e aplicativo Mobile otimizado para a execução da correção via câmera.  

Requisitos não funcionais:  
RNF01 - Desempenho e Agilidade na Correção: O processo de leitura e correção automatizada deve ser rápido, permitindo corrigir o volume de uma turma (cerca de 50 alunos) em aproximadamente 30 minutos.  
RNF02 - Usabilidade e Interface Minimalista: A interface do aplicativo deve ser simples, lógica, amigável e minimalista (com poucos elementos em tela), priorizando a facilidade de uso durante a correção.  
RNF03 - Precisão no Processamento de Imagem: O algoritmo de leitura óptica da câmera deve identificar com alta precisão o QR Code e as marcações nos preenchimentos da folha de respostas.  
RNF04 - Multiplataforma / Portabilidade: O sistema deve possuir uma interface Web para tarefas de gestão/criação de provas e um aplicativo Mobile voltado para a captura e correção via câmera.  
RNF05 - Compatibilidade de Exportação: A exportação de relatórios deve ser gerada em formatos amplamente compatíveis para manipulação de dados pelo usuário, especificamente em planilhas excel (.xlsx) e documentos editáveis (.doc).  

Limites e restrições  
A funcionalidade principal de correção automatizada depende estritamente da presença de uma câmera funcional no dispositivo móvel do professor.  
A leitura visual depende da correta impressão da folha de respostas com o QR Code e os campos de marcação legíveis.  
O sistema é limitado à correção de questões de múltipla escolha (leitura de marcação de alternativas), não cobrindo a correção automatizada de questões discursivas/dissertativas. 
