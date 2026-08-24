# Execution Plan 0012 — Moderation Report Inbox

Status: **ATIVO**

## Objetivo

Fechar o primeiro loop operacional de moderação expondo uma fila read-only de `ListingReport` somente para operador autorizado, sem inventar política de moderação.

Fluxo:

`Buyer sinaliza Listing → report persistido → operador admin autenticado consulta fila`

## Evidência que abriu o slice

- `docs/PRODUCT.md` define moderação e administração como capacidades centrais.
- O Plan 0011 já persiste `ListingReport`, mas o contrato existente só permite criar o sinal e consultar o estado do próprio Buyer.
- Não existe hoje query de moderação/admin consumindo os sinais persistidos.
- SEO básico já possui metadata dinâmica no detalhe público; promoções, Vehicle Hub e ingestão não fecham um loop operacional já iniciado.

## Escopo

- query autenticada para listar reports;
- autorização restrita a operador `admin` já existente no baseline ABP;
- retorno mínimo com identidade do report, Listing, título/status do Listing e instante do sinal;
- ordenação determinística por mais recente;
- histórico permanece consultável mesmo quando o Listing deixa de estar público;
- prova HTTP real cobrindo autorização e histórico.

## Fora de escopo

- motivo/taxonomia ou texto livre;
- aprovar/rejeitar denúncia;
- remover, pausar ou suspender Listing automaticamente;
- workflow/status de moderação;
- scoring, thresholds ou priorização;
- notificação ao Seller/Buyer;
- perfil/PII do Buyer;
- novo frontend/admin shell ou novo cliente OIDC.

## Critérios de aceite

- [ ] rota convencional da inbox existe;
- [ ] anônimo não acessa;
- [ ] Buyer autenticado sem role admin não acessa;
- [ ] admin autenticado recebe reports persistidos;
- [ ] itens de Listings pausados/arquivados continuam na fila como histórico;
- [ ] query não expõe PII Buyer;
- [ ] todos os workflows aplicáveis ficam verdes no head funcional.

## Progress log

- 2026-08-24: slice aberto a partir do gap operacional deixado pelo Plan 0011: sinal persistido sem consumidor de moderação.

## Decision log

- 2026-08-24: primeira inbox é read-only; política/ações de moderação continuam NÃO DECIDIDAS.
- 2026-08-24: autorização mínima reutiliza a role `admin` já presente no baseline ABP; não é criada taxonomia própria de roles neste slice.
