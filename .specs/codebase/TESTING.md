# Testing Infrastructure

**Analyzed:** 2026-04-10

## Test Frameworks

- Unit/Integration: nenhum framework identificado
- E2E: nenhum framework identificado
- Coverage: nenhum tooling identificado

## Test Organization

**Location:** `lua/zettelvim/testes/`

**Naming:** arquivos com prefixo `Test` e sufixo `.lua`

**Structure:** scripts simples, sem harness visível, sem assertions explícitas e sem comando central de execução

## Testing Patterns

### Unit Tests

**Approach:** inexistente como suíte formal
**Location:** não identificado

O repositório não contém chamadas para `busted`, `plenary`, `luassert`, `mini.test` ou equivalente. Não há arquivos de configuração de teste nem convenção de fixtures reutilizáveis.

### Integration Tests

**Approach:** manual / ad hoc
**Location:** `lua/zettelvim/testes/`

Os dois arquivos encontrados funcionam mais como scripts de exercício do fluxo:

- `TestNovaNota.lua` chama `NovaNota(...)`
- `TestSerializeMarkdown.lua` chama `SerializeMarkdown(Geologia)`

Esses scripts pressupõem que símbolos globais e contexto anterior já estejam carregados.

### E2E Tests

**Approach:** inexistente
**Location:** não identificado

Não há cenários automatizados cobrindo interação real com buffers do Neovim, keymaps, `buftype`, Tree-sitter ou o vault externo.

## Test Execution

**Commands:** nenhum comando oficial documentado

**Configuration:** inexistente no repositório

Na prática, o comportamento parece ser validado manualmente dentro do próprio Neovim, com inspeção de arquivos no diretório `NVIM_TEMPESTADE`.

## Coverage Targets

- Current: não mensurável no estado atual
- Goals: não documentados
- Enforcement: inexistente

## Observed Quality Signals

- há comentários e `print()` úteis para depuração manual
- o fluxo principal depende fortemente de estado do editor, o que torna testes unitários puros menos diretos
- a ausência de testes automatizados aumenta o risco em mudanças que tocam `config.lua` e `utils.lua`

## Testing Gaps Relevant to Current Codebase

- comportamento em buffers especiais (`terminal`, `help`, `nofile`, `prompt`)
- compatibilidade com notas sem extensão marcadas via autocmd
- deduplicação de links e atualização do índice `ranking`
- robustez diante de notas/índice inexistentes ou corrompidos
- regressões na integração com Tree-sitter markdown

## Recommended Baseline for Future Features

- introduzir um harness mínimo para executar funções Lua em modo headless do Neovim
- separar helpers puros de manipulação de texto/links do código acoplado a buffer
- começar cobrindo fluxos críticos de `ZettelVimCreateorFind()` e `NormalCall()/VisualCall()`
