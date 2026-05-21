# 📖 Dicionário de Dados — E-commerce Olist

## Modelo de Dados (Star Schema)

```
dCalendario (1) ──── (N) fPedidos (N) ──── (1) dClientes
                             │
                    (N) fItens (N) ──── (1) dProduto
                             │
                    (N) dVendedor
                             
fPedidos (1) ──── (N) fAvaliacoes
```

---

## Tabelas Fato

### `fPedidos`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id_pedido | TEXT (PK) | Identificador único do pedido |
| id_cliente | TEXT (FK) | Referência ao cliente |
| status_pedido | TEXT | delivered / shipped / canceled / etc |
| data_pedido | DATETIME | Timestamp do pedido |
| data_entrega | DATETIME | Quando o cliente recebeu |
| data_estimada_entrega | DATETIME | Prazo prometido |
| dias_ate_entrega | INT | Duração em dias (calculado) |
| entregue_no_prazo | BOOL | data_entrega ≤ data_estimada |
| dias_atraso | INT | Dias de atraso (0 se no prazo) |

### `fItens`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id_pedido | TEXT (FK) | Referência ao pedido |
| num_item | INT | Sequência do item no pedido |
| id_produto | TEXT (FK) | Referência ao produto |
| id_vendedor | TEXT (FK) | Referência ao vendedor |
| valor_item | CURRENCY | Preço do produto |
| frete_valor | CURRENCY | Custo do frete |
| receita_item | CURRENCY | valor_item + frete_valor (calculado) |

### `fAvaliacoes`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id_avaliacao | TEXT (PK) | Identificador da avaliação |
| id_pedido | TEXT (FK) | Referência ao pedido |
| nota | INT | 1 a 5 estrelas |
| titulo | TEXT | Título do comentário |
| comentario | TEXT | Texto completo |
| data_criacao | DATETIME | Quando foi criada |

---

## Tabelas Dimensão

### `dClientes`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id_cliente | TEXT (PK) | ID único do cliente |
| cidade | TEXT | Cidade do cliente |
| uf | CHAR(2) | Estado |
| regiao | TEXT | Norte / Nordeste / etc |

### `dProduto`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id_produto | TEXT (PK) | ID único do produto |
| categoria_raw | TEXT | Categoria original (português) |
| categoria_en | TEXT | Tradução para inglês |
| macrocategoria | TEXT | Agrupamento por área (calculado) |
| peso_g | NUMBER | Peso em gramas |
| comprimento_cm | NUMBER | Comprimento em cm |

---

## Segmentos RFM

| Segmento | Critério | Ação Recomendada |
|----------|----------|------------------|
| ⭐ Campeões | R≥4, F≥4, M≥4 | Programas de fidelidade premium |
| 💛 Fiéis | R≥4, F≥3 ou M≥3 | Upsell e cross-sell |
| 🆕 Novos | R≥4, F≤2 | Onboarding e segunda compra |
| 😴 Em Risco | R≤2, F≥3, M≥3 | Campanhas de reativação |
| 🆘 Campeões Perdidos | R≤2, F≥4, M≥4 | Oferta especial de retorno |
| ❄️ Perdidos | R≤1 | Baixo investimento — limpar lista |

---

## Medidas DAX Documentadas

### rfm_analysis.dax
| Medida | Complexidade | Funções DAX |
|--------|-------------|-------------|
| `[R — Dias desde última compra]` | Média | CALCULATE, MAX |
| `[Score R (1-5)]` | Alta | PERCENTILEX.INC, SWITCH |
| `[Score RFM Composto]` | Média | VAR, média ponderada |
| `[Segmento RFM]` | Alta | SWITCH(TRUE()) com múltiplas condições |

### medidas_ecommerce.dax
| Medida | Complexidade | Funções DAX |
|--------|-------------|-------------|
| `[Receita MoM %]` | Média | DATEADD |
| `[Receita YoY %]` | Média | SAMEPERIODLASTYEAR |
| `[% Entregas no Prazo]` | Média | CALCULATE com duplo filtro |
| `[NPS Score Aproximado]` | Baixa | Promotores % - Detratores % |
| `[% Market Share Categoria]` | Média | ALLSELECTED |
| `[Ranking Categoria]` | Média | RANKX |
