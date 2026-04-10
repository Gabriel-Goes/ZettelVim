# Tech Stack

**Analyzed:** 2026-04-10
**Scope:** working tree atual de `ZettelVim`

## Core

- Framework: plugin para Neovim baseado na API global `vim`
- Language: Lua para runtime embutido do Neovim
- Runtime: Neovim com suporte a autocmd, keymaps, buffers e Tree-sitter
- Package manager: nenhum manifesto encontrado no repositório (`rockspec`, `package.json`, `lazy.nvim`, `packer`, `makefile` ou equivalente)

## Plugin Runtime

- Entry point: `lua/zettelvim/init.lua`
- Configuration layer: `lua/zettelvim/config.lua`
- Core business logic: `lua/zettelvim/utils.lua`
- Data model / legacy serializers: `lua/zettelvim/Notas.lua`, `lua/zettelvim/NovaNota.lua`, `lua/zettelvim/Serialize.lua`, `lua/zettelvim/SerializeMarkdown.lua`

## Data and Persistence

- Primary storage: arquivos plain-text em diretório externo apontado por `NVIM_TEMPESTADE`
- Default vault path: `$HOME/docs/TempestaCerebralis/`
- Internal metadata format: blocos fenced markdown como ````links` e ````ranking`
- Indexing approach: arquivo índice `tempesta cerebralis` com contagem de conexões

## Testing

- Unit: nenhum framework identificado
- Integration: nenhum framework identificado
- E2E: nenhum framework identificado
- Observed test artifacts: scripts manuais em `lua/zettelvim/testes/`

## External Services

- Neovim runtime API: leitura de buffer, keymaps, comandos Ex, autocmd e buffers
- Tree-sitter Markdown parser: usado para localizar blocos `links` e `ranking`
- Filesystem local: leitura e escrita direta de notas e do índice
- OS/browser launcher: `xdg-open` ou `start` para busca na Wikipedia

## Development Tools

- Code search in current environment: `rg` e `sg` disponíveis para análise
- Documentation artifacts: `README.md`, `INSTALL.md`, `TODO.md`, `fontes_lua.md`
- Spec artifacts: `.specs/features/` e `.specs/quick/`

## Notable Gaps

- Não há versionamento explícito de dependências
- Não há comando oficial de teste no repositório
- Não há configuração de CI, lint ou formatter identificável
