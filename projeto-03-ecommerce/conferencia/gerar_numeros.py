"""
Reproduz em pandas as regras do modelo Power BI e gera os números de conferência
(docs/numeros_de_conferencia.md).

Uso:  python gerar_numeros.py C:/dev/olist numeros.json
"""
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

D = str(Path(sys.argv[1])) + "/"
c = pd.read_csv(D+"olist_customers_dataset.csv")
o = pd.read_csv(D+"olist_orders_dataset.csv", parse_dates=["order_purchase_timestamp","order_delivered_customer_date","order_estimated_delivery_date"])
i = pd.read_csv(D+"olist_order_items_dataset.csv")
r = pd.read_csv(D+"olist_order_reviews_dataset.csv", parse_dates=["review_answer_timestamp"])
pr = pd.read_csv(D+"olist_products_dataset.csv")

INI, FIM = pd.Timestamp("2017-01-01"), pd.Timestamp("2018-08-31")
o["data_pedido"] = o.order_purchase_timestamp.dt.normalize()
o = o[(o.data_pedido >= INI) & (o.data_pedido <= FIM)]
o = o.merge(c[["customer_id","customer_unique_id","customer_state"]], on="customer_id")
o["valido"] = ~o.order_status.isin(["canceled","unavailable"])
# avaliação: a resposta mais recente de cada pedido
rv = r.sort_values("review_answer_timestamp").drop_duplicates("order_id", keep="last")[["order_id","review_score"]]
o = o.merge(rv, on="order_id", how="left")
o["entregue_data"] = o.order_delivered_customer_date.dt.normalize()
o["dias_entrega"] = (o.entregue_data - o.data_pedido).dt.days
o["no_prazo"] = o.order_delivered_customer_date.dt.normalize() <= o.order_estimated_delivery_date.dt.normalize()

it = i.merge(o[["order_id","data_pedido","customer_unique_id","valido","customer_state"]], on="order_id")
it = it.merge(pr[["product_id","product_category_name"]], on="product_id", how="left")
it["receita"] = it.price + it.freight_value
iv = it[it.valido]
ov = o[o.valido]

out = {}
out["pedidos_no_periodo"] = len(o)
out["pedidos_validos"] = len(ov)
out["cancelados_ou_indisponiveis"] = int((~o.valido).sum())
out["receita_total"] = round(iv.receita.sum(), 2)
out["receita_produtos"] = round(iv.price.sum(), 2)
out["receita_frete"] = round(iv.freight_value.sum(), 2)
out["pedidos_com_itens_validos"] = iv.order_id.nunique()
out["ticket_medio"] = round(iv.receita.sum() / iv.order_id.nunique(), 2)
out["clientes_unicos_compradores"] = ov.customer_unique_id.nunique()
fr = ov.groupby("customer_unique_id").order_id.nunique()
out["clientes_recorrentes"] = int((fr >= 2).sum())
out["taxa_recompra_pct"] = round(100 * (fr >= 2).mean(), 2)
ent = o[o.order_status.eq("delivered") & o.order_delivered_customer_date.notna()]
out["entregas"] = len(ent)
out["prazo_medio_dias"] = round(ent.dias_entrega.mean(), 2)
out["pct_no_prazo"] = round(100 * ent.no_prazo.mean(), 2)
av = ov[ov.review_score.notna()]
out["nota_media"] = round(av.review_score.mean(), 3)
out["pct_nota_5"] = round(100 * (av.review_score == 5).mean(), 2)
out["pct_nota_1_2"] = round(100 * (av.review_score <= 2).mean(), 2)
# nota por atraso
ent2 = ent[ent.review_score.notna()]
out["nota_media_no_prazo"] = round(ent2[ent2.no_prazo].review_score.mean(), 2)
out["nota_media_atrasado"] = round(ent2[~ent2.no_prazo].review_score.mean(), 2)

mens = iv.groupby(iv.data_pedido.dt.to_period("M")).receita.sum()
out["receita_mensal"] = {str(k): round(v, 2) for k, v in mens.items()}
mm3 = mens.rolling(3).mean()
out["mm3_2018_08"] = round(mm3.iloc[-1], 2)
out["mes_pico"] = str(mens.idxmax())
out["receita_2017_ate_ago"] = round(mens["2017-01":"2017-08"].sum(), 2)
out["receita_2018_ate_ago"] = round(mens["2018-01":"2018-08"].sum(), 2)
out["crescimento_jan_ago_pct"] = round(100 * (out["receita_2018_ate_ago"] / out["receita_2017_ate_ago"] - 1), 1)
cat = iv.fillna({"product_category_name": "sem_categoria"}).groupby("product_category_name").receita.sum().sort_values(ascending=False)
out["top5_categorias"] = {k: round(v, 2) for k, v in cat.head(5).items()}
uf = iv.groupby("customer_state").receita.sum().sort_values(ascending=False)
out["top3_estados_pct"] = {k: round(100 * v / uf.sum(), 1) for k, v in uf.head(3).items()}

# RFM (data de referência = dia seguinte ao fim da janela)
REF = FIM + pd.Timedelta(days=1)
g = iv.groupby("customer_unique_id")
rfm = pd.DataFrame({"recencia": (REF - g.data_pedido.max()).dt.days,
                    "frequencia": g.order_id.nunique(),
                    "valor": g.receita.sum()})
# quintis como o DAX vai fazer: PERCENTILEX.INC e comparação <=
q = rfm.recencia.quantile([.2,.4,.6,.8], interpolation="linear").values
rfm["R"] = np.select([rfm.recencia <= q[0], rfm.recencia <= q[1], rfm.recencia <= q[2], rfm.recencia <= q[3]], [5,4,3,2], 1)
qm = rfm.valor.quantile([.2,.4,.6,.8]).values
rfm["M"] = np.select([rfm.valor <= qm[0], rfm.valor <= qm[1], rfm.valor <= qm[2], rfm.valor <= qm[3]], [1,2,3,4], 5)
rfm["F"] = np.select([rfm.frequencia >= 3, rfm.frequencia == 2], [3,2], 1)
def seg(x):
    if x.F >= 2 and x.R >= 4: return "Campeões"
    if x.F >= 2 and x.R <= 2: return "Recorrentes em risco"
    if x.F >= 2: return "Recorrentes"
    if x.R == 5: return "Novos"
    if x.R >= 3: return "Compradores ocasionais"
    return "Inativos"
rfm["segmento"] = rfm.apply(seg, axis=1)
out["rfm_quintis_recencia"] = [float(x) for x in q]
out["rfm_quintis_valor"] = [round(float(x), 2) for x in qm]
out["rfm_distribuicao_F"] = rfm.F.value_counts().sort_index().to_dict()
s = rfm.groupby("segmento").agg(clientes=("valor","size"), receita=("valor","sum"))
s["pct_clientes"] = (100 * s.clientes / s.clientes.sum()).round(1)
s["pct_receita"] = (100 * s.receita / s.receita.sum()).round(1)
s["receita"] = s.receita.round(2)
out["rfm_segmentos"] = s.sort_values("receita", ascending=False).to_dict("index")
json.dump(out, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=int)
print(f"Números salvos em {sys.argv[2]}")
