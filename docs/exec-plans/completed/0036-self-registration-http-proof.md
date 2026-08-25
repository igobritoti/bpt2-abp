# Execution Plan 0036 — Self-registration HTTP Proof

Status: **CONCLUÍDO**

## Objetivo

Fechar o gap de evidência explicitamente deixado pelo Plan 0027: provar em banco fresco que o Account module realmente permite self-registration no BPT2 e que o usuário criado consegue autenticar pelo fluxo local existente.

Vertical proof:

`fresh DB → /Account/Register disponível → POST /api/account/register cria usuário → password grant autentica o novo usuário`

## Contexto

Base remota verificada: `8cd2e3430e7b80fb178b0d41b556b575a50d0041`, após o merge do Plan 0035.

Antes deste slice:

- o Plan 0027 manteve cadastro de usuário fora dos blockers porque o BPT2 usa o Account Web do ABP e não havia evidência de self-registration desabilitado;
- esse mesmo plano registrou que um E2E BPT2 dedicado aumentaria a força da prova;
- `scripts/seller-auth-http-smoke.sh` provava OIDC discovery, PKCE obrigatório e redirect para `/Account/Login`, mas não criava usuário novo;
- a documentação oficial atual do ABP declara `/Account/Register` e `AccountSettingNames.IsSelfRegistrationEnabled = true` por padrão e informa que `IAccountAppService.RegisterAsync` aplica essa configuração.

## Escopo executado

- o Seller Auth smoke continua sendo a única boundary focal deste comportamento;
- `/Account/Register` é acessado no host real e validado como página de cadastro com username/e-mail/password;
- um usuário único é criado anonimamente por `POST /api/account/register` com `RegisterDto`;
- a resposta é validada por `id`, username e e-mail;
- o mesmo usuário obtém token via password grant com sua própria senha;
- os checks anteriores de OIDC discovery, PKCE obrigatório e redirect para login permanecem no mesmo smoke.

## Fora de escopo

- customizar UI de Account;
- confirmação de e-mail;
- recuperação de senha;
- social login;
- roles/permissões novas;
- perfil Seller automático;
- mudança de política de cadastro;
- migration/schema/infra.

## Critérios de aceite

1. [x] `/Account/Register` retorna página disponível no host real.
2. [x] `POST /api/account/register` cria usuário novo sem credencial administrativa.
3. [x] resposta de registro contém identidade coerente com username/e-mail enviados.
4. [x] o usuário recém-criado consegue obter access token com sua própria senha.
5. [x] os checks existentes de discovery, PKCE e login redirect continuam verdes.
6. [x] nenhuma política, schema ou feature de produto adicional foi introduzida.

## Evidência executada

Head funcional: `89d39c7ba2a5854e0fb4a5beea663028c490555a`.

O **BPT2 Seller Auth HTTP Gate** passou no run `32861574745`, job `97846584995`, contra PostgreSQL 17 fresco e host ABP real.

Marcadores executados:

- `FRESH MIGRATION GATE: PASSED`
- build .NET: `0 Warning(s)` / `0 Error(s)`
- `SELLER_AUTH_DISCOVERY: PASS`
- `SELF_REGISTRATION_PAGE: PASS`
- `SELF_REGISTRATION_CREATED: PASS`
- `SELF_REGISTRATION_LOGIN: PASS`
- `SELLER_AUTH_PKCE_REQUIRED: PASS`
- `SELLER_AUTH_LOGIN_REDIRECT: PASS`
- `SELLER AUTH HTTP SPIKE: PASSED`

O **BPT2 Harness Gate** também passou no mesmo head funcional.

Classe da evidência: **B — comportamento reproduzido em CI contra aplicação real**.

## Decision log

- **DECIDIDO por evidência:** self-registration está operacional no BPT2 atual; não é apenas comportamento assumido da configuração padrão.
- **DECIDIDO por evidência:** o cadastro cria identidade utilizável para autenticação local imediatamente no estado atual.
- **DECIDIDO:** este slice permanece prova/hardening; nenhuma feature ou política nova foi necessária.
- **NÃO DECIDIDO:** confirmação de e-mail, onboarding automático de Seller e política futura de cadastro.

## Progress log

- 2026-08-25: `main` remoto confirmado em `8cd2e3430e7b80fb178b0d41b556b575a50d0041`.
- 2026-08-25: Seller Hub descartado como próximo gap porque o Plan 0022 já possui prova HTTP real completa.
- 2026-08-25: gap selecionado a partir do Plan 0027: self-registration possuía suporte/configuração documentados, mas não E2E BPT2 dedicado.
- 2026-08-25: Seller Auth smoke ampliado sem mudança de produto/schema.
- 2026-08-25: Harness Gate passou no head funcional.
- 2026-08-25: Seller Auth HTTP Gate passou integralmente, incluindo cadastro e autenticação do usuário novo.

## Resultado

**PASSA / CONCLUÍDO.** O BPT2 agora possui prova executável de:

`usuário anônimo → self-registration → identidade criada → autenticação com credencial própria`

O gap de evidência deixado pelo Plan 0027 está fechado sem adicionar regra, schema ou infraestrutura.
