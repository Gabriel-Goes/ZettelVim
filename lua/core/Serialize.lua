-- Author: Gabriel Góes Rocha de Lima
-- Date: 2024-02-13
-- ./lua/core/Serialize.lua
-- Version: 0.1
-- License: GPL-3.0
-- Description: Função para serializar uma lua table em um arquivo.lua
-------------------------------------------------------------------------------
-- Inicia a serialização com o nome da variável
function SerializeWithVarName(varName, o, filePath)
    local file, err = io.open(filePath, 'w')
    if not file then error('Could not open file: ' .. err) end
    file:write(varName .. ' = ')
    Serialize(o, file)
    file:write('\n')
    file:close()
end
-- Serialização de Notas(lua tables) para um código lua que gera as lua tables.
function Serialize (o, file, indent)
    indent = indent or ''
    local write = function(str) file:write(str) end

    if type(o) == 'number' then
        write(tostring(o))
    elseif type(o) == 'string' then
        write(string.format('%q', o))
    elseif type(o) == 'table' then
        write('{\n')
        for k, v in pairs(o) do
            write(indent .. '  [' .. string.format('%q', k) .. '] = ')
            Serialize(v, file, indent .. '  ')
            write(',\n')
        end
        write(indent .. '}\n')
    else
        error(' -> Cannot serialize a ' .. type(o))
    end
end
