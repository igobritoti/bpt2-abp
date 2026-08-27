# Saved Search e-mail delivery readiness — BPT2

Data: 2026-08-27

Status: **AUDITADO / BLOQUEADO PARA IMPLEMENTAÇÃO DE DELIVERY**

## Pergunta

O estado atual do BPT2 possui pré-condições suficientes para promover o delivery externo de Saved Search por e-mail sem inventar consentimento, destinatário, provider ou modelo de consistência?

## Resultado executivo

| Boundary | Resultado | Evidência |
|---|---|---|
| Canal técnico provider-neutral | PASSA | Host já referencia `Volo.Abp.Emailing`; `IEmailSender` é a abstração padrão e Development troca por `NullEmailSender`. |
| Provider concreto | NÃO PRECISA SER DECIDIDO AGORA | Código de produto pode depender de `IEmailSender`; provider/configuração é infraestrutura posterior. |
| Consentimento por canal | NÃO PASSA | `AlertEnabled` foi consolidado no Plan 0054 como opt-in de **monitoramento/detecção**, não consentimento de e-mail. |
| Destinatário elegível/verificável | NÃO PASSA | Plan 0036 provou self-registration + login, mas deixou confirmação de e-mail explicitamente fora de escopo. |
| Estado durável de delivery | NÃO PASSA | Não existe contrato persistido de pending/sent/failed/retry para o side effect externo de Saved Search. |
| Idempotência/retry/recovery | NÃO PASSA | ADR-0003 exige coordenação durável, idempotência e retry para messaging externo; o ledger de detecção não equivale a ledger de delivery. |
| Runner automático | BLOQUEADO | Continua faltando deployment/claim/concurrency/retry/restart/locking reproduzível para o runner de Saved Search. |

Conclusão: **não abrir implementação de envio de e-mail ainda**.

## Evidência local

### 1. O BPT2 já possui boundary técnico de e-mail

`main/BomPraTi/BomPraTiModule.cs` importa `Volo.Abp.Emailing` e, em Development, substitui `IEmailSender` por `NullEmailSender`.

Isso prova que o host já reconhece o side effect e possui uma abstração provider-neutral. Não é necessário criar `ISavedSearchSmtpSender`, escolher SendGrid/SES/Resend ou acoplar o Marketplace a um SDK de provider para começar o desenho de produto.

### 2. Monitoramento não é consentimento de e-mail

O Plan 0054 entregou ao Buyer controle explícito de **“Monitorar novas ofertas”** e preservou a semântica de `AlertEnabled` como habilitação da detecção.

Portanto:

`AlertEnabled == true` **não autoriza** inferir `EmailDeliveryEnabled == true`.

Se e-mail for promovido como canal de produto, consentimento de canal precisa ser representado/expresso separadamente ou por um novo contrato que torne essa semântica explícita.

### 3. O cadastro atual não prova destinatário confirmado

O Plan 0036 provou:

`anonymous → self-registration → user created → login`

Mas registrou confirmação de e-mail explicitamente fora de escopo.

Logo, o BPT2 atual prova que uma conta possui um endereço de e-mail informado; não prova, pelo slice executado, que esse endereço passou por confirmação/eligibility suficiente para ser usado como destinatário de alertas externos.

Este audit não inventa a política futura de confirmação. Apenas registra que a pré-condição de “destinatário verificável” já usada nos blockers do produto ainda não foi comprovada.

### 4. Detection ledger não é delivery ledger

O Saved Search possui ledger idempotente de detecção `(SavedSearchId, ListingId)`. Isso impede replay de match, mas não representa o lifecycle de um side effect externo.

Um delivery pode falhar depois do match existir e precisa permitir recuperação sem duplicar envio. ADR-0003 exige, para messaging externo crítico:

- estado durável da operação;
- idempotência;
- retry policy;
- transactional outbox quando um commit precisa causar trabalho posterior;
- compensação/reconciliação quando aplicável.

Portanto não é aceitável implementar:

`match encontrado → await emailSender.SendAsync(...) → marcar depois`

como modelo de consistência.

## Evidência oficial ABP 10.6

Documentação oficial atual do ABP 10.6 confirma:

- `IEmailSender` é a abstração recomendada para manter código provider-independent;
- Emailing possui integração com background jobs;
- `NullEmailSender` é fornecido para ambientes em que envio real não deve ocorrer;
- MailKit, se escolhido no futuro, continua sendo consumido preferencialmente via `IEmailSender`.

Isso resolve a dúvida **arquitetural** de como o código de produto deve depender de e-mail, mas não resolve consentimento, destinatário, durability ou política operacional.

## Decisões

### DECIDIDO

- **EMAIL_CHANNEL_TECHNICAL_BOUNDARY = JÁ EXISTE** via `IEmailSender`.
- **PROVIDER_CONCRETO = NÃO DECIDIR NO CÓDIGO DE PRODUTO** enquanto `IEmailSender` for suficiente.
- **MONITORING_OPT_IN != EMAIL_CONSENT**.
- **DETECTION_LEDGER != DELIVERY_LEDGER**.
- **EMAIL_DELIVERY_IMPLEMENTATION = BLOQUEADO** no estado atual.

### NÃO DECIDIDO

- se e-mail será o primeiro/único canal externo de Saved Search;
- política exata de confirmação/eligibility do destinatário;
- frequência/digest versus envio por match;
- template/localização;
- provider SMTP/API concreto;
- retry/backoff e dead-letter/reconciliation operacionais;
- topologia final do runner.

## Gate mínimo para reabrir implementação

Delivery de Saved Search só volta a ser elegível quando existir evidência suficiente para responder, antes do código:

1. **Consentimento:** qual estado representa opt-in explícito para o canal escolhido?
2. **Destinatário:** qual fonte autoritativa fornece um recipient elegível/verificável?
3. **Durability:** qual entidade/outbox registra pending/sent/failed e a chave idempotente de delivery?
4. **Recovery:** como retry/restart evita perda e duplicação?
5. **Trigger operacional:** qual runner/deployment processa a fila com concorrência segura?
6. **Provider boundary:** implementação continua atrás de `IEmailSender` ou há evidência para uma extensão específica?

Sem esses pontos, permanecer em **PARCIAL/BLOQUEADO**, não implementar workaround.

## Impacto no roadmap

- Saved Search monitoring/detection: **JÁ EXISTE**.
- Saved Search automatic runner: **BLOQUEADO** por deployment/locking.
- Saved Search external delivery: **PARCIAL / BLOQUEADO PARA IMPLEMENTAÇÃO** até os gates acima.
- Favorite price-drop delivery: não herda consentimento de Saved Search; permanece capability separada.
