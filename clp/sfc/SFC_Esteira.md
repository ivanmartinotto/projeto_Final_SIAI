# SFC / Grafcet — Sequência da Esteira

Descrição textual da sequência física (T3.2) para você **montar no editor SFC
do Codesys**. O Codesys SFC é gráfico: aqui está a estrutura (Steps, Transitions,
Ações) e as expressões em ST para copiar nas transições/ações.

> Convenção: `S` = Step (etapa), `T` = Transition (condição p/ avançar).
> Ações de etapa usam qualificadores: `N` (não-armazenada, ativa enquanto a etapa
> estiver ativa), `S` (set), `R` (reset), `P` (pulso).

> **Cena Factory IO = "Sorting by height".** A cena não tem furadeira/prensa, então
> a **usinagem não usa atuador físico**: é uma fase **temporizada** (`tmr_usina`) em
> que a esteira para no ponto e `produzindo := TRUE` — é isso que faz o
> `FB_GestaoEnergia` consumir energia. A inspeção reaproveita os **sensores de
> altura** da cena (baixo = presença sob o leitor; alto = caixa alta). Assim a
> decisão energética (pausar/bateria) continua tendo sentido sem um atuador de
> usinagem. Sinais reais → ver `clp/Mapa_IO.md`.

---

## Variáveis (I/O) usadas — casar com o mapa de I/O (T3.1)

| Nome | Tipo | Sentido | Significado |
|------|------|---------|-------------|
| `sensor_entrada` | BOOL | IN | Caixa presente na entrada |
| `sensor_posicao` | BOOL | IN | Caixa parada no ponto de usinagem (sensor difuso do meio) |
| `sensor_qualidade_presente` | BOOL | IN | Caixa sob o leitor de altura (sensor difuso baixo) |
| `sensor_qualidade` | BOOL | IN | Caixa alta (sensor difuso alto): TRUE = aprovada / FALSE = refugo |
| `sensor_saida` | BOOL | IN | Caixa chegou à saída/contagem |
| `motor_esteira` | BOOL | OUT | Liga motor da esteira |
| `desviador` | BOOL | OUT | Pistão/pusher separador (refugo) |
| `libera_peca` | BOOL | IN | Vem do `PRG_Main` (decisão energética liberou) |
| `produzindo` | BOOL | OUT | Informa ao FB de energia que está usinando |
| `ciclo_concluido` | BOOL | OUT | Pulso ao concluir a peça (CLP conta/grava) |
| `tmr_usina` | TON | — | Temporizador da usinagem (substitui o atuador físico) |

> Não há mais `atuador_usina`: a cena "Sorting by height" não tem furadeira. A
> usinagem é 100% temporizada — esteira parada + `produzindo` durante `tmr_usina`.

---

## Diagrama (texto)

```
   ┌─────────────────────────┐
   │ S0  INICIAL (Step inic.) │  ação: produzindo:=FALSE; ciclo_concluido:=FALSE
   └────────────┬────────────┘
                │ T0:  libera_peca AND sensor_entrada
                ▼
   ┌─────────────────────────┐
   │ S1  TRANSPORTE_1         │  N: motor_esteira
   └────────────┬────────────┘
                │ T1:  sensor_posicao
                ▼
   ┌─────────────────────────┐
   │ S2  USINAGEM (temporiz.) │  esteira PARADA (motor OFF) ; N: produzindo
   │      (tmr_usina IN:=TRUE)│  sem atuador — só o timer
   └────────────┬────────────┘
                │ T2:  tmr_usina.Q      (tempo de ciclo cumprido)
                ▼
   ┌─────────────────────────┐
   │ S3  INSPECAO             │  N: motor_esteira  (leva ao sensor de altura)
   └────────────┬────────────┘
                │ T3:  sensor_qualidade_presente   (caixa sob o leitor de altura)
                ▼
         ◇ divergência (ramo exclusivo) ◇
        /                               \
  T4a: APROVADA                     T4b: REFUGO
  (sensor_qualidade=TRUE)           (sensor_qualidade=FALSE)
        │                               │
        ▼                               ▼
 ┌──────────────┐                ┌──────────────────────┐
 │ S4  SAIDA    │ N:motor_esteira│ S5  REFUGO           │ N:motor_esteira; N:desviador
 └──────┬───────┘                └──────────┬───────────┘
        │ T5: sensor_saida                  │ T6: sensor_saida
        \_______________  convergência  ____/
                        │
                        ▼
   ┌─────────────────────────┐
   │ S6  CONTAGEM            │  P: ciclo_concluido   (pulso 1 scan)
   └────────────┬────────────┘
                │ T7:  TRUE  (incondicional, volta ao início)
                ▼
              (retorna a S0)
```

---

## Expressões para colar nas transições (ST)

| Transição | Condição |
|-----------|----------|
| T0 | `libera_peca AND sensor_entrada` |
| T1 | `sensor_posicao` |
| T2 | `tmr_usina.Q` |
| T3 | `sensor_qualidade_presente`  *(peça sob o sensor; pode ser outro sensor de presença)* |
| T4a | `sensor_qualidade`  *(aprovada)* |
| T4b | `NOT sensor_qualidade`  *(refugo)* |
| T5 | `sensor_saida` |
| T6 | `sensor_saida` |
| T7 | `TRUE` |

## Ações das etapas (ST)

| Step | Qualif. | Ação |
|------|---------|------|
| S0 | N | `produzindo := FALSE; ciclo_concluido := FALSE;` |
| S1 | N | `motor_esteira := TRUE;` |
| S2 | N | `motor_esteira := FALSE; produzindo := TRUE; tmr_usina(IN:=TRUE, PT:=T#12s);`  *(esteira parada = caixa sendo "usinada"; sem atuador)* |
| S3 | N | `motor_esteira := TRUE; produzindo := FALSE; tmr_usina(IN:=FALSE);` |
| S4 | N | `motor_esteira := TRUE;` |
| S5 | N | `motor_esteira := TRUE; desviador := TRUE;` |
| S6 | P | `ciclo_concluido := TRUE;`  *(pulso — CLP conta a peça e grava no SQL)* |

> **Regra-chave (T4.4):** a transição **T0** depende de `libera_peca`. Enquanto a
> decisão energética não liberar (PONTA sem bateria → PAUSA), o SFC fica parado em
> S0 e a próxima peça não inicia.

> **Reset de saídas:** ao sair de cada step o Codesys desativa as ações `N`
> automaticamente. Se preferir controle explícito, use um step de limpeza ou
> ações `R` no retorno a S0.
