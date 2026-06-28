-- =====================================================================
-- Celula de Manufatura Energeticamente Autonoma
-- Esquema de banco - historico de producao, consumo e eventos da ONS
-- Alvo: MySQL 8 / MariaDB.  (Notas de portabilidade p/ PostgreSQL no fim.)
-- Atende: RF09 (registro p/ auditoria), T5.5
-- =====================================================================

CREATE DATABASE IF NOT EXISTS celula_autonoma
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE celula_autonoma;

-- ---------------------------------------------------------------------
-- Ordens de Servico (RF01, RF10)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ordem_servico (
  id_os           INT AUTO_INCREMENT PRIMARY KEY,
  cliente         VARCHAR(120)    NOT NULL,
  qtd_pedida      INT             NOT NULL,
  qtd_produzida   INT             NOT NULL DEFAULT 0,
  qtd_refugo      INT             NOT NULL DEFAULT 0,
  status          ENUM('ABERTA','EM_PRODUCAO','PAUSADA','CONCLUIDA')
                                  NOT NULL DEFAULT 'ABERTA',
  custo_total     DECIMAL(10,2)   NOT NULL DEFAULT 0.00,  -- R$ acumulado
  criada_em       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  concluida_em    DATETIME        NULL
);

-- ---------------------------------------------------------------------
-- Producao - uma linha por peca finalizada (RF09)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS producao (
  id_producao     BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_os           INT             NOT NULL,
  carimbo         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resultado       ENUM('APROVADA','REFUGO') NOT NULL,
  fonte_energia   ENUM('REDE','BATERIA')    NOT NULL,  -- de onde veio a energia
  custo_peca      DECIMAL(8,4)    NOT NULL,            -- R$ desta peca
  tempo_ciclo_s   DECIMAL(6,2)    NULL,
  CONSTRAINT fk_prod_os FOREIGN KEY (id_os) REFERENCES ordem_servico(id_os)
);

-- ---------------------------------------------------------------------
-- Consumo - amostras periodicas de energia/SOC (RF07, RF09)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS consumo (
  id_consumo      BIGINT AUTO_INCREMENT PRIMARY KEY,
  carimbo         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  potencia_kw     DECIMAL(7,3)    NOT NULL,   -- potencia instantanea
  energia_kwh     DECIMAL(9,4)    NOT NULL,   -- energia no intervalo
  fonte_energia   ENUM('REDE','BATERIA')      NOT NULL,
  soc_pct         DECIMAL(5,2)    NOT NULL,   -- estado de carga da bateria 0..100
  geracao_solar_kw DECIMAL(7,3)   NOT NULL DEFAULT 0.000
);

-- ---------------------------------------------------------------------
-- Eventos da ONS - mudancas de estado/tarifa (RF02, RF08)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS evento_ons (
  id_evento       BIGINT AUTO_INCREMENT PRIMARY KEY,
  carimbo         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado          ENUM('NORMAL','PONTA','ALERTA_DEMANDA') NOT NULL,
  tarifa          DECIMAL(6,2)    NOT NULL,   -- R$/kWh vigente
  acao_tomada     ENUM('PRODUZIR_REDE','PRODUZIR_BATERIA','PAUSAR') NULL
);

-- Indices p/ consultas de auditoria por tempo
CREATE INDEX idx_prod_carimbo    ON producao(carimbo);
CREATE INDEX idx_consumo_carimbo ON consumo(carimbo);
CREATE INDEX idx_evento_carimbo  ON evento_ons(carimbo);

-- =====================================================================
-- NOTAS DE PORTABILIDADE (PostgreSQL)
--  - AUTO_INCREMENT      -> use GENERATED ALWAYS AS IDENTITY ou SERIAL
--  - ENUM(...)           -> crie TYPE ... AS ENUM, ou use VARCHAR + CHECK
--  - DATETIME            -> TIMESTAMP
--  - CURRENT_TIMESTAMP   -> igual (ok)
-- =====================================================================
