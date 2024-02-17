-- Autor: Gabriel Góes
-- Email: gabrielgoes@usp.br
-- Date: 2024-02-17
-- Last Modified: 2024-02-17
-- Version: 0.1
-- License: GPL 3.0

-- Configurações do ZettelVim
require('zettelvim.utils')

-------------------------------------------------------------------------------
---- CreatorFind Normal Mode
vim.keymap.set("n", "<leader>zf", function()
    vim.cmd("w")
    local nota_alvo = vim.fn.expand("<cword>")
    ZettleVimCreateorFind(nota_alvo)
    -- abre o arquivo alvo
    vim.cmd("e " .. tempestade_path .. nota_alvo)
end, {noremap = true, silent = true})
--
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
print('Hello, from zettelvim.lua.config')
