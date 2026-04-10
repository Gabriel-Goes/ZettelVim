# Validation T8-T10: Buffer Source Guard

**Date**: 2026-04-10
**Executor**: Codex
**Scope**: T8, T9, T10
**Audit baseline**: `.specs/features/001-e382-buftype-guard/audit-T1-T7.md`

---

## Result

| Task | Status | Notes |
| --- | --- | --- |
| T8 | PASS | `require('zettelvim.utils')` e `require('zettelvim.config')` carregam com `NVIM_TEMPESTADE` controlado |
| T9 | PASS | Cenário A preservado: nota fonte salva, alvo criado, link bidirecional e índice atualizado |
| T10 | PASS | Cenário B validado em dois ramos: `terminal` com referência rica e `nofile` com fallback legível |

---

## T8

### Command

```bash
env NVIM_TEMPESTADE=/tmp/zettelvim-test-vault/ nvim --headless -u NONE -i NONE -n \
  "+set rtp+=/home/ggrl/projetos/ZettelVim" \
  "+lua require('zettelvim.utils')" \
  "+lua require('zettelvim.config')" \
  "+qall!"
```

### Observed

- Exit status `0`
- Sem stack trace Lua
- `utils.lua` e `config.lua` carregam normalmente

---

## T9

### Setup

- Vault temporário em `/tmp/zettelvim-scenario-a-clean/`
- Índice inicial `tempesta cerebralis` com bloco `ranking`
- Nota fonte `Fonte` com a palavra `AlvoPalavra` no corpo e bloco `links`

### Command

```bash
env NVIM_TEMPESTADE=/tmp/zettelvim-scenario-a-clean/ nvim --headless -u NONE -i NONE -n \
  "+set rtp+=/home/ggrl/projetos/ZettelVim" \
  "+lua local vault=os.getenv('NVIM_TEMPESTADE'); local fence=string.char(96,96,96); vim.fn.mkdir(vault, 'p'); vim.fn.writefile({'# Tempesta', '', fence .. 'ranking', fence, ''}, vault .. 'tempesta cerebralis'); vim.fn.writefile({'# Fonte', '', 'AlvoPalavra', fence .. 'links', fence, ''}, vault .. 'Fonte'); local function count_exact(lines, needle) local count = 0; for _, line in ipairs(lines) do if line == needle then count = count + 1 end end; return count end; local config=require('zettelvim.config'); vim.cmd('edit ' .. vim.fn.fnameescape(vault .. 'Fonte')); vim.fn.cursor(3, 1); config.NormalCall(); local source_lines=vim.fn.readfile(vault .. 'Fonte'); local target_lines=vim.fn.readfile(vault .. 'AlvoPalavra'); local index_text=table.concat(vim.fn.readfile(vault .. 'tempesta cerebralis'), '\n'); assert(count_exact(source_lines, 'AlvoPalavra') >= 2, 'source missing bidirectional link'); assert(count_exact(target_lines, 'Fonte') >= 1, 'target missing backlink to source'); assert(index_text:match('AlvoPalavra%s*|%s*1'), 'index missing target count'); print('scenario_a_ok')" \
  "+qall!"
```

### Observed

- `Normal Call`
- `Nota Alvo: AlvoPalavra`
- `Nota 'AlvoPalavra' criada com sucesso!`
- `Nota 'AlvoPalavra' conectada com sucesso à nota 'Fonte'!`
- `scenario_a_ok`

### Assertions covered

- a nota fonte foi salva sem erro
- a nota alvo foi criada
- a nota fonte passou a conter o link para `AlvoPalavra`
- a nota alvo passou a conter o backlink `Fonte`
- o índice passou a conter `AlvoPalavra | 1`

---

## T10

### Setup

- Vault temporário em `/tmp/zettelvim-scenario-b/`
- Índice inicial `tempesta cerebralis` com bloco `ranking`
- Dois subcenários no mesmo processo headless:
  - `terminal` com saída `AlvoTerminal`
  - buffer `nofile` sem nome com a palavra `AlvoFallback`

### Command

```bash
env NVIM_TEMPESTADE=/tmp/zettelvim-scenario-b/ nvim --headless -u NONE -i NONE -n \
  "+set rtp+=/home/ggrl/projetos/ZettelVim" \
  "+lua local vault=os.getenv('NVIM_TEMPESTADE'); local cwd=vim.fn.getcwd(); local fence=string.char(96,96,96); vim.fn.mkdir(vault, 'p'); vim.fn.writefile({'# Tempesta', '', fence .. 'ranking', fence, ''}, vault .. 'tempesta cerebralis'); local config=require('zettelvim.config'); local function join(path) return table.concat(vim.fn.readfile(path), '\n') end; local function lines(buf) return vim.api.nvim_buf_get_lines(buf, 0, -1, false) end; vim.cmd('enew'); local term_buf=vim.api.nvim_get_current_buf(); vim.fn.termopen({'/bin/sh', '-c', 'printf AlvoTerminal'}); local ok=vim.wait(1000, function() return table.concat(lines(term_buf), ' '):match('AlvoTerminal') ~= nil end, 20); assert(ok, 'terminal output not ready'); local term_name=vim.api.nvim_buf_get_name(term_buf); local term_lines_before=lines(term_buf); vim.fn.cursor(1, 1); config.NormalCall(); local term_lines_after=lines(term_buf); local term_target=join(vault .. 'AlvoTerminal'); local index_after_term=join(vault .. 'tempesta cerebralis'); assert(vim.deep_equal(term_lines_before, term_lines_after), 'terminal source buffer changed'); assert(term_target:match('term://'), 'terminal target missing bufname'); assert(term_target:match('%[argv:'), 'terminal target missing argv0'); assert(index_after_term:match('AlvoTerminal%s*|%s*1'), 'index missing terminal target count'); vim.cmd('enew'); local nofile_buf=vim.api.nvim_get_current_buf(); vim.bo.buftype='nofile'; vim.bo.bufhidden='hide'; vim.api.nvim_buf_set_name(nofile_buf, ''); vim.api.nvim_buf_set_lines(nofile_buf, 0, -1, false, {'AlvoFallback'}); local nofile_lines_before=lines(nofile_buf); vim.fn.cursor(1, 1); config.NormalCall(); local nofile_lines_after=lines(nofile_buf); local fallback_target=join(vault .. 'AlvoFallback'); local index_after_fallback=join(vault .. 'tempesta cerebralis'); assert(vim.deep_equal(nofile_lines_before, nofile_lines_after), 'nofile source buffer changed'); assert(fallback_target:match(cwd, 1, true) ~= nil, 'fallback target missing cwd'); assert(fallback_target:match('%(nofile%)'), 'fallback target missing buftype'); assert(index_after_fallback:match('AlvoFallback%s*|%s*1'), 'index missing fallback target count'); print('scenario_b_ok'); print('terminal_bufname:' .. term_name); print('terminal_note:' .. term_target); print('fallback_note:' .. fallback_target)" \
  "+qall!"
```

### Observed

- `Normal Call`
- `Nota Alvo: AlvoTerminal`
- `Nota 'AlvoTerminal' conectada com sucesso à fonte 'ggrl@GeoServer term://~/projetos/ZettelVim//3:/bin/sh [argv:/bin/sh]'!`
- `Normal Call`
- `Nota Alvo: AlvoFallback`
- `Nota 'AlvoFallback' conectada com sucesso à fonte 'ggrl@GeoServer /home/ggrl/projetos/ZettelVim (nofile)'!`
- `scenario_b_ok`

### Assertions covered

- o fluxo em `terminal` não disparou `E382`
- o buffer fonte `terminal` permaneceu inalterado
- `AlvoTerminal` foi criada e recebeu `term://... [argv:/bin/sh]`
- o índice passou a conter `AlvoTerminal | 1`
- o fluxo em `nofile` não disparou `E382`
- o buffer fonte `nofile` permaneceu inalterado
- `AlvoFallback` foi criada e recebeu fallback legível com `cwd` e `(nofile)`
- o índice passou a conter `AlvoFallback | 1`

---

## Notes

- A validação usou harness headless em vez de interação manual, o que é compatível com a própria task definition quando o executor já possui um fluxo reproduzível.
- As duas observações não-bloqueantes do auditor para T7 permanecem válidas:
  - `VisualCall()` ainda pode yankar texto com resíduos ANSI em terminal
  - `vim.cmd("e " .. tempestade_path .. nota_alvo)` continua vulnerável a espaços em `nota_alvo`
