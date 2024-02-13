-- Autor: Gabriel Góes Rocha de Lima
-- Data: 2024-02-12
-- ./lua/core/NovaNota.lua
-------------------------------------------------------------------------------
-- Função para criar novas notas
function NovaNota (titulo, conteudo, tags, links)
    local nota = {
        header = {titulo = titulo,
                  code = {time = os.time(),
                          id = '',
                  tags = tags or {}}
        },
        links = links,
        conteudo = conteudo,
    }

    local fileName = "TempestadeCerebral/" .. nota.header.code.id .. ".lua"
    local file, er = io.open(fileName, "w")
    if file then Serialize(nota, file) file:close() else error(er) end
end
