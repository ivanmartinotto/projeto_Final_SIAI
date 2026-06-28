"""
Simulador da ONS - Celula de Manufatura Energeticamente Autonoma
================================================================

Entrega, em "tempo real" (por hora simulada), o ESTADO da rede e a TARIFA
de energia para o CLP (Codesys) e o SCADA (ScadaBR).

Dois modos de operacao:
  1) console  -> imprime estado/tarifa no terminal (teste isolado - T2.4)
  2) modbus   -> expoe os dados como servidor Modbus TCP (slave) para o CLP ler
                 (requer: pip install pymodbus)

MAPA DE REGISTRADORES MODBUS (Holding Registers) - ONS -> CLP/SCADA
-------------------------------------------------------------------
  HR0  estado_ons    0=NORMAL  1=PONTA  2=ALERTA_DEMANDA
  HR1  tarifa_x100   tarifa em R$/kWh multiplicada por 100 (inteiro). Ex.: 120 = R$ 1,20
  HR2  hora_sim      hora simulada do dia (0..23)

Obs.: usa-se x100 porque Modbus transporta inteiros de 16 bits; o CLP divide por 100.

Cenarios cobertos (RNF03 - troca facil de cenario para demonstracao):
  - Fora de ponta  -> NORMAL  (produz da rede)
  - Horario de ponta -> PONTA (migra para bateria se SOC suficiente)
  - Alerta de demanda -> ALERTA_DEMANDA (pausa se nao houver bateria)
"""

from __future__ import annotations
import argparse
import time
from dataclasses import dataclass

# ---------------------------------------------------------------------------
# 1) MODELO DE DADOS DA ONS (T2.1)
# ---------------------------------------------------------------------------

# Codigos numericos dos estados (devem casar com o enum E_EstadoONS no ST)
NORMAL = 0
PONTA = 1
ALERTA_DEMANDA = 2

NOME_ESTADO = {NORMAL: "NORMAL", PONTA: "PONTA", ALERTA_DEMANDA: "ALERTA_DEMANDA"}

# Tarifa associada a cada estado (R$/kWh). Ajuste livre para demonstracao.
TARIFA = {
    NORMAL: 0.50,          # fora de ponta - energia barata
    PONTA: 1.20,           # horario de ponta - energia cara
    ALERTA_DEMANDA: 1.50,  # alerta da ONS - mais cara ainda + risco de corte
}

# Janela de horario de ponta padrao no Brasil: 18h-21h.
# Fora dessa janela = NORMAL. ALERTA_DEMANDA e injetado manualmente (ver --forcar).
HORA_PONTA_INI = 18
HORA_PONTA_FIM = 21  # exclusivo: ponta = [18, 19, 20]


@dataclass
class EstadoONS:
    hora: int
    estado: int
    tarifa: float

    @property
    def tarifa_x100(self) -> int:
        return int(round(self.tarifa * 100))

    def __str__(self) -> str:
        return (f"[{self.hora:02d}h] estado={NOME_ESTADO[self.estado]:<14} "
                f"tarifa=R$ {self.tarifa:.2f}/kWh")


# ---------------------------------------------------------------------------
# 2) REGRA QUE DEFINE O ESTADO A PARTIR DA HORA (T2.2)
# ---------------------------------------------------------------------------

def avaliar(hora: int, forcar: int | None = None) -> EstadoONS:
    """Retorna o estado/tarifa para a hora dada.
    Se 'forcar' for passado (0/1/2), sobrepoe a regra de horario -
    util para demonstrar ALERTA_DEMANDA sob comando (RNF03)."""
    hora = hora % 24
    if forcar is not None:
        estado = forcar
    elif HORA_PONTA_INI <= hora < HORA_PONTA_FIM:
        estado = PONTA
    else:
        estado = NORMAL
    return EstadoONS(hora=hora, estado=estado, tarifa=TARIFA[estado])


# ---------------------------------------------------------------------------
# 3) MODO CONSOLE - teste isolado (T2.4)
# ---------------------------------------------------------------------------

def run_console(passo_s: float, forcar: int | None) -> None:
    print("Simulador ONS - modo console. Ctrl+C para sair.\n")
    hora = 0
    try:
        while True:
            est = avaliar(hora, forcar)
            print(est)
            time.sleep(passo_s)
            hora = (hora + 1) % 24
    except KeyboardInterrupt:
        print("\nEncerrado.")


# ---------------------------------------------------------------------------
# 4) MODO MODBUS TCP - servidor slave que o CLP le (T2.2 / RNF06)
# ---------------------------------------------------------------------------

def run_modbus(host: str, port: int, passo_s: float, forcar: int | None) -> None:
    """Expoe HR0..HR2 via Modbus TCP. Atualiza a cada 'passo_s' segundos,
    avancando a hora simulada. O CLP (Codesys, master Modbus) le os registros."""
    try:
        from pymodbus.datastore import (ModbusSequentialDataBlock,
                                         ModbusSlaveContext, ModbusServerContext)
        from pymodbus.server import StartTcpServer
        import threading
    except ImportError:
        raise SystemExit("Falta a dependencia: pip install pymodbus")

    # Bloco de holding registers inicializado com a hora 0
    est0 = avaliar(0, forcar)
    hr = ModbusSequentialDataBlock(0, [est0.estado, est0.tarifa_x100, est0.hora])
    store = ModbusSlaveContext(hr=hr, zero_mode=True)
    context = ModbusServerContext(slaves=store, single=True)

    def atualizar():
        hora = 0
        while True:
            est = avaliar(hora, forcar)
            # setValues(fx=3 -> holding registers, endereco, valores)
            context[0].setValues(3, 0, [est.estado, est.tarifa_x100, est.hora])
            print("ONS ->", est)
            time.sleep(passo_s)
            hora = (hora + 1) % 24

    threading.Thread(target=atualizar, daemon=True).start()
    print(f"Servidor Modbus TCP em {host}:{port} (HR0=estado, HR1=tarifa_x100, HR2=hora)")
    StartTcpServer(context=context, address=(host, port))


# ---------------------------------------------------------------------------
# 5) CLI
# ---------------------------------------------------------------------------

def main() -> None:
    p = argparse.ArgumentParser(description="Simulador da ONS (estado + tarifa)")
    p.add_argument("--modo", choices=["console", "modbus"], default="console")
    p.add_argument("--host", default="0.0.0.0")
    p.add_argument("--port", type=int, default=5020,
                   help="porta Modbus TCP (502 exige admin; 5020 e seguro)")
    p.add_argument("--passo", type=float, default=2.0,
                   help="segundos reais por hora simulada")
    p.add_argument("--forcar", type=int, choices=[0, 1, 2], default=None,
                   help="forca o estado: 0=NORMAL 1=PONTA 2=ALERTA_DEMANDA (demo)")
    args = p.parse_args()

    if args.modo == "console":
        run_console(args.passo, args.forcar)
    else:
        run_modbus(args.host, args.port, args.passo, args.forcar)


if __name__ == "__main__":
    main()
