-- Author: Gabriel Góes Rocha de Lima
-- Date: 2024-02-13
-- ./lua/core/SerializeMarkdown.lua
-- Version: 0.1
-- License: GPL-3.0
-- Description: Função para Serializar lua tables em MardownFiles
-------------------------------------------------------------------------------
-- Define o caminho para salvar markdowns em variável global
local temp_path = os.getenv("NVIM_TEMPESTADE")

-- Função para Serializar lua tables em MardownFiles
function SerializeMarkdown(nota, filePath)
    local file, err = io.open(temp_path .. filePath, "w")
    if not file then
        error(err) end
    -- Escreve título
    if #nota.header.titulo > 0 then
        file:write("# " .. nota.header.titulo)
    end
    -- Escreve o código
    if #nota.header.code.id > 0 then
        file:write(' -  ' .. nota.header.code.id .. "\n")
        file:write("Data: " .. os.date("%c", nota.header.code.time) .. "\n")
        file:write("\n")
    end
    -- Escreve os links
    if #nota.links > 0 then
        file:write('### Links\n')
        for _, link in ipairs(nota.links) do
            file:write("- " .. link .. "\n")
        end
    end
    -- Escreve os tags
    if #nota.tags > 0 then
        file:write('### Tags\n')
        for _, tag in ipairs(nota.tags) do
            file:write("- " .. tag .. "\n")
        end
        file:write("\n")
    end
    -- Escreve o conteúdo
    if #nota.conteudo > 0 then file:write(nota.conteudo .. "\n\n") end
    file:close() end
-------------------------------------------------------------------------------
print("SerializeMarkdown Carregado com sucesso")
