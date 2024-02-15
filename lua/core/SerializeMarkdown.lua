-- Author: Gabriel Góes Rocha de Lima
-- Date: 2024-02-13
-- ./lua/core/SerializeMarkdown.lua
-- Version: 0.1
-- License: GPL-3.0
-- Description: Função para Serializar lua tables em MardownFiles
-------------------------------------------------------------------------------
-- Define o caminho para salvar markdowns em variável global
-- Função para Serializar lua tables em MardownFiles

function SerializeMarkdown(nota)
    local filePath = "./docs/markdown/" .. nota.header.titulo .. ".md"
    local file, err = io.open(filePath, "w")
    if not file then
        error(err) end
    -- Escreve título
    if nota.header.titulo then
        file:write("# " .. nota.header.titulo .. "\n")
    end
    -- Escreve a data
    if nota.header.time then
        print(nota.header.time)
        file:write("Data: " .. os.date("%c", nota.header.time) .. "\n")
        file:write("\n")
    end
    -- Escreve os links
    if #nota.header.links > 0 then
        print(nota.header.links.length)
        file:write('---- Links --------------------------------------------------------------------\n')
        for n, link in ipairs(nota.header.links) do
            file:write("[" .. n .. '] ' .. link .. "\n")
        end
        file:write("-------------------------------------------------------------------------------\n\n")
    -- Escreve o conteúdo
    if nota.conteudo then file:write(nota.conteudo .. "\n") end
    file:close() end
end
