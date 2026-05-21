// ============================================================
// PROJETO 02 — RH & MERCADO DE TRABALHO
// Arquivo: transformacoes_caged.m
// Descrição: Scripts Power Query (M) para tratamento dos dados
//            do CAGED (Cadastro Geral de Empregados e Desempregados)
// Fonte: https://dados.mte.gov.br/acervo/caged
// Autor: Jonathan Silva de Sá
// ============================================================


// ────────────────────────────────────────────────────────────
// QUERY 1: Carga e limpeza do CAGED mensal
// ────────────────────────────────────────────────────────────
let
    // 1. Carregar arquivo CSV (ajuste o caminho ou use parâmetro)
    Fonte = Csv.Document(
        File.Contents("dados/caged_mensal.csv"),
        [
            Delimiter       = ";",
            Columns         = 30,
            Encoding        = 1252,   // Windows-1252 (padrão MTE)
            QuoteStyle      = QuoteStyle.None
        ]
    ),

    // 2. Promover cabeçalhos
    Cabecalhos = Table.PromoteHeaders(Fonte, [PromoteAllScalars = true]),

    // 3. Selecionar e renomear apenas as colunas necessárias
    ColunasUteis = Table.SelectColumns(
        Cabecalhos,
        {
            "competência",
            "região",
            "uf",
            "município",
            "seção",        // CBO seção (ex: 'A', 'B', 'C'...)
            "subclasse",    // Subclasse CNAE
            "salário fixo",
            "grau de instrução",
            "movimentação"  // 1=admissão, 2=desligamento
        }
    ),
    Renomeadas = Table.RenameColumns(
        ColunasUteis,
        {
            {"competência",      "competencia"},
            {"região",           "regiao"},
            {"uf",               "uf"},
            {"município",        "municipio"},
            {"seção",            "secao_cbo"},
            {"subclasse",        "subclasse_cnae"},
            {"salário fixo",     "salario_fixo"},
            {"grau de instrução","grau_instrucao"},
            {"movimentação",     "tipo_movimentacao"}
        }
    ),

    // 4. Tipagem correta
    Tipagem = Table.TransformColumnTypes(
        Renomeadas,
        {
            {"competencia",       type text},
            {"regiao",            type text},
            {"uf",                type text},
            {"municipio",         type text},
            {"secao_cbo",         type text},
            {"subclasse_cnae",    type text},
            {"salario_fixo",      type number},
            {"grau_instrucao",    type text},
            {"tipo_movimentacao", Int64.Type}
        },
        "pt-BR"
    ),

    // 5. Remover nulos em colunas críticas
    SemNulosCriticos = Table.SelectRows(
        Tipagem,
        each [competencia] <> null and [competencia] <> ""
             and [tipo_movimentacao] <> null
    ),

    // 6. Criar colunas derivadas de data
    ComAno = Table.AddColumn(
        SemNulosCriticos,
        "ano",
        each Number.From(Text.Start([competencia], 4)),
        Int64.Type
    ),
    ComMes = Table.AddColumn(
        ComAno,
        "mes",
        each Number.From(Text.End([competencia], 2)),
        Int64.Type
    ),
    ComData = Table.AddColumn(
        ComMes,
        "data_competencia",
        each #date([ano], [mes], 1),
        type date
    ),

    // 7. Coluna de tipo legível
    ComTipoTexto = Table.AddColumn(
        ComData,
        "tipo_mov_texto",
        each if [tipo_movimentacao] = 1 then "Admissão"
             else if [tipo_movimentacao] = 2 then "Desligamento"
             else "Outro",
        type text
    ),

    // 8. Normalizar grau de instrução
    GrauNormalizado = Table.AddColumn(
        ComTipoTexto,
        "grau_instrucao_grupo",
        each
            let g = [grau_instrucao]
            in
                if Text.Contains(g, "Analfabeto") or Text.Contains(g, "Fundamental Incompleto")
                then "Fundamental Incompleto ou menos"
                else if Text.Contains(g, "Fundamental Completo")
                then "Fundamental Completo"
                else if Text.Contains(g, "Médio")
                then "Ensino Médio"
                else if Text.Contains(g, "Superior Incompleto")
                then "Superior Incompleto"
                else if Text.Contains(g, "Superior Completo")
                then "Superior Completo"
                else if Text.Contains(g, "Mestrado") or Text.Contains(g, "Doutorado")
                then "Pós-Graduação"
                else "Não Informado",
        type text
    ),

    // 9. Coluna de salário faixa
    ComFaixaSalario = Table.AddColumn(
        GrauNormalizado,
        "faixa_salarial",
        each
            let s = [salario_fixo]
            in
                if s = null or s <= 0                  then "Não informado"
                else if s <= 1412                      then "Até 1 SM"
                else if s <= 2824                      then "1-2 SM"
                else if s <= 5648                      then "2-4 SM"
                else if s <= 14120                     then "4-10 SM"
                else                                        "Acima 10 SM",
        type text
    ),

    // 10. Remover coluna original de competência (substituída pelas datas)
    Final = Table.RemoveColumns(
        ComFaixaSalario,
        {"competencia"}
    )

in
    Final


// ────────────────────────────────────────────────────────────
// QUERY 2: Agregação — Saldo por UF e Setor
// (cria tabela resumo para visuais de mapa/matriz)
// ────────────────────────────────────────────────────────────
let
    Fonte = CAGED_Limpo,  // referência à Query 1

    // Agrupar por UF + Setor + Ano/Mês
    Agrupado = Table.Group(
        Fonte,
        {"uf", "secao_cbo", "data_competencia", "ano", "mes"},
        {
            {"admissoes",       each Table.RowCount(Table.SelectRows(_, each [tipo_movimentacao] = 1)), Int64.Type},
            {"desligamentos",   each Table.RowCount(Table.SelectRows(_, each [tipo_movimentacao] = 2)), Int64.Type},
            {"salario_medio",   each List.Average([salario_fixo]),    type number},
            {"total_registros", each Table.RowCount(_),               Int64.Type}
        }
    ),

    // Calcular saldo e rotatividade
    ComSaldo = Table.AddColumn(
        Agrupado,
        "saldo",
        each [admissoes] - [desligamentos],
        Int64.Type
    ),
    ComRotatividade = Table.AddColumn(
        ComSaldo,
        "taxa_rotatividade",
        each if ([admissoes] + [desligamentos]) = 0 then null
             else Number.Round(
                 [desligamentos] / (([admissoes] + [desligamentos]) / 2) * 100,
                 2
             ),
        type number
    )

in
    ComRotatividade


// ────────────────────────────────────────────────────────────
// QUERY 3: Tabela de Referência — Setores CNAE
// ────────────────────────────────────────────────────────────
let
    Setores = #table(
        type table [secao = text, nome_setor = text, macrossetor = text],
        {
            {"A", "Agricultura, Pecuária, Produção Florestal, Pesca e Aquicultura", "Primário"},
            {"B", "Indústrias Extrativas",                                          "Secundário"},
            {"C", "Indústrias de Transformação",                                    "Secundário"},
            {"D", "Eletricidade e Gás",                                             "Secundário"},
            {"E", "Água, Esgoto, Atividades de Gestão de Resíduos",                 "Secundário"},
            {"F", "Construção",                                                     "Secundário"},
            {"G", "Comércio, Reparação de Veículos Automotores",                    "Terciário"},
            {"H", "Transporte, Armazenagem e Correio",                              "Terciário"},
            {"I", "Alojamento e Alimentação",                                       "Terciário"},
            {"J", "Informação e Comunicação",                                       "Terciário"},
            {"K", "Atividades Financeiras, de Seguros",                             "Terciário"},
            {"L", "Atividades Imobiliárias",                                        "Terciário"},
            {"M", "Atividades Profissionais, Científicas e Técnicas",               "Terciário"},
            {"N", "Atividades Administrativas e Serviços Complementares",           "Terciário"},
            {"O", "Administração Pública, Defesa e Seguridade Social",              "Terciário"},
            {"P", "Educação",                                                       "Terciário"},
            {"Q", "Saúde Humana e Serviços Sociais",                                "Terciário"},
            {"R", "Artes, Cultura, Esporte e Recreação",                            "Terciário"},
            {"S", "Outras Atividades de Serviços",                                  "Terciário"},
            {"T", "Serviços Domésticos",                                            "Terciário"}
        }
    )
in
    Setores
