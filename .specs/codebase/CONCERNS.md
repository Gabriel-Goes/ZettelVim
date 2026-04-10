# Concerns and Tech Debt

**Analyzed:** 2026-04-10

## Active Concerns

### C1: Concentração de lógica em utils.lua

**Severity:** Medium
**Location:** `lua/zettelvim/utils.lua`
**Description:** Praticamente toda a lógica de domínio (notas, links, índice, filetype, Tree-sitter) está em um único arquivo de ~360 linhas. Qualquer mudança requer cuidado com efeitos colaterais.
**Impact:** aumenta risco de regressão em refatorações; dificulta implementação paralela de tasks.

### C2: Acoplamento ao buffer atual para leitura de links

**Severity:** High (sendo resolvido por feature 001)
**Location:** `lua/zettelvim/utils.lua:186-193` — `processa_nota()` chama `encontra_bloco_de_links_no_buffer_atual()`
**Description:** A leitura de links depende de Tree-sitter sobre o buffer aberto. Isso impede operar sobre arquivos não carregados e causa E382 em buffers especiais.
**Impact:** bug E382 ao usar o plugin em terminais integrados. A feature 001-e382-buftype-guard substitui isso por parsing textual file-based.

### C3: ZettelVimNovaNota() sem guarda de buffer

**Severity:** Medium
**Location:** `lua/zettelvim/utils.lua:314-333`
**Description:** `ZettelVimNovaNota()` possui o mesmo padrão vulnerável de `ZettelVimCreateorFind()` (chama `add_link_biderecional()` sem verificar se o buffer é nota), mas não é acionada por nenhum keymap em `setup()`.
**Impact:** potencial E382 se essa função for exposta ao usuário no futuro. Documentado como out-of-scope na feature 001.

### C4: Ausência de framework de testes

**Severity:** Medium
**Location:** `lua/zettelvim/testes/`
**Description:** Apenas scripts manuais de exercício. Sem harness, sem assertions, sem CI.
**Impact:** validação depende inteiramente de testes manuais no Neovim. Aumenta risco em refatorações.

### C5: Prints de debug no fluxo principal

**Severity:** Low
**Location:** `lua/zettelvim/utils.lua` — espalhados por todo o arquivo
**Description:** Muitos `print()` usados para depuração manual que poluem o output do Neovim durante uso normal.
**Impact:** ruído visual para o usuário final; sem impacto funcional.

### C6: Escrita de links por posição fixa (linha 4)

**Severity:** Medium
**Location:** `lua/zettelvim/utils.lua:207,229`
**Description:** `table.insert(nota_content, 4, link)` assume que o bloco de links começa na linha 4 do arquivo. Se o formato da nota mudar, links serão inseridos no lugar errado.
**Impact:** fragilidade na inserção de links. A feature 001 mitiga isso com `append_link_to_note_path()` que localiza o bloco `links` por parsing.

## Deferred / Future

- Sanitização de escape sequences ANSI em seleções visuais de terminal
- Enriquecimento da referência de fonte com git branch, modelo AI, processos filhos
- Revisão de `add_link_em_indice()` para tratar índice ausente/malformado
- Reestruturação dos módulos legados de serialização
