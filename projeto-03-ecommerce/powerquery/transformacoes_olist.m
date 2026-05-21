// ============================================================
// PROJETO 03 — E-COMMERCE (Dataset Olist)
// Arquivo: transformacoes_olist.m
// Descrição: Power Query M para tratamento do dataset Olist
// Fonte: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
// Arquivos: olist_orders_dataset.csv, olist_order_items_dataset.csv
//           olist_customers_dataset.csv, olist_products_dataset.csv
//           olist_order_reviews_dataset.csv
// Autor: Jonathan Silva de Sá
// ============================================================


// ────────────────────────────────────────────────────────────
// QUERY 1: fPedidos — Tabela de pedidos tratada
// ────────────────────────────────────────────────────────────
let
    Fonte = Csv.Document(
        File.Contents("dados/olist_orders_dataset.csv"),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Cabecalhos = Table.PromoteHeaders(Fonte, [PromoteAllScalars = true]),

    // Selecionar colunas relevantes
    Selecionadas = Table.SelectColumns(
        Cabecalhos,
        {
            "order_id",
            "customer_id",
            "order_status",
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date"
        }
    ),

    // Renomear para português
    Renomeadas = Table.RenameColumns(
        Selecionadas,
        {
            {"order_id",                        "id_pedido"},
            {"customer_id",                     "id_cliente"},
            {"order_status",                    "status_pedido"},
            {"order_purchase_timestamp",        "data_pedido"},
            {"order_approved_at",               "data_aprovacao"},
            {"order_delivered_carrier_date",    "data_coleta_transportadora"},
            {"order_delivered_customer_date",   "data_entrega"},
            {"order_estimated_delivery_date",   "data_estimada_entrega"}
        }
    ),

    // Tipagem correta para datas
    Tipagem = Table.TransformColumnTypes(
        Renomeadas,
        {
            {"id_pedido",                    type text},
            {"id_cliente",                   type text},
            {"status_pedido",                type text},
            {"data_pedido",                  type datetime},
            {"data_aprovacao",               type datetime},
            {"data_coleta_transportadora",   type datetime},
            {"data_entrega",                 type datetime},
            {"data_estimada_entrega",        type datetime}
        }
    ),

    // Extrair só a data (sem hora) para join com calendário
    ComDataPedidoDate = Table.AddColumn(
        Tipagem,
        "data_pedido_date",
        each Date.From([data_pedido]),
        type date
    ),

    // Coluna: dias até entrega
    ComPrazoEntrega = Table.AddColumn(
        ComDataPedidoDate,
        "dias_ate_entrega",
        each if [data_entrega] = null or [data_pedido] = null
             then null
             else Duration.Days([data_entrega] - [data_pedido]),
        Int64.Type
    ),

    // Coluna: entregue no prazo?
    ComNoPrazo = Table.AddColumn(
        ComPrazoEntrega,
        "entregue_no_prazo",
        each if [data_entrega] = null or [data_estimada_entrega] = null
             then null
             else [data_entrega] <= [data_estimada_entrega],
        type logical
    ),

    // Coluna: atraso em dias (só para pedidos atrasados)
    ComAtraso = Table.AddColumn(
        ComNoPrazo,
        "dias_atraso",
        each if [data_entrega] = null or [data_estimada_entrega] = null
             then null
             else if [data_entrega] > [data_estimada_entrega]
             then Duration.Days([data_entrega] - [data_estimada_entrega])
             else 0,
        Int64.Type
    ),

    // Remover linhas sem id_pedido
    SemNulos = Table.SelectRows(
        ComAtraso,
        each [id_pedido] <> null and [id_pedido] <> ""
    )

in
    SemNulos


// ────────────────────────────────────────────────────────────
// QUERY 2: fItens — Itens dos pedidos
// ────────────────────────────────────────────────────────────
let
    Fonte = Csv.Document(
        File.Contents("dados/olist_order_items_dataset.csv"),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Cabecalhos = Table.PromoteHeaders(Fonte, [PromoteAllScalars = true]),
    Renomeadas = Table.RenameColumns(
        Cabecalhos,
        {
            {"order_id",            "id_pedido"},
            {"order_item_id",       "num_item"},
            {"product_id",          "id_produto"},
            {"seller_id",           "id_vendedor"},
            {"price",               "valor_item"},
            {"freight_value",       "frete_valor"}
        }
    ),
    Tipagem = Table.TransformColumnTypes(
        Renomeadas,
        {
            {"id_pedido",   type text},
            {"num_item",    Int64.Type},
            {"id_produto",  type text},
            {"id_vendedor", type text},
            {"valor_item",  Currency.Type},
            {"frete_valor", Currency.Type}
        }
    ),

    // Coluna: receita total por item (produto + frete)
    ComReceitaItem = Table.AddColumn(
        Tipagem,
        "receita_item",
        each [valor_item] + [frete_valor],
        Currency.Type
    )

in
    ComReceitaItem


// ────────────────────────────────────────────────────────────
// QUERY 3: dProduto — Dimensão de produtos com categorias PT
// ────────────────────────────────────────────────────────────
let
    // Carregar produtos
    Produtos = Csv.Document(
        File.Contents("dados/olist_products_dataset.csv"),
        [Delimiter = ",", Encoding = 65001]
    ),
    ProdCab = Table.PromoteHeaders(Produtos, [PromoteAllScalars = true]),
    ProdSel = Table.SelectColumns(ProdCab, {"product_id", "product_category_name", "product_weight_g", "product_length_cm"}),
    ProdRen = Table.RenameColumns(
        ProdSel,
        {
            {"product_id",            "id_produto"},
            {"product_category_name", "categoria_raw"},
            {"product_weight_g",      "peso_g"},
            {"product_length_cm",     "comprimento_cm"}
        }
    ),

    // Carregar tabela de tradução categoria PT
    Categorias = Csv.Document(
        File.Contents("dados/product_category_name_translation.csv"),
        [Delimiter = ",", Encoding = 65001]
    ),
    CatCab = Table.PromoteHeaders(Categorias, [PromoteAllScalars = true]),
    CatRen = Table.RenameColumns(
        CatCab,
        {
            {"product_category_name",            "categoria_raw"},
            {"product_category_name_english",    "categoria_en"}
        }
    ),

    // Join: adicionar nome em inglês (e criaremos PT manualmente)
    ComCategoria = Table.NestedJoin(
        ProdRen, {"categoria_raw"},
        CatRen,  {"categoria_raw"},
        "cat_join", JoinKind.LeftOuter
    ),
    Expandido = Table.ExpandTableColumn(
        ComCategoria, "cat_join", {"categoria_en"}
    ),

    // Agrupar categorias em macrocategorias
    ComMacro = Table.AddColumn(
        Expandido,
        "macrocategoria",
        each
            let c = Text.Lower(Text.From([categoria_en]))
            in
                if Text.Contains(c, "electronics") or Text.Contains(c, "computers") or Text.Contains(c, "telephony")
                then "Eletrônicos & Tech"
                else if Text.Contains(c, "furniture") or Text.Contains(c, "bed") or Text.Contains(c, "housewares")
                then "Casa & Decoração"
                else if Text.Contains(c, "fashion") or Text.Contains(c, "clothing") or Text.Contains(c, "shoes")
                then "Moda & Vestuário"
                else if Text.Contains(c, "sport") or Text.Contains(c, "leisure")
                then "Esportes & Lazer"
                else if Text.Contains(c, "beauty") or Text.Contains(c, "health")
                then "Beleza & Saúde"
                else if Text.Contains(c, "book") or Text.Contains(c, "cds") or Text.Contains(c, "dvds")
                then "Livros & Mídia"
                else if Text.Contains(c, "toys") or Text.Contains(c, "baby")
                then "Infantil & Brinquedos"
                else if Text.Contains(c, "food") or Text.Contains(c, "drinks")
                then "Alimentos"
                else "Outros",
        type text
    ),

    // Tipagem final
    TipagemFinal = Table.TransformColumnTypes(
        ComMacro,
        {
            {"id_produto",      type text},
            {"categoria_raw",   type text},
            {"categoria_en",    type text},
            {"macrocategoria",  type text},
            {"peso_g",          type number},
            {"comprimento_cm",  type number}
        }
    )

in
    TipagemFinal
