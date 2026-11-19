# Dicionário de dados

## fPedidos (um pedido)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id_pedido | texto | `order_id` |
| id_cliente_unico | texto | `customer_unique_id`: o cliente real |
| cidade_cliente, uf_cliente | texto | Endereço de entrega deste pedido |
| status_pedido | texto | delivered, shipped, canceled, unavailable, invoiced, processing, created, approved |
| pedido_valido | lógico | Falso para canceled e unavailable |
| data_pedido | data | Data da compra (sem hora) |
| data_entrega | data | Data de entrega ao cliente (nula se não entregue) |
| data_estimada | data | Data prometida na compra |
| dias_ate_entrega | inteiro | data_entrega − data_pedido |
| entregue_no_prazo | lógico | data_entrega ≤ data_estimada |
| nota_avaliacao | inteiro | 1 a 5; resposta mais recente do pedido |

## fItens (um item de pedido)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id_pedido, item | texto, inteiro | Pedido e número do item |
| id_produto, id_vendedor | texto | Produto e vendedor |
| id_cliente_unico, uf_cliente, data_pedido, pedido_valido | | Copiados do pedido, para ligar direto às dimensões |
| valor_produto | decimal | `price` |
| valor_frete | decimal | `freight_value` |
| receita | decimal | valor_produto + valor_frete |

## dClientes (um cliente real)

| Coluna | Descrição |
|--------|-----------|
| id_cliente_unico | `customer_unique_id` |
| cidade, uf | Do pedido mais recente |

## dProdutos (um produto)

| Coluna | Descrição |
|--------|-----------|
| id_produto | `product_id` |
| categoria | Nome legível ("Cama Mesa Banho"); "Sem Categoria" para os 610 produtos sem categoria |

## dCalendario (um dia, 01/01/2017 a 31/08/2018)

Data · Ano · Trimestre · MesNum · Mes · MesAno · AnoMesNum (para ordenar) · DiaSemana · DiaSemanaNum

## dRFM (um cliente com pedido válido)

| Coluna | Descrição |
|--------|-----------|
| Recencia | Dias entre a última compra e 01/09/2018 |
| Frequencia | Pedidos válidos |
| Valor | Receita do cliente |
| R, M | Quintis (5 = melhor) |
| F | 1, 2 ou 3 (3 ou mais pedidos) |
| Segmento, OrdemSegmento | Campeões, Recorrentes, Recorrentes em risco, Novos, Compradores ocasionais, Inativos |
