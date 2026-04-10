# SPEC-001: VisualCall e NormalCall devem adaptar comportamento conforme o buffer fonte

## Problema

Ao executar `qff` (VisualCall) ou `<leader>qf` (NormalCall), as funções
assumem que o buffer atual é uma nota do TempestaCerebralis. Elas salvam o
buffer e adicionam links bidirecionais incondicionalmente.

Quando o buffer atual **não é uma nota** (terminal rodando Claude/Codex,
nvim-tree, Telescope, help, qualquer outro buffer), isso causa:
- Erro E382 (`buftype` definido impede `:write`)
- Ou pior: modificação indevida de um buffer que não é nota

## Reprodução

1. Abrir Neovim com um terminal integrado (ex: Claude Code, Codex)
2. Selecionar texto no modo visual dentro do terminal
3. Pressionar `qff`
4. Erro E382 — ou tentativa de salvar/modificar o buffer do terminal como nota

## O que define uma nota?

Um arquivo cujo caminho está dentro do diretório `tempestade_path`.

Essa lógica já existe em `setMarkdonwFileType()` (`utils.lua:35-43`):

```lua
local function setMarkdonwFileType()
    local nota_fonte_path = vim.fn.expand("%:p")
    if nota_fonte_path:sub(1, #tempestade_path) == tempestade_path then
        vim.bo.filetype = "markdown"
    end
end
```

Arquivos dentro de `tempestade_path` são tratados como markdown pelo LSP/treesitter
mesmo sem extensão `.md` no nome.

## Comportamento correto

### Regra fundamental

A nota_alvo **sempre** registra de onde veio. O buffer fonte **só é alterado**
se for uma nota.

### Operações do ZettelVimCreateorFind

| # | Operação | Cenário A (fonte é nota) | Cenário B (fonte não é nota) |
|---|----------|--------------------------|------------------------------|
| 1 | Salvar buffer atual | Sim | **Não** |
| 2 | Criar nota_alvo se não existir | Sim | Sim |
| 3 | Escrever fonte na nota_alvo (link na nota_alvo apontando para a fonte) | Sim | **Sim** |
| 4 | Escrever alvo na nota_fonte (link na nota_fonte apontando para o alvo) | Sim | **Não** |
| 5 | Registrar nota_alvo no índice "tempesta cerebralis" | Sim | Sim |
| 6 | Abrir nota_alvo | Sim | Sim |

### Cenário A — buffer atual É uma nota

Comportamento completo, **idêntico ao atual**:
- Salvar o buffer (nota_fonte)
- Criar nota_alvo se não existir
- Link bidirecional: fonte ↔ alvo (ambos os arquivos são modificados)
- Registrar no índice
- Abrir nota_alvo

### Cenário B — buffer atual NÃO é uma nota

Comportamento parcial:
- **Não salvar** o buffer atual (evita E382, buffer pode ser terminal/etc)
- Criar nota_alvo se não existir
- **Escrever na nota_alvo** a referência de onde ela veio (nome do buffer fonte)
  — a nota_alvo sabe sua origem
- **Não alterar o buffer fonte** — ele não é nota, não deve ser modificado
- Registrar no índice "tempesta cerebralis"
- Abrir nota_alvo

A diferença: no cenário A o link é **bidirecional** (ambos os arquivos são
escritos). No cenário B o link é **unidirecional** (só a nota_alvo recebe a
referência da fonte).

## Requisitos

- **REQ-01**: `VisualCall()` e `NormalCall()` devem verificar se o buffer atual
  é uma nota (caminho dentro de `tempestade_path`) antes de decidir o fluxo
- **REQ-02**: Quando o buffer atual **é** uma nota → comportamento completo
  bidirecional. Idêntico ao atual.
- **REQ-03**: Quando o buffer atual **não é** uma nota → criar nota_alvo,
  escrever nela a referência da fonte (link unidirecional), registrar no índice,
  abrir nota_alvo. Sem salvar o buffer fonte, sem alterar o buffer fonte.
- **REQ-04**: A nota_alvo **sempre** contém a referência de onde veio,
  independente do cenário
- **REQ-05**: O buffer fonte **nunca** é alterado quando não é uma nota
- **REQ-06**: A nota_alvo **sempre** é registrada no índice "tempesta
  cerebralis", independente do cenário. O contador de conexões no ranking
  (`add_link_em_indice`) **sempre incrementa** — tanto para conexões
  bidirecionais (cenário A) quanto unidirecionais (cenário B). Isso permite
  rastrear quantas vezes uma nota foi citada, referenciada ou conectada,
  independente do tipo de fonte.
- **REQ-07**: O critério "é uma nota" deve ser consistente com a lógica de
  `setMarkdonwFileType()` — baseado no caminho do arquivo estar dentro de
  `tempestade_path`

## Definição: identificação da fonte em buffers não-nota

Quando a fonte não é uma nota, a referência escrita no bloco `links` da
nota_alvo deve conter informação mínima sobre a origem:

```
{user}@{host} {cwd} ({buftype})
```

Exemplo: `ggrl@GeoServer /home/ggrl/projetos/ZettelVim (terminal)`

Obtido via:
- `os.getenv("USER")` → user
- `vim.loop.os_gethostname()` → host
- `vim.fn.getcwd()` → cwd
- `vim.bo.buftype` → tipo do buffer

Esta é uma solução mínima viável. Captura de contexto mais rico (statusline
do Claude/Codex, git branch, modelo em uso) fica para uma iteração futura.

## Escopo

### Incluído

- `ZettelVimCreateorFind()` — fluxo principal acionado por `NormalCall()` e `VisualCall()`
- `NormalCall()` e `VisualCall()` — guarda de `:write` e fluxo condicional

### Excluído

- **`ZettelVimNovaNota()`** — possui o mesmo padrão vulnerável
  (`add_link_biderecional()` + `add_link_em_indice()` sem guarda de buffer),
  mas não é acionada por nenhum keymap registrado em `setup()`. Fica para uma
  iteração futura, quando essa função for exposta ao usuário.
- **Sanitização de `nota_alvo` vindo de seleção visual em terminal** — ao
  selecionar texto num buffer de terminal, escape sequences ANSI (ex:
  `\027[31m`) podem poluir o nome da nota. O `gsub("%c")` atual remove o byte
  de controle mas deixa resíduos como `[31m`. Esse problema já existe
  independente desta feature e não será tratado aqui.

## Arquivos envolvidos

| Arquivo | O que precisa mudar |
|---------|---------------------|
| `lua/zettelvim/config.lua` | `NormalCall()` e `VisualCall()` — guarda + fluxo condicional |
| `lua/zettelvim/utils.lua` | `ZettelVimCreateorFind()` — separar link bidirecional do unidirecional; expor checagem "é nota" como função pública |
