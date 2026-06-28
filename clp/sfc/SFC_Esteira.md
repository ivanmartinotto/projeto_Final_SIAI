# SFC / Grafcet — Sequência da Esteira

Descrição textual da sequência física (T3.2) para você **montar no editor SFC
do Codesys**. O Codesys SFC é gráfico: aqui está a estrutura (Steps, Transitions,
Ações) e as expressões em ST para copiar nas transições/ações.

> Convenção: `S` = Step (etapa), `T` = Transition (condição p/ avançar).
> Ações de etapa usam qualificadores: `N` (não-armazenada, ativa enquanto a etapa
> estiver ativa), `S` (set), `R` (reset), `P` (pulso).

---

## Variáveis (I/O) usadas — casar com o mapa de I/O (T3.1)

| Nome | Tipo | Sentido | Significado |
|------|------|---------|-------------|
| `sensor_entrada` | BOOL | IN | Peça bruta presente na entrada |
| `sensor_posicao` | BOOL | IN | Peça posicionada na estação de usinagem |
| `sensor_qualidade` | BOOL | IN | TRUE = aprovada / FALSE = refugo |
| `sensor_saida` | BOOL | IN | Peça chegou à saída/contagem |
| `motor_esteira` | BOOL | OUT | Liga motor da esteira |
| `atuador_usina` | BOOL | OUT | Aciona furadeira/prensa |
| `desviador` | BOOL | OUT | Pistão separador (refugo) |
| `libera_peca` | BOOL | IN | Vem do `PRG_Main` (decisão energética liberou) |
| `produzindo` | BOOL | OUT | Informa ao FB de energia que está usinando |
| `ciclo_concluido` | BOOL | OUT | Pulso ao concluir a peça (CLP conta/grava) |
| `tmr_usina` | TON | — | Temporizador do tempo de ciclo da usinagem |

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
   │ S2  USINAGEM             │  N: atuador_usina ; N: produzindo
   │      (tmr_usina IN:=TRUE)│
   └────────────┬────────────┘
                │ T2:  tmr_usina.Q      (tempo de ciclo cumprido)
                ▼
   ┌─────────────────────────┐
   │ S3  INSPECAO             │  N: motor_esteira  (leva ao sensor de qualidade)
   └────────────┬────────────┘
                │ T3:  sensor_qualidade_lido   (peça sob o sensor)
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
| S2 | N | `atuador_usina := TRUE; produzindo := TRUE; tmr_usina(IN:=TRUE, PT:=T#12s);` |
| S3 | N | `motor_esteira := TRUE; atuador_usina := FALSE; produzindo := FALSE; tmr_usina(IN:=FALSE);` |
| S4 | N | `motor_esteira := TRUE;` |
| S5 | N | `motor_esteira := TRUE; desviador := TRUE;` |
| S6 | P | `ciclo_concluido := TRUE;`  *(pulso — CLP conta a peça e grava no SQL)* |

> **Regra-chave (T4.4):** a transição **T0** depende de `libera_peca`. Enquanto a
> decisão energética não liberar (PONTA sem bateria → PAUSA), o SFC fica parado em
> S0 e a próxima peça não inicia.

> **Reset de saídas:** ao sair de cada step o Codesys desativa as ações `N`
> automaticamente. Se preferir controle explícito, use um step de limpeza ou
> ações `R` no retorno a S0.
