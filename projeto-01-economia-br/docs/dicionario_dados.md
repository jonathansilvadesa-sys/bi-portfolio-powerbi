# 📖 Dicionário de Dados — Dashboard Econômico Brasil

## Modelo de Dados

```
fato_indicadores
    ├── sk_tempo       → dim_tempo
    └── sk_indicador   → dim_indicador
```

---

## Tabelas

### `fato_indicadores`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | BIGINT | Chave surrogate |
| sk_tempo | INT (FK) | Referência à dim_tempo |
| sk_indicador | INT (FK) | Referência à dim_indicador |
| valor | NUMERIC | Valor do indicador no período |
| valor_anterior | NUMERIC | Valor do período imediatamente anterior |
| variacao_pp | NUMERIC | Diferença em pontos percentuais |
| dt_carga | TIMESTAMP | Data/hora da carga no DW |

### `dim_indicador`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| codigo | VARCHAR | Código único (ex: 'IPCA', 'SELIC') |
| nome | VARCHAR | Nome legível |
| unidade | VARCHAR | Unidade de medida (%, R$/USD, etc.) |
| fonte | VARCHAR | Organização responsável pelo dado |
| periodicidade | VARCHAR | mensal / trimestral / anual |
| categoria | VARCHAR | inflação / juros / emprego / crescimento |

---

## Indicadores e Fontes

| Indicador | Código API | URL |
|-----------|-----------|-----|
| IPCA Mensal | IBGE SIDRA T1737 / V2266 | https://servicodados.ibge.gov.br/api/v3/agregados/1737 |
| Taxa SELIC | BCB SGS Série 432 | https://api.bcb.gov.br/dados/serie/bcdata.sgs.432/dados |
| Câmbio USD | BCB SGS Série 1 | https://api.bcb.gov.br/dados/serie/bcdata.sgs.1/dados |
| PIB Trimestral | IBGE SIDRA T1621 | https://servicodados.ibge.gov.br/api/v3/agregados/1621 |
| Taxa Desemprego | IBGE SIDRA T6318 | https://servicodados.ibge.gov.br/api/v3/agregados/6318 |
| IGP-M | IPEA — código PRECOS12_IGPM12 | http://ipeadata.gov.br/api/odata4/ValoresSerie(SERCODIGO='PRECOS12_IGPM12') |

---

## Medidas DAX Documentadas

| Medida | Descrição | Fórmula Base |
|--------|-----------|--------------|
| `[IPCA Mensal %]` | Valor do IPCA no período selecionado | SELECTEDVALUE |
| `[IPCA 12 Meses Acumulado]` | Produtório dos últimos 12 meses | PRODUCTX com EDATE |
| `[SELIC Real]` | SELIC deflacionada pelo IPCA | Fisher equation |
| `[IPCA MoM Variação pp]` | Diferença em pontos percentuais vs mês anterior | DATEADD(-1, MONTH) |
| `[IPCA YoY Variação pp]` | Diferença vs mesmo mês do ano anterior | SAMEPERIODLASTYEAR |
| `[IPCA Média Móvel 3M]` | Média simples dos últimos 3 meses | DATESINPERIOD + AVERAGEX |
| `[Status IPCA]` | Semáforo textual (Verde/Amarelo/Laranja/Vermelho) | SWITCH(TRUE()) |

---

## Layout do Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│  PAINEL ECONÔMICO BRASIL          Atualizado em: dd/mm/yyyy │
├─────────────────────────────────────────────────────────────┤
│ [Filtro: Ano] [Filtro: Indicador] [Filtro: Categoria]       │
├──────────┬──────────┬──────────┬──────────┬─────────────────┤
│  IPCA    │  SELIC   │ DESEMP.  │  CÂMBIO  │ Status Geral    │
│  0,44%   │  10,5%   │  7,9%    │  R$5,08  │  🟡 Atenção     │
│  +0,1pp  │  =       │  -0,3pp  │  +0,02   │                 │
├──────────┴──────────┴──────────┴──────────┴─────────────────┤
│                                                             │
│   Linha: IPCA Mensal + Média Móvel 3M (últimos 24 meses)   │
│                                                             │
├─────────────────────────┬───────────────────────────────────┤
│  Barras: SELIC vs IPCA  │  Área: Desemprego por Trimestre   │
│  (últimos 12 meses)     │  (série histórica)                │
└─────────────────────────┴───────────────────────────────────┘
```

---

## Boas Práticas Aplicadas

- ✅ Tabela de calendário isolada e marcada como "tabela de datas"
- ✅ Medidas organizadas em pastas por categoria (Inflação, Juros, Emprego)
- ✅ Nenhuma coluna calculada desnecessária na tabela fato
- ✅ SELECTEDVALUE com fallback para evitar erros em múltipla seleção
- ✅ Variáveis (VAR) para legibilidade e performance
- ✅ Formatação de texto dinâmico via medidas (não em títulos fixos)
