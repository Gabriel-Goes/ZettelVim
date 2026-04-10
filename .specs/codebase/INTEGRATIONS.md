# External Integrations

**Analyzed:** 2026-04-10

## Editor Runtime

**Service:** Neovim API global (`vim`)
**Purpose:** operar buffers, comandos, keymaps, environment variables e arquivos
**Implementation:** espalhada por `lua/zettelvim/config.lua` e `lua/zettelvim/utils.lua`
**Configuration:** implícita pelo runtime do Neovim
**Authentication:** não aplicável

Funções observadas:

- `vim.cmd`
- `vim.fn.expand`
- `vim.fn.readfile`
- `vim.fn.writefile`
- `vim.api.nvim_set_keymap`
- `vim.api.nvim_create_autocmd`

## Syntax Parsing

**Service:** Tree-sitter markdown parser do Neovim
**Purpose:** localizar blocos fenced `links` e `ranking`
**Implementation:** `get_arvore_de_sintaxe()`, `encontra_bloco_de_links_recursivamente()`, `encontra_bloco_de_ranking_recursivamente()`
**Configuration:** requer parser markdown funcional no ambiente do usuário
**Authentication:** não aplicável

## Filesystem and Vault

**Service:** filesystem local do usuário
**Purpose:** persistir notas, criar diretórios e manter o índice de conexões
**Implementation:** `lua/zettelvim/utils.lua`
**Configuration:** `NVIM_TEMPESTADE` ou fallback para `$HOME/docs/TempestaCerebralis/`
**Authentication:** permissões do sistema de arquivos do usuário

Objetos externos relevantes:

- diretório do vault de notas
- arquivo índice `tempesta cerebralis`
- arquivos individuais de nota criados sem extensão markdown obrigatória

## Environment and OS

**Service:** variáveis de ambiente e utilitários do sistema operacional
**Purpose:** localizar o vault e abrir páginas externas
**Implementation:** `os.getenv`, `vim.fn.setenv`, `vim.fn.system`
**Configuration:** depende de `NVIM_TEMPESTADE`, `HOME` e disponibilidade de `xdg-open` ou `start`
**Authentication:** não aplicável

## External Web Integration

### API Name

**Purpose:** abrir a página da Wikipedia para o termo atual
**Location:** `openWikipediaPage()` em `lua/zettelvim/config.lua`
**Authentication:** nenhuma
**Key endpoints:** `https://{lang}.wikipedia.org/wiki/{termo}`

Essa integração é disparada por atalho e apenas delega ao navegador do sistema; não há cliente HTTP interno nem persistência de resposta.

## Webhooks

Nenhum webhook identificado.

## Background Jobs

- Queue system: inexistente
- Location: não aplicável
- Jobs: não aplicável

## Integration Risks

- a lógica principal assume que o parser markdown está disponível no Neovim do usuário
- a criação e edição de notas dependem de um diretório externo válido e gravável
- o comando de abertura da Wikipedia varia por plataforma e não possui fallback robusto além de `start`/`xdg-open`
