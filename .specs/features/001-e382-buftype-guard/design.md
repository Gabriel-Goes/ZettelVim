# Buffer Source Guard Design

**Spec**: `.specs/features/001-e382-buftype-guard/spec.md`
**Status**: Draft

---

## Architecture Overview

A solução proposta mantém a arquitetura atual do plugin: `config.lua` continua
como camada de entrada dos comandos, e `utils.lua` continua como camada de
domínio e persistência. A mudança principal é tornar explícito o conceito de
"fonte atual" e separar dois fluxos de conexão:

- fluxo bidirecional quando a fonte é uma nota dentro de `tempestade_path`
- fluxo unidirecional quando a fonte é qualquer outro buffer

O ponto crítico do design é remover a dependência do buffer atual para editar
links do arquivo alvo. Hoje parte da lógica lê links a partir do buffer aberto;
para suportar fontes não-nota com segurança, a escrita de links deve operar
sobre caminhos de arquivo e referências de fonte explícitas.

### Trade-off: Tree-sitter → parsing textual

Atualmente, a cadeia `processa_nota()` → `encontra_bloco_de_links_no_buffer_atual()`
→ `encontra_bloco_de_links_recursivamente()` usa Tree-sitter sobre o **buffer
aberto** para localizar o bloco `links`. Isso impede operar sobre arquivos que
não estão carregados em buffer (cenário B) e acopla a leitura de links ao
estado do editor.

A solução adotada é trocar essa cadeia por **parsing textual direto do arquivo**
via `vim.fn.readfile` + `line:match()`, seguindo o padrão já estabelecido por
`add_link_em_indice()` (que parseia o bloco `ranking` dessa forma).

**Funções que serão reescritas:**

- `processa_nota()` (`utils.lua:186`) — deixará de chamar funções de buffer
- `add_link_biderecional()` (`utils.lua:213`) — chamará as novas funções file-based
- `add_fonte_em_links_de_alvo()` (`utils.lua:196`) — substituída por `append_link_to_note_path()`

**O que se perde:** validação estrutural do markdown via árvore de sintaxe.

**O que se ganha:** independência do buffer atual, consistência com o padrão de
`add_link_em_indice()`, e viabilidade do fluxo unidirecional.

```mermaid
graph TD
    A[Usuario aciona qf/qff] --> B[config.lua captura alvo]
    B --> C[utils.resolve_source_context()]
    C --> D{source_context.is_nota?}
    D -->|sim| E[config.lua executa :write]
    D -->|nao| F[config.lua nao salva buffer]
    E --> G[utils.ZettelVimCreateorFind alvo + contexto]
    F --> G
    G --> H[ensure_target_note_exists]
    H --> I{source_context.is_nota?}
    I -->|sim| J[add_bidirectional_link]
    I -->|nao| K[add_unidirectional_source_link]
    J --> L[add_link_em_indice]
    K --> L
    L --> M[config.lua abre nota alvo]
```

---

## Code Reuse Analysis

### Existing Components to Leverage

| Component | Location | How to Use |
| --- | --- | --- |
| `get_tempestade_path()` | `lua/zettelvim/utils.lua` | Reutilizar sem alteração como fonte única do diretório de notas |
| `setMarkdonwFileType()` | `lua/zettelvim/utils.lua` | Extrair a regra de prefixo de caminho para um helper público de classificação de nota |
| Criação de nota alvo | `lua/zettelvim/utils.lua` | Reaproveitar a criação do esqueleto markdown quando o arquivo ainda não existir |
| `add_link_em_indice()` | `lua/zettelvim/utils.lua` | Manter exatamente como etapa final obrigatória nos dois cenários |
| Captura de palavra/seleção | `lua/zettelvim/config.lua` | Preservar o fluxo atual de `NormalCall()` e `VisualCall()` para derivar `nota_alvo` |
| Abertura da nota alvo | `lua/zettelvim/config.lua` | Preservar `vim.cmd("e " .. tempestade_path .. nota_alvo)` após a persistência |

### Integration Points

| System | Integration Method |
| --- | --- |
| Buffer atual do Neovim | `vim.fn.expand`, `vim.bo.buftype`, `vim.fn.getcwd()` e `vim.api.nvim_get_current_buf()` |
| Runtime do sistema | `os.getenv("USER")` e `vim.loop.os_gethostname()` para montar referência mínima da fonte não-nota |
| Vault de notas | `vim.fn.readfile` e `vim.fn.writefile` para editar fonte/alvo e índice |
| Fluxo existente do plugin | `config.lua` delega para `utils.lua` e continua responsável por keymap, captura de entrada e abertura do alvo |

---

## Components

### Source Context Resolver

- **Atende**: REQ-01, REQ-07
- **Purpose**: classificar o buffer atual como nota ou não-nota e produzir a referência textual da fonte
- **Location**: `lua/zettelvim/utils.lua`
- **Interfaces**:
  - `is_nota_path(path): boolean` - retorna `true` quando o caminho está dentro de `tempestade_path`
  - `buffer_atual_e_nota(): boolean` - conveniência para `config.lua` decidir se pode executar `:write`
  - `resolve_source_context(): SourceContext` - retorna um contexto completo da fonte atual
- **Dependencies**: `tempestade_path`, `vim.fn.expand`, `vim.bo.buftype`, `vim.fn.getcwd`, `os.getenv`, `vim.loop.os_gethostname`
- **Reuses**: a mesma regra de prefixo já usada por `setMarkdonwFileType()`

### Command Guard in `config.lua`

- **Atende**: REQ-01, REQ-02, REQ-05
- **Purpose**: impedir `:write` em buffers que não representam notas do vault
- **Location**: `lua/zettelvim/config.lua`
- **Interfaces**:
  - `NormalCall()` - resolve o contexto da fonte, salva apenas se `is_nota == true`, chama o orquestrador e abre o alvo
  - `VisualCall()` - resolve o contexto da fonte, salva apenas se `is_nota == true`, normaliza a seleção, chama o orquestrador e abre o alvo
- **Dependencies**: `utils.resolve_source_context()` ou `utils.buffer_atual_e_nota()`, `utils.ZettelVimCreateorFind()`
- **Reuses**: keymaps existentes, captura de `<cword>`, yank visual e limpeza do registrador `a`

### Target Note Ensurer

- **Atende**: REQ-02, REQ-03
- **Purpose**: garantir que `nota_alvo` exista com a estrutura mínima esperada antes de qualquer atualização de links
- **Location**: `lua/zettelvim/utils.lua`
- **Interfaces**:
  - `ensure_note_exists(nota_alvo): string` - cria a nota quando necessário e retorna `nota_alvo_path`
- **Dependencies**: `tempestade_path`, `capitalizeFirstLetter`, `vim.fn.filereadable`, `vim.fn.writefile`
- **Reuses**: o formato atual de criação de nota em `ZettelVimCreateorFind()`

### File-Based Link Writer

- **Atende**: REQ-02, REQ-03, REQ-04, REQ-05
- **Purpose**: ler e escrever links diretamente nos arquivos de nota, sem depender do buffer atual
- **Location**: `lua/zettelvim/utils.lua`
- **Interfaces**:
  - `read_links_from_note_path(nota_path): string[]` - extrai os links atuais do arquivo alvo/fonte
  - `append_link_to_note_path(nota_path, link_ref): boolean` - insere o link se ele ainda não existir
  - `add_bidirectional_link(nota_fonte, nota_alvo): nil` - atualiza fonte e alvo quando ambas são notas
  - `add_unidirectional_source_link(source_ref, nota_alvo): nil` - atualiza apenas o alvo quando a fonte não é nota
- **Dependencies**: `vim.fn.readfile`, `vim.fn.writefile`, constantes `link_line_head` e `link_line_tail`
- **Parsing method**: leitura via `vim.fn.readfile` + iteração com `line:match()` para localizar `link_line_head`/`link_line_tail`, seguindo o mesmo padrão de `add_link_em_indice()` para o bloco `ranking`
- **Reuses**: semântica atual de link bidirecional, mas trocando o acoplamento ao buffer por leitura direta do arquivo

### Flow Orchestrator

- **Atende**: REQ-02, REQ-03, REQ-06
- **Purpose**: centralizar o fluxo de criação/encontro de nota alvo e aplicar o modo correto de conexão
- **Location**: `lua/zettelvim/utils.lua`
- **Interfaces**:
  - `ZettelVimCreateorFind(nota_alvo, source_context): nil` - cria a nota alvo, escolhe fluxo uni/bidirecional, registra no índice
- **Dependencies**: `ensure_note_exists`, `add_bidirectional_link`, `add_unidirectional_source_link`, `add_link_em_indice`
- **Reuses**: assinatura atual da função pública, com extensão para receber contexto da fonte

---

## Data Models

### SourceContext

```lua
local source_context = {
    is_nota = true or false,
    source_ref = "MinhaNota" or "ggrl@GeoServer /home/ggrl/projetos/ZettelVim (terminal)",
    source_note_name = "MinhaNota" or nil,
    source_path = "/abs/path/do/buffer/atual",
    buftype = "terminal" or "",
}
```

**Relationships**: produzido por `resolve_source_context()`, consumido por `NormalCall()`, `VisualCall()` e `ZettelVimCreateorFind()`.

### Link Update Mode

```lua
local link_update_mode = {
    mode = "bidirectional" or "unidirectional",
    update_source = true or false,
    update_target = true,
    update_index = true,
}
```

**Relationships**: não precisa ser exposto como API pública; representa a decisão interna aplicada pelo orquestrador a partir de `source_context.is_nota`.

---

## Detailed Flow

### Scenario A: fonte atual e uma nota

1. `config.lua` captura o alvo do cursor ou da seleção.
2. `utils.resolve_source_context()` retorna `is_nota = true` e `source_ref = nome_da_nota`.
3. `config.lua` executa `vim.cmd("w")`.
4. `ZettelVimCreateorFind()` garante que a nota alvo exista.
5. `add_bidirectional_link()` escreve `nota_alvo` na nota fonte e `nota_fonte` na nota alvo, evitando duplicação.
6. `add_link_em_indice("tempesta cerebralis", nota_alvo)` incrementa o ranking.
7. `config.lua` abre a nota alvo.

### Scenario B: fonte atual nao e uma nota

1. `config.lua` captura o alvo do cursor ou da seleção.
2. `utils.resolve_source_context()` retorna `is_nota = false` e monta `source_ref` no formato `{user}@{host} {cwd} ({buftype})`.
3. `config.lua` nao executa `vim.cmd("w")`.
4. `ZettelVimCreateorFind()` garante que a nota alvo exista.
5. `add_unidirectional_source_link()` escreve apenas `source_ref` no bloco `links` da nota alvo, evitando duplicação.
6. `add_link_em_indice("tempesta cerebralis", nota_alvo)` incrementa o ranking.
7. `config.lua` abre a nota alvo.

---

## Error Handling Strategy

| Error Scenario | Handling | User Impact |
| --- | --- | --- |
| Buffer atual tem `buftype` especial e nao pode ser salvo | `config.lua` pula `:write` quando `source_context.is_nota == false` | evita `E382` e mantém o fluxo funcional |
| `nota_alvo` nao existe | `ensure_note_exists()` cria o arquivo com o esqueleto padrão | comportamento continua transparente para o usuário |
| Link ja existe no arquivo fonte ou alvo | `append_link_to_note_path()` faz no-op | evita duplicação de links |
| `USER`, hostname ou `buftype` vierem vazios | `resolve_source_context()` aplica fallbacks seguros (`unknown-user`, `unknown-host`, `file`) | a nota alvo continua registrando origem legível |
| Arquivo indice estiver ausente ou malformado | manter comportamento atual de `add_link_em_indice()` nesta iteração | fora do escopo desta feature; risco documentado, não expandido aqui |

---

## Tech Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Onde fazer a guarda de `:write` | Em `config.lua` | o problema acontece no comando acionado pelo usuário; a proteção deve ocorrer antes de qualquer tentativa de salvar |
| Como identificar "é uma nota" | Extrair helper público reutilizando a regra de prefixo de `setMarkdonwFileType()` | garante consistência entre filetype e comportamento de criação de links |
| Como representar fonte não-nota | String textual mínima `{user}@{host} {cwd} ({buftype})` | atende o spec sem depender de integrações extras ou parsing de statusline |
| Como atualizar links | Leitura/escrita direta no arquivo de nota, não no buffer atual | remove acoplamento ao buffer corrente e viabiliza fluxo unidirecional seguro |
| O que preservar do fluxo atual | criação de nota, abertura do alvo e atualização do índice | reduz a mudança ao mínimo necessário para resolver o bug |

---

## Out of Scope

- enriquecer a referência da fonte com branch git, nome do modelo ou statusline do Claude/Codex
- revisar `add_link_em_indice()` para tratar melhor arquivos índice ausentes ou inconsistentes
- reestruturar os módulos legados de serialização
- automatizar testes nessa fase de design
