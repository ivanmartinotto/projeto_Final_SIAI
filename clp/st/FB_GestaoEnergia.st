(* =====================================================================
   FB_GestaoEnergia  -  Structured Text (IEC 61131-3 / Codesys)
   ---------------------------------------------------------------------
   Gestão (simulada) da fonte própria (T4.3 / RF07):
     - integra geração solar e consumo no SOC da bateria
     - faz o chaveamento lógico rede/bateria conforme a decisão
   Chame este FB ciclicamente (ex.: a cada 100 ms ou a cada peça).
   ===================================================================== *)

FUNCTION_BLOCK FB_GestaoEnergia
VAR_INPUT
    usar_bateria   : BOOL;   (* TRUE => decisão = BATERIA *)
    potencia_kW    : REAL;   (* consumo da estação quando produzindo *)
    produzindo     : BOOL;   (* TRUE durante o ciclo de usinagem *)
    geracao_solar_kW : REAL; (* geração solar simulada *)
    dt_s           : REAL;   (* intervalo desde a última chamada [s] *)
    cap_bateria_kWh : REAL;  (* capacidade da bateria [kWh] *)
END_VAR
VAR_OUTPUT
    soc            : REAL;    (* 0..100 % - estado de carga atual *)
    rele_rede      : BOOL;    (* aciona contator da rede *)
    rele_bateria   : BOOL;    (* aciona contator da bateria *)
END_VAR
VAR
    energia_kWh    : REAL;    (* energia armazenada [kWh] *)
    init_done      : BOOL;
    consumo_kW     : REAL;
    delta_kWh      : REAL;
END_VAR

(* inicializa a bateria a 80% na primeira varredura *)
IF NOT init_done THEN
    energia_kWh := 0.80 * cap_bateria_kWh;
    init_done := TRUE;
END_IF

(* consumo só existe enquanto a estação está produzindo *)
IF produzindo THEN
    consumo_kW := potencia_kW;
ELSE
    consumo_kW := 0.0;
END_IF

(* --- Balanço de energia da bateria ---------------------------------
   A solar sempre carrega. O consumo só desconta da bateria se a
   decisão foi BATERIA; se for REDE, a estação puxa da rede. *)
delta_kWh := geracao_solar_kW * (dt_s / 3600.0);          (* entra solar *)
IF usar_bateria THEN
    delta_kWh := delta_kWh - consumo_kW * (dt_s / 3600.0); (* sai consumo *)
END_IF

energia_kWh := energia_kWh + delta_kWh;

(* satura entre 0 e a capacidade *)
IF energia_kWh > cap_bateria_kWh THEN
    energia_kWh := cap_bateria_kWh;
END_IF
IF energia_kWh < 0.0 THEN
    energia_kWh := 0.0;
END_IF

IF cap_bateria_kWh > 0.0 THEN
    soc := 100.0 * energia_kWh / cap_bateria_kWh;
ELSE
    soc := 0.0;
END_IF

(* --- Chaveamento dos contatores (intertravamento: nunca os dois) --- *)
rele_bateria := usar_bateria;
rele_rede    := NOT usar_bateria AND produzindo;
