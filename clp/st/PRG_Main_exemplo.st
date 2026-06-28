(* =====================================================================
   PRG_Main (exemplo)  -  liga ONS -> Decisão -> SFC -> Energia
   ---------------------------------------------------------------------
   Demonstra como instanciar os FBs e cravar a regra:
   "a esteira só inicia a próxima peça se a decisão liberar" (T4.4).
   Ajuste os endereços Modbus (%IW/%QW) conforme o mapa de I/O (T3.1).
   ===================================================================== *)

PROGRAM PRG_Main
VAR
    (* --- Instâncias dos function blocks --- *)
    fbDecisao : FB_DecisaoEnergetica;
    fbEnergia : FB_GestaoEnergia;

    (* --- Entradas vindas do simulador ONS via Modbus --- *)
    estadoONS_raw : INT;    (* mapear em %IW p/ HR0 do simulador *)
    tarifa_raw    : INT;    (* mapear em %IW p/ HR1 (x100)        *)

    (* --- Parâmetros da máquina (parametrizáveis) --- *)
    POTENCIA_KW   : REAL := 5.0;
    TEMPO_CICLO_S : REAL := 12.0;
    EFICIENCIA    : REAL := 0.90;
    SOC_MIN       : REAL := 30.0;
    CAP_BAT_KWH   : REAL := 10.0;
    SOLAR_KW      : REAL := 1.2;

    (* --- Estado da OS --- *)
    os_qtd_pedida   : INT := 10;
    os_qtd_feita    : INT := 0;
    os_pendente     : BOOL;

    (* --- Interface com o SFC da esteira --- *)
    libera_peca     : BOOL;   (* SFC lê isto na transição inicial *)
    ciclo_concluido : BOOL;   (* SFC seta TRUE ao terminar a peça *)
    produzindo      : BOOL;   (* SFC mantém TRUE durante a usinagem *)
END_VAR

(* 1) Converte registros Modbus em engenharia *)
os_pendente := (os_qtd_feita < os_qtd_pedida);

(* 2) Roda a decisão energética *)
fbDecisao(
    estadoONS     := TO_E_EstadoONS(estadoONS_raw),
    tarifa        := INT_TO_REAL(tarifa_raw) / 100.0,
    potencia_kW   := POTENCIA_KW,
    tempo_ciclo_s := TEMPO_CICLO_S,
    eficiencia    := EFICIENCIA,
    soc           := fbEnergia.soc,
    soc_min       := SOC_MIN,
    os_pendente   := os_pendente
);

libera_peca := fbDecisao.liberar_producao;   (* <- SFC usa isto (T4.4) *)

(* 3) Gestão de energia / chaveamento *)
fbEnergia(
    usar_bateria     := (fbDecisao.decisao = BATERIA),
    potencia_kW      := POTENCIA_KW,
    produzindo       := produzindo,
    geracao_solar_kW := SOLAR_KW,
    dt_s             := 0.1,          (* tempo de varredura *)
    cap_bateria_kWh  := CAP_BAT_KWH
);

(* 4) Contabiliza peça concluída (pulso vindo do SFC) *)
IF ciclo_concluido THEN
    os_qtd_feita := os_qtd_feita + 1;
    (* aqui o SCADA/CLP grava na tabela 'producao' via datasource SQL *)
END_IF

(* Nota: TO_E_EstadoONS é só ilustrativo; no Codesys faça um CASE ou
   um cast direto INT->ENUM, pois o enum já tem os valores 0/1/2. *)
