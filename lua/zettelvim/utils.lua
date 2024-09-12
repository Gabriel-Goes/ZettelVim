-- Author: Gabriel Góes Rocha de Lima
-- Email: gabrielgoes@usp.br
-- Date: 2024-02-08
-- Last Modified: 2024-06-27
-- Version: 0.1.1
-- License: GPL
-- Description: Pluggin para transformar o neovim em um zettelkasten machine
-- ZettelVim/zettelvim/lua/utils.lua
--
---- Configurações ------------------------------------------------------------
-- Caminho para o diretório de notas
local tempestade_path = os.getenv('NVIM_TEMPESTADE') or vim.fn.expand("$USER/vidia/docs/TempestaCerebralis/")
-- verfica se o diretório de notas foi definido
if vim.fn.isdirectory(tempestade_path) == 0 then
    print("Diretório de notas não encontrado: " .. tempestade_path)
    print('Criando ...')
    vim.fn.mkdir(tempestade_path, "p")
    return
end

vim.fn.setenv("NVIM_TEMPESTADE", tempestade_path)

-- Link e ranking Head e Tail
local link_line_head = '```links'
local link_line_tail= '```'
local ranking_line_head = '```ranking'
local ranking_line_tail = '```'

-- DEBUG
function string.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

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
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
                             pattern = "*",
                             callback = setMarkdonwFileType,
                         })

--------------- ZettelVim - Notas de conexões Bidirecionais  ------------------
-- Função para obter o número do buffer atual - Buffer da nota_fonte
local function get_buffer_atual(bufrn)
    bufrn = bufrn or vim.api.nvim_get_current_buf()
    return bufrn
end

-- Função para obter a árvore de sintaxe do buffer com TreeSitter.
local function get_arvore_de_sintaxe(bufrn)
    local parser = vim.treesitter.get_parser(bufrn, "markdown")
    local nodo = parser:parse()[1]:root()
    return nodo
end


local function nodo_contem_ranking_block(nodo, bufrn)
    local start_row, _, end_row, _ = nodo:range()
    local lines = vim.api.nvim_buf_get_lines(bufrn, start_row, end_row + 1, false)
    for _, line in ipairs(lines) do
        if line:match(ranking_line_head) then
            return true
        end
    end
    return false
end

local function encontra_bloco_de_ranking_recursivamente(node, bufrn)
    if node:type() == "fenced_code_block" and nodo_contem_ranking_block(node, bufrn) then
        return node
    end
    for child_node in node:iter_children() do
        local result = encontra_bloco_de_ranking_recursivamente(child_node, bufrn)
        if result then
            return result
        end
    end
    return nil
end

-- Função para obter o texto do node
local function get_node_text(nodo, bufrn)
    local start_row, start_col, end_row, end_col = nodo:range()
    local lines = vim.api.nvim_buf_get_lines(bufrn, start_row, end_row + 1, false)
    if #lines > 0 then
        lines[#lines] = string.sub(lines[#lines], 1, end_col)
        lines[1] = string.sub(lines[1], start_col + 1)
    end
    return lines
end

local function encontra_bloco_de_ranking_no_buffer_atual()
    local bufrn = get_buffer_atual()
    local root = get_arvore_de_sintaxe(bufrn)
    local node = encontra_bloco_de_ranking_recursivamente(root, bufrn)
    if node then
        local ranking_header_lines = get_node_text(node, bufrn)
        return ranking_header_lines
    end
    return nil
end

-- Função auxiliar para verificar se o nó contém o padrão de "setext_heading"
local function nodo_contem_links(nodo, bufrn)
    local start_row, _, end_row, _ = nodo:range()
    local lines = vim.api.nvim_buf_get_lines(bufrn, start_row, end_row + 1, false)
    for _, line in ipairs(lines) do
        if line:match(link_line_head) then
            print(' Link Header Encontrado')
            print(' Linha: ' .. line)
            return true
        end
        print(' Link Header Não Encontrado')
    end
    return false
end

-- Função recursiva para encontrar o bloco de links na árvore de sintaxe.
local function encontra_bloco_de_links_recursivamente(nodo, bufrn)
    if nodo:type() == "fenced_code_block" and nodo_contem_links(nodo, bufrn) then
        return nodo
    end
    for nodo_filho in nodo:iter_children() do
        local bloco_links = encontra_bloco_de_links_recursivamente(nodo_filho, bufrn)
        if bloco_links then
            return bloco_links
        end
    end
    return nil
end

-- Função principal para encontrar o bloco de links no buffer atual.
local function encontra_bloco_de_links_no_buffer_atual()
    local bufrn = get_buffer_atual()
    local root = get_arvore_de_sintaxe(bufrn)
    local nodo = encontra_bloco_de_links_recursivamente(root, bufrn)
    if nodo then
        local link_header_lines = get_node_text(nodo, bufrn)
        return link_header_lines
    end
    return nil
end

-- Função para obter os links link_header
local function get_links_from_link_header(link_header)
    print(' -> Iniciando Processamento de Links')
    -- Cria uma tabela para armazenar os links
    local links = {}
    local unique_links = {}
    if type (link_header) == "table" and #link_header > 1 then
        print(' -> Link Header com ' .. (#link_header) .. ' links')
        -- itera sobre as linhas do bloco, começando da segunda linha e terminando na penúltima
        -- para ignorar as linhas de link_header e link_tail
        for i = 2, #link_header - 1 do
            -- Adiciona a linha atual ao bloco de links
            local link = link_header[i]:trim()
            print(' -> Link: ' .. link)
            if link:trim() ~= "" and not unique_links[link] then
                unique_links[link] = true
                table.insert(links, link)
                print(' -> Link Adicionado: ' .. link)
                end
            end
        else
            print(' -> Link Header com 0 links')
        end
        print(' Número de Links: ' .. #links)
        return links
    end
        if not string.trim then
            function string.trim(s)
                return s:match("^%s*(.-)%s*$")
            end
end

-- Função para processar os arquivos  e retornar os links
local function processa_nota(nota)
    print(' -> Iniciando Processamento de Nota: ' .. nota)
    print('')
    local nota_path = tempestade_path .. nota
    local link_header = encontra_bloco_de_links_no_buffer_atual()
    local links = get_links_from_link_header(link_header)
    return links, nota_path
end

-- Função para Adicionar link para o nota_fonte no arquivo alvo
local function add_fonte_em_links_de_alvo(nota_fonte, nota_alvo)
    local links_de_alvo, nota_alvo_path = processa_nota(nota_alvo)
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
end

-- Função para Adicionar Link Biderecional entre dois arquivos
local function add_link_biderecional(nota_fonte, nota_alvo)
    local links_de_fonte, nota_fonte_path = processa_nota(nota_fonte)
    print('Nota Fonte: ' .. nota_fonte)
    print('Nota Alvo: ' .. nota_alvo)
    local link_em_fonte_existe = false
    -- checa se bloco de links de nota_fonte possui link para nota_alvo
    if vim.tbl_contains(links_de_fonte, nota_alvo) then
        link_em_fonte_existe = true
        print('Link em Fonte Existe')
        print('Links em Fonte: ' .. table.concat(links_de_fonte, ', '))
    end
    -- se nota_fonte não possui link para nota_alvo
    if not link_em_fonte_existe then
        print('Link em Fonte Não Existe')
        -- Adiciona a nota_alvo ao bloco de links da nota_fonte
        local nota_fonte_content = vim.fn.readfile(nota_fonte_path)
        table.insert(nota_fonte_content, 4, nota_alvo)
        vim.fn.writefile(nota_fonte_content, nota_fonte_path)
        add_fonte_em_links_de_alvo(nota_fonte, nota_alvo)
    end
    print('')
end

-- Transformando uma palavra é um título, Capitalize First Letter
local function capitalizeFirstLetter(str)
    return (str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function add_link_em_indice(nota_indice_tematico, nota_alvo)
    local index_file_path = tempestade_path .. nota_indice_tematico
    local index_file_content = vim.fn.readfile(index_file_path)
    local in_ranking_block = false
    local links_count = {}
    for _, line in ipairs(index_file_content) do
        if line:match(ranking_line_head) then
            in_ranking_block = true
        elseif line:match(ranking_line_tail) then
            in_ranking_block = false
        elseif in_ranking_block then
            local link, count = line:match("^(.-)%s*|%s*(%d+)$")
            if link and count then
                links_count[link] = tonumber(count)
            else
                links_count[line:trim()] = 1
            end
        end
    end

    if links_count[nota_alvo] then
        links_count[nota_alvo] = links_count[nota_alvo] + 1
    else
        links_count[nota_alvo] = 1
    end

    local sorted_links = {}

    for link, count in pairs(links_count) do
        table.insert(sorted_links, {link = link, count = count})
    end

    table.sort(sorted_links, function(a, b)
        return a.count > b.count
    end)

    local new_index_content = {}
    local ranking_found = false
    for _, line in ipairs(index_file_content) do
        table.insert(new_index_content, line)
        if line:match(ranking_line_head) then
            ranking_found = true
            break
        end
    end

    if ranking_found then
        for _, entry in ipairs(sorted_links) do
            table.insert(new_index_content, entry.link .. " | " .. entry.count)
        end
        table.insert(new_index_content, ranking_line_tail)
    else
        table.insert(new_index_content, ranking_line_head)
        for _, entry in ipairs(sorted_links) do
            table.insert(new_index_content, entry.link .. " | " .. entry.count)
        end
        table.insert(new_index_content, ranking_line_tail)
    end

    vim.fn.writefile(new_index_content, index_file_path)
end

-- Função para adicionar link em Nota Índice Temático
-------------------------------------------------------------------------------

local M = {}
function M.get_tempestade_path()
    return tempestade_path
end

-- Função para criar uma nova nota
function M.ZettelVimNovaNota(nota_alvo)
    -- Verifica se a palavra é vazia
    if nota_alvo == "" then
        print("Sem palavras, tsc tsc tsc...")
        return
    end
    -- Pega o caminho da nota_alvo
    local nota_alvo_path = tempestade_path .. nota_alvo
    -- Checa se a nota_alvo existe
    if vim.fn.filereadable(nota_alvo_path) == 0 then
        print("Nota '" ..  nota_alvo .. "' não existe, criando...")
        local titulo = "# " .. capitalizeFirstLetter(nota_alvo)
        vim.fn.writefile({titulo, '', link_line_head, link_line_tail}, nota_alvo_path)
        print("Nota '" ..  nota_alvo .. "' criada com sucesso!")
    end
    -- Adiciona link biderecional entre nota_fonte e nota_alvo
    local nota_fonte = vim.fn.expand("%:t")
    add_link_biderecional(nota_fonte, nota_alvo)
    print("Nota '" ..  nota_alvo .. "' conectada com sucesso à nota '" .. nota_fonte .. "'!")
    add_link_em_indice("tempesta cerebralis", nota_alvo)
end

-------------------- ZettelVimCreateorFind(nota_alvo) -------------------------
-- Função para criar ou encontrar uma nota
function M.ZettelVimCreateorFind(nota_alvo)
    -- Verifica se a palavra é vazia
    if nota_alvo == "" then
        print("Sem palavras, tsc tsc tsc...")
        return
    end
    -- Pega o caminho da nota_alvo
    local nota_alvo_path = tempestade_path .. nota_alvo
    -- Checa se a nota_alvo existe
    if vim.fn.filereadable(nota_alvo_path) == 0 then
        print("Nota '" ..  nota_alvo .. "' não existe, criando...")
        local titulo = "# " .. capitalizeFirstLetter(nota_alvo)
        vim.fn.writefile({titulo, '', link_line_head, link_line_tail, ''}, nota_alvo_path)
        print("Nota '" ..  nota_alvo .. "' criada com sucesso!")
    end
    local nota_fonte = vim.fn.expand("%:t")
    -- Adiciona link biderecional entre nota_fonte e nota_alvo
    add_link_biderecional(nota_fonte, nota_alvo)
    print("Nota '" ..  nota_alvo .. "' conectada com sucesso à nota '" .. nota_fonte .. "'!")
    add_link_em_indice("tempesta cerebralis", nota_alvo)
end

-------------------------------------------------------------------------------
return M
