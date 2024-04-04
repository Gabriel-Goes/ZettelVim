# ZettelVim

ZettelVim é um ambiente de escrita de notas para estudos no Neovim, usando Lua e Treesitter. Insparado no método Zettelkasten de Niklas Luhmannvisa criar um ecossistema de conhecimento interconectado, onde cada nota pode ser facilmente acessada, criada e interligada, formando uma rede robusta de informações.

## Características

- **Criação e Acesso Rápido a Notas**: Com simples comandos, crie e acesse notas diretamente no Neovim.
- **Links Bidirecionais**: Implementação do conceito de hiperligações à maneira do Zettelkasten, permitindo conexões ricas entre notas.
- **Notas Índices Temáticos**: Se achar interessante, organize notas em temas específicos, aumentando a conexão entre notas de mesma temática.
- **Flexibilidade e Extensibilidade**: Desenvolvido com lua e aproveitando o poder do Treesitter para análise sintática, oferecendo uma base para expanões futuras e customizações.

![Alt text](https://raw.githubusercontent.com/Gabriel-Goes/ZettelVim/main/zettelvim2.gif)

## Início Rápido

Para começar a usar o ZettelVim, siga estes passos:

1. Garanta que tenha o [Neovim](https://neovim.io/) instalado em sua máquina.
2. Clone este repositório para a sua máquina local.
3. Siga as instruções de configuração no arquivo 'INSTALL.md' para configurar o ZettelVim no Neovim.

## Comandos Básicos

- Para criar uma nova nota, use `<leader>qff` com o cursor sobre a palavra desejada.
- No modo visual, o comando `qff` permite acessar termos compostos por mais de uma palavra selecionadas.
- Notas automaticamente criadas são adicionadas ao glossário, e seus links são gerenciados automaticamente.

## Estrutura do Projeto

ZettelVim organiza o conhecimento em notas individuais dentro de um diretório chamado `TempestadeCerebral`. Cada nota pode conter links para outras notas, formando uma rede de conhecimento interconectada.

## Contribuições

Contribuições para o ZettelVim são bem-vindas! Se você tem ideias para melhorias, correções de bugs ou novas funcionalidades, sinta-se à vontade para abrir uma issue ou enviar um pull request.

## Licença

Este projeto é distribuido sob a licença GPL-3.0. Veja o arquivo `LICENSE` para mais detalhes.

## Reconhecimentos

- Niklas Luhmann, pelo desenvolvimento do método Zettelkasten.
- A comunidade Neovim, pelo desenvolvimento de um editor poderoso e extensível.
