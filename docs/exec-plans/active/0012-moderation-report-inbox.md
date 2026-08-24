# Execution Plan 0012 — Moderation Report Inbox

Status: **ATIVO**

## Objetivo

Fechar o primeiro loop operacional de moderação permitindo que somente um operador administrativo autenticado consulte, em modo read-only, os sinais de Listing já persistidos pelo Plan 0011.

Fluxo:

`Buyer sinaliza Listing → report persistido → Admin autenticado consulta fila`

## Evidência que abriu o slice

- `docs/PRODUCT.md` mantém moderação e administração como capacidades centrais.
- O Plan 0011 passou a persistir `ListingReport`, mas o contrato atual só permite criar o sinal e consultar o estado do próprio Buyer.
- Não existe query administrativa/operacional que consuma `ListingReport`.
- SEO básico já possui metadata no detalhe público; promoções, Vehicle Hub e ingestão são expansões independentes e maiores.

## Escopo

- query read-only de reports no Marketplace;
- autorização restrita ao papel administrativo já existente no host ABP;
- retorno mínimo de report, Listing e instante do sinal;
- ordenação determinística mais recente primeiro;
- histórico visível mesmo se o Listing estiver Pause/Archive;
- prova HTTP real de autorização, isolamento e preservação histórica.

## Fora de escopo

- motivo/taxonomia ou texto livre;
- aprovar/rejeitar denúncia;
- suspensão/remoção automática ou manual;
- scoring, threshold ou prioridade;
- notificação ao Seller/Buyer;
- resolução de PII do Buyer;
- nova UI/admin client;
- nova infraestrutura.

## Critérios de aceite

- [ ] rota convencional da inbox existe;
- [ ] anônimo recebe 401;
- [ ] usuário autenticado sem papel admin recebe 403;
- [ ] admin autenticado visualiza reports persistidos;
- [ ] item retorna apenas dados mínimos necessários e não resolve PII Buyer;
- [ ] reports permanecem visíveis depois de Pause/Archive do Listing;
- [ ] build/migrations e gates aplicáveis permanecem verdes.

## Progress log

- 2026-08-24: slice aberto a partir do gap operacional deixado explicitamente pelo Plan 0011: há sinais persistidos, mas nenhum consumidor administrativo.

## Decision log

- 2026-08-24: primeiro consumo de moderação é read-only; nenhuma política de enforcement será inventada neste slice.
- 2026-08-24: autorização reutiliza o papel administrativo já existente no host, sem criar taxonomia nova de permissões antes de necessidade comprovada.
