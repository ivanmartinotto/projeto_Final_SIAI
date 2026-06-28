# Simulador da ONS

Entrega estado da rede + tarifa ao CLP/SCADA (Fase 2 do escopo).

## Dependência (apenas modo modbus)
```
pip install pymodbus
```

## Uso

Modo console (teste isolado — T2.4):
```
python simulador_ons.py --modo console --passo 2
```

Modo Modbus TCP (CLP lê os registros — T2.2 / RNF06):
```
python simulador_ons.py --modo modbus --port 5020 --passo 2
```

Forçar cenário para demonstração (RNF03):
```
python simulador_ons.py --modo console --forcar 2   # ALERTA_DEMANDA
```

## Mapa Modbus (Holding Registers) — ONS → CLP/SCADA

| Reg | Conteúdo | Valores |
|-----|----------|---------|
| HR0 | `estado_ons` | 0=NORMAL · 1=PONTA · 2=ALERTA_DEMANDA |
| HR1 | `tarifa_x100` | tarifa R$/kWh × 100 (ex.: 120 = R$ 1,20) |
| HR2 | `hora_sim` | hora simulada do dia (0..23) |

No Codesys, divida HR1 por 100.0 para obter a tarifa em REAL.

## Tarifas padrão

| Estado | Tarifa |
|--------|--------|
| NORMAL | R$ 0,50/kWh |
| PONTA | R$ 1,20/kWh |
| ALERTA_DEMANDA | R$ 1,50/kWh |

Ponta padrão: 18h–21h. Edite `HORA_PONTA_INI/FIM` e `TARIFA` no `.py`.
