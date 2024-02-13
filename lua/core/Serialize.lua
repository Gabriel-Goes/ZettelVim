-- Serialização de Notas(lua tables) para um código lua que gera as lua tables.
function Serialize (o, file, indent)
    indent = indent or ''
    local write = function(str) file:write(str) end --

    if type(o) == 'number' then
        write(o)
    elseif type(o) == 'string' then
        write(string.format('%q', o))
    elseif type(o) == 'table' then
        write('{\n')
        for k,v in pairs(o) do
            write(indent .. '  [')
            Serialize(k, indent .. '  ')
            write('] = ')
            Serialize(v, indent .. '  ')
            write(',\n')
        end
        write(indent .. '}\n')
    else
        error('cannot serialize a ' .. type(o))
    end
end
