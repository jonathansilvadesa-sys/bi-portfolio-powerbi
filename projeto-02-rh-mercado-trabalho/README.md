# 👥 Projeto 02 — People Analytics: Mercado de Trabalho Brasileiro

> Dashboard de análise de empregabilidade usando dados reais do CAGED (Ministério do Trabalho). Saldo de empregos, rotatividade setorial, análise salarial e sazonalidade — com Power Query M e DAX avançado.

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat-square&logo=powerbi&logoColor=black)
![Power Query](https://img.shields.io/badge/Power%20Query-217346?style=flat-square&logo=microsoft&logoColor=white)
![DAX](https://img.shields.io/badge/DAX-0078D4?style=flat-square&logo=microsoft&logoColor=white)

---

## 🎯 Objetivo

Analisar o mercado formal de trabalho brasileiro através de dados públicos do CAGED, demonstrando skills de ETL com Power Query e análise com DAX — exatamente o tipo de People Analytics que estruturo em ambiente corporativo.

---

## 📐 Modelo de Dados

```
dCalendario (tabela de datas)
      │
      │ 1:N
fCaged ──── dLocalidade (UF, Região)
      │
      └──── dSetor (Seção CNAE, Macrossetor)
            │
            └──── dGrauInstrucao
```

**Granularidade:** 1 linha por movimentação (admissão ou desligamento)

---

## 📊 Análises do Dashboard

### Página 1 — Visão Geral
- KPI: Saldo total, Admissões, Desligamentos, Taxa de Rotatividade
- Linha: Saldo mensal + MA3M (sazonalidade)
- Mapa coroplético: Saldo por UF (heatmap)
- Barra: Top 10 setores por geração de empregos

### Página 2 — Análise Salarial
- Distribuição de salários por faixa (histograma)
- Salário médio × Grau de instrução
- Premium salarial: Superior vs Fundamental
- Dispersão: Admissões × Salário médio por setor

### Página 3 — Sazonalidade
- Heatmap mês × ano (admissões)
- Índice sazonal por mês (qual mês contrata mais historicamente)
- Comparativo YoY por setor

---

## 📁 Arquivos do Projeto

```
projeto-02-rh-mercado-trabalho/
├── powerquery/
│   └── transformacoes_caged.m    ← ETL completo (3 queries documentadas)
├── dax/
│   └── medidas_rh.dax            ← 20+ medidas (saldo, rotatividade, ranking)
└── docs/
    ├── dicionario_dados.md
    └── screenshots/
        ├── 01_visao_geral.png
        ├── 02_analise_salarial.png
        └── 03_sazonalidade.png
```

---

## 💡 Destaques Técnicos

### Power Query — Tratamento de dados reais do CAGED
```m
// Normalizar grau de instrução (dado vem sujo no CAGED)
GrauNormalizado = Table.AddColumn(
    Fonte, "grau_instrucao_grupo",
    each
        if Text.Contains([grau_instrucao], "Superior Completo")
        then "Superior Completo"
        else if Text.Contains([grau_instrucao], "Médio")
        then "Ensino Médio"
        else "Outros",
    type text
)
```

### DAX — Taxa de Rotatividade
```dax
[Taxa Rotatividade %] =
VAR Deslig  = [Total Desligamentos]
VAR Estoque = DIVIDE([Total Admissões] + [Total Desligamentos], 2)
RETURN ROUND(DIVIDE(Deslig, Estoque) * 100, 2)
```

### DAX — Índice Sazonal
```dax
[Índice Sazonal Admissões] =
VAR MesAtual = SELECTEDVALUE(dCalendario[Mês Num])
VAR MediaHistorica =
    CALCULATE(
        AVERAGEX(VALUES(dCalendario[Ano]), [Total Admissões]),
        FILTER(ALL(dCalendario), dCalendario[Mês Num] = MesAtual)
    )
RETURN DIVIDE([Total Admissões], MediaHistorica)
```

---

## ▶️ Como Reproduzir

```bash
# 1. Baixar o CAGED (dados abertos)
# Acesse: https://dados.mte.gov.br/acervo/caged
# Baixe os arquivos CSV por competência (ex: CAGEDMOV202401.7z)

# 2. No Power BI Desktop:
#    Home → Get Data → Text/CSV
#    Aplique as transformações de powerquery/transformacoes_caged.m

# 3. Conectar tabelas de referência (dCalendario, dSetor)
# 4. Importar medidas de dax/medidas_rh.dax via Tabular Editor
```

---

## 🔗 Conexão com Experiência Profissional

| Técnica | Onde apliquei |
|---------|--------------|
| Power Query com CSVs sujos | Icatu Seguros — ETL de dados do GR5 exportados em CSV |
| Taxa de rotatividade DAX | Icatu — indicador de flutuação de processos jurídicos |
| Ranking dinâmico RANKX | Ipiranga — ranking de distribuidores por performance |
| Sazonalidade com MA3M | Grupo Dupla — análise de variação mensal de KPIs |

---

## 📬 Contato

**Jonathan Silva de Sá** · [LinkedIn](https://linkedin.com/in/jonathan-de-sa) · jonathansilvadesa@gmail.com
