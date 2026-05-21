# 🛒 Projeto 03 — Dashboard E-commerce: Performance de Vendas & RFM

> Dashboard de e-commerce completo usando o dataset público Olist (100k pedidos reais). Análise de receita, logística, satisfação e segmentação de clientes por RFM — com DAX avançado, Power Query M e modelagem dimensional.

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat-square&logo=powerbi&logoColor=black)
![DAX](https://img.shields.io/badge/DAX-0078D4?style=flat-square&logo=microsoft&logoColor=white)
![Power Query](https://img.shields.io/badge/Power%20Query-217346?style=flat-square&logo=microsoft&logoColor=white)

---

## 🎯 Objetivo

Demonstrar um ciclo completo de BI: **ETL com Power Query → Modelagem estrela → DAX avançado → Storytelling visual**. A análise RFM em DAX puro é o grande destaque — técnica amplamente usada em ambientes corporativos para segmentação de clientes/processos.

---

## 📦 Dataset

**[Olist Brazilian E-commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)** — Kaggle

- ~100.000 pedidos (2016–2018)
- 9 arquivos CSV relacionados
- Dados reais anonimizados de um marketplace brasileiro

---

## 📐 Modelo de Dados (Star Schema)

```
                    dCalendario
                         │
      dProduto ──── fItens ──── fPedidos ──── dClientes
      (categoria)    │              │          (UF, cidade)
                     │              │
                 dVendedor       fAvaliacoes
                                (nota, comentário)
```

**Granularidade:** fPedidos = 1 linha por pedido | fItens = 1 linha por item

---

## 📊 Páginas do Dashboard

### Página 1 — Performance de Vendas
| Visual | Descrição |
|--------|-----------|
| KPI Cards | Receita, Pedidos, Ticket Médio, Clientes |
| Linha | Receita mensal + MA3M + YoY |
| Barra | Top 10 categorias por receita |
| Mapa | Receita por estado (mapa de calor) |
| Tooltip | Detalhes da categoria ao hover |

### Página 2 — Logística & Entrega
| Visual | Descrição |
|--------|-----------|
| KPI Cards | Prazo médio, % no prazo, Atraso médio |
| Scatter | Prazo entrega × Nota avaliação (correlação) |
| Barras | % no prazo por estado |
| Linha | Evolução do prazo médio ao longo do tempo |

### Página 3 — Satisfação (NPS)
| Visual | Descrição |
|--------|-----------|
| Gauge | NPS Score aproximado |
| Rosca | Distribuição de notas (1-5 estrelas) |
| Matrix | Nota média por categoria × mês |
| Word Cloud | Termos mais frequentes em avaliações negativas |

### Página 4 — Análise RFM
| Visual | Descrição |
|--------|-----------|
| Scatter | R × F com tamanho = M (bolhas por cliente) |
| Matrix | Distribuição de clientes por segmento |
| Barras | Receita por segmento RFM |
| Tabela | Top clientes por score RFM composto |

---

## 📁 Arquivos do Projeto

```
projeto-03-ecommerce/
├── dax/
│   ├── rfm_analysis.dax         ← Análise RFM completa (R, F, M scores + segmentos)
│   └── medidas_ecommerce.dax    ← Receita, logística, NPS, comparativos temporais
├── powerquery/
│   └── transformacoes_olist.m   ← ETL para 3 tabelas principais do dataset
└── docs/
    ├── dicionario_dados.md
    └── screenshots/
        ├── 01_performance_vendas.png
        ├── 02_logistica.png
        ├── 03_nps_satisfacao.png
        └── 04_rfm_segmentacao.png
```

---

## 💡 Destaque Técnico — Análise RFM em DAX Puro

A análise RFM classifica clientes em 3 dimensões e os segmenta automaticamente:

```dax
// Score de Recência (1-5): menor recência = score maior
[Score R (1-5)] =
VAR Recencia = [R — Dias desde última compra]
VAR P20 = PERCENTILEX.INC(ALL(dClientes[id_cliente]),
              [R — Dias desde última compra], 0.20)
...
RETURN SWITCH(TRUE(), Recencia <= P20, 5, ...)

// Segmentação automática por combinação R+F+M
[Segmento RFM] =
SWITCH(TRUE(),
    R >= 4 && F >= 4 && M >= 4,  "⭐ Campeões",
    R >= 4 && F <= 2,            "🆕 Novos Clientes",
    R <= 2 && F >= 4 && M >= 4,  "🆘 Campeões Perdidos",
    R <= 1,                      "❄️ Perdidos",
    ...
)
```

---

## ▶️ Como Reproduzir

```bash
# 1. Baixe o dataset do Kaggle
# https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
# Extraia os CSVs na pasta dados/

# 2. No Power BI Desktop:
#    Home → Get Data → Text/CSV → selecione cada arquivo
#    Advanced Editor → cole os scripts de powerquery/transformacoes_olist.m

# 3. Monte o modelo seguindo o schema estrela acima

# 4. Importe as medidas via Tabular Editor:
#    File → Open → dax/rfm_analysis.dax
#    File → Open → dax/medidas_ecommerce.dax
```

---

## 🔗 Conexão com Experiência Profissional

| Técnica | Onde apliquei corporativamente |
|---------|-------------------------------|
| RFM Analysis em DAX | Análise de "aging" de processos na Icatu Seguros |
| PERCENTILEX para scores | Ranqueamento de escritórios jurídicos por performance |
| Scatter correlação prazo × nota | KPIs de satisfação + prazo na Icatu |
| Power Query com múltiplos CSVs | ETL multi-fonte (GR5 + Excel + Azure) na Icatu |

---

## 📬 Contato

**Jonathan Silva de Sá** · [LinkedIn](https://linkedin.com/in/jonathan-de-sa) · jonathansilvadesa@gmail.com

> 💬 *RFM é simples de explicar para o negócio e poderoso para criar ação. É exatamente isso que um bom dashboard deve fazer.*
