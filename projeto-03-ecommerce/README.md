# 🛒 Projeto 03 — E-commerce (Olist)

> Dashboard de vendas, logística, satisfação e segmentação RFM com o dataset público do Olist: cerca de 99 mil pedidos de jan/2017 a ago/2018.

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat-square&logo=powerbi&logoColor=black)
![DAX](https://img.shields.io/badge/DAX-0078D4?style=flat-square&logo=microsoft&logoColor=white)
![Power Query](https://img.shields.io/badge/Power%20Query-217346?style=flat-square&logo=microsoft&logoColor=white)

> **Status:** Power Query, modelo e medidas prontos e conferidos contra os dados. Dashboard em montagem: os prints entram em `docs/prints/`.

## Principais achados

| | |
|---|---|
| **R$ 15,7 mi** de receita em 97.910 pedidos | Ticket médio de R$ 160; o frete é 14% da receita |
| **+140%** de jan a ago/2018 contra o mesmo período de 2017 | Pico em nov/2017, mês da Black Friday |
| **97%** dos clientes compraram uma única vez | Taxa de recompra de 3%: o desafio do negócio é retenção |
| **93%** das entregas chegam no prazo | Mas a nota média cai de **4,3** (no prazo) para **2,3** (com atraso) |

## Decisões de modelagem

1. **O cliente é `customer_unique_id`.** No Olist, `customer_id` muda a cada pedido: são 99.441 ids para 96.096 clientes reais. Usar `customer_id` faria todo cliente parecer novo e zeraria a recompra.
2. **Janela de jan/2017 a ago/2018.** Os meses fora dela têm de 1 a 324 pedidos e distorcem qualquer tendência.
3. **Uma definição de receita:** preço + frete dos itens de pedidos válidos (sem cancelados e indisponíveis). Os pagamentos somam mais, porque incluem juros de parcelamento.
4. **Uma avaliação por pedido:** 551 pedidos têm mais de uma; fica a resposta mais recente.
5. **Estado do pedido, não do cadastro:** o dataset de clientes guarda o endereço de entrega de cada pedido, e 39 clientes mudaram de estado.
6. **Tipagem com cultura `en-US`** no Power Query: os CSVs usam ponto decimal, e um Power BI em português leria 58.9 como 589.
7. **RFM como tabela calculada,** com os limites dos quintis calculados uma vez. Como medida, os percentis seriam recalculados sobre 95 mil clientes a cada célula.
8. **Frequência em faixas fixas** (1, 2, 3+ pedidos), porque com 97% dos clientes em 1 compra não existe quintil de frequência.

## 📐 Modelo de dados

```
            dCalendario              dProdutos
               │   │                     │
               ▼   ▼                     ▼
          fPedidos   fItens ◄────────────┘
               ▲   ▲
               │   │
            dClientes ◄──── 1:1 ────► dRFM
```

| Tabela | Grão | Origem |
|--------|------|--------|
| `fPedidos` | Pedido | orders + clientes + avaliações |
| `fItens` | Item de pedido | order_items + dados do pedido |
| `dClientes` | Cliente real (`customer_unique_id`) | customers |
| `dProdutos` | Produto | products |
| `dCalendario` | Dia | DAX |
| `dRFM` | Cliente com compra válida | DAX (tabela calculada) |

## 📁 Arquivos

```
projeto-03-ecommerce/
├── powerquery/transformacoes_olist.m   # 8 consultas (parâmetro, auxiliares, fatos e dimensões)
├── dax/medidas_ecommerce.dax           # calendário + medidas de vendas, clientes, tempo, logística e satisfação
├── dax/rfm_analysis.dax                # tabela calculada dRFM + medidas de apoio
├── conferencia/gerar_numeros.py        # mesmas regras em pandas, para conferir o Power BI
└── docs/
    ├── roteiro_dashboard.md            # passo a passo de montagem e layout das 4 páginas
    ├── numeros_de_conferencia.md       # valor esperado de cada medida e visual
    └── dicionario_dados.md             # colunas de cada tabela
```

## ▶️ Como reproduzir

1. Baixe o [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) e descompacte em uma pasta.
2. Siga o [roteiro de montagem](docs/roteiro_dashboard.md).
3. Confira cada visual com os [números de conferência](docs/numeros_de_conferencia.md), gerados por `conferencia/gerar_numeros.py` com as mesmas regras do modelo.
