-- Autor: Gabriel Góes Rocha de Lima
-- Data: 2024-02-12
-- ./lua/core/NovaNota.lua
-- Version: 0.1
-- License: GPL-3.0
-- Description: Função para criar novas notas
-------------------------------------------------------------------------------
local MinhaNovaNota = Notas
-- Função para criar novas notas
function NovaNota (titulo, conteudo, links)
    MinhaNovaNota = {
        header = {
            titulo = titulo,
            time = os.time(),
            links = links or {}
        },
        conteudo = conteudo
    }
    local fileName = "./docs/TempestadeCerebral/" .. titulo .. ".lua"
    local file, er = io.open(fileName, "w")
    if file then
        SerializeWithVarName(titulo, MinhaNovaNota, fileName) file:close()
    else error(er .. " -> " .. fileName .. " -> " .. os.date())
    end
end
