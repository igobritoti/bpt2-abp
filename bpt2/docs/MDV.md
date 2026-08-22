# MDV — Matriz de Decisão e Verificação

A MDV é a fonte de verdade para distinguir capacidade documentada de decisão BPT.

Estados: `PASSA`, `NAO_PASSA`, `DECIDIDO`, `NAO_DECIDIDO`, `ADIADO`.

| ID | Questão | Estado | Decisão atual |
|---|---|---|---|
| ARCH-001 | ABP 10.6 como chassis | PASSA / DECIDIDO | baseline 10.6 |
| ARCH-002 | Modular monolith | PASSA / DECIDIDO | iniciar como monólito modular |
| ARCH-003 | Evitar arquitetura clássica multilayer por padrão | PASSA / DECIDIDO | host no-layers; criar abstração somente por necessidade |
| MOD-001 | Cross-module via Contracts/events | PASSA / DECIDIDO | implementation-to-implementation proibido |
| DATA-001 | PostgreSQL baseline | PASSA / DECIDIDO | PostgreSQL |
| DATA-002 | Estratégia física final de DbContexts | NAO_DECIDIDO | validar no repositório antes de congelar |
| DATA-004 | Schema PostgreSQL por módulo | NAO_DECIDIDO | não congelar |
| DATA-005 | FK física cross-module | NAO_DECIDIDO | não generalizar sem evidência |
| TX-001 | ABP Unit of Work como mecanismo | PASSA / DECIDIDO | usar mecanismo oficial |
| TX-002 | Atomicidade multi-módulo da composição escolhida | NAO_DECIDIDO | teste mínimo obrigatório quando o slice exigir |
| CON-001 | Optimistic concurrency disponível no ABP | PASSA / DECIDIDO | mecanismo aprovado |
| CON-002 | Aplicação em Listing | NAO_DECIDIDO | provar com conflito concorrente |
| AUTH-001 | Ownership de Listing | NAO_DECIDIDO | provar Seller A x Seller B |
| AUTH-002 | Público não vê Draft | PASSA como requisito / DECIDIDO | kill test obrigatório |
| LOCK-001 | Distributed lock | ADIADO | introduzir somente com caso real |
| SEARCH-001 | PostgreSQL vs search externo | NAO_DECIDIDO | benchmark antes de infraestrutura externa |
| MEDIA-001 | Provider de object storage | NAO_DECIDIDO | não escolher por preferência |
| MIG-001 | Preservação do BPT1 durante o BPT2 | PASSA / DECIDIDO | BPT1 não é descartado; permanece donor/referência até decisão futura explícita |

## Regra epistemológica

Uma opção tecnicamente suportada não vira automaticamente uma decisão do BPT. Preferência/inferência permanece aberta até documentação aplicável ou teste executável distinguir as alternativas.
