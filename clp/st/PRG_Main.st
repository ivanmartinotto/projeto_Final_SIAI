(* =====================================================================
   PRG_Main  -  liga ONS -> Decisão -> SFC -> Energia
   ---------------------------------------------------------------------
   Versão pronta para colar no Codesys (sem TO_E_EstadoONS ilustrativo).
   Crie um POU tipo PROGRAM chamado PRG_Main, cole tudo abaixo e adicione
   PRG_Main na Task Configuration (MainTask).

   Pré-requisitos na árvore do projeto:
     - DUTs (Enumerations): E_EstadoONS, E_Decisao
     - Function Blocks: FB_DecisaoEnergetica, FB_GestaoEnergia
     - SFC: SFC_Esteira (lê libera_peca; escreve ciclo_concluido/produzindo)

   Mapa Modbus (Holding Registers do simulador ONS):
     HR0 -> estadoONS_raw (0/1/2)   HR1 -> tarifa_raw (R$/kWh x100)
   Ajuste os %IW/%QW no I/O Mapping do Modbus TCP conforme T3.1.
   ===================================================================== *)

PROGRAM PRG_Main
VAR
    (* --- Instâncias dos function blocks --- *)
    fbDecisao : FB_DecisaoEnergetica;
    fbEnergia : FB_GestaoEnergia;

    (* --- Entradas vindas do simulador ONS via Modbus --- *)
    estadoONS_raw : INT;    (* mapear em %IW p/ HR0 do simulador *)
    tarifa_raw    : INT;    (* mapear em %IW p/ HR1 (x100)        *)
    eEstadoONS    : E_EstadoONS;  (* estadoONS_raw convertido em enum *)

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
    libera_peca     : BOOL;   (* SFC lê isto na transição inicial T0 *)
    ciclo_concluido : BOOL;   (* SFC seta TRUE (pulso) ao terminar a peça *)
    produzindo      : BOOL;   (* SFC mantém TRUE durante a usinagem *)
END_VAR

(* 0) Converte o registro Modbus (INT) no enum E_EstadoONS.
      Cast direto INT->ENUM não é garantido em todos os targets;
      o CASE é explícito e seguro. *)
CASE estadoONS_raw OF
    0:   eEstadoONS := NORMAL;
    1:   eEstadoONS := PONTA;
    2:   eEstadoONS := ALERTA_DEMANDA;
ELSE
    eEstadoONS := NORMAL;   (* valor inesperado -> assume NORMAL *)
END_CASE

(* 1) Há peças pendentes na OS? *)
os_pendente := (os_qtd_feita < os_qtd_pedida);

(* 2) Roda a decisão energética *)
fbDecisao(
    estadoONS     := eEstadoONS,
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
    dt_s             := 0.1,          (* tempo de varredura da task *)
    cap_bateria_kWh  := CAP_BAT_KWH
);

(* 4) Contabiliza peça concluída (pulso vindo do SFC) *)
IF ciclo_concluido THEN
    os_qtd_feita := os_qtd_feita + 1;
    (* aqui o SCADA/CLP grava na tabela 'producao' via datasource SQL *)
END_IF
