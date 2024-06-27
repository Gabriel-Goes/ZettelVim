-- Autor: Gabriel Góes
-- Email: gabrielgoes@usp.br
-- Date: 2024-02-17
-- Last Modified: 2024-06-27
-- Version: 0.1.1
-- License: GPL 3.0
-- ZettelVim/lua/zettelvim/config.lua
-------------------------------------------------------------------------------
-- Configurações do ZettelVim
local utils = require('zettelvim.utils')
local tempestade_path = utils.get_tempestade_path()
local ZettelVimCreateorFind = utils.ZettelVimCreateorFind
local wikipedia_lang = 'pt'
-------------------------------------------------------------------------------
local M = {}
function M.NormalCall()
    print('Normal Call')
    -- Salva o arquivo atual
    vim.cmd("w")
    local nota_alvo = vim.fn.expand("<cword>")
    print('Nota Alvo: ' .. nota_alvo)
    ZettelVimCreateorFind(nota_alvo)
    -- abre o arquivo alvo
    vim.cmd("e " .. tempestade_path .. nota_alvo)
end

function M.VisualCall()
    vim.cmd("w") -- Salva o arquivo atual
    vim.cmd("normal! \"ay") -- Yank a seleção do buffer no visual mode, e apenas a seleção ao registro 'a'
    local selection = vim.fn.getreg("a") -- Imediatamente após o yan, obtém a seleção do registro 'a' e armazena na variável selection
    selection = selection:gsub("\n", " ") -- Substitui quebras de linha por espaços
    selection = selection:gsub("%c", " ") -- Substitui ^@ por espaços
    print('Seleção atual: ' .. selection) -- Imprime a seleção atual
    ZettelVimCreateorFind(selection) -- Chama a função ZettelVimCreateorFind com a seleção
    vim.fn.setreg("a", "") -- limpa o registro 'a'
    vim.cmd("e " .. tempestade_path .. selection) -- abre o arquivo alvo
end

function M.openWikipediaPage(text)
    text = text:gsub(" ", "_")
    local url = "https://" .. wikipedia_lang .. ".wikipedia.org/wiki/" .. text
    local command = vim.fn.has('win32') == 1 and "start" or "xdg-open"
    vim.fn.system(command .. " " .. vim.fn.shellescape(url))
end

function M.searchWikipedia()
    local mode = vim.api.nvim_get_mode().mode
    local text = nil
    if mode == 'n' then
        text = vim.fn.expand("<cword>")
        print('Texto: ' .. text)
    elseif mode == 'v' or mode == 'V' or mode == '' then
        vim.cmd("normal! \"ay") -- Yank a seleção do buffer no visual mode, e apenas a seleção ao registro 'a'
        text = vim.fn.getreg("a") -- Imediatamente após o yan, obtém a seleção do registro 'a' e armazena na variável selection
    end
    if text and text ~= '' then
        vim.ui.input({ prompt = 'Search Wikipedia (pt/en): ', default = 'pt'}, function(lang)
            if lang and lang ~= '' then wikipedia_lang = lang end
            vim.ui.input({ prompt = 'Search Wikipedia: ', default = text} , function(input_text)
                if input_text and input_text ~= '' then M.openWikipediaPage(input_text) end
            end)
        end)
    else
        print('modo não suportado')
    end
end

function M.setup(opts)
    vim.api.nvim_set_keymap('v', opts.visual_mode_keymap or 'qf',
        '<cmd>lua require("zettelvim.config").VisualCall()<CR>',
        { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', opts.normal_mode_keymap or '<leader>qf',
        '<cmd>lua require("zettelvim.config").NormalCall()<CR>',
        { noremap = true, silent = true })
    -- Search Wikipedia
    vim.api.nvim_set_keymap('n', opts.wiki_normal_mode_keymap or '<leader>ws',
        '<cmd>lua require("zettelvim.config").searchWikipedia()<CR>',
        {noremap = true, silent = true})
    vim.api.nvim_set_keymap('v', opts.wiki_visual_mode_keymap or 'ws',
        '<cmd>lua require("zettelvim.config").searchWikipedia()<CR>',
        {noremap = true, silent = true})
end

return M
-------------------------------------------------------------------------------
