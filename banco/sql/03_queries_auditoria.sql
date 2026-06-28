-- =====================================================================
-- Queries de auditoria (T5.5) - prova de rastreabilidade producao/consumo
-- =====================================================================
USE celula_autonoma;

-- 1) Progresso de cada OS (produzido x pedido)
SELECT  os.id_os, os.cliente, os.qtd_pedida,
        os.qtd_produzida, os.qtd_refugo,
        ROUND(100.0 * os.qtd_produzida / os.qtd_pedida, 1) AS pct_concluido,
        os.custo_total, os.status
FROM    ordem_servico os
ORDER BY os.id_os;

-- 2) Pecas produzidas por fonte de energia (rede x bateria)
SELECT  fonte_energia,
        COUNT(*)                       AS pecas,
        SUM(resultado = 'APROVADA')    AS aprovadas,
        SUM(resultado = 'REFUGO')      AS refugos,
        ROUND(SUM(custo_peca), 4)      AS custo_total_rs
FROM    producao
GROUP BY fonte_energia;

-- 3) Custo medio por peca por OS
SELECT  id_os,
        COUNT(*)                  AS pecas,
        ROUND(AVG(custo_peca), 4) AS custo_medio_rs
FROM    producao
GROUP BY id_os;

-- 4) Energia total consumida por fonte
SELECT  fonte_energia,
        ROUND(SUM(energia_kwh), 4) AS energia_kwh,
        ROUND(AVG(soc_pct), 1)     AS soc_medio_pct
FROM    consumo
GROUP BY fonte_energia;

-- 5) Linha do tempo dos eventos da ONS e a acao tomada
SELECT  carimbo, estado, tarifa, acao_tomada
FROM    evento_ons
ORDER BY carimbo;

-- 6) Quanto tempo a producao ficou pausada por alerta da ONS
--    (conta eventos que resultaram em PAUSAR)
SELECT  estado,
        COUNT(*) AS qtd_pausas
FROM    evento_ons
WHERE   acao_tomada = 'PAUSAR'
GROUP BY estado;

-- 7) Economia estimada: custo se TUDO fosse na ponta vs custo real
--    (demonstra o valor da decisao energetica)
SELECT  ROUND(SUM(custo_peca), 4)               AS custo_real_rs,
        ROUND(SUM(tempo_ciclo_s/3600.0 * 5.0 * 1.20), 4) AS custo_se_tudo_ponta_rs
FROM    producao;  -- 5.0 kW e tarifa de ponta 1,20 hardcoded p/ comparacao
