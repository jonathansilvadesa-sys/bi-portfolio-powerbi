# Números de conferência

Valores calculados em Python (pandas) com as mesmas regras do modelo, a partir dos CSVs originais do Olist. Depois de montar cada visual, compare: se o número não bater, alguma etapa do Power Query ou alguma medida está diferente do esperado.

Janela: 01/01/2017 a 31/08/2018 · pedidos válidos = sem `canceled` e `unavailable` · receita = preço + frete.

## Cartões (sem filtro)

| Medida | Valor esperado |
|--------|----------------|
| Linhas em `fPedidos` | 99.092 |
| Receita | R$ 15.683.706,74 |
| Receita Produtos | R$ 13.449.529,68 |
| Receita Frete | R$ 2.234.177,06 (14,25% da receita) |
| Pedidos | 97.910 |
| Pedidos com Itens | 97.905 |
| Ticket Medio | R$ 160,19 |
| Pedidos Cancelados | 1.182 (1,19%) |
| Clientes | 94.707 |
| Clientes Recorrentes | 2.875 |
| Taxa de Recompra | 3,04% |
| Pedidos por Cliente | 1,03 |
| Entregas | 96.203 |
| Prazo Medio de Entrega (dias) | 12,48 |
| % Entregue no Prazo | 93,21% |
| Nota Media | 4,12 |
| % Nota 5 | 58,40% |
| % Notas 1 e 2 | 13,85% |
| Nota Media no Prazo | 4,29 |
| Nota Media com Atraso | 2,27 |

## Receita por mês

| Mês | Receita | | Mês | Receita |
|-----|--------:|-|-----|--------:|
| jan/17 | 136.943,46 | | jan/18 | 1.101.920,01 |
| fev/17 | 283.561,69 | | fev/18 | 979.486,16 |
| mar/17 | 425.617,96 | | mar/18 | 1.152.656,99 |
| abr/17 | 405.848,61 | | abr/18 | 1.156.248,89 |
| mai/17 | 582.710,83 | | mai/18 | 1.145.686,46 |
| jun/17 | 499.652,24 | | jun/18 | 1.020.381,90 |
| jul/17 | 578.753,73 | | jul/18 | 1.039.783,58 |
| ago/17 | 661.903,52 | | ago/18 | 996.973,51 |
| set/17 | 717.102,72 | | | |
| out/17 | 764.756,03 | | | |
| nov/17 | **1.172.191,68** (pico) | | | |
| dez/17 | 861.526,77 | | | |

- Receita Acumulada no Ano, dez/17: R$ 7.090.569,24
- Receita Media Movel 3M: mar/17 = 282.041,04 · nov/17 = 884.683,48 · ago/18 = 1.019.046,33 (jan e fev/17 ficam em branco)
- Crescimento vs Ano Anterior: ago/18 = +50,6% · jan a ago/18 contra jan a ago/17 = +140,4%

## Categorias e estados

| Top 5 categorias | Receita |
|------------------|--------:|
| Beleza Saude | 1.432.213,38 |
| Relogios Presentes | 1.294.824,43 |
| Cama Mesa Banho | 1.239.779,55 |
| Esporte Lazer | 1.144.753,87 |
| Informatica Acessorios | 1.049.201,49 |

Estados (UF do pedido): SP 37,4% · RJ 13,4% · MG 11,7% da receita.

## RFM (`dRFM`)

- Linhas: 94.703 clientes (4 clientes com pedido válido não têm itens e ficam fora)
- Data de referência: 01/09/2018
- Limites de recência (dias): 95 · 180 · 271 · 384
- Limites de valor (R$): 55,31 · 87,48 · 132,99 · 208,97
- Frequência: 91.829 clientes com 1 pedido · 2.639 com 2 · 235 com 3 ou mais

| Segmento | Clientes | % clientes | Receita | % receita |
|----------|---------:|-----------:|--------:|----------:|
| Campeões | 1.238 | 1,3% | 397.912,40 | 2,5% |
| Recorrentes | 617 | 0,7% | 189.068,19 | 1,2% |
| Recorrentes em risco | 1.019 | 1,1% | 299.247,43 | 1,9% |
| Novos | 18.352 | 19,4% | 3.004.946,84 | 19,2% |
| Compradores ocasionais | 36.883 | 38,9% | 5.858.584,69 | 37,4% |
| Inativos | 36.594 | 38,6% | 5.933.947,19 | 37,8% |
