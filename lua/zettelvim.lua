-- Author: Gabriel Góes Rocha de Lima
-- Email: gabrielgoes@usp.br
-- Date: 2024-02-08
-- Last Modified: 2024-02-08
-- Version: 0.1
-- License: GPL
-- Description: Pluggin para transformar o neovim em um zettelkasten machine
-- ZettelVim/lua/zettelvim.lua

---- Configurações ------------------------------------------------------------
-- Path para o diretório de tempestade cerebral
local tempestade_path = os.getenv("NVIM_TEMPESTADE")

-- Tratar todos os arquivos de um diretório como Markdown mesmo sem a extensão
local function setMarkdonwFileType()
    -- Obtém o caminho completo do arquivo atual
    local nota_fonte_path = vim.fn.expand("%:p")
    -- verifica se o caminho da nota_fonte está dentro do tempestade_path
    if nota_fonte_path:sub(1, #tempestade_path) == tempestade_path then
        -- Ajusta o filetype para markdown
        vim.bo.filetype = "markdown"
    end
end
-- Cria autocmd que chama setMarkdonwFileType para arquivos em tempestade_path
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"},{
                             pattern = "*",
                             callback = setMarkdonwFileType})
-- Link Head e Tail
local link_line_head = '------ links ------------------------------------------------------------------'
local link_line_tail = '-------------------------------------------------------------------------------'
-------------------------------------------------------------------------------
-- DEBUG
local function print_table(t, indent)
    indent = indent or ""
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(indent .. tostring(k) .. ":")
            print_table(v, indent .. "  ")
        else
            print(indent .. tostring(k) .. ": " .. tostring(v))
        end
    end
end
-------------------------------------------------------------------------------
-- Transformando uma palavra é um título, Capitalize First Letter
local function capitalizeFirstLetter(str)
    return (str:gsub("^.", string.upper))
end
-- Função para adicionar link em Nota Índice Temático
local function add_link_em_indice(nota_indice_tematico, nota_alvo)
    -- Adiciona a palavra ao arquivo "tempestade cerebral" como um indice
    local index_file_path = tempestade_path .. nota_indice_tematico
    local index_file_content  = vim.fn.readfile(index_file_path)
    table.insert(index_file_content, nota_alvo)
    vim.fn.writefile(index_file_content, index_file_path)
end
--------------- ZettelVim - Notas de conexões Bidirecionais  ------------------
-- Função para obter o número do buffer atual - Buffer da nota_fonte
local function get_buffer_atual(bufrn)
    bufrn = bufrn or vim.api.nvim_get_current_buf()
    return bufrn
end
-- Função para obter a árvore de sintaxe do buffer com TreeSitter.
local function get_arvore_de_sintaxe(bufrn)
    local parser = vim.treesitter.get_parser(bufrn, "markdown")
    return parser:parse()[1]:root()
end
-- Função auxiliar para verificar se o nó contém o padrão de "setext_heading"
local function nodo_contem_setext_heading(nodo, bufrn)
    local start_row, _, end_row, _ = nodo:range()
    local lines = vim.api.nvim_buf_get_lines(bufrn, start_row, end_row + 1, false)
    for _, line in ipairs(lines) do
        if line:match(link_line_head) then

            return true
        end
    end
    return false
end
-- Função recursiva para encontrar o bloco de links na árvore de sintaxe.
local function encontra_bloco_de_links_recursivamente(node, bufrn)
    if node:type() == "setext_heading" and nodo_contem_setext_heading(node, bufrn) then
        return node
    end
    for child_node in node:iter_children() do
        local result = encontra_bloco_de_links_recursivamente(child_node, bufrn)
        if result then
            return result
        end
    end
    return nil
end
-- Função principal para encontrar o bloco de links no buffer atual.
local function encontra_bloco_de_links_no_buffer_atual()
    local bufrn = get_buffer_atual()
    print("bufrn: ", bufrn)
    local root = get_arvore_de_sintaxe(bufrn)
    print("root: ", root)
    return encontra_bloco_de_links_recursivamente(root, bufrn)
end
-- Teste da função principal para encontrar o bloco de links no buffer atual.
--print(encontra_bloco_de_links_no_buffer_atual())
-------------------------------------------------------------------------------
-- Função para obter os links link_header
local function get_links_from_link_header(link_header)
    -- Cria uma tabela para armazenar os links
    local links = {}
    -- itera sobre as linhas do bloco, começando da segunda linha e terminando na penúltima
    -- para ignorar as linhas de link_header e link_tail
    for i = 2, #link_header - 1 do
        -- Adiciona a linha atual ao bloco de links
        local link = link_header[i]
        if link then
            table.insert(links, link)
        end
    end
    return links
end
-- Função para processar os arquivos  e retornar os links
local function processa_nota(nota)
    local nota_path = tempestade_path .. nota
    local link_header = encontra_bloco_de_links_no_buffer_atual()
    local links = get_links_from_link_header(link_header)
    return links, nota_path
end
-- Função para Adicionar link para o nota_fonte no arquivo alvo
local function add_fonte_em_links_de_alvo(nota_fonte, nota_alvo)
    local links_de_alvo, nota_alvo_path = processa_nota(nota_alvo)
    print(" Conteúdo de links_de_alvo antes de verificar existencia:")
    print_table(links_de_alvo)
    -- Verifica se o link já existe no bloco de links
    local link_em_alvo_existe = false
    if vim.tbl_contains(links_de_alvo, nota_fonte) then
        link_em_alvo_existe = true
    end
    -- se não houver nota_alvo em links
    if not link_em_alvo_existe then
        local nota_alvo_content = vim.fn.readfile(nota_alvo_path)
        -- Adiciona a palavra ao bloco de links do arquivo alvo
        table.insert(nota_alvo_content, 4, nota_fonte)
        vim.fn.writefile(nota_alvo_content, nota_alvo_path)
    end
    print(" Conteúdo de links_de_alvo depois de verificar existencia:")
    print_table(links_de_alvo)
end
-- Função para Adicionar Link Biderecional entre dois arquivos
local function add_link_biderecional(nota_fonte, nota_alvo)
    local links_de_fonte, nota_fonte_path = processa_nota(nota_fonte)
    -- checa se bloco de links de nota_fonte possui link para nota_alvo
    local link_em_fonte_existe = false
    if vim.tbl_contains(links_de_fonte, nota_alvo) then
        link_em_fonte_existe = true
    end
    -- se nota_fonte não possui link para nota_alvo
    if not link_em_fonte_existe then
        -- Adiciona a nota_alvo ao bloco de links da nota_fonte
        local nota_fonte_content = vim.fn.readfile(nota_fonte_path)
        table.insert(nota_fonte_content, 4, nota_alvo)
        vim.fn.writefile(nota_fonte_content, nota_fonte_path)
        add_fonte_em_links_de_alvo(nota_fonte, nota_alvo)
    end
end
-------------------- ZettleVimCreateorFind(nota_alvo) -------------------------
-- Função para criar ou encontrar uma nota
function ZettleVimCreateorFind(nota_alvo)
    -- Verifica se a palavra é vazia
    if nota_alvo == "" then
        print("Sem palavras, tsc tsc tsc...")
        return
    end
    -- Pega o caminho da nota_alvo
    local nota_alvo_path = tempestade_path .. nota_alvo
    -- Checa se a nota_alvo existe
    if vim.fn.filereadable(nota_alvo_path) == 0 then
        -- Cria o arquivo com:
        -- título
        -- e pula linha,
        -- link_line_head,
        -- link_line_tail
        -- e pula linha
        local titulo = "# " .. capitalizeFirstLetter(nota_alvo)
        vim.fn.writefile({titulo, '', link_line_head, link_line_tail, ''}, nota_alvo_path)
        -- Adiciona link à nota índice temático 'tempestade cerebral'
        add_link_em_indice("tempestade cerebral", nota_alvo)
    end
    -- Adiciona link biderecional entre nota_fonte e nota_alvo
    local nota_fonte = vim.fn.expand("%:t")
    add_link_biderecional(nota_fonte, nota_alvo)
end
-------------------------------------------------------------------------------
---- CreatorFind Normal Mode
vim.keymap.set("n", "<leader>zf", function()
    vim.cmd("w")
    local nota_alvo = vim.fn.expand("<cword>")
    ZettleVimCreateorFind(nota_alvo)
    -- abre o arquivo alvo
    vim.cmd("e " .. tempestade_path .. nota_alvo)
end, {noremap = true, silent = true})
---- CreatorFind Visual Mode
vim.keymap.set("v", "zf", function()
    -- Salva o arquivo atual
    vim.cmd("w")
    -- Yank a seleção do buffer no visual mode, e apenas a seleção ao registro 'a'
    vim.cmd("normal! \"ay")
    -- Imediatamente após o yan, obtém a seleção do registro 'a' e armazena na variável selection
    local selection = vim.fn.getreg("a")
    -- Chama a função ZettleVimCreateorFind com a seleção
    ZettleVimCreateorFind(selection)
    -- limpa o registro 'a'
    vim.fn.setreg("a", "")
    -- abre o arquivo alvo
    vim.cmd("e " .. tempestade_path .. selection)
end, {noremap = true, silent = true})
-------------------------------------------------------------------------------
print("ZettleVim carregado com sucesso")
