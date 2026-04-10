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
local tempestade_path = os.getenv('NVIM_TEMPESTADE') or vim.fn.expand("$HOME/docs/TempestaCerebralis/")
-- verfica se o diretório de notas foi definido
if vim.fn.isdirectory(tempestade_path) == 0 then
    print("Diretório de notas não encontrado: " .. tempestade_path)
    print('Criando ...')
    vim.fn.mkdir(tempestade_path, "p")
    -- if tempestade_path/'tempesta cerebralis' não exsite:
    if vim.fn.isdirectory(tempestade_path) == 0 then
        print("Erro ao criar diretório de notas: " .. tempestade_path)
        return
    end

    -- criar arquivo 'tempesta cerebralis'
    local tempesta_cerebralis_path = tempestade_path .. 'tempesta cerebralis'
    if vim.fn.filereadable(tempesta_cerebralis_path) == 0 then
        local tempesta_cerebralis_content = {
            "# tempesta cerebralis",
            "",
            "```links",
            "```",
            "",
            "```ranking",
            "```",
        }
        vim.fn.writefile(tempesta_cerebralis_content, tempesta_cerebralis_path)
    end
end

vim.fn.setenv("NVIM_TEMPESTADE", tempestade_path)

-- Link e ranking Head e Tail
local link_line_head = '```links'
local link_line_tail= '```'
local ranking_line_head = '```ranking'
local ranking_line_tail = '```'

local function trim(s)
    if type(s) ~= "string" then
        return ""
    end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function string.trim(s)
    return trim(s)
end

local function escape_lua_pattern(text)
    return text:gsub("([^%w])", "%%%1")
end

local function is_nota_path(path)
    if type(path) ~= "string" or path == "" then
        return false
    end
    return path:sub(1, #tempestade_path) == tempestade_path
end

-- Tratar todos os arquivos de um diretório como Markdown mesmo sem a extensão
local function setMarkdonwFileType()
    -- Obtém o caminho completo do arquivo atual
    local nota_fonte_path = vim.fn.expand("%:p")
    -- verifica se o caminho da nota_fonte está dentro do tempestade_path
    if is_nota_path(nota_fonte_path) then
        -- Ajusta o filetype para markdown
        vim.bo.filetype = "markdown"
    end
end

-- Cria autocmd que chama setMarkdonwFileType para arquivos em tempestade_path
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
                             pattern = "*",
                             callback = setMarkdonwFileType,
                         })

--------------- ZettelVim - Contexto e Persistência  --------------------------
local function get_current_buffer_path()
    local source_path = vim.fn.expand("%:p")
    if source_path ~= "" then
        return source_path
    end
    local ok, bufname = pcall(vim.api.nvim_buf_get_name, 0)
    if ok and type(bufname) == "string" then
        return bufname
    end
    return ""
end

local function buffer_atual_e_nota()
    return is_nota_path(get_current_buffer_path())
end

local function get_note_name_from_path(path)
    if not is_nota_path(path) then
        return nil
    end
    return vim.fn.fnamemodify(path, ":t")
end

local function get_env_with_fallback(name, fallback)
    local value = trim(os.getenv(name))
    if value == "" then
        return fallback
    end
    return value
end

local function get_hostname_with_fallback()
    local ok, hostname = pcall(vim.loop.os_gethostname)
    if not ok or trim(hostname) == "" then
        return "unknown-host"
    end
    return hostname
end

local function get_current_bufname()
    local ok, bufname = pcall(vim.api.nvim_buf_get_name, 0)
    if not ok then
        return ""
    end
    return trim(bufname)
end

local function get_current_channel()
    local ok, channel = pcall(function()
        return vim.bo.channel
    end)
    if not ok or type(channel) ~= "number" or channel == 0 then
        return nil
    end
    return channel
end

local function get_terminal_argv0(channel)
    if not channel then
        return nil
    end
    local ok, info = pcall(vim.api.nvim_get_chan_info, channel)
    if not ok or type(info) ~= "table" or type(info.argv) ~= "table" then
        return nil
    end
    local argv0 = trim(info.argv[1])
    if argv0 == "" then
        return nil
    end
    return argv0
end

local function build_source_ref(source_context)
    if source_context.is_nota and source_context.source_note_name then
        return source_context.source_note_name
    end

    if source_context.source_kind == "terminal" and source_context.bufname ~= "" then
        if source_context.terminal_argv0 then
            return string.format("%s@%s %s [argv:%s]",
                source_context.user,
                source_context.host,
                source_context.bufname,
                source_context.terminal_argv0)
        end
        return string.format("%s@%s %s (%s)",
            source_context.user,
            source_context.host,
            source_context.bufname,
            source_context.buftype)
    end

    if source_context.bufname ~= "" then
        return string.format("%s@%s %s (%s)",
            source_context.user,
            source_context.host,
            source_context.bufname,
            source_context.buftype)
    end

    return string.format("%s@%s %s (%s)",
        source_context.user,
        source_context.host,
        source_context.cwd,
        source_context.buftype)
end

local function resolve_source_context()
    local source_path = get_current_buffer_path()
    local source_note_name = get_note_name_from_path(source_path)
    local bufname = get_current_bufname()
    local raw_buftype = trim(vim.bo.buftype)
    local buftype = raw_buftype ~= "" and raw_buftype or "file"
    local source_kind = "buffer"
    local channel = get_current_channel()
    local terminal_argv0 = nil

    if source_note_name then
        source_kind = "nota"
    elseif raw_buftype == "terminal" then
        source_kind = "terminal"
        terminal_argv0 = get_terminal_argv0(channel)
    end

    local source_context = {
        is_nota = source_note_name ~= nil,
        source_kind = source_kind,
        source_note_name = source_note_name,
        source_path = source_path ~= "" and source_path or bufname,
        bufname = bufname,
        buftype = buftype,
        cwd = trim(vim.fn.getcwd()) ~= "" and vim.fn.getcwd() or ".",
        user = get_env_with_fallback("USER", "unknown-user"),
        host = get_hostname_with_fallback(),
        channel = channel,
        terminal_argv0 = terminal_argv0,
    }

    source_context.source_ref = build_source_ref(source_context)
    return source_context
end

local function find_fenced_block_bounds(lines, block_head, block_tail)
    local head_pattern = "^" .. escape_lua_pattern(block_head) .. "%s*$"
    local tail_pattern = "^" .. escape_lua_pattern(block_tail) .. "%s*$"
    local block_start = nil

    for index, line in ipairs(lines) do
        if not block_start and line:match(head_pattern) then
            block_start = index
        elseif block_start and line:match(tail_pattern) then
            return block_start, index
        end
    end

    return nil, nil
end

local function get_links_from_lines(lines)
    local links = {}
    local unique_links = {}
    local block_start, block_end = find_fenced_block_bounds(lines, link_line_head, link_line_tail)

    if not block_start or not block_end or block_end <= block_start then
        return links
    end

    for index = block_start + 1, block_end - 1 do
        local link = trim(lines[index])
        if link ~= "" and not unique_links[link] then
            unique_links[link] = true
            table.insert(links, link)
        end
    end

    return links
end

local function read_links_from_note_path(nota_path)
    if vim.fn.filereadable(nota_path) == 0 then
        return {}
    end
    local lines = vim.fn.readfile(nota_path)
    return get_links_from_lines(lines)
end

local function append_link_to_note_path(nota_path, link_ref)
    local normalized_link = trim(link_ref)
    if normalized_link == "" then
        return false
    end

    local nota_content = {}
    if vim.fn.filereadable(nota_path) == 1 then
        nota_content = vim.fn.readfile(nota_path)
    end

    if vim.tbl_contains(get_links_from_lines(nota_content), normalized_link) then
        return false
    end

    local block_start, block_end = find_fenced_block_bounds(nota_content, link_line_head, link_line_tail)
    if not block_start or not block_end then
        if #nota_content > 0 and trim(nota_content[#nota_content]) ~= "" then
            table.insert(nota_content, "")
        end
        table.insert(nota_content, link_line_head)
        table.insert(nota_content, normalized_link)
        table.insert(nota_content, link_line_tail)
    else
        table.insert(nota_content, block_end, normalized_link)
    end

    vim.fn.writefile(nota_content, nota_path)
    return true
end

local capitalizeFirstLetter

local function ensure_note_exists(nota_alvo)
    local nota_alvo_path = tempestade_path .. nota_alvo
    if vim.fn.filereadable(nota_alvo_path) == 0 then
        print("Nota '" ..  nota_alvo .. "' não existe, criando...")
        local titulo = "# " .. capitalizeFirstLetter(nota_alvo)
        vim.fn.writefile({titulo, '', link_line_head, link_line_tail, ''}, nota_alvo_path)
        print("Nota '" ..  nota_alvo .. "' criada com sucesso!")
    end
    return nota_alvo_path
end

local function add_bidirectional_link(nota_fonte, nota_alvo)
    local nota_fonte_path = tempestade_path .. nota_fonte
    local nota_alvo_path = tempestade_path .. nota_alvo

    append_link_to_note_path(nota_fonte_path, nota_alvo)
    append_link_to_note_path(nota_alvo_path, nota_fonte)
end

local function add_unidirectional_source_link(source_ref, nota_alvo)
    local nota_alvo_path = tempestade_path .. nota_alvo
    append_link_to_note_path(nota_alvo_path, source_ref)
end

local function add_link_biderecional(nota_fonte, nota_alvo)
    add_bidirectional_link(nota_fonte, nota_alvo)
end

-- Transformando uma palavra é um título, Capitalize First Letter
capitalizeFirstLetter = function(str)
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

M.is_nota_path = is_nota_path
M.buffer_atual_e_nota = buffer_atual_e_nota
M.resolve_source_context = resolve_source_context

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
function M.ZettelVimCreateorFind(nota_alvo, source_context)
    -- Verifica se a palavra é vazia
    if nota_alvo == "" then
        print("Sem palavras, tsc tsc tsc...")
        return
    end
    ensure_note_exists(nota_alvo)

    source_context = source_context or resolve_source_context()

    if source_context.is_nota then
        local nota_fonte = source_context.source_note_name or vim.fn.expand("%:t")
        add_bidirectional_link(nota_fonte, nota_alvo)
        print("Nota '" ..  nota_alvo .. "' conectada com sucesso à nota '" .. nota_fonte .. "'!")
    else
        add_unidirectional_source_link(source_context.source_ref, nota_alvo)
        print("Nota '" ..  nota_alvo .. "' conectada com sucesso à fonte '" .. source_context.source_ref .. "'!")
    end

    add_link_em_indice("tempesta cerebralis", nota_alvo)
end

-------------------------------------------------------------------------------
return M
