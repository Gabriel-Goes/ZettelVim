-- Autor: Gabriel Góes
-- Email: gabrielgoes@usp.br
-- Date: 2024-02-17
-- Last Modified: 2024-02-17
-- Version: 0.1
-- License: GPL 3.0
-- ZettelVim/lua/zettelvim/config.lua
-------------------------------------------------------------------------------
print('Hello, from zettelvim.lua.config')
-- Configurações do ZettelVim
local utils = require('zettelvim.utils')
local tempestade_path = utils.get_tempestade_path()
-------------------------------------------------------------------------------
local M = {}
function M.NormalCall()
    -- Salva o arquivo atual
    vim.cmd("w")
    local nota_alvo = vim.fn.expand("<cword>")
    utils.ZettelVimCreateorFind(nota_alvo)
    -- abre o arquivo alvo
    vim.cmd("e " .. tempestade_path .. nota_alvo)
    end
function M.VisualCall()
    vim.cmd("w") -- Salva o arquivo atual
    vim.cmd("normal! \"ay") -- Yank a seleção do buffer no visual mode, e apenas a seleção ao registro 'a'
    local selection = vim.fn.getreg("a") -- Imediatamente após o yan, obtém a seleção do registro 'a' e armazena na variável selection
    utils.ZettelVimCreateorFind(selection) -- Chama a função ZettelVimCreateorFind com a seleção
    vim.fn.setreg("a", "") -- limpa o registro 'a'
    vim.cmd("e " .. tempestade_path .. selection) -- abre o arquivo alvo
end
return M
