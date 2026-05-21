-- ============================================================
-- PROJETO 01 — DASHBOARD ECONÔMICO BRASIL
-- Arquivo: economia_setup.sql
-- Descrição: DDL e carga inicial para o modelo econômico
-- Banco: PostgreSQL 15+
-- Autor: Jonathan Silva de Sá
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- SCHEMA
-- ────────────────────────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS economia;
SET search_path TO economia;


-- ────────────────────────────────────────────────────────────
-- DIMENSÃO TEMPO
-- ────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS dim_tempo CASCADE;
CREATE TABLE dim_tempo (
    sk_tempo        SERIAL PRIMARY KEY,
    data            DATE        NOT NULL UNIQUE,
    ano             SMALLINT    NOT NULL,
    mes             SMALLINT    NOT NULL,  -- 1-12
    nome_mes        VARCHAR(20) NOT NULL,
    trimestre       SMALLINT    NOT NULL,  -- 1-4
    semestre        SMALLINT    NOT NULL,  -- 1-2
    ano_mes         CHAR(7)     NOT NULL,  -- 'YYYY-MM'
    ano_trimestre   VARCHAR(10) NOT NULL,  -- '2024 T1'
    is_fim_semana   BOOLEAN     NOT NULL DEFAULT FALSE
);

-- Popular com série de datas (2019-2026)
INSERT INTO dim_tempo (data, ano, mes, nome_mes, trimestre, semestre, ano_mes, ano_trimestre, is_fim_semana)
SELECT
    d::DATE                                                 AS data,
    EXTRACT(YEAR  FROM d)::SMALLINT                        AS ano,
    EXTRACT(MONTH FROM d)::SMALLINT                        AS mes,
    TO_CHAR(d, 'TMMonth')                                  AS nome_mes,
    EXTRACT(QUARTER FROM d)::SMALLINT                      AS trimestre,
    CASE WHEN EXTRACT(MONTH FROM d) <= 6 THEN 1 ELSE 2 END AS semestre,
    TO_CHAR(d, 'YYYY-MM')                                  AS ano_mes,
    EXTRACT(YEAR FROM d)::TEXT || ' T' ||
        EXTRACT(QUARTER FROM d)::TEXT                      AS ano_trimestre,
    EXTRACT(DOW FROM d) IN (0, 6)                          AS is_fim_semana
FROM generate_series('2019-01-01'::DATE, '2026-12-31'::DATE, '1 day') AS d;

CREATE INDEX idx_dim_tempo_data  ON dim_tempo(data);
CREATE INDEX idx_dim_tempo_anomes ON dim_tempo(ano_mes);


-- ────────────────────────────────────────────────────────────
-- DIMENSÃO INDICADOR
-- ────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS dim_indicador CASCADE;
CREATE TABLE dim_indicador (
    sk_indicador    SERIAL PRIMARY KEY,
    codigo          VARCHAR(50)  NOT NULL UNIQUE,
    nome            VARCHAR(100) NOT NULL,
    descricao       TEXT,
    unidade         VARCHAR(50)  NOT NULL,
    fonte           VARCHAR(100) NOT NULL,
    periodicidade   VARCHAR(20)  NOT NULL,  -- 'mensal', 'trimestral', 'anual'
    categoria       VARCHAR(50)  NOT NULL   -- 'inflação', 'juros', 'emprego', 'crescimento'
);

INSERT INTO dim_indicador (codigo, nome, descricao, unidade, fonte, periodicidade, categoria) VALUES
('IPCA',          'IPCA',                          'Índice Nacional de Preços ao Consumidor Amplo — variação mensal', '% a.m.',    'IBGE',         'mensal',      'inflação'),
('IPCA_ACUM_12M', 'IPCA Acumulado 12 meses',       'IPCA acumulado nos últimos 12 meses',                            '% a.a.',    'IBGE',         'mensal',      'inflação'),
('SELIC',         'Taxa SELIC',                    'Taxa básica de juros da economia brasileira (meta)',              '% a.a.',    'Banco Central','mensal',      'juros'),
('CDI',           'Taxa CDI',                      'Certificado de Depósito Interbancário — taxa diária',             '% a.d.',    'B3/CETIP',     'mensal',      'juros'),
('DESEMPREGO',    'Taxa de Desemprego',             'Taxa de desocupação PNADC (trimestral, 14+ anos)',               '%',         'IBGE PNADC',   'trimestral',  'emprego'),
('PIB_VARIACAO',  'PIB — Variação Trimestral',      'Variação do PIB em relação ao trimestre anterior (ajustado)',   '% t/t-1',   'IBGE',         'trimestral',  'crescimento'),
('PIB_ACUM_12M',  'PIB — Variação Anual',           'Variação acumulada do PIB nos últimos 12 meses',                '% a/a',     'IBGE',         'trimestral',  'crescimento'),
('CAMBIO_USD',    'Câmbio BRL/USD',                'Taxa de câmbio dólar americano (média do período)',              'R$/USD',    'Banco Central','mensal',      'câmbio'),
('IGPM',          'IGP-M',                         'Índice Geral de Preços do Mercado — variação mensal',            '% a.m.',    'FGV',          'mensal',      'inflação');


-- ────────────────────────────────────────────────────────────
-- FATO INDICADORES
-- ────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS fato_indicadores CASCADE;
CREATE TABLE fato_indicadores (
    id              BIGSERIAL PRIMARY KEY,
    sk_tempo        INT         NOT NULL REFERENCES dim_tempo(sk_tempo),
    sk_indicador    INT         NOT NULL REFERENCES dim_indicador(sk_indicador),
    valor           NUMERIC(12, 4),
    valor_anterior  NUMERIC(12, 4),  -- período anterior (para variação)
    variacao_pp     NUMERIC(12, 4),  -- variação em pontos percentuais
    dt_carga        TIMESTAMP   NOT NULL DEFAULT NOW(),
    UNIQUE(sk_tempo, sk_indicador)
);

CREATE INDEX idx_fato_tempo      ON fato_indicadores(sk_tempo);
CREATE INDEX idx_fato_indicador  ON fato_indicadores(sk_indicador);
CREATE INDEX idx_fato_sk_combo   ON fato_indicadores(sk_tempo, sk_indicador);


-- ────────────────────────────────────────────────────────────
-- VIEW ANALÍTICA (facilita consumo no Power BI)
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_indicadores_economicos AS
SELECT
    t.data,
    t.ano,
    t.mes,
    t.nome_mes,
    t.trimestre,
    t.ano_mes,
    t.ano_trimestre,
    i.codigo            AS indicador,
    i.nome              AS nome_indicador,
    i.categoria,
    i.unidade,
    i.fonte,
    f.valor,
    f.valor_anterior,
    f.variacao_pp,
    -- Classificação semáforo
    CASE i.codigo
        WHEN 'IPCA' THEN
            CASE
                WHEN f.valor <= 0.30 THEN 'Verde'
                WHEN f.valor <= 0.60 THEN 'Amarelo'
                WHEN f.valor <= 1.00 THEN 'Laranja'
                ELSE 'Vermelho'
            END
        WHEN 'DESEMPREGO' THEN
            CASE
                WHEN f.valor <= 7   THEN 'Verde'
                WHEN f.valor <= 10  THEN 'Amarelo'
                WHEN f.valor <= 13  THEN 'Laranja'
                ELSE 'Vermelho'
            END
        ELSE NULL
    END                 AS semaforo
FROM fato_indicadores f
JOIN dim_tempo     t ON t.sk_tempo     = f.sk_tempo
JOIN dim_indicador i ON i.sk_indicador = f.sk_indicador;


-- ────────────────────────────────────────────────────────────
-- EXEMPLO DE CONSULTA ANALÍTICA
-- ────────────────────────────────────────────────────────────

-- IPCA vs SELIC no mesmo período
SELECT
    t.ano_mes,
    MAX(CASE WHEN i.codigo = 'IPCA'   THEN f.valor END) AS ipca_mensal_pct,
    MAX(CASE WHEN i.codigo = 'SELIC'  THEN f.valor END) AS selic_pct_aa,
    MAX(CASE WHEN i.codigo = 'CAMBIO_USD' THEN f.valor END) AS cambio_brl_usd
FROM fato_indicadores f
JOIN dim_tempo     t ON t.sk_tempo     = f.sk_tempo
JOIN dim_indicador i ON i.sk_indicador = f.sk_indicador
WHERE t.ano BETWEEN 2022 AND 2024
GROUP BY t.ano_mes
ORDER BY t.ano_mes;
