# 📊 Projeto 01 — Dashboard Econômico Brasil

> Painel executivo de indicadores macroeconômicos brasileiros com análise histórica, tendências e semáforo de situação — construído com Power BI, DAX avançado e dados da API do Banco Central e IBGE.

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat-square&logo=powerbi&logoColor=black)
![DAX](https://img.shields.io/badge/DAX-0078D4?style=flat-square&logo=microsoft&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=flat-square&logo=postgresql&logoColor=white)

---

## 🎯 Objetivo

Construir um painel executivo que permita ao usuário acompanhar os principais indicadores econômicos do Brasil em um único lugar, com contexto histórico, comparativos e alertas visuais — exatamente o tipo de dashboard estratégico que desenvolvo profissionalmente.

---

## 📐 Modelo de Dados (Star Schema)

```
          dim_indicador
               │
               │ N
fato_indicadores ──────── dim_tempo
  (1 linha por           (calendário
  indicador/período)      completo)
```

**Granularidade:** 1 registro por indicador por período (mensal ou trimestral)

---

## 📊 Indicadores Monitorados

| Indicador | Fonte | Periodicidade |
|-----------|-------|---------------|
| IPCA | IBGE SIDRA | Mensal |
| Taxa SELIC | Banco Central (SGS) | Mensal |
| SELIC Real (deflacionada) | Calculado | Mensal |
| Taxa de Desemprego | IBGE PNADC | Trimestral |
| PIB — Variação Trimestral | IBGE | Trimestral |
| Câmbio BRL/USD | Banco Central (SGS) | Mensal |
| IGP-M | IPEA | Mensal |

---

## 📁 Arquivos do Projeto

```
projeto-01-economia-br/
├── dax/
│   └── medidas_economia.dax      ← Todas as medidas documentadas
├── queries/
│   └── economia_setup.sql        ← DDL + views + queries analíticas
└── docs/
    ├── dicionario_dados.md       ← Documentação completa do modelo
    └── screenshots/              ← Prints do dashboard
        ├── 01_visao_geral.png
        ├── 02_inflacao_historica.png
        └── 03_comparativo_selic_ipca.png
```

---

## 💡 Destaques Técnicos em DAX

### Produtório para IPCA Acumulado 12 meses
```dax
[IPCA 12 Meses Acumulado] =
VAR UltimoMes = MAX(dCalendario[Data])
VAR InicioJanela = EDATE(UltimoMes, -11)
RETURN
CALCULATE(
    PRODUCTX(
        FILTER(fIndicadores,
               fIndicadores[indicador] = "IPCA" &&
               fIndicadores[data] >= InicioJanela &&
               fIndicadores[data] <= UltimoMes),
        1 + fIndicadores[valor] / 100
    ) - 1,
    ALL(dCalendario)
) * 100
```

### SELIC Real (equação de Fisher)
```dax
[SELIC Real (deflacionada)] =
VAR SelicNominal = [SELIC % a.a.]
VAR InflacaoAnual = [IPCA 12 Meses Acumulado]
RETURN
ROUND(((1 + SelicNominal/100) / (1 + InflacaoAnual/100) - 1) * 100, 2)
```

### Semáforo dinâmico
```dax
[Status IPCA] =
SWITCH(TRUE(),
    [IPCA Mensal %] <= 0.3, "🟢 Controlado",
    [IPCA Mensal %] <= 0.6, "🟡 Atenção",
    [IPCA Mensal %] <= 1.0, "🟠 Elevado",
                            "🔴 Crítico"
)
```

---

## ▶️ Como Reproduzir

```bash
# 1. Configure o banco PostgreSQL (ver queries/economia_setup.sql)
psql -U postgres -d sua_base -f queries/economia_setup.sql

# 2. Execute o ETL Python para popular os dados
cd ../../etl-pipeline-dados-abertos
python src/pipeline.py --source bcb ibge --indicadores ipca selic desemprego pib cambio

# 3. Conecte o Power BI Desktop ao PostgreSQL
#    Home → Get Data → PostgreSQL
#    Server: localhost | Database: sua_base | Schema: economia
#    Tabelas: fato_indicadores, dim_tempo, dim_indicador

# 4. Importe as medidas DAX
#    No Tabular Editor: File → Open → dax/medidas_economia.dax
```

---

## 🔗 Conexão com Experiência Profissional

Este dashboard replica o tipo de trabalho que realizei:
- **Icatu Seguros**: semáforos de KPIs jurídicos (êxito, aging, assertividade)
- **Ipiranga**: dashboards executivos com múltiplos indicadores em esquema estrela
- Uso de **SAMEPERIODLASTYEAR**, **DATEADD** e **PRODUCTX** em produção

---

## 📬 Contato

**Jonathan Silva de Sá** · [LinkedIn](https://linkedin.com/in/jonathan-de-sa) · jonathansilvadesa@gmail.com
