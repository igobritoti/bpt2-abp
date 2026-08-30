# Technical debt tracker

Dívida técnica conhecida e deliberadamente adiada vive aqui. TODOs locais podem apontar para um ID deste arquivo; não devem ser o único registro de dívida material.

| ID | Área | Dívida / evidência | Trigger para tratar | Estado |
|---|---|---|---|---|
| TD-001 | GitHub / integração | `main` é reportada com `protected=false` e o repositório não possui rulesets, embora `ENGINEERING.md` exija branch → PR → CI → merge. #160 documenta que checks atuais são path-filtered e não devem virar required contexts cegamente. | Acesso administrativo para ativar proteção/ruleset; para required status, primeiro provar um desenho que reporte somente checks aplicáveis ou um fan-in universal sem bloquear PRs por workflow não disparado. | BLOQUEADO — #160 |

Quando uma dívida for resolvida, remova-a da tabela no mesmo PR e preserve contexto histórico no execution plan/ADR relevante se houver valor.
