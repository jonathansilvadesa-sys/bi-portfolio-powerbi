# Roteiro de montagem no Power BI Desktop

Siga na ordem. Ao fim de cada etapa, confira os números em [numeros_de_conferencia.md](numeros_de_conferencia.md).

## 1. Dados (Power Query)

1. **Página Inicial > Transformar dados.** No editor: **Gerenciar parâmetros > Novo parâmetro**, nome `PastaDados`, tipo Texto, valor `C:\dev\olist\` (com a barra no final).
2. Para cada bloco de [`transformacoes_olist.m`](../powerquery/transformacoes_olist.m), na ordem do arquivo: **Nova fonte > Consulta nula > Editor avançado**, cole o código e renomeie a consulta com o nome do título do bloco.
3. Em `fnLerCsv`, `stgClientes` e `stgAvaliacoes`: botão direito > desmarque **Habilitar carga**. Elas são auxiliares.
4. **Fechar e aplicar.** Confira: `fPedidos` com 99.092 linhas.

## 2. Modelo

1. **Modelagem > Nova tabela**: cole `dCalendario` (de `dax/medidas_ecommerce.dax`). Depois: **Marcar como tabela de datas** (coluna `Data`) e, na coluna `MesAno`, **Classificar por coluna > AnoMesNum**.
2. Relacionamentos (Exibição de modelo), todos 1:* com filtro em sentido único, saindo da dimensão:

| De (1) | Para (*) |
|--------|----------|
| dCalendario[Data] | fPedidos[data_pedido] |
| dCalendario[Data] | fItens[data_pedido] |
| dClientes[id_cliente_unico] | fPedidos[id_cliente_unico] |
| dClientes[id_cliente_unico] | fItens[id_cliente_unico] |
| dProdutos[id_produto] | fItens[id_produto] |

3. **Nova tabela**: cole `dRFM` (de `dax/rfm_analysis.dax`). Relacione `dRFM[id_cliente_unico]` com `dClientes[id_cliente_unico]` (1:1, filtro nos dois sentidos). Classifique `dRFM[Segmento]` por `dRFM[OrdemSegmento]`.
4. Crie uma tabela vazia `_Medidas` (**Inserir dados > Carregar**) e cole nela todas as medidas dos dois arquivos `.dax`.
5. Formatos: medidas de receita em moeda R$ com 2 casas, as de `%` em porcentagem com 1 casa, notas com 2 casas.

## 3. Páginas

Tela 16:9. Cada página responde a uma pergunta, que vira o título dela.

### Página 1 · Vendas: "A receita mais que dobrou em 2018, com pico na Black Friday"

| Posição | Visual | Campos |
|---------|--------|--------|
| Topo | 4 cartões | Receita · Pedidos · Ticket Medio · Taxa de Recompra |
| Centro | Gráfico de linhas | Eixo: dCalendario[MesAno] · Valores: Receita e Receita Media Movel 3M |
| Base esquerda | Barras horizontais (top 10) | dProdutos[categoria] · Receita |
| Base direita | Mapa coroplético ou barras | fItens[uf_cliente] · Receita |
| Segmentação | Botões | dCalendario[Ano] |

### Página 2 · Logística: "93% chegam no prazo, mas o atraso custa 2 pontos de nota"

| Posição | Visual | Campos |
|---------|--------|--------|
| Topo | 3 cartões | Prazo Medio de Entrega (dias) · % Entregue no Prazo · Pedidos Cancelados |
| Centro esquerda | Colunas agrupadas | Nota Media no Prazo e Nota Media com Atraso (cartão de título: medida Titulo Atraso) |
| Centro direita | Barras | fPedidos[uf_cliente] · Prazo Medio de Entrega (dias), ordenado |
| Base | Linhas | dCalendario[MesAno] · % Entregue no Prazo |

### Página 3 · Satisfação: "58% dão nota máxima; 14% dão 1 ou 2"

| Posição | Visual | Campos |
|---------|--------|--------|
| Topo | 3 cartões | Nota Media · % Nota 5 · % Notas 1 e 2 |
| Centro | Colunas | fPedidos[nota_avaliacao] · Pedidos Avaliados |
| Base | Linhas | dCalendario[MesAno] · Nota Media |

### Página 4 · Clientes: "97% compraram uma vez só: o desafio é recompra"

| Posição | Visual | Campos |
|---------|--------|--------|
| Topo | Cartão de texto | medida Titulo Recompra |
| Topo | 3 cartões | Clientes · Clientes Recorrentes · Taxa de Recompra |
| Centro | Barras horizontais | dRFM[Segmento] · Clientes RFM e Receita |
| Base | Matriz | Linhas: dRFM[Segmento] · Valores: Clientes RFM, % Clientes no Segmento, Valor Medio por Cliente, Recencia Media (dias) |

## 4. Salvar e publicar no repositório

1. **Arquivo > Opções > Recursos em versão prévia**: ative **Salvar como projeto do Power BI (.pbip)**, se ainda não estiver ativo.
2. **Arquivo > Salvar como** > tipo `.pbip`, na pasta `projeto-03-ecommerce/pbip/` do repositório. O formato `.pbip` salva modelo e relatório como texto, então o Git mostra o que mudou entre versões.
3. Tire um print de cada página (**Exportar > PDF** e recortar, ou a ferramenta de captura do Windows) e salve em `projeto-03-ecommerce/docs/prints/` como `01_vendas.png`, `02_logistica.png`, `03_satisfacao.png` e `04_clientes.png`.
4. Não suba os CSVs: são 120 MB, e qualquer pessoa baixa do Kaggle.
