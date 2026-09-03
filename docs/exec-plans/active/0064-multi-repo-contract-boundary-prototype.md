# Plan 0064 — Multi-repo contract-boundary prototype

Status: **ATIVO**

## Objetivo / outcome

Testar mecanicamente uma fronteira de dois repositórios sobre o estado atual do BPT2 sem migrar o produto: um snapshot backend e um snapshot frontend independentes, com ownership explícito dos arquivos shared/control-plane e um mecanismo fail-closed de sincronização de contrato.

O estudo responde aos thresholds disparados no Plan 0063. Ele não mede produtividade humana, não cria repositórios permanentes e não seleciona monorepo ou split como arquitetura vencedora.

## Contexto congelado antes dos resultados

- `main` de origem: `1006d6c1f1e61942b037487bf1fbc9cd86d3b6ba`;
- evidência precedente: Plan 0063, com 12/13 contract-sync candidates e 13/13 mudanças contendo paths shared/control-plane;
- árvore backend protótipo: checkout completo menos `public-web/**`;
- árvore frontend protótipo: somente `public-web/**`;
- ownership shared/control-plane: permanece no lado backend/plataforma neste protótipo; nenhuma cópia de `docs/**`, `scripts/**`, `.github/**` ou arquivos root é admitida no snapshot frontend;
- contrato público exportado: conteúdo de `modules/**/.Contracts/**` mais `main/BomPraTi/Controllers/**`, identificado por SHA-256 determinístico de path+conteúdo;
- lock frontend: digest do contrato exportado. Lock divergente deve falhar fechado.

## Perguntas de pesquisa

RQ1. O backend atual compila quando `public-web/**` é fisicamente removido da árvore?

RQ2. O frontend atual instala dependências e passa seu gate quando materializado sozinho, sem arquivos shared/root do backend?

RQ3. Um fingerprint determinístico do contrato consegue detectar mecanicamente consumo stale e convergir após atualização explícita do lock?

RQ4. A política de rollout consegue representar, de forma fail-closed, transições `unchanged`, `compatible` e `breaking` sem inferir compatibilidade semântica do código?

RQ5. Quantos arquivos shared/control-plane precisariam ser duplicados no frontend para os builds deste protótipo? O valor observado é métrica do protótipo, não requisito arquitetural.

## Métricas pré-declaradas

- `backend_build_pass`;
- `frontend_install_pass`;
- `frontend_check_pass`;
- número de arquivos backend/frontend/shared no snapshot original;
- `frontend_shared_files_copied`;
- número de arquivos que compõem o contrato exportado;
- digest SHA-256 do contrato;
- stale lock rejeitado (`true/false`);
- lock atualizado aceito (`true/false`);
- resultados da máquina de rollout para `unchanged`, `compatible`, `breaking` e `unknown`.

## Protocolo de compatibilidade / deploy

O protótipo não classifica automaticamente uma mudança real como compatible ou breaking.

Estados:
- `unchanged`: digest igual; deploys independentes permitidos pelo mecanismo;
- `compatible`: classificação externa explícita; backend pode publicar/deployar primeiro, depois frontend atualiza o lock;
- `breaking`: deploy direto fica bloqueado; requer etapa de compatibilidade/dual-support ou rollout coordenado antes da troca do lock;
- `unknown`: bloqueado.

Assim o experimento mede a mecânica de coordenação sem transformar heurística de diff em afirmação semântica.

## Regras de decisão pré-declaradas

- se backend ou frontend não construir isoladamente, split não pode ser recomendado sem primeiro medir/corrigir a dependência que falhou;
- se `frontend_shared_files_copied > 0`, um estudo posterior deve medir custo de ownership/duplicação desses arquivos antes de recomendar split;
- se stale lock não falhar fechado ou lock atualizado não convergir, mecanismo de contrato é inadequado e precisa ser redesenhado antes de qualquer protótipo multi-repo posterior;
- se os três estados de rollout não forem representados fail-closed, não há base para afirmar segurança operacional de deploy separado;
- sucesso de todos os gates prova somente viabilidade mecânica deste particionamento/build e do protocolo de lock; não prova menor custo, maior velocidade ou melhor manutenção.

## Execução

Workflow dedicado deverá:
1. checkout com histórico completo;
2. executar `scripts/prototype-multi-repo-boundary.py` e produzir JSON;
3. materializar backend removendo `public-web` e executar `dotnet build main/BomPraTi/BomPraTi.csproj --configuration Release`;
4. materializar frontend apenas com `public-web`, executar `npm ci --no-audit --no-fund` e `npm run check`;
5. publicar `multi-repo-contract-boundary-prototype.json` como artifact.

## Threats to validity

- builds isolados não equivalem a deploy real;
- frontend não usa hoje um package gerado diretamente dos contratos C#, então o lock é um mecanismo experimental de coordenação, não uma integração de tipos em produção;
- `compatible`/`breaking` são entradas explícitas do protocolo, não inferências automáticas;
- ownership backend/plataforma é uma hipótese operacional deste protótipo;
- um runner GitHub Actions não mede produtividade ou custo humano;
- ausência de shared files no snapshot frontend não prova ausência de conhecimento compartilhado entre equipes.

## Critérios de aceite

- protocolo registrado antes do resultado;
- produto/runtime/schema/dependencies inalterados;
- artifact machine-readable produzido em head exato;
- builds backend/frontend isolados executados;
- stale/updated lock e rollout state machine testados;
- conclusões limitadas às métricas acima;
- checks aplicáveis verdes e nenhum review thread pendente antes de merge.
