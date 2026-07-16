# Mapa de I/O (T3.1) — Factory IO ↔ Codesys ↔ ONS

Esqueleto para preencher com os endereços reais da cena escolhida no Factory IO.
Enquanto os endereços não estiverem fechados, as colunas *Endereço Factory IO*,
*Endereço Modbus* e *Var Codesys (%IW/%QW/%IX/%QX)* ficam como `TODO`.

> **Cena adotada: "Sorting by height".** Sem estação de usinagem física — a usinagem
> é temporizada no CLP (`tmr_usina`), então **não existe atuador `atuador_usina`**.
> A inspeção reaproveita os dois sensores difusos de altura da cena (baixo = presença
> sob o leitor; alto = caixa alta). Ver `clp/sfc/SFC_Esteira.md`.

> Regra de tipo Modbus:
> - **Sensores** (entradas do CLP) → Factory IO expõe como *Discrete Inputs*
>   (bits) ou *Input Registers*. No Codesys mapear em `%IX` / `%IW`.
> - **Atuadores** (saídas do CLP) → *Coils* (bits) ou *Holding Registers*.
>   No Codesys mapear em `%QX` / `%QW`.
> - Um bit = 1 sinal booleano. Um register = 16 bits (valores numéricos).

---

## 1. Sinais da esteira — Factory IO ↔ Codesys

### 1.1 Entradas (sensores — Factory IO → CLP)

| Var Codesys | Tipo | Sinal na cena "Sorting by height" | Endereço Factory IO | Modbus (tipo/offset) | %IX/%IW | Origem SFC |
|-------------|------|--------------------------|---------------------|----------------------|---------|-----------|
| `sensor_entrada` | BOOL | Sensor difuso na entrada (caixa emitida) | TODO | Discrete Input / TODO | TODO | T0 |
| `sensor_posicao` | BOOL | Sensor difuso do meio (ponto de usinagem — esteira para aqui) | TODO | Discrete Input / TODO | TODO | T1 |
| `sensor_qualidade_presente` | BOOL | Sensor difuso **baixo** (presença sob o leitor de altura) | TODO | Discrete Input / TODO | TODO | T3 |
| `sensor_qualidade` | BOOL | Sensor difuso **alto** (caixa alta = aprovada; baixa = refugo) | TODO | Discrete Input / TODO | TODO | T4a/T4b |
| `sensor_saida` | BOOL | Sensor difuso na saída/contagem | TODO | Discrete Input / TODO | TODO | T5/T6 |

### 1.2 Saídas (atuadores — CLP → Factory IO)

| Var Codesys | Tipo | Sinal na cena "Sorting by height" | Endereço Factory IO | Modbus (tipo/offset) | %QX/%QW | Origem SFC |
|-------------|------|--------------------------|---------------------|----------------------|---------|-----------|
| `motor_esteira` | BOOL | Belt conveyor(s) da linha | TODO | Coil / TODO | TODO | S1,S3,S4,S5 (OFF em S2) |
| `desviador` | BOOL | Pusher (empurra refugo p/ saída lateral) | TODO | Coil / TODO | TODO | S5 |

> Usinagem **não tem atuador**: em S2 a esteira fica OFF e `tmr_usina` conta o tempo
> de ciclo (`produzindo := TRUE`). O consumo de energia sai daí, não de um coil.

---

## 2. Sinais da ONS — Simulador ↔ Codesys

Simulador em `ons/simulador` (Modbus TCP Server, porta padrão `5020`).
Ver `ons/simulador/README.md`.

| Var Codesys | Tipo | Conteúdo | Modbus | %IW | Conversão |
|-------------|------|----------|--------|-----|-----------|
| `estadoONS_raw` | INT | HR0: 0=NORMAL·1=PONTA·2=ALERTA | Holding Reg 0 | TODO | CASE → `E_EstadoONS` |
| `tarifa_raw` | INT | HR1: tarifa R$/kWh ×100 | Holding Reg 1 | TODO | `/100.0` → REAL |
| `hora_sim` | INT | HR2: hora do dia (0..23) | Holding Reg 2 | TODO | (opcional, SCADA) |

---

## 3. Variáveis internas (não vão ao Modbus)

Ficam no CLP; algumas o ScadaBR lê para supervisão (seção 3.3 do guia de config).

| Var | Tipo | Onde | Uso |
|-----|------|------|-----|
| `libera_peca` | BOOL | PRG_Main → SFC | trava T0 se decisão não liberar (T4.4) |
| `produzindo` | BOOL | SFC → FB_GestaoEnergia | TRUE durante usinagem |
| `ciclo_concluido` | BOOL | SFC → PRG_Main | pulso: conta peça / grava SQL |
| `soc` | REAL | FB_GestaoEnergia | estado de carga bateria 0..100% |
| `decisao` | E_Decisao | FB_DecisaoEnergetica | PAUSA/REDE/BATERIA |
| `custo_peca` | REAL | FB_DecisaoEnergetica | R$/peça na tarifa atual |
| `rele_rede` / `rele_bateria` | BOOL | FB_GestaoEnergia | chaveamento fonte (intertravado) |
| `os_qtd_pedida` / `os_qtd_feita` | INT | PRG_Main | progresso da OS |

---

## 4. Como preencher (checklist)

1. Abrir a cena no Factory IO → `File → Drivers → Modbus TCP/IP Server`.
2. Na aba de configuração, cada point da cena mostra seu **tipo** (coil / input)
   e **offset**. Copiar para as colunas *Endereço Factory IO* / *Modbus*.
3. No Codesys, no I/O Mapping do slave Modbus, anotar o `%IX`/`%QX`/`%IW`/`%QW`
   atribuído a cada canal → coluna correspondente.
4. Trocar todos os `TODO`. Este arquivo vira a fonte de verdade da integração
   (T3.4) e do data source do ScadaBR.

> Dica: em "Sorting by height" a inspeção usa dois sensores difusos — o baixo
> (`sensor_qualidade_presente`, presença) e o alto (`sensor_qualidade`, caixa alta).
> Se a cena usar um sensor de visão único, combine presença + valor conforme o
> hardware. Detalhes da sequência em `clp/sfc/SFC_Esteira.md`.
