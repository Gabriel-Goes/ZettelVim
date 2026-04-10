# Project Structure

**Root:** `/home/ggrl/projetos/ZettelVim`
**Analyzed:** 2026-04-10

## Directory Tree

```text
.
├── .specs
│   ├── codebase
│   ├── features
│   │   └── 001-e382-buftype-guard
│   └── quick
│       └── 001-e382-buftype-visualcall
├── lua
│   └── zettelvim
│       ├── testes
│       ├── config.lua
│       ├── init.lua
│       ├── utils.lua
│       └── *.lua legados
├── INSTALL.md
├── README.md
├── TODO.md
├── USO.md
└── zettelvim2.gif
```

## Module Organization

### Plugin Runtime

**Purpose:** expor a interface principal do plugin dentro do Neovim
**Location:** `lua/zettelvim/`
**Key files:** `init.lua`, `config.lua`, `utils.lua`

### Legacy Note Serialization

**Purpose:** modelar notas como tabelas Lua e serializá-las em arquivo
**Location:** `lua/zettelvim/`
**Key files:** `Notas.lua`, `NovaNota.lua`, `Serialize.lua`, `SerializeMarkdown.lua`

### Manual Test Scripts

**Purpose:** experimentos e validações manuais de serialização
**Location:** `lua/zettelvim/testes/`
**Key files:** `TestNovaNota.lua`, `TestSerializeMarkdown.lua`

### Specifications

**Purpose:** documentação de brownfield e especificação incremental de features
**Location:** `.specs/`
**Key files:** `.specs/features/001-e382-buftype-guard/spec.md`

### Project Docs

**Purpose:** onboarding humano, instalação e backlog solto
**Location:** raiz do repositório
**Key files:** `README.md`, `INSTALL.md`, `TODO.md`, `USO.md`

## Where Things Live

**Navegação e criação de notas:**

- UI/Interface: `lua/zettelvim/config.lua`
- Business Logic: `lua/zettelvim/utils.lua`
- Data Access: filesystem via `vim.fn.readfile`, `vim.fn.writefile`
- Configuration: `NVIM_TEMPESTADE` em `lua/zettelvim/utils.lua`

**Detecção de markdown e parsing estrutural:**

- UI/Interface: implícita, acionada por eventos de buffer
- Business Logic: `setMarkdonwFileType()`, `get_arvore_de_sintaxe()`
- Data Access: buffer atual e Tree-sitter
- Configuration: `tempestade_path`

**Integração com Wikipedia:**

- UI/Interface: `searchWikipedia()` em `lua/zettelvim/config.lua`
- Business Logic: `openWikipediaPage()`
- Data Access: nenhuma persistência interna
- Configuration: `wikipedia_lang`

## Special Directories

**`.specs/features/`:**
**Purpose:** specs por feature em fluxo spec-driven
**Examples:** `001-e382-buftype-guard/spec.md`

**`.specs/quick/`:**
**Purpose:** área de rascunho rápido para ideação/levantamento
**Examples:** existe o diretório `001-e382-buftype-visualcall`, mas ele está vazio no working tree atual

**`lua/zettelvim/testes/`:**
**Purpose:** scripts manuais de validação local
**Examples:** `TestNovaNota.lua`, `TestSerializeMarkdown.lua`

## Structural Observations

- O plugin principal cabe em poucos arquivos, com `utils.lua` concentrando quase toda a lógica
- Não existe separação entre `src`, `tests`, `docs` e `config`; a estrutura é simples e direta
- O repositório adota a pasta `.specs/` com docs de `codebase/` e `features/` já populados; falta apenas `project/` (PROJECT.md, ROADMAP.md, STATE.md)
