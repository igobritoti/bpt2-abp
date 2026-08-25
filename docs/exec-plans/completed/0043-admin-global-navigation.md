# Execution Plan 0043 — Admin Global Navigation

Status: **COMPLETO**

## Objetivo

Fechar o gap pós-MVP de `menu global/tema` explicitamente registrado no Plan 0027: disponibilizar no menu principal do host ABP um ponto de entrada para `/admin`, sem criar permissão, layout ou frontend administrativo paralelo.

Vertical proof:

`admin autenticado → menu principal LeptonXLite → Operações → /admin`

## Contexto

Base remota verificada: `9881ba486aa1536fd9680ce884b9e136e7f75874`, após o merge do Plan 0042.

Evidência:

- o Plan 0027 classifica `menu global/tema` como gap administrativo pós-MVP;
- `/admin` já era o hub administrativo autoritativo, mas o host não registrava contributor/menu próprio;
- `BomPraTiModule` usa LeptonXLite;
- a documentação oficial atual do ABP MVC/Razor Pages define `IMenuContributor` + `AbpNavigationOptions` para contribuir ao `StandardMenus.Main`, renderizado pelo tema;
- `ICurrentUser.IsInRole(string)` existe na API atual do ABP e permite espelhar a mesma role `admin` já exigida pelas páginas administrativas.

## Escopo entregue

- criado `BomPraTiMenuContributor` implementando `IMenuContributor`;
- contributor registrado em `AbpNavigationOptions` no host;
- adicionado um único item `Operações` para `/admin` no menu principal;
- item renderizado somente para `ICurrentUser.IsInRole("admin")`;
- autorização server-side das páginas permaneceu inalterada;
- smoke HTTP real prova que admin recebe `Operações → /admin` e usuário autenticado sem role admin não recebe o link;
- Product API Gate reutilizado, sem novo workflow.

## Fora de escopo preservado

- nova permission/policy;
- submenu por Catálogo/Moderação/Ingestão;
- customização/replacement de layout;
- troca ou fork do tema LeptonXLite;
- frontend admin separado;
- permissões granulares;
- migration/schema/infra;
- novo workflow.

## Critérios de aceite

1. [x] menu principal do host contém `Operações` → `/admin` para usuário `admin` autenticado.
2. [x] usuário autenticado sem role `admin` não recebe o item do Bom Pra Ti no menu principal.
3. [x] `/admin` continua protegida pela role `admin` independentemente do menu.
4. [x] links operacionais existentes de `/admin` continuam alcançáveis.
5. [x] implementação usa `IMenuContributor`/`AbpNavigationOptions`, sem override de layout/tema.
6. [x] nenhuma permission, schema, infra ou autoridade nova foi criada.

## Decision log

- **DECIDIDO por evidência:** usar a infraestrutura de navegação do ABP em vez de editar layout do LeptonXLite.
- **DECIDIDO:** um único item aponta ao hub `/admin`; as operações específicas continuam dentro do hub.
- **DECIDIDO:** visibilidade do menu espelha a role `admin` atual via `ICurrentUser.IsInRole("admin")`; permission granular permanece adiada.
- **DECIDIDO:** esconder o menu melhora descoberta, mas não substitui autorização server-side.
- **DECIDIDO por teste executado:** a prova deve inspecionar semanticamente o anchor `/admin` e seu texto descendente; markup interno do tema não faz parte do contrato.

## Progress log

- 2026-08-25: `main` remoto confirmado em `9881ba486aa1536fd9680ce884b9e136e7f75874`.
- 2026-08-25: ausência de `IMenuContributor`/`AbpNavigationOptions` confirmada no repositório.
- 2026-08-25: documentação oficial atual do ABP confirmou `IMenuContributor`, `StandardMenus.Main`, `AbpNavigationOptions` e resolução de serviços pelo `MenuConfigurationContext`.
- 2026-08-25: API atual de `ICurrentUser` confirmou `IsInRole(string)`.
- 2026-08-25: Host Gate passou com build do contributor e wiring nativo.
- 2026-08-25: primeiro smoke focal encontrou `href="/admin"`, mas a asserção literal `>Operações<` falhou por depender do markup interno do tema.
- 2026-08-25: smoke corrigido para parsear semanticamente o anchor `/admin` e validar texto `Operações` tolerando elementos descendentes.
- 2026-08-25: Product API Gate focal passou incluindo `Exercise admin global navigation`; smokes administrativos anteriores também permaneceram verdes.
