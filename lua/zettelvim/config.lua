-- Autor: Gabriel Góes
-- Email: gabrielgoes@usp.br
-- Date: 2024-02-17
-- Last Modified: 2024-02-17
-- Version: 0.1
-- License: GPL 3.0
-- ZettelVim/lua/zettelvim/config.lua
-------------------------------------------------------------------------------
-- Configurações do ZettelVim
local utils = require('zettelvim.utils')
local tempestade_path = utils.get_tempestade_path()
-------------------------------------------------------------------------------
M = {}
function M.NormallCall()
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
    print('Seleção atual: ' .. selection) -- Imprime a seleção atual
    utils.ZettelVimCreateorFind(selection) -- Chama a função ZettelVimCreateorFind com a seleção
    vim.fn.setreg("a", "") -- limpa o registro 'a'
    vim.cmd("e " .. tempestade_path .. selection) -- abre o arquivo alvo
end

function M.setup(opts)
    vim.api.nvim_set_keymap('n', opts.normal_mode_keymap or '<leader>bf', '<cmd>lua require("zettelvim.config").NormalCall()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('v', opts.visual_mode_keymap or 'bf', '<cmd>lua require("zettelvim.config").VisualCall()<CR>', { noremap = true, silent = true })
end

return M
-------------------------------------------------------------------------------
