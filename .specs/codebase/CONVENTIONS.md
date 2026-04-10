# Code Conventions

**Analyzed:** 2026-04-10

## Naming Conventions

### Files

Há duas convenções coexistindo:

- arquivos centrais do plugin em lowercase: `init.lua`, `config.lua`, `utils.lua`
- módulos legados em PascalCase: `Notas.lua`, `NovaNota.lua`, `Serialize.lua`, `SerializeMarkdown.lua`

### Functions and Methods

O código mistura estilos:

- camel/snake_case: `get_tempestade_path`, `add_link_em_indice`, `setMarkdonwFileType`
- nomes iniciando em maiúscula para comandos públicos: `NormalCall`, `VisualCall`, `Serialize`
- prefixos de domínio: `ZettelVimCreateorFind`, `ZettelVimNovaNota`

Exemplos observados:

- `searchWikipedia`
- `capitalizeFirstLetter`
- `encontra_bloco_de_links_recursivamente`
- `get_links_from_link_header`

### Variables

Predomina `snake_case`, com forte presença de nomes em português:

- `nota_alvo`
- `nota_fonte`
- `nota_alvo_path`
- `link_em_fonte_existe`
- `ranking_found`

Há mistura com inglês dentro do mesmo arquivo:

- `sorted_links`
- `index_file_content`
- `selection`
- `command`

### Constants

Constantes simples são declaradas como `local` no topo do arquivo:

- `link_line_head`
- `link_line_tail`
- `ranking_line_head`
- `ranking_line_tail`
- `wikipedia_lang`

## Code Organization

### Imports and Dependencies

O padrão dominante é declarar `require` no topo do arquivo e capturar dependências locais:

```lua
local utils = require('zettelvim.utils')
local tempestade_path = utils.get_tempestade_path()
local ZettelVimCreateorFind = utils.ZettelVimCreateorFind
```

### File Structure

Arquivos principais seguem este formato:

1. cabeçalho extenso em comentário
2. `local` com dependências e constantes
3. funções locais auxiliares
4. tabela módulo `local M = {}`
5. funções públicas `M.*`
6. `return M`

Nos módulos legados, há maior uso de globais e efeitos colaterais imediatos, como `print()` no carregamento.

## Type Safety and Documentation

**Approach:** sem tipagem estática; documentação embutida em comentários de cabeçalho e comentários inline

Exemplos:

- cabeçalhos com autor, data, versão e licença em praticamente todos os arquivos
- comentários explicando passo a passo ações de buffer em `config.lua`
- comentários descritivos longos em `utils.lua`

Não há annotations de tipos, EmmyLua ou validação estrutural explícita.

## Error Handling

O código usa três padrões distintos:

- `print(...)` seguido de `return` para condições inválidas ou operacionais
- `error(...)` em módulos de serialização, quando falha `io.open`
- confiança em chamadas do `vim` runtime sem `pcall`, deixando erros do Neovim propagarem

Exemplos:

- diretório ausente em `utils.lua` imprime mensagem, cria pasta e encerra o módulo cedo
- `ZettelVimCreateorFind()` retorna quando `nota_alvo == ""`
- `SerializeWithVarName()` lança erro se não consegue abrir arquivo

## Comments and Debugging

Há muitos `print()` de debug espalhados no fluxo principal, especialmente em `utils.lua`:

- `" -> Iniciando Processamento de Links"`
- `"Link em Fonte Existe"`
- `"Nota '...' criada com sucesso!"`

Comentários são em português e costumam explicar intenção operacional, não apenas regras de domínio.

## Observed Inconsistencies

- typo persistente em `setMarkdonwFileType`
- mistura de português e inglês em nomes
- coexistência de lowercase e PascalCase para nomes de arquivo
- alguns módulos legados usam globais (`Nota_Estudo`, `MinhaNovaNota`, `NovaNota`) em vez de retorno de módulo

## Implications for Future Work

- mudanças em `utils.lua` precisam preservar o estilo híbrido já existente
- novas APIs públicas do plugin devem preferir o padrão `M.funcao`
- ao tocar módulos legados, é preciso considerar que eles seguem convenções diferentes do runtime principal
