# Execution Plan 0036 — Self-registration HTTP Proof

Status: **ATIVO**

## Objetivo

Fechar o gap de evidência explicitamente deixado pelo Plan 0027: provar em banco fresco que o Account module realmente permite self-registration no BPT2 e que o usuário criado consegue autenticar pelo fluxo local existente.

Vertical proof:

`fresh DB → /Account/Register disponível → POST /api/account/register cria usuário → password grant autentica o novo usuário`

## Contexto

Base remota verificada: `8cd2e3430e7b80fb178b0d41b556b575a50d0041`, após o merge do Plan 0035.

Evidência atual:

- o Plan 0027 manteve cadastro de usuário fora dos blockers porque o BPT2 usa o Account Web do ABP e não havia evidência de self-registration desabilitado;
- esse mesmo plano registrou que um E2E BPT2 dedicado aumentaria a força da prova;
- `scripts/seller-auth-http-smoke.sh` hoje prova OIDC discovery, PKCE obrigatório e redirect para `/Account/Login`, mas não cria usuário novo;
- a documentação oficial atual do ABP declara `/Account/Register` e `AccountSettingNames.IsSelfRegistrationEnabled = true` por padrão e informa que `IAccountAppService.RegisterAsync` aplica essa configuração.

## Escopo

- estender somente o smoke Seller Auth existente;
- provar que `/Account/Register` está disponível em runtime real;
- criar um usuário único via `POST /api/account/register` usando o contrato oficial `RegisterDto`;
- provar que o novo usuário autentica pelo password grant já habilitado para o cliente de app usado pelos smokes;
- manter banco fresco e host real como boundary de evidência.

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

1. [ ] `/Account/Register` retorna página disponível no host real.
2. [ ] `POST /api/account/register` cria usuário novo sem credencial administrativa.
3. [ ] resposta de registro contém identidade coerente com username/e-mail enviados.
4. [ ] o usuário recém-criado consegue obter access token com sua própria senha.
5. [ ] os checks existentes de discovery, PKCE e login redirect continuam verdes.
6. [ ] nenhuma política, schema ou feature de produto adicional é introduzida.

## Decision log

- **DECIDIDO por evidência:** este slice é prova/hardening, não nova feature; o comportamento já é fornecido pelo Account module.
- **DECIDIDO:** reutilizar o Seller Auth gate existente, porque ele já é a boundary HTTP do Account/OpenIddict no BPT2.
- **NÃO DECIDIDO:** confirmação de e-mail, onboarding automático de Seller e política futura de cadastro.

## Progress log

- 2026-08-25: `main` remoto confirmado em `8cd2e3430e7b80fb178b0d41b556b575a50d0041`.
- 2026-08-25: Seller Hub descartado como próximo gap porque o Plan 0022 já possui prova HTTP real completa.
- 2026-08-25: gap selecionado a partir do Plan 0027: self-registration possui suporte/configuração documentados, mas não E2E BPT2 dedicado.
