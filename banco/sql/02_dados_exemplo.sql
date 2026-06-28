-- =====================================================================
-- Dados de exemplo - para testar as queries de auditoria sem rodar a planta
-- =====================================================================
USE celula_autonoma;

INSERT INTO ordem_servico (cliente, qtd_pedida, status) VALUES
  ('Cliente Alfa', 10, 'EM_PRODUCAO');

-- OS 1: 3 pecas produzidas (2 aprovadas via rede, 1 refugo via bateria)
INSERT INTO producao (id_os, resultado, fonte_energia, custo_peca, tempo_ciclo_s) VALUES
  (1, 'APROVADA', 'REDE',    0.0167, 12.0),
  (1, 'REFUGO',   'REDE',    0.0167, 12.0),
  (1, 'APROVADA', 'BATERIA', 0.0400, 12.5);

-- Amostras de consumo
INSERT INTO consumo (potencia_kw, energia_kwh, fonte_energia, soc_pct, geracao_solar_kw) VALUES
  (5.000, 0.0167, 'REDE',    80.00, 1.20),
  (5.000, 0.0167, 'REDE',    79.50, 1.10),
  (5.000, 0.0174, 'BATERIA', 78.00, 0.30);

-- Eventos da ONS
INSERT INTO evento_ons (estado, tarifa, acao_tomada) VALUES
  ('NORMAL',         0.50, 'PRODUZIR_REDE'),
  ('PONTA',          1.20, 'PRODUZIR_BATERIA'),
  ('ALERTA_DEMANDA', 1.50, 'PAUSAR');

-- Atualiza contadores da OS
UPDATE ordem_servico
   SET qtd_produzida = 2, qtd_refugo = 1, custo_total = 0.0734
 WHERE id_os = 1;
