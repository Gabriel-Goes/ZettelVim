# Buffer Source Guard Tasks

**Design**: `.specs/features/001-e382-buftype-guard/design.md`
**Status**: Closed
**Audit**: `.specs/features/001-e382-buftype-guard/audit-T1-T7.md`
**Validation**: `.specs/features/001-e382-buftype-guard/validation-T8-T10.md`

---

## Pre-Execution Tool Check

Antes de executar estas tasks, o agente responsável deve confirmar com o usuário
quais ferramentas locais prefere usar.

**Assunção padrão para esta feature:**

- MCP: `NONE`
- Skill: `NONE`
- Ferramentas locais suficientes: shell + edição local de arquivos

Se o executor tiver um harness headless de Neovim já padronizado no projeto,
ele pode usá-lo nas tasks de validação; caso contrário, seguir a validação
manual descrita abaixo.

---

## Execution Plan

### Phase 1: Foundation (Sequential)

Definir as novas interfaces públicas e extrair helpers base em `utils.lua`.

```text
T1 → T2 → T3
```

### Phase 2: Core Implementation (Sequential)

Implementar a escrita file-based de links, refatorar o orquestrador e então
atualizar a camada de comandos em `config.lua`.

```text
T3 → T4 → T5 → T6
```

### Phase 3: Validation (Sequential)

Validar sintaxe/carregamento e depois os dois cenários funcionais da spec.

```text
T6 → T7 → T8 → T9 → T10
```

### Why No Parallelism

Não há paralelismo seguro relevante nesta feature.

- `T1` a `T5` compartilham o mesmo write set em `lua/zettelvim/utils.lua`
- `T6` altera `lua/zettelvim/config.lua`, mas depende da interface concluída em `utils.lua`
- `T8`, `T9` e `T10` validam o mesmo fluxo final e devem rodar sobre o estado já integrado

---

## Task Breakdown

### T1: Expor helpers públicos de classificação da fonte

**What**: criar helpers públicos em `utils.lua` para responder se um caminho está dentro de `tempestade_path` e se o buffer atual é uma nota.
**Where**: `lua/zettelvim/utils.lua`
**Depends on**: None
**Reuses**: regra de prefixo de `setMarkdonwFileType()`

**Tools**:

- MCP: `NONE`
- Skill: `NONE`

**Done when**:

- [ ] Existe um helper público equivalente a `is_nota_path(path)`
- [ ] Existe um helper público equivalente a `buffer_atual_e_nota()`
- [ ] A regra usada é a mesma de `setMarkdonwFileType()`
- [ ] Nenhuma mudança foi feita em `ZettelVimNovaNota()`

**Verify**:

```bash
rg -n "is_nota_path|buffer_atual_e_nota|setMarkdonwFileType" lua/zettelvim/utils.lua
```

**Expected**: os helpers novos aparecem em `utils.lua` e a checagem continua baseada em `tempestade_path`.

---

### T2: Criar `SourceContext` e o resolvedor da fonte atual

**What**: adicionar em `utils.lua` um resolvedor de contexto da fonte atual, incluindo `is_nota`, `source_kind`, `source_ref`, `source_note_name`, `source_path`, `bufname` e `buftype`.
**Where**: `lua/zettelvim/utils.lua`
**Depends on**: T1
**Reuses**: `vim.fn.expand`, `vim.bo.buftype`, `vim.bo.channel`, `vim.fn.getcwd`, `vim.api.nvim_buf_get_name`, `vim.api.nvim_get_chan_info`, `os.getenv("USER")`, `vim.loop.os_gethostname()`

**Tools**:

- MCP: `NONE`
- Skill: `NONE`

**Done when**:

- [ ] Existe uma função equivalente a `resolve_source_context()`
- [ ] Quando a fonte é nota, `source_ref` representa o nome da nota fonte
- [ ] Quando a fonte é terminal, `source_ref` prioriza `bufname` e inclui `argv0` quando disponível
- [ ] Quando a fonte não é terminal, `source_ref` prioriza `bufname` útil e recua para `{user}@{host} {cwd} ({buftype})` quando necessário
- [ ] Existem fallbacks seguros para `USER`, hostname, `bufname`, `argv0` e `buftype` vazios

**Verify**:

```bash
rg -n "resolve_source_context|source_kind|source_ref|os_gethostname|getcwd|bufname|get_chan_info|argv" lua/zettelvim/utils.lua
```

**Expected**: o resolvedor e os campos do contexto aparecem exatamente uma vez no fluxo novo, incluindo o ramo específico para terminal.

---

### T3: Extrair helper de garantia de criação da nota alvo

**What**: tirar de `ZettelVimCreateorFind()` a responsabilidade de criar a nota alvo e encapsular isso em um helper reutilizável.
**Where**: `lua/zettelvim/utils.lua`
**Depends on**: T2
**Reuses**: criação atual de arquivo com `capitalizeFirstLetter`, `vim.fn.filereadable` e `vim.fn.writefile`

**Tools**:

- MCP: `NONE`
- Skill: `NONE`

**Done when**:

- [ ] Existe um helper equivalente a `ensure_note_exists(nota_alvo)`
- [ ] O helper preserva o formato atual de criação do arquivo alvo
- [ ] `ZettelVimCreateorFind()` deixa de duplicar diretamente o bloco de criação

**Verify**:

```bash
rg -n "ensure_note_exists|filereadable|capitalizeFirstLetter|writefile" lua/zettelvim/utils.lua
```

**Expected**: a criação da nota alvo fica centralizada em um helper dedicado.

---

### T4: Implementar leitura e inserção de links por arquivo

**What**: substituir a dependência do buffer atual por helpers file-based para ler o bloco `links` de uma nota e inserir uma nova referência sem duplicação.
**Where**: `lua/zettelvim/utils.lua`
**Depends on**: T3
**Reuses**: parsing textual já usado por `add_link_em_indice()` para o bloco `ranking`

**Tools**:

- MCP: `NONE`
- Skill: `NONE`

**Done when**:

- [ ] Existe um helper equivalente a `read_links_from_note_path(nota_path)`
- [ ] Existe um helper equivalente a `append_link_to_note_path(nota_path, link_ref)`
- [ ] A localização do bloco `links` usa `vim.fn.readfile` + iteração textual
- [ ] Inserção duplicada vira no-op
- [ ] O fluxo novo não depende de `encontra_bloco_de_links_no_buffer_atual()`

**Verify**:

```bash
rg -n "read_links_from_note_path|append_link_to_note_path|readfile|link_line_head|link_line_tail" lua/zettelvim/utils.lua
```

**Expected**: a leitura/escrita de links passa a operar por arquivo, não pelo buffer atual.

---

### T5: Refatorar os fluxos uni e bidirecional em `utils.lua`

**What**: adaptar o fluxo de conexão para suportar atualização bidirecional entre duas notas e atualização unidirecional quando a fonte não é nota.
**Where**: `lua/zettelvim/utils.lua`
**Depends on**: T4
**Reuses**: semântica atual de `add_link_biderecional()` e etapa obrigatória de `add_link_em_indice()`

**Tools**:

- MCP: `NONE`
- Skill: `NONE`

**Done when**:

- [ ] Existe uma função equivalente a `add_bidirectional_link(nota_fonte, nota_alvo)`
- [ ] Existe uma função equivalente a `add_unidirectional_source_link(source_ref, nota_alvo)`
- [ ] O fluxo bidirecional continua escrevendo fonte e alvo
- [ ] O fluxo unidirecional escreve apenas no alvo
- [ ] O buffer fonte nunca é usado como destino de escrita no cenário não-nota

**Verify**:

```bash
rg -n "add_bidirectional_link|add_unidirectional_source_link|add_link_em_indice|append_link_to_note_path" lua/zettelvim/utils.lua
```

**Expected**: há dois fluxos explícitos, um para nota↔nota e outro para fonte externa→nota.

---

### T6: Atualizar `ZettelVimCreateorFind()` para orquestrar pelo `SourceContext`

**What**: mudar a API pública de `ZettelVimCreateorFind()` para receber o contexto da fonte e decidir corretamente entre fluxo bidirecional e unidirecional.
**Where**: `lua/zettelvim/utils.lua`
**Depends on**: T5
**Reuses**: `ensure_note_exists`, `resolve_source_context`, `add_bidirectional_link`, `add_unidirectional_source_link`, `add_link_em_indice`

**Tools**:

- MCP: `NONE`
- Skill: `NONE`

**Done when**:

- [ ] `ZettelVimCreateorFind()` aceita `nota_alvo` e `source_context`
- [ ] A nota alvo sempre é criada se não existir
- [ ] O índice `tempesta cerebralis` sempre é atualizado nos dois cenários
- [ ] O fluxo continua retornando cedo para `nota_alvo == ""`
- [ ] O escopo continua excluindo `ZettelVimNovaNota()`

**Verify**:

```bash
rg -n "function M.ZettelVimCreateorFind|source_context|add_unidirectional_source_link|add_bidirectional_link|add_link_em_indice" lua/zettelvim/utils.lua
```

**Expected**: a função pública orquestra o modo correto de atualização a partir de `source_context`.

---

### T7: Atualizar `NormalCall()` e `VisualCall()` com a guarda de buffer fonte

**What**: adaptar `config.lua` para resolver o `SourceContext`, executar `:write` apenas quando a fonte é nota e chamar a nova API de `ZettelVimCreateorFind()`.
**Where**: `lua/zettelvim/config.lua`
**Depends on**: T6
**Reuses**: captura atual de `<cword>`, captura de seleção visual, limpeza do registrador `a` e abertura final da nota alvo

**Tools**:

- MCP: `NONE`
- Skill: `NONE`

**Done when**:

- [ ] `NormalCall()` resolve o contexto da fonte antes de decidir salvar
- [ ] `VisualCall()` resolve o contexto da fonte antes de decidir salvar
- [ ] `vim.cmd("w")` só roda quando `source_context.is_nota == true`
- [ ] Ambos os comandos chamam `ZettelVimCreateorFind(nota_alvo, source_context)`
- [ ] A abertura da nota alvo permanece igual ao comportamento atual

**Verify**:

```bash
rg -n "resolve_source_context|ZettelVimCreateorFind|vim.cmd\\(\"w\"\\)|NormalCall|VisualCall" lua/zettelvim/config.lua
```

**Expected**: `config.lua` passa a proteger o `:write` e a usar a nova interface do orquestrador.

---

### T8: Validar carregamento e regressão básica de sintaxe

**What**: garantir que os arquivos alterados carregam no Neovim sem erro de sintaxe ou de require básico.
**Where**: `lua/zettelvim/utils.lua`, `lua/zettelvim/config.lua`
**Depends on**: T7
**Reuses**: entrypoint atual `require('zettelvim.config')`

**Tools**:

- MCP: `NONE`
- Skill: `NONE`

**Done when**:

- [x] `utils.lua` carrega sem erro de sintaxe
- [x] `config.lua` carrega sem erro de sintaxe
- [x] `require('zettelvim.config')` continua resolvendo

**Verify**:

```bash
env NVIM_TEMPESTADE=/tmp/zettelvim-test-vault/ nvim --headless -u NONE -i NONE -n \
  "+set rtp+=/home/ggrl/projetos/ZettelVim" \
  "+lua require('zettelvim.utils')" \
  "+lua require('zettelvim.config')" \
  "+qall!"
```

**Expected**: comando encerra com status 0 e sem stack trace Lua.
**Observed**: validado com status 0. Ver `.specs/features/001-e382-buftype-guard/validation-T8-T10.md`.

---

### T9: Validar o cenário A em harness headless com nota real

**What**: provar que o comportamento antigo foi preservado quando o buffer fonte é uma nota dentro de `tempestade_path`.
**Where**: harness headless do Neovim com vault temporário
**Depends on**: T8
**Reuses**: passos do cenário A descritos em `spec.md`

**Tools**:

- MCP: `NONE`
- Skill: `NONE`

**Done when**:

- [x] A nota fonte pode ser salva normalmente
- [x] A nota alvo é criada se não existir
- [x] O link `nota_fonte -> nota_alvo` é escrito
- [x] O link `nota_alvo -> nota_fonte` é escrito
- [x] O índice `tempesta cerebralis` incrementa a nota alvo

**Verify**:

```bash
Ver comando reproduzível em `.specs/features/001-e382-buftype-guard/validation-T8-T10.md`.
```

**Expected**:

- a nota fonte é salva sem erro
- a nota alvo é criada e recebe o backlink para a fonte
- a nota fonte recebe o link para o alvo
- o índice incrementa `nota_alvo | 1`
- `validation-T8-T10.md` registra `scenario_a_ok`

---

### T10: Validar o cenário B em harness headless com buffer não-nota

**What**: provar que buffers especiais não sofrem `:write`, não são alterados, e ainda assim geram a nota alvo com referência unidirecional e atualização do índice.
**Where**: harness headless do Neovim com buffers `terminal` e `nofile`
**Depends on**: T9
**Reuses**: reprodução descrita em `spec.md`

**Tools**:

- MCP: `NONE`
- Skill: `NONE`

**Done when**:

- [x] `qf` ou `qff` em buffer não-nota não dispara `E382`
- [x] O buffer fonte não é modificado
- [x] A nota alvo é criada se não existir
- [x] Em terminal, a nota alvo recebe referência rica com `bufname` e `argv0` quando disponível
- [x] Em buffers não-nota sem metadados ricos, o fallback continua legível e estável
- [x] O índice `tempesta cerebralis` incrementa a nota alvo

**Verify**:

```bash
Ver comando reproduzível em `.specs/features/001-e382-buftype-guard/validation-T8-T10.md`.
```

**Expected**:

- o subcenário `terminal` registra `scenario_b_ok` sem `E382`
- a nota `AlvoTerminal` recebe `term://... [argv:...]`
- o subcenário `nofile` grava fallback legível `{user}@{host} {cwd} (nofile)`
- `validation-T8-T10.md` registra os dois resultados observados

**Expected**:

- abrir um `:terminal`, `:help` ou outro buffer com `buftype` especial
- disparar o fluxo com `<leader>qf` ou `qff`
- confirmar ausência de `E382`
- confirmar no arquivo alvo que só ele foi modificado
- confirmar que terminal usa referência rica e que outros casos degradam para fallback sem erro

---

## Parallel Execution Map

```text
Phase 1 (Sequential):
  T1 ──→ T2 ──→ T3

Phase 2 (Sequential due shared write set in utils.lua):
  T3 ──→ T4 ──→ T5 ──→ T6

Phase 3 (Sequential):
  T6 ──→ T7 ──→ T8 ──→ T9 ──→ T10
```

---

## Task Granularity Check

| Task | Scope | Status |
| --- | --- | --- |
| T1: Helpers públicos de classificação | 1 conceito / 1 arquivo | ✅ Granular |
| T2: `SourceContext` | 1 conceito / 1 arquivo | ✅ Granular |
| T3: `ensure_note_exists` | 1 helper / 1 arquivo | ✅ Granular |
| T4: leitura/escrita file-based de links | 2 helpers coesos / 1 arquivo | ✅ Aceitável |
| T5: fluxos uni e bidirecional | 1 comportamento / 1 arquivo | ✅ Granular |
| T6: orquestrador `ZettelVimCreateorFind()` | 1 função pública / 1 arquivo | ✅ Granular |
| T7: guarda em `config.lua` | 1 file change coeso | ✅ Aceitável |
| T8: carga/sintaxe | 1 verificação integrada | ✅ Granular |
| T9: cenário A | 1 validação funcional | ✅ Granular |
| T10: cenário B | 1 validação funcional | ✅ Granular |

**Granularity check**:

- ✅ cada task entrega um comportamento ou helper verificável
- ✅ o write set foi mantido pequeno e explícito
- ✅ validações críticas foram separadas por cenário da spec
- ⚠️ quase não há paralelismo seguro porque `utils.lua` concentra a maior parte da implementação
