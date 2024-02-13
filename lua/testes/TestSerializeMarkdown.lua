-- Author: Gabriel Góes Rocha de Lima
-- Date: 2024-02-13
-- ./lua/testes/TestSerializeMarkdown.lua
-- Version: 0.1
-- License: GPL-3.0
-- Description: Função para testar SerializeMardown.lua
-------------------------------------------------------------------------------
require("SerializeMarkdown")
print("SerializeMarkdown Carregado com sucesso")

-- Exemplo de nota 
local minhaNota = {
    header = {
        titulo = "Minha Primeira Nota em Markdown",
          code = {
              id = '1',
              time = os.time()},
    },
    tags = {'teste', 'lua'},
    links = {},
    conteudo =[[
## Testando a serialização de notas em markdown

Testando.]]
}
print("minhaNota definida com sucesso")

-- Chamada da função SerializeMarkdown para minhaNota e salvando em Teste_Markdown.md
print('')
print("Teste SerializeMarkown")
SerializeMarkdown(minhaNota, "Teste_Markdown.md")
