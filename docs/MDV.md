# MDV — Matriz de Decisão e Verificação

Estados: PASSA, NÃO PASSA, DECIDIDO, NÃO DECIDIDO, ADIADO.

| ID | Questão | Estado |
|---|---|---|
| ARCH-001 | ABP 10.6 baseline | DECIDIDO |
| ARCH-002 | Modular Monolith | DECIDIDO |
| ARCH-003 | app-nolayers / evitar classic layered | DECIDIDO |
| MOD-001 | Cross-module via Contracts/events | DECIDIDO |
| MOD-002 | Implementation-to-implementation entre módulos | NÃO PASSA / PROIBIDO |
| DATA-001 | PostgreSQL | DECIDIDO |
| DATA-002 | Estratégia final de DbContext compartilhado/substituído | NÃO DECIDIDO até Gate 01 no repo novo |
| DATA-004 | Schema PostgreSQL separado por módulo | NÃO DECIDIDO |
| DATA-005 | FK física cross-module | NÃO DECIDIDO |
| TX-001 | ABP Unit of Work como mecanismo | DECIDIDO |
| TX-002 | Atomicidade multi-módulo no desenho final | NÃO DECIDIDO até teste |
| CON-001 | Optimistic concurrency disponível | DECIDIDO como mecanismo |
| CON-002 | Aplicação exata em Listing | NÃO DECIDIDO até teste |
| AUTH-001 | Seller ownership enforcement | NÃO DECIDIDO até teste |
| AUTH-002 | Público nunca vê Draft/private | DECIDIDO como requisito; teste obrigatório |
| LOCK-001 | Distributed locking | ADIADO até caso real |
| JOB-001 | Background jobs | ADIADO até caso real |
| SEARCH-001 | PostgreSQL vs engine externo | NÃO DECIDIDO; benchmark futuro |

## Regra de decisão

Documentação/código/standard -> capacidade comprovada -> teste mínimo se a decisão específica do BPT não estiver resolvida -> PASS/FAIL -> decisão registrada.

Inferência ou preferência não vira requisito arquitetural sem evidência.
