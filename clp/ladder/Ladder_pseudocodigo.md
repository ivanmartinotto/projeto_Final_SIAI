# Ladder (LD) — Pseudocódigo para desenhar no Codesys

Conversão do SFC (T3.3). Ladder é gráfico — aqui está **rung a rung** com a
notação:

```
--| |--   contato normalmente aberto (NA / NO)   — lê TRUE quando a var é TRUE
--|/|--   contato normalmente fechado (NF / NC)  — lê TRUE quando a var é FALSE
--( )--   bobina (saída)
--(S)--   bobina SET (trava)
--(R)--   bobina RESET (destrava)
[TON]     temporizador on-delay
```

Esta versão usa **bits de etapa** (`Estapa_Sx`) para reproduzir a sequência do
SFC em LD puro — equivale a um Grafcet codificado em Ladder. Se você montar o
SFC direto no Codesys, este arquivo serve de espelho/validação.

---

## Bits internos (memória)

| Bit | Significado |
|-----|-------------|
| `Etapa_S0` ... `Etapa_S6` | etapa ativa (só uma por vez) |
| `motor_esteira`, `atuador_usina`, `desviador` | saídas físicas |
| `produzindo`, `ciclo_concluido` | flags p/ o resto do CLP |
| `libera_peca` | vem da decisão energética |

Inicialização (1º scan): `Etapa_S0 := TRUE`, demais etapas FALSE.

---

## Rungs — avanço da sequência (transições)

```
RUNG 1  (T0: S0 -> S1)   inicia se liberado e tem peça
  --|Etapa_S0|----|libera_peca|----|sensor_entrada|-----------(S)--Etapa_S1
                                                              --(R)--Etapa_S0

RUNG 2  (T1: S1 -> S2)
  --|Etapa_S1|----|sensor_posicao|-----------------------------(S)--Etapa_S2
                                                              --(R)--Etapa_S1

RUNG 3  (T2: S2 -> S3)   espera o tempo de ciclo
  --|Etapa_S2|----|tmr_usina.Q|--------------------------------(S)--Etapa_S3
                                                              --(R)--Etapa_S2

RUNG 4  (T4a: S3 -> S4, peça APROVADA)
  --|Etapa_S3|----|sensor_qualidade_presente|----|sensor_qualidade|---(S)--Etapa_S4
                                                                    --(R)--Etapa_S3

RUNG 5  (T4b: S3 -> S5, peça REFUGO)
  --|Etapa_S3|----|sensor_qualidade_presente|----|/sensor_qualidade|--(S)--Etapa_S5
                                                                    --(R)--Etapa_S3

RUNG 6  (T5: S4 -> S6)
  --|Etapa_S4|----|sensor_saida|-------------------------------(S)--Etapa_S6
                                                              --(R)--Etapa_S4

RUNG 7  (T6: S5 -> S6)
  --|Etapa_S5|----|sensor_saida|-------------------------------(S)--Etapa_S6
                                                              --(R)--Etapa_S5

RUNG 8  (T7: S6 -> S0)   incondicional, fecha o ciclo
  --|Etapa_S6|------------------------------------------------(S)--Etapa_S0
                                                              --(R)--Etapa_S6
```

## Rungs — ações (saídas por etapa)

```
RUNG 9   motor da esteira ligado em S1, S3, S4, S5
  --|Etapa_S1|--+--------------------------------------------( )--motor_esteira
  --|Etapa_S3|--+
  --|Etapa_S4|--+
  --|Etapa_S5|--+        (contatos em PARALELO = OR)

RUNG 10  usinagem + flag produzindo em S2
  --|Etapa_S2|-----------------------------------------------( )--atuador_usina
  --|Etapa_S2|-----------------------------------------------( )--produzindo

RUNG 11  temporizador da usinagem (roda enquanto S2 ativa)
  --|Etapa_S2|----------------------------[TON  PT:=T#12s]----( )--tmr_usina.Q
                                          IN          Q

RUNG 12  desviador (pistão) só no ramo de refugo (S5)
  --|Etapa_S5|-----------------------------------------------( )--desviador

RUNG 13  pulso de conclusão em S6 (CLP conta a peça / grava no SQL)
  --|Etapa_S6|-----------------------------------------------( )--ciclo_concluido
```

---

## Notas de montagem

- **Intertravamento das etapas:** o par `(S)`/`(R)` garante que só uma `Etapa_Sx`
  fique ativa. No Codesys, prefira detecção de borda nas transições se houver
  risco de re-disparo no mesmo scan.
- **`sensor_qualidade_presente`:** sensor de presença que indica a peça sob o
  leitor de qualidade. Se a sua cena do Factory IO usar um único sensor, combine
  presença + valor lógico conforme o hardware.
- **Pausa por energia:** como T0 (RUNG 1) exige `libera_peca`, basta a decisão
  energética zerar esse bit que a linha para no fim do ciclo atual e não inicia a
  próxima peça (T4.4) — sem travar no meio da usinagem.
- **Espelho do SFC:** se montar o SFC nativo do Codesys, não precisa destes rungs
  de transição (1–8); use apenas as ações (9–13) dentro dos steps. Mantido aqui
  como alternativa 100% Ladder, atendendo o RNF01 (LD para sequência).
```
