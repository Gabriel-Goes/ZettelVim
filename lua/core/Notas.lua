-- Author: Gabriel Góes Rocha de Lima
-- Date: 2024-02-13
-- ./lua/core/Notas.lua
-- Version: 0.1
-- License: GPL-3.0
-- Description: Função para definir estrutura de notas de estudo
-------------------------------------------------------------------------------

-- Definição de arquétipos de notas de estudo.
Nota_Estudo = {
    header = {
        titulo = '',
        time = os.time(),
        links = {},
    },
    conteudo = [[]],
}
