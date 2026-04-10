# Auditoria T1-T7: Buffer Source Guard

**Auditor:** Claude Opus 4.6
**Data:** 2026-04-10
**Diff analisado:** working tree vs HEAD (commit 347734c)

---

## T1: Expor helpers públicos de classificação da fonte

**Status:** PASS

### Done When

| Critério | Status | Evidência |
|----------|--------|-----------|
| Existe helper público `is_nota_path(path)` | OK | `utils.lua:44-49` — local function + `M.is_nota_path` exportado na linha 393 |
| Existe helper público `buffer_atual_e_nota()` | OK | `utils.lua:81-83` — local function + `M.buffer_atual_e_nota` exportado na linha 394 |
| Regra usada é a mesma de `setMarkdonwFileType()` | OK | `setMarkdonwFileType()` (linha 52) agora chama `is_nota_path()` diretamente |
| Nenhuma mudança em `ZettelVimNovaNota()` | OK | Linhas 398-418 idênticas ao original |

### Verify

```
rg -n "is_nota_path|buffer_atual_e_nota|setMarkdonwFileType" lua/zettelvim/utils.lua

:!rg -n "is_nota_path|buffer_atual_e_nota|setMarkdonwFileType" lua/zettelvim/utils.lua
44:local function is_nota_path(path)
52:local function setMarkdonwFileType()
56:    if is_nota_path(nota_fonte_path) then
62:-- Cria autocmd que chama setMarkdonwFileType para arquivos em tempestade_path
65:                             callback = setMarkdonwFileType,
81:local function buffer_atual_e_nota()
82:    return is_nota_path(get_current_buffer_path())
86:    if not is_nota_path(path) then
393:M.is_nota_path = is_nota_path
394:M.buffer_atual_e_nota = buffer_atual_e_nota

```

Match: OK — helpers aparecem e `setMarkdonwFileType` reutiliza `is_nota_path`.

### REQ Coverage

| REQ | Coberto? | Como |
|-----|----------|------|
| REQ-01 | OK | `is_nota_path()` e `buffer_atual_e_nota()` permitem decidir o fluxo |
| REQ-07 | OK | `setMarkdonwFileType()` usa `is_nota_path()` — mesma regra |

### Observações

- `is_nota_path()` inclui validação defensiva de tipo (`type(path) ~= "string" or path == ""`). Boa prática.
- `buffer_atual_e_nota()` usa `get_current_buffer_path()` que faz fallback para `nvim_buf_get_name(0)` quando `expand("%:p")` retorna vazio. Isso cobre edge cases de buffers sem path.

---

## T2: Criar SourceContext e resolvedor

**Status:** PASS

### Done When

| Critério | Status | Evidência |
|----------|--------|-----------|
| Existe `resolve_source_context()` | OK | `utils.lua:176-209` |
| Fonte nota → `source_ref` = nome da nota | OK | `build_source_ref()` linha 142-143 |
| Fonte terminal → `source_ref` prioriza `bufname` + `argv0` | OK | `build_source_ref()` linhas 146-158 |
| Fonte não-terminal → `bufname` ou fallback `{cwd}` | OK | `build_source_ref()` linhas 161-173 |
| Fallbacks para valores vazios | OK | `get_env_with_fallback("USER", "unknown-user")` (linha 201), `get_hostname_with_fallback()` → `"unknown-host"` (linha 103), `buftype` fallback → `"file"` (linha 181) |

### Verify

```
rg -n "resolve_source_context|source_kind|source_ref|os_gethostname|getcwd|bufname|get_chan_info|argv"
```

Match: OK — ramo terminal com `argv` presente.

### REQ Coverage

| REQ | Coberto? | Como |
|-----|----------|------|
| REQ-08 | OK | `build_source_ref()` linhas 146-158: terminal com bufname e argv0 |
| REQ-09 | OK | Fallbacks em cascata: terminal→bufname→cwd. Nunca falha. |

### Observações

- `get_current_channel()` usa `pcall(function() return vim.bo.channel end)`. O pcall com wrapper é defensivo para quando `vim.bo.channel` não existe (buffers sem canal).
- `source_context.cwd` chama `vim.fn.getcwd()` **duas vezes** (linha 200): uma no `trim()` e outra no valor. Ineficiente mas funcional. Não é bloqueante.

---

## T3: Extrair helper de garantia de criação da nota alvo

**Status:** PASS

### Done When

| Critério | Status | Evidência |
|----------|--------|-----------|
| Existe `ensure_note_exists(nota_alvo)` | OK | `utils.lua:288-297` |
| Preserva formato atual de criação | OK | Mesmo template: `{titulo, '', link_line_head, link_line_tail, ''}` (linha 293) |
| `ZettelVimCreateorFind()` usa o helper | OK | Linha 428: `ensure_note_exists(nota_alvo)` |

### Verify

Match: OK — criação centralizada em helper dedicado.

### REQ Coverage

| REQ | Coberto? | Como |
|-----|----------|------|
| REQ-02 | OK | Nota alvo criada em ambos os cenários |
| REQ-03 | OK | `ensure_note_exists` chamado antes da bifurcação uni/bidi |

### Observações

- `capitalizeFirstLetter` precisou virar `local capitalizeFirstLetter` (forward declaration na linha 286) + atribuição como expressão na linha 317, porque `ensure_note_exists` é declarada antes de `capitalizeFirstLetter`. Solução correta para Lua.
- **`ZettelVimNovaNota()` NÃO usa `ensure_note_exists()`** — ainda tem o bloco de criação duplicado (linhas 405-412). Isso é correto para esta feature (fora do escopo), mas fica como debt.

---

## T4: Implementar leitura e inserção de links por arquivo

**Status:** PASS

### Done When

| Critério | Status | Evidência |
|----------|--------|-----------|
| Existe `read_links_from_note_path(nota_path)` | OK | `utils.lua:247-253` |
| Existe `append_link_to_note_path(nota_path, link_ref)` | OK | `utils.lua:255-284` |
| Localização usa `vim.fn.readfile` + iteração textual | OK | `find_fenced_block_bounds()` linhas 211-225 |
| Inserção duplicada vira no-op | OK | Linha 266: `vim.tbl_contains(get_links_from_lines(...))` retorna false |
| Não depende de `encontra_bloco_de_links_no_buffer_atual()` | OK | Função removida completamente |

### Verify

Match: OK — leitura/escrita opera por arquivo.

### REQ Coverage

| REQ | Coberto? | Como |
|-----|----------|------|
| REQ-04 | OK | `append_link_to_note_path()` garante que nota_alvo sempre recebe referência |
| REQ-05 | OK | Não opera sobre buffers, apenas sobre arquivos |

### Observações

- `find_fenced_block_bounds()` é genérica — recebe `block_head` e `block_tail` como parâmetros. Pode ser reutilizada para o bloco `ranking` no futuro.
- `escape_lua_pattern()` (linha 40-42) é usada para escapar `` ``` `` no pattern matching. Necessária porque backtick é literal em patterns Lua, mas é boa prática defensiva.
- **Achado importante:** `append_link_to_note_path()` cria um bloco `links` se ele não existir (linhas 271-277). O comportamento original inseria na linha 4 fixa. A nova implementação é mais robusta.

---

## T5: Refatorar fluxos uni e bidirecional

**Status:** PASS

### Done When

| Critério | Status | Evidência |
|----------|--------|-----------|
| Existe `add_bidirectional_link(nota_fonte, nota_alvo)` | OK | `utils.lua:299-305` |
| Existe `add_unidirectional_source_link(source_ref, nota_alvo)` | OK | `utils.lua:307-310` |
| Bidirecional escreve fonte e alvo | OK | Linhas 303-304: dois `append_link_to_note_path` |
| Unidirecional escreve apenas no alvo | OK | Linha 309: um `append_link_to_note_path` |
| Buffer fonte nunca é destino de escrita no cenário não-nota | OK | `add_unidirectional_source_link` recebe `source_ref` (string), não path |

### Verify

Match: OK — dois fluxos explícitos.

### REQ Coverage

| REQ | Coberto? | Como |
|-----|----------|------|
| REQ-02 | OK | `add_bidirectional_link` no cenário A |
| REQ-03 | OK | `add_unidirectional_source_link` no cenário B |
| REQ-05 | OK | Cenário B não toca nenhum arquivo da fonte |

### Observações

- `add_link_biderecional()` (linha 312-314) foi mantido como wrapper delegando para `add_bidirectional_link()`. Isso preserva compatibilidade com `ZettelVimNovaNota()` que ainda chama o nome antigo (linha 415). Decisão correta.

---

## T6: Atualizar ZettelVimCreateorFind() para orquestrar pelo SourceContext

**Status:** PASS

### Done When

| Critério | Status | Evidência |
|----------|--------|-----------|
| Aceita `nota_alvo` e `source_context` | OK | Linha 422: `function M.ZettelVimCreateorFind(nota_alvo, source_context)` |
| Nota alvo sempre criada | OK | Linha 428: `ensure_note_exists(nota_alvo)` antes da bifurcação |
| Índice sempre atualizado | OK | Linha 441: `add_link_em_indice(...)` após a bifurcação |
| Retorno cedo para `nota_alvo == ""` | OK | Linhas 424-427 |
| Escopo exclui `ZettelVimNovaNota()` | OK | Linhas 398-418 intocadas |

### Verify

Match: OK — função orquestra por `source_context`.

### REQ Coverage

| REQ | Coberto? | Como |
|-----|----------|------|
| REQ-02 | OK | `source_context.is_nota` → `add_bidirectional_link` |
| REQ-03 | OK | `not is_nota` → `add_unidirectional_source_link` |
| REQ-06 | OK | `add_link_em_indice` sempre chamado (linha 441) |

### Observações

- Fallback `source_context = source_context or resolve_source_context()` (linha 430) permite chamadas sem contexto explícito. Defensivo e mantém retrocompatibilidade.
- `nota_fonte` usa `source_context.source_note_name or vim.fn.expand("%:t")` (linha 433). O fallback para `expand("%:t")` é defensivo mas desnecessário — se `is_nota == true`, `source_note_name` sempre existe por construção de `resolve_source_context()`. Não é bug, apenas redundância.

---

## T7: Atualizar NormalCall() e VisualCall() com guarda

**Status:** PASS_WITH_NOTES

### Done When

| Critério | Status | Evidência |
|----------|--------|-----------|
| `NormalCall()` resolve contexto antes de salvar | OK | `config.lua:19` |
| `VisualCall()` resolve contexto antes de salvar | OK | `config.lua:31` |
| `vim.cmd("w")` só roda quando `is_nota == true` | OK | Linhas 20-22 e 32-34 |
| Ambos chamam `ZettelVimCreateorFind(alvo, source_context)` | OK | Linhas 25 e 40 |
| Abertura da nota alvo preservada | OK | Linhas 27 e 42 |

### Verify

Match: OK — `config.lua` protege `:write` e usa nova interface.

### REQ Coverage

| REQ | Coberto? | Como |
|-----|----------|------|
| REQ-01 | OK | `source_context.is_nota` decide o fluxo |
| REQ-02 | OK | Cenário A: `:write` + bidirecional |
| REQ-05 | OK | Cenário B: sem `:write`, sem alteração da fonte |

### Notas (motivo do PASS_WITH_NOTES)

**N1 — `VisualCall()` faz yank em buffer de terminal.** No cenário B (terminal), `vim.cmd("normal! \"ay")` (linha 35) executa yank no buffer de terminal. Isso funciona no Neovim, mas o conteúdo yankado pode conter escape sequences residuais (ANSI). Documentado como out-of-scope na spec, mas vale registrar que o fluxo passa por aqui.

**N2 — `vim.cmd("e " .. tempestade_path .. nota_alvo)` não é protegido por contexto.** Linhas 27 e 42 abrem a nota alvo incondicionalmente com concatenação direta. Se `nota_alvo` contiver espaços (vindo de seleção visual), o comando `:e` pode falhar ou abrir o arquivo errado. Isso já era um problema antes da feature — não é regressão.

---

## Verificação de Escopo Global

| Item | Status |
|------|--------|
| `ZettelVimNovaNota()` inalterada | OK — linhas 398-418 idênticas |
| Módulos legados intocados (`Notas.lua`, `NovaNota.lua`, `Serialize.lua`, `SerializeMarkdown.lua`) | OK — sem diff |
| `init.lua` intocado | OK — sem diff |
| `searchWikipedia()` / `openWikipediaPage()` intocados | OK — linhas 45-72 de config.lua |
| `add_link_em_indice()` intacta | OK — linhas 323-382 de utils.lua sem mudança |
| Funções Tree-sitter antigas completamente removidas | OK — nenhuma referência restante |

---

## Veredicto Final

| Task | Status |
|------|--------|
| T1 | **PASS** |
| T2 | **PASS** |
| T3 | **PASS** |
| T4 | **PASS** |
| T5 | **PASS** |
| T6 | **PASS** |
| T7 | **PASS_WITH_NOTES** |

**Resultado global: PASS** — A implementação está correta, cobre todos os REQs (01-09), e respeita o escopo definido.

---

## Handoff para Codex: Pendências e Correções

### Obrigatório (antes de T8-T10)

Nenhuma correção obrigatória. O código está funcional e correto.

### Recomendado (pode ser feito durante T8-T10 ou depois)

1. **Ineficiência em `resolve_source_context()`** (`utils.lua:200`):
   `vim.fn.getcwd()` é chamado duas vezes na mesma expressão. Sugestão:
   ```
   local raw_cwd = vim.fn.getcwd()
   cwd = (trim(raw_cwd) ~= "") and raw_cwd or ".",
   ```

2. **Redundância em `ZettelVimCreateorFind()`** (`utils.lua:433`):
   `source_context.source_note_name or vim.fn.expand("%:t")` — o fallback para
   `expand("%:t")` nunca será atingido quando `is_nota == true`, pois
   `resolve_source_context()` sempre preenche `source_note_name` nesse caso.
   Pode simplificar para `source_context.source_note_name`.

### Próximos Passos

O Codex deve agora executar:

- **T8**: Validar carregamento headless. **ATENÇÃO**: o verify command precisa de
  `NVIM_TEMPESTADE` definido ou um diretório temporário, senão `utils.lua` faz
  `mkdir` e retorna cedo sem expor `M`.
  Sugestão de comando corrigido:
  ```bash
  NVIM_TEMPESTADE=/tmp/zettelvim-test-vault/ mkdir -p /tmp/zettelvim-test-vault && nvim --headless -u NONE "+set rtp+=/home/ggrl/projetos/ZettelVim" "+lua require('zettelvim.utils')" "+lua require('zettelvim.config')" +q; echo "exit: $?"
  ```

- **T9**: Validar cenário A manualmente (nota → nota, bidirecional)

- **T10**: Validar cenário B manualmente (terminal/help → nota, unidirecional com referência rica)
