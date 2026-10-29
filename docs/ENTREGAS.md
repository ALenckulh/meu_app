# Entregas

## N1 — Protótipo navegável (entregue)

- [x] Login/cadastro mock
- [x] Dashboard + NavigationBar
- [x] CRUD turmas e alunos + importação mock
- [x] Banco de questões (CRUD, busca, gabarito)
- [x] Provas (seleção, ordem, variações, preview)
- [x] Geração (prévia prova, folha, QR, individualização)
- [x] Correção simulada
- [x] Resultados + estatísticas/gráfico

## N2 — Sistema funcional

- [x] Firebase Auth + Realtime Database
- [x] CRUD real turmas/alunos/questões/provas (`*RtdbRepository`)
- [x] Importação CSV real (`file_picker` + `CsvAlunosParser`, prévia com validação)
- [x] Variações reais + remapeamento de gabarito persistido (`prova.turmaId`)
- [x] PDF + QR real (`pdf`/`printing`: prova geral, folha geral, prova+folha por aluno e da turma inteira; QR `CPROVA|v1|p=..|v=..|a=..`)
- [x] Câmera + leitura do QR (`mobile_scanner`) — identifica prova, variação e aluno
- [x] Correções e estatísticas reais (respostas A–D manuais pós-QR; `correcoes` filtradas por `professorId`)
- [x] README v2 — contrato no [`README.md`](../README.md) (escopo N2, RF status, run, APK)
- [ ] Leitura óptica das marcações da folha (OMR) — **N3**

### Entrega Moodle (fora do git)

- Zip do projeto **sem** pasta `build/` + APK release + README v2 (já no repo)
- Diários individuais (um por aluno); naming: `N2_NumDoGrupo.zip`, `N2_NomeDoAluno_diario.*`

## N3 — Completo e validado (pendente)

- [ ] Segurança RTDB / isolamento por professor (além de `auth != null`)
- [ ] OCR / OMR robusto da folha
- [ ] Exportação Excel/relatórios
- [ ] Testes automatizados amplos
- [ ] Layout de impressão validado
