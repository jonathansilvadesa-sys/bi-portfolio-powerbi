// ============================================================
// PROJETO 03 — E-COMMERCE (Dataset Olist)
// Power Query M: uma consulta por bloco abaixo.
// No Power BI: Página Inicial > Transformar dados > Nova fonte >
// Consulta nula > Editor avançado, e cole o bloco (sem o comentário
// de título). O nome da consulta é o do título de cada bloco.
//
// Fonte: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
// Autor: Jonathan Silva de Sá
//
// Decisões de modelagem (detalhes no README):
// 1. O cliente real é customer_unique_id. customer_id muda a cada pedido.
// 2. Janela de análise: jan/2017 a ago/2018. Os meses fora dela têm de
//    1 a 324 pedidos e distorcem as tendências.
// 3. Pedidos cancelados ou indisponíveis ficam no modelo (para contar
//    cancelamentos), mas saem da receita via coluna pedido_valido.
// 4. Uma avaliação por pedido: a resposta mais recente.
// 5. Números vêm com ponto decimal: toda tipagem usa a cultura "en-US",
//    senão um Power BI em português lê 58.9 como 589.
// ============================================================


// ────────────────────────────────────────────────────────────
// PastaDados  (parâmetro de texto: Gerenciar parâmetros > Novo)
// Valor: C:\dev\olist\   (com a barra no final)
// ────────────────────────────────────────────────────────────


// ────────────────────────────────────────────────────────────
// fnLerCsv  (função auxiliar, não carregar no modelo)
// ────────────────────────────────────────────────────────────
(arquivo as text) as table =>
let
    Fonte = Csv.Document(
        File.Contents(PastaDados & arquivo),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Cabecalhos = Table.PromoteHeaders(Fonte, [PromoteAllScalars = true])
in
    Cabecalhos


// ────────────────────────────────────────────────────────────
// stgClientes  (auxiliar, não carregar)
// Mapa customer_id (um por pedido) -> customer_unique_id (o cliente real)
// ────────────────────────────────────────────────────────────
let
    Fonte = fnLerCsv("olist_customers_dataset.csv"),
    Colunas = Table.SelectColumns(Fonte, {"customer_id", "customer_unique_id", "customer_city", "customer_state"}),
    Renomeadas = Table.RenameColumns(Colunas, {
        {"customer_id", "id_cliente_pedido"},
        {"customer_unique_id", "id_cliente_unico"},
        {"customer_city", "cidade"},
        {"customer_state", "uf"}
    })
in
    Renomeadas


// ────────────────────────────────────────────────────────────
// stgAvaliacoes  (auxiliar, não carregar)
// 551 pedidos têm mais de uma avaliação: fica a resposta mais recente.
// ────────────────────────────────────────────────────────────
let
    Fonte = fnLerCsv("olist_order_reviews_dataset.csv"),
    Colunas = Table.SelectColumns(Fonte, {"order_id", "review_score", "review_answer_timestamp"}),
    Tipadas = Table.TransformColumnTypes(Colunas, {
        {"review_score", Int64.Type},
        {"review_answer_timestamp", type datetime}
    }, "en-US"),
    // Table.Buffer fixa a ordenação antes de remover duplicatas
    Ordenadas = Table.Buffer(Table.Sort(Tipadas, {{"review_answer_timestamp", Order.Descending}})),
    UmaPorPedido = Table.Distinct(Ordenadas, {"order_id"}),
    Final = Table.SelectColumns(UmaPorPedido, {"order_id", "review_score"})
in
    Final


// ────────────────────────────────────────────────────────────
// fPedidos  (carregar)
// Grão: um pedido. 99.092 linhas na janela.
// ────────────────────────────────────────────────────────────
let
    Fonte = fnLerCsv("olist_orders_dataset.csv"),
    Tipadas = Table.TransformColumnTypes(Fonte, {
        {"order_purchase_timestamp", type datetime},
        {"order_delivered_customer_date", type datetime},
        {"order_estimated_delivery_date", type datetime}
    }, "en-US"),
    ComData = Table.AddColumn(Tipadas, "data_pedido", each Date.From([order_purchase_timestamp]), type date),
    NaJanela = Table.SelectRows(ComData, each [data_pedido] >= #date(2017, 1, 1) and [data_pedido] <= #date(2018, 8, 31)),

    // cliente real
    ComCliente = Table.NestedJoin(NaJanela, {"customer_id"}, stgClientes, {"id_cliente_pedido"}, "cli", JoinKind.LeftOuter),
    // cidade e UF de entrega deste pedido
    ExpandeCliente = Table.ExpandTableColumn(ComCliente, "cli", {"id_cliente_unico", "cidade", "uf"},
        {"id_cliente_unico", "cidade_cliente", "uf_cliente"}),

    // avaliação
    ComAvaliacao = Table.NestedJoin(ExpandeCliente, {"order_id"}, stgAvaliacoes, {"order_id"}, "av", JoinKind.LeftOuter),
    ExpandeAvaliacao = Table.ExpandTableColumn(ComAvaliacao, "av", {"review_score"}, {"nota_avaliacao"}),

    ComValido = Table.AddColumn(ExpandeAvaliacao, "pedido_valido",
        each not List.Contains({"canceled", "unavailable"}, [order_status]), type logical),
    ComDataEntrega = Table.AddColumn(ComValido, "data_entrega", each Date.From([order_delivered_customer_date]), type date),
    ComDataEstimada = Table.AddColumn(ComDataEntrega, "data_estimada", each Date.From([order_estimated_delivery_date]), type date),
    ComDias = Table.AddColumn(ComDataEstimada, "dias_ate_entrega",
        each if [data_entrega] = null then null else Duration.Days([data_entrega] - [data_pedido]), Int64.Type),
    ComNoPrazo = Table.AddColumn(ComDias, "entregue_no_prazo",
        each if [data_entrega] = null then null else [data_entrega] <= [data_estimada], type logical),

    Final = Table.SelectColumns(Table.RenameColumns(ComNoPrazo, {
        {"order_id", "id_pedido"}, {"order_status", "status_pedido"}}), {
        "id_pedido", "id_cliente_unico", "cidade_cliente", "uf_cliente", "status_pedido", "pedido_valido", "data_pedido",
        "data_entrega", "data_estimada", "dias_ate_entrega", "entregue_no_prazo", "nota_avaliacao"}),
    Tipos = Table.TransformColumnTypes(Final, {
        {"id_pedido", type text}, {"id_cliente_unico", type text}, {"cidade_cliente", type text},
        {"uf_cliente", type text}, {"status_pedido", type text}, {"nota_avaliacao", Int64.Type}})
in
    Tipos


// ────────────────────────────────────────────────────────────
// fItens  (carregar)
// Grão: um item de pedido. Leva data, cliente, UF e validade do pedido
// para se ligar direto às dimensões (modelo estrela, sem fato->fato).
// ────────────────────────────────────────────────────────────
let
    Fonte = fnLerCsv("olist_order_items_dataset.csv"),
    Tipadas = Table.TransformColumnTypes(Fonte, {
        {"order_item_id", Int64.Type},
        {"price", type number},
        {"freight_value", type number}
    }, "en-US"),
    ComPedido = Table.NestedJoin(Tipadas, {"order_id"}, fPedidos, {"id_pedido"}, "ped", JoinKind.Inner),
    ExpandePedido = Table.ExpandTableColumn(ComPedido, "ped",
        {"data_pedido", "id_cliente_unico", "uf_cliente", "pedido_valido"}),
    ComReceita = Table.AddColumn(ExpandePedido, "receita", each [price] + [freight_value], type number),
    Final = Table.SelectColumns(Table.RenameColumns(ComReceita, {
        {"order_id", "id_pedido"}, {"order_item_id", "item"}, {"product_id", "id_produto"},
        {"seller_id", "id_vendedor"}, {"price", "valor_produto"}, {"freight_value", "valor_frete"}}), {
        "id_pedido", "item", "id_produto", "id_vendedor", "id_cliente_unico", "uf_cliente",
        "data_pedido", "pedido_valido", "valor_produto", "valor_frete", "receita"}),
    Tipos = Table.TransformColumnTypes(Final, {
        {"id_pedido", type text}, {"id_produto", type text}, {"id_vendedor", type text},
        {"id_cliente_unico", type text}, {"uf_cliente", type text}, {"data_pedido", type date},
        {"pedido_valido", type logical}})
in
    Tipos


// ────────────────────────────────────────────────────────────
// dClientes  (carregar)
// Grão: um cliente real. Cidade e UF do pedido mais recente
// (39 clientes mudaram de estado entre pedidos).
// ────────────────────────────────────────────────────────────
let
    Pedidos = Table.SelectColumns(fPedidos, {"id_cliente_unico", "cidade_cliente", "uf_cliente", "data_pedido"}),
    // Table.Buffer fixa a ordenação antes de remover duplicatas
    Ordenados = Table.Buffer(Table.Sort(Pedidos, {{"data_pedido", Order.Descending}})),
    UmPorCliente = Table.Distinct(Ordenados, {"id_cliente_unico"}),
    Final = Table.RenameColumns(Table.SelectColumns(UmPorCliente, {"id_cliente_unico", "cidade_cliente", "uf_cliente"}),
        {{"cidade_cliente", "cidade"}, {"uf_cliente", "uf"}}),
    Tipos = Table.TransformColumnTypes(Final, {{"id_cliente_unico", type text}, {"cidade", type text}, {"uf", type text}})
in
    Tipos


// ────────────────────────────────────────────────────────────
// dProdutos  (carregar)
// 610 produtos sem categoria viram "Sem Categoria".
// ────────────────────────────────────────────────────────────
let
    Fonte = fnLerCsv("olist_products_dataset.csv"),
    Colunas = Table.SelectColumns(Fonte, {"product_id", "product_category_name"}),
    SemNulo = Table.ReplaceValue(Colunas, "", "sem_categoria", Replacer.ReplaceValue, {"product_category_name"}),
    Legivel = Table.TransformColumns(SemNulo, {{"product_category_name",
        each Text.Proper(Text.Replace(_, "_", " ")), type text}}),
    Final = Table.RenameColumns(Legivel, {{"product_id", "id_produto"}, {"product_category_name", "categoria"}}),
    Tipos = Table.TransformColumnTypes(Final, {{"id_produto", type text}})
in
    Tipos
