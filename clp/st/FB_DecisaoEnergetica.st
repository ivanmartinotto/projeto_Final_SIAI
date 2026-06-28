(* =====================================================================
   FB_DecisaoEnergetica  -  Structured Text (IEC 61131-3 / Codesys)
   ---------------------------------------------------------------------
   Núcleo da "inteligência" da célula (Fase 4 do escopo):
     - calcula custo por peça      (T4.1)
     - decide rede / bateria / pausa (T4.2)
     - atualiza SOC (simulado)      (T4.3)

   COMO USAR NO CODESYS:
     1. Crie os tipos enumerados (TYPE ... END_TYPE) em um arquivo DUT,
        ou cole os blocos TYPE abaixo num objeto "DUT".
     2. Crie um Function Block chamado FB_DecisaoEnergetica e cole o
        conteúdo a partir de "FUNCTION_BLOCK".
     3. Instancie no PRG principal (ver exemplo de chamada no fim).

   Entradas vindas do simulador ONS via Modbus:
     HR0 -> estadoONS (0/1/2)   HR1 -> tarifa_x100   (divida por 100.0)
   ===================================================================== *)

(* ---------- TIPOS (colar em um DUT) ---------- *)
TYPE E_EstadoONS : (
    NORMAL          := 0,
    PONTA           := 1,
    ALERTA_DEMANDA  := 2
); END_TYPE

TYPE E_Decisao : (
    PAUSA   := 0,
    REDE    := 1,
    BATERIA := 2
); END_TYPE


(* ---------- FUNCTION BLOCK ---------- *)
FUNCTION_BLOCK FB_DecisaoEnergetica
VAR_INPUT
    estadoONS     : E_EstadoONS;  (* estado da rede vindo da ONS          *)
    tarifa        : REAL;         (* R$/kWh (HR1/100.0)                   *)
    potencia_kW   : REAL;         (* potência da estação de usinagem      *)
    tempo_ciclo_s : REAL;         (* tempo de ciclo de uma peça [s]       *)
    eficiencia    : REAL;         (* rendimento 0.0..1.0                  *)
    soc           : REAL;         (* estado de carga da bateria 0..100 %  *)
    soc_min       : REAL;         (* SOC mínimo p/ usar bateria (ex.: 30) *)
    os_pendente   : BOOL;         (* TRUE enquanto faltam peças na OS      *)
END_VAR
VAR_OUTPUT
    decisao          : E_Decisao; (* resultado: PAUSA / REDE / BATERIA    *)
    custo_peca       : REAL;      (* R$ por peça na tarifa atual          *)
    liberar_producao : BOOL;      (* TRUE => SFC pode iniciar a peça      *)
END_VAR
VAR
    tempo_ciclo_h : REAL;
END_VAR

(* --- 1) Custo por peça (T4.1) ---------------------------------------
   Custo = (Potência[kW] * Tempo_ciclo[h] * Tarifa[R$/kWh]) / Eficiência *)
tempo_ciclo_h := tempo_ciclo_s / 3600.0;

IF eficiencia <= 0.0 THEN
    eficiencia := 1.0;   (* proteção contra divisão por zero *)
END_IF

custo_peca := (potencia_kW * tempo_ciclo_h * tarifa) / eficiencia;

(* --- 2) Decisão energética (T4.2) ----------------------------------- *)
IF NOT os_pendente THEN
    (* nada a produzir -> não faz sentido ligar a estação *)
    decisao          := PAUSA;
    liberar_producao := FALSE;
    RETURN;
END_IF

CASE estadoONS OF
    NORMAL:
        (* fora de ponta: energia barata -> produz direto da rede *)
        decisao := REDE;

    PONTA, ALERTA_DEMANDA:
        (* energia cara / risco de corte: usa bateria se houver carga,
           caso contrário pausa para não consumir da rede no pico *)
        IF soc > soc_min THEN
            decisao := BATERIA;
        ELSE
            decisao := PAUSA;
        END_IF
END_CASE

(* Libera a sequência física apenas se a fonte foi definida *)
liberar_producao := (decisao = REDE) OR (decisao = BATERIA);
