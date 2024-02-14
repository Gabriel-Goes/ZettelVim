-- Autor: Gabriel Góes Rocha de Lima
-- Data: 2024-02-12
-- ./lua/core/NovaNota.lua
-- Version: 0.1
-- License: GPL-3.0
-- Description: Função para criar novas notas
-------------------------------------------------------------------------------
local MinhaNovaNota = Notas
-- Função para criar novas notas
function NovaNota (titulo, conteudo, tags, links)
    MinhaNovaNota = {
        header = {
            titulo = titulo,
            code = {
                id = '1',
                time = os.time()
            }
        },
        tags = tags or {},
        links = links or {},
        conteudo = conteudo,
        subnotas = {}
    }
    local fileName = "./docs/TempestadeCerebral/" .. MinhaNovaNota.header.code.id .. '-' .. titulo:gsub("%s+", "_") .. ".lua"
    local file, er = io.open(fileName, "w")
    if file then
        SerializeWithVarName(titulo, MinhaNovaNota, fileName) file:close()
    else error(er .. " -> " .. fileName .. " -> " .. os.date())
    end
end
