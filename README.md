# 📈 Portfólio BI — Power BI, DAX & Storytelling com Dados

> Coleção de projetos de Business Intelligence desenvolvidos com Power BI, DAX avançado e Power Query. Cada projeto usa dados públicos para demonstrar as mesmas técnicas aplicadas em contextos corporativos reais.

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat-square&logo=powerbi&logoColor=black)
![DAX](https://img.shields.io/badge/DAX-0078D4?style=flat-square&logo=microsoft&logoColor=white)
![Power Query](https://img.shields.io/badge/Power%20Query-217346?style=flat-square&logo=microsoft&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=flat-square&logo=microsoftsqlserver&logoColor=white)

---

## 🗂️ Projetos

### 📊 Projeto 1 — Dashboard de Desempenho Econômico BR
**Arquivo:** `projeto-01-economia-br/`

Painel analítico de indicadores macroeconômicos brasileiros para acompanhamento executivo.

**Dados:** IBGE (IPCA, PIB, desemprego) · Banco Central (SELIC, câmbio)
**Técnicas:** Modelo estrela, DAX com inteligência de tempo, drill-through, bookmarks

**KPIs e medidas DAX:**
- Variação YoY e MoM do IPCA
- SELIC real deflacionada
- Correlação desemprego × PIB por trimestre

---

### 👥 Projeto 2 — Análise de RH e Mercado de Trabalho
**Arquivo:** `projeto-02-rh-mercado-trabalho/`

Painel de People Analytics usando dados públicos do CAGED (Ministério do Trabalho).

**Dados:** CAGED 2022-2024 · RAIS (Relação Anual de Informações Sociais)
**Técnicas:** ETL com Power Query, segmentações dinâmicas, medidas DAX complexas

**Análises:**
- Saldo de empregos por setor, estado e grau de instrução
- Taxa de rotatividade setorial
- Sazonalidade de admissões ao longo do ano
- Top cidades geradoras de emprego

---

### 🛒 Projeto 3 — Dashboard de Vendas E-commerce
**Arquivo:** `projeto-03-ecommerce/`

Análise completa de desempenho de vendas usando dataset público do Olist (e-commerce brasileiro).

**Dados:** [Olist Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — Kaggle
**Técnicas:** Modelagem dimensional, RFM Analysis em DAX, mapa de calor geográfico

**Análises:**
- Revenue, ticket médio e crescimento MoM
- Análise RFM de clientes (Recência, Frequência, Monetário)
- Performance por categoria e estado
- Tempo médio de entrega vs satisfação

---

## 🛠️ Stack e Ferramentas

| Ferramenta | Uso |
|------------|-----|
| **Power BI Desktop** | Desenvolvimento dos dashboards |
| **Power Query (M)** | Transformação e limpeza dos dados |
| **DAX** | Medidas calculadas, KPIs e inteligência de tempo |
| **SQL Server / PostgreSQL** | Fonte de dados relacional |
| **ALM Toolkit** | Deploy e controle de versão de modelos tabular |
| **Tabular Editor** | Desenvolvimento e otimização de medidas DAX |
| **DAX Studio** | Performance tuning e debugging |

---

## 💡 Padrões e Boas Práticas Aplicadas

### Modelagem de Dados
- ✅ Esquema estrela (Star Schema) em todos os projetos
- ✅ Tabela de calendário isolada com marcação de data
- ✅ Relacionamentos 1:N — nunca Many-to-Many sem tabela ponte
- ✅ Colunas calculadas na fonte, medidas no modelo

### DAX Avançado

```dax
-- Receita do Período com Comparativo Ano Anterior
Receita YoY % = 
VAR ReceitaAtual = [Receita Total]
VAR ReceitaAnterior = CALCULATE([Receita Total], SAMEPERIODLASTYEAR(dCalendario[Data]))
RETURN
    IF(
        NOT ISBLANK(ReceitaAnterior),
        DIVIDE(ReceitaAtual - ReceitaAnterior, ReceitaAnterior),
        BLANK()
    )

-- Moving Average 3 meses
Receita MA3M = 
AVERAGEX(
    DATESINPERIOD(dCalendario[Data], LASTDATE(dCalendario[Data]), -3, MONTH),
    [Receita Total]
)

-- % do Total com ALLSELECTED (respeita filtros do usuário)
Market Share = 
DIVIDE(
    [Receita Total],
    CALCULATE([Receita Total], ALLSELECTED(dProduto[Categoria]))
)
```

### Power Query (M)

```m
// Transformação de tipo robusto com tratamento de erro
TipoSeguro = Table.TransformColumnTypes(
    Fonte,
    {
        {"data_venda", type date},
        {"valor", Currency.Type},
        {"quantidade", Int64.Type}
    },
    "pt-BR"
),

// Coluna condicional com tratamento de nulos
CategoriaSegmento = Table.AddColumn(
    TipoSeguro,
    "segmento",
    each if [valor] >= 10000 then "Premium"
         else if [valor] >= 1000 then "Standard"
         else "Basic",
    type text
)
```

---

## 📁 Estrutura dos Arquivos

```
bi-portfolio-powerbi/
│
├── projeto-01-economia-br/
│   ├── modelo/
│   │   └── economia_br.bim          # Definição do modelo (Tabular Editor)
│   ├── queries/
│   │   └── economia_setup.sql       # SQL para preparar os dados
│   ├── docs/
│   │   ├── screenshots/             # Prints dos dashboards
│   │   └── dicionario_dados.md      # Documentação das métricas
│   └── README.md
│
├── projeto-02-rh-mercado-trabalho/
│   ├── powerquery/
│   │   └── transformacoes.m         # Scripts Power Query documentados
│   ├── dax/
│   │   └── medidas.dax             # Medidas DAX com comentários
│   ├── docs/
│   │   └── screenshots/
│   └── README.md
│
├── projeto-03-ecommerce/
│   ├── dax/
│   │   └── rfm_analysis.dax        # Análise RFM completa em DAX
│   ├── docs/
│   │   └── screenshots/
│   └── README.md
│
└── README.md  ← você está aqui
```

> **Nota sobre os arquivos .pbix:** Os dashboards Power BI completos podem ser solicitados por e-mail (jonathansilvadesa@gmail.com), pois os arquivos .pbix são grandes para versionamento no Git. Os scripts DAX, Power Query (M) e definições de modelo (.bim) estão todos versionados aqui.

---

## 🔗 Conexão com Experiência Profissional

| Técnica neste portfólio | Onde apliquei profissionalmente |
|-------------------------|-------------------------------|
| Esquema estrela + SSAS  | Ipiranga — migração MicroStrategy → Analysis Services |
| DAX + KPIs jurídicos    | Icatu Seguros — indicadores de êxito, aging, assertividade |
| ETL multi-fonte         | Icatu — GR5 + Excel + Azure → Power BI |
| ALM Toolkit + deploy    | Grupo Dupla — versionamento de modelos BI |

---

## 📬 Contato

**Jonathan Silva de Sá** · [LinkedIn](https://linkedin.com/in/jonathan-de-sa) · jonathansilvadesa@gmail.com

> 💬 *"Um bom dashboard não mostra dados — conta uma história que leva a uma decisão."*
