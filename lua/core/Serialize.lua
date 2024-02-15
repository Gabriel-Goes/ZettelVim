-- Author: Gabriel Góes Rocha de Lima
-- Date: 2024-02-13
-- ./lua/core/Serialize.lua
-- Version: 0.1
-- License: GPL-3.0
-- Description: Função para serializar uma lua table em um arquivo.lua
-------------------------------------------------------------------------------
--
local function removerAcentos(str)
    local accents = {
        ['á'] = 'a', ['é'] = 'e', ['í'] = 'i', ['ó'] = 'o', ['ú'] = 'u',
        ['Á'] = 'A', ['É'] = 'E', ['Í'] = 'I', ['Ó'] = 'O', ['Ú'] = 'U',
        ['à'] = 'a', ['è'] = 'e', ['ì'] = 'i', ['ò'] = 'o', ['ù'] = 'u',
        ['À'] = 'A', ['È'] = 'E', ['Ì'] = 'I', ['Ò'] = 'O', ['Ù'] = 'U',
        ['ã'] = 'a', ['õ'] = 'o',
        ['Ã'] = 'A', ['Õ'] = 'O',
        ['â'] = 'a', ['ê'] = 'e', ['î'] = 'i', ['ô'] = 'o', ['û'] = 'u',
        ['Â'] = 'A', ['Ê'] = 'E', ['Î'] = 'I', ['Ô'] = 'O', ['Û'] = 'U',
        ['ç'] = 'c', ['Ç'] = 'C',
    }
    for accented, unaccented in pairs(accents) do
        str = str:gsub(accented, unaccented)
    end
    str = str:gsub("%s+", "_")
    return str
end
--
-- Inicia a serialização com o nome da variável
function SerializeWithVarName(varName, o, filePath)
    local file, err = io.open(filePath, 'w')
    if not file then error('Could not open file: ' .. err) end
    file:write(removerAcentos(varName) .. ' = ')
    Serialize(o, file)
    file:write('\n')
    file:write('return ' .. removerAcentos(varName))
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
