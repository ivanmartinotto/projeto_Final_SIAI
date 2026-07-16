# Célula de Manufatura Energeticamente Autônoma — Escopo do Projeto

> Linha de produção automatizada alimentada por fonte própria (solar/bateria) que decide **quando produzir** com base no custo da energia e nas ordens de serviço, integrando modelagem de processo (BPMN/OPM), regras da ONS, controle no CLP (IEC 61131-3) e supervisão SCADA.

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Processo Sugerido (a planta)](#2-processo-sugerido-a-planta)
3. [Requisitos](#3-requisitos)
4. [Decisões Técnicas](#4-decisões-técnicas)
5. [Arquitetura do Sistema](#5-arquitetura-do-sistema)
6. [Estrutura do Repositório](#6-estrutura-do-repositório)
7. [Roadmap de Implementação (fases e tarefas)](#7-roadmap-de-implementação-fases-e-tarefas)

---

## 1. Visão Geral

O objetivo é demonstrar domínio do ciclo completo: **planejar o negócio** (BPMN), **arquitetar o sistema** (OPM) e **executar a engenharia** (CLP + SCADA), com o diferencial de **eficiência energética e integração com a rede elétrica** (Indústria 4.0).

A "inteligência" do projeto está em uma regra simples: a célula só produz quando vale a pena energeticamente. Em **horário de ponta** ou sob **alerta de alta demanda da ONS**, a célula pausa a produção ou migra o consumo para a **bateria**, dependendo do estado de carga (SOC). Fora da ponta, produz direto da rede.

**O que entregamos no fim:**
- Documento de requisitos e design
- Diagramas BPMN e OPM
- Código do CLP (ST + SFC) e algoritmo de decisão
- Planta simulada (Factory IO) integrada
- Apresentação final

---

## 2. Processo Sugerido (a planta)

Para não complicar, sugerimos um processo genérico e fácil de mapear no Factory IO:

### Linha de Usinagem e Inspeção de Peças

Uma peça bruta entra na esteira, passa por uma estação de processamento (que representa a usinagem — **o grande consumidor de energia**, o que dá sentido à decisão energética), é inspecionada por um sensor e separada entre saída (aprovada) e refugo (reprovada).

**Etapas físicas da esteira:**

| # | Etapa | Atuador / Sensor | Observação |
|---|-------|------------------|------------|
| 1 | **Alimentação** | Sensor de presença (entrada) | Detecta peça bruta na esteira |
| 2 | **Transporte 1** | Motor da esteira | Leva a peça até a estação |
| 3 | **Usinagem (simulada)** | Atuador da estação (ex.: furadeira/prensa) + sensor de posição | Processo de maior consumo; tem tempo de ciclo fixo |
| 4 | **Inspeção** | Sensor de qualidade (ex.: óptico/altura) | Aprova ou reprova a peça |
| 5 | **Separação** | Desviador (pistão) + sensores de saída | Aprovada → saída; reprovada → refugo |
| 6 | **Saída/Contagem** | Sensor de saída | Conta peças produzidas |

---

## 3. Requisitos

### 3.1 Requisitos Funcionais (RF)

| ID | Requisito |
|----|-----------|
| RF01 | Receber e registrar uma **Ordem de Serviço (OS)** com quantidade de peças a produzir |
| RF02 | Ler dados (simulados) de **tarifa de energia** e **status da rede ONS** (horário de ponta / alerta de demanda) |
| RF03 | Calcular o **custo por peça** com base na potência da máquina, tempo de ciclo, tarifa atual e eficiência |
| RF04 | **Decidir** entre: produzir da rede, produzir da bateria, ou pausar/enfileirar a produção |
| RF05 | Disparar a **sequência física da esteira** no CLP (alimentação → usinagem → inspeção → separação) |
| RF06 | Monitorar **sensores** e atuar nos **atuadores** da linha em tempo real |
| RF07 | Gerenciar a fonte própria: leitura de **SOC da bateria** e geração solar (simulada), e chaveamento rede/bateria |
| RF08 | Exibir no **SCADA** o estado da linha, consumo, alarmes da ONS e progresso da OS |
| RF09 | **Registrar** produção e consumo em **banco SQL** para auditoria |
| RF10 | Emitir o **faturamento/fechamento** da OS ao concluir a quantidade pedida |

### 3.2 Requisitos Não-Funcionais (RNF)

| ID | Requisito |
|----|-----------|
| RNF01 | Programação do CLP em conformidade com a **IEC 61131-3** (ST para lógica/matemática; SFC para sequência). Ladder descartado por redundância — o SFC já atende a exigência de linguagem de sequência |
| RNF02 | Usar **softwares gratuitos/acadêmicos**: Factory IO, Codesys, ScadaBR (ou Elipse) |
| RNF03 | A simulação de tarifa/ONS deve permitir **trocar de cenário** facilmente (ponta/fora de ponta/alerta) para demonstração |
| RNF04 | O sistema deve responder a um alerta da ONS em **tempo de ciclo curto** (pausar/migrar antes de iniciar a próxima peça) |
| RNF05 | Código versionado no **GitHub**, com documentação clara e diagramas exportados (PNG/PDF + fonte editável) |
| RNF06 | Comunicação entre Factory IO ↔ CLP ↔ SCADA via protocolo suportado (ex.: **Modbus TCP** ou OPC) |

### 3.3 Premissas e Simplificações

- Geração solar, SOC da bateria e tarifas são **simulados** (não há hardware real).
- O "faturamento" é um registro/relatório, não integração fiscal real.
- O cenário da ONS é simplificado em estados discretos (ex.: `NORMAL`, `PONTA`, `ALERTA_DEMANDA`).

---

## 4. Decisões Técnicas

| Camada | Ferramenta sugerida | Justificativa |
|--------|---------------------|---------------|
| Planta (chão de fábrica) | **Factory IO** | Simula a linha física, sensores e atuadores; integra via Modbus/OPC |
| CLP | **Codesys** | IDE gratuita, suporta ST, SFC e Ladder (IEC 61131-3); driver Modbus/OPC nativo |
| Modelagem BPMN | **bizagi Modeler / Camunda Modeler** | Gratuitos, exportam BPMN 2.0 |
| Modelagem OPM | **OPCloud** (ou edição manual em draw.io seguindo a notação) | Ferramenta oficial de OPM; draw.io como alternativa |
| Comunicação | **Modbus TCP** | Padrão simples e suportado por Factory IO, Codesys e ScadaBR |

---

## 5. Arquitetura do Sistema

Fluxo de informação entre as camadas:

```
   [Cliente / OS]
        |
        v
  +-----------------------+        +------------------------+
  |  Camada de Negócio    |  --->  |  Simulação ONS         |
  |  (BPMN: recebe OS,    |        |  (tarifa, ponta,       |
  |   fatura, fecha OS)    |       |   alerta de demanda)   |
  +-----------------------+        +------------------------+
        |                                   |
        v                                   v
  +---------------------------------------------------+
  |  CLP (Codesys)                                     |
  |  - ST: cálculo de custo/peça, decisão energética   |
  |  - SFC: sequência da esteira                       |
  |  - Gestão rede/bateria (SOC)                       |
  +---------------------------------------------------+
        |  Modbus TCP                 
        v                              
  +---------------------+     
  |  Factory IO         |     
  |  (planta física:    |     
  |   sensores/atuadores)|     
  +---------------------+     
```

---

## 6. Estrutura do Repositório

```
/
├── README.md                  # visão geral + este escopo (ou link para ele)
├── ESCOPO_PROJETO.md          # este documento
├── docs/
│   ├── requisitos/            # documento de requisitos detalhado
│   ├── bpmn/                  # .bpmn + PNG/PDF exportados
│   └── opm/                   # diagramas OPM + OPL
├── clp/
│   ├── projeto_codesys/       # projeto Codesys
│   ├── st/                    # trechos de Texto Estruturado
│   └── sfc/                   # Grafcet/SFC
├── ons/
│   └── simulador/             # script/planilha que gera tarifa e estados da rede
└─ factoryio/
   └── cena/                  # arquivo da cena + prints

```

---

## 7. Roadmap de Implementação (fases e tarefas)

Cada fase segue a lógica **requisitos → decisões técnicas → diagramas → código → simulação/teste**. As tarefas têm IDs para facilitar o rastreio (issues/board do GitHub).

### Fase 0 — Setup e Alinhamento
| ID | Tarefa | Descrição |
|----|--------|-----------|
| T0.1 | Criar repositório e estrutura de pastas | Subir este documento e a estrutura da seção 6 |
| T0.2 | Instalar e validar softwares | Factory IO, Codesys, ScadaBR, banco SQL e ferramentas de modelagem |
| T0.3 | Definir protocolo e versões | Fechar Modbus vs OPC, versões e banco; registrar na seção 4 |
| T0.4 | Validar este escopo em grupo | Ajustar processo, requisitos e divisão de tarefas |

### Fase 1 — Modelagem de Processo (BPMN + OPM)
| ID | Tarefa | Descrição |
|----|--------|-----------|
| T1.1 | **BPMN** ponta a ponta | Modelar: entrada da OS → verificação ONS → decisão energética → ordem ao CLP → produção → registro → faturamento. Incluir gateway de decisão (produzir/bateria/pausar) |
| T1.2 | **OPM** — objetos e processos | Objetos físicos (CLP, Peça, Sensor, Inversor, Bateria) e informacionais (Preço da Energia, Status, OS); processos (Usinar, Monitorar, Consumir, Decidir). Gerar o diagrama (OPD) e o texto (OPL) |
| T1.3 | Exportar diagramas | PNG/PDF + arquivo-fonte em `docs/bpmn` e `docs/opm` |
| T1.4 | Revisão cruzada | Verificar se BPMN e OPM são consistentes entre si e com os requisitos |

### Fase 2 — Camada de Regulação ONS
| ID | Tarefa | Descrição |
|----|--------|-----------|
| T2.1 | Definir modelo de dados da ONS | Estados (`NORMAL`/`PONTA`/`ALERTA_DEMANDA`) + tarifa associada a cada um |
| T2.2 | Construir o simulador | Script/planilha que entrega tarifa e estado em "tempo real" (ex.: por horário simulado) ao CLP/SCADA |
| T2.3 | Definir regra de resposta à demanda | Em PONTA/ALERTA → migrar para bateria se SOC suficiente, senão pausar |
| T2.4 | Teste isolado da ONS | Verificar que o simulador troca de estado e que o sinal chega ao CLP |

### Fase 3 — Programação do CLP (sequência física)
| ID | Tarefa | Descrição |
|----|--------|-----------|
| T3.1 | Mapear I/O | Lista de sensores/atuadores e endereços Modbus entre Factory IO e Codesys |
| T3.2 | **SFC (Grafcet)** da esteira | Sequência: alimentação → transporte → usinagem → inspeção → separação → contagem |
| ~~T3.3~~ | ~~Converter SFC → Ladder~~ | **Removido** — Ladder redundante com o SFC (RNF01 já atendido) |
| T3.4 | Integrar com Factory IO | Conectar via Modbus e validar movimento da linha |
| T3.5 | Teste da sequência | Rodar um ciclo completo de peça (aprovada e reprovada) |

### Fase 4 — Algoritmo de Decisão Energética
| ID | Tarefa | Descrição |
|----|--------|-----------|
| T4.1 | **ST** — cálculo de custo/peça | `Custo = (Potência × Tempo_ciclo × Tarifa) / Eficiência`. Parametrizar valores |
| T4.2 | **ST** — lógica de decisão | Entradas: estado ONS, tarifa, SOC bateria, OS pendente → saída: rede / bateria / pausa |
| T4.3 | **ST** — gestão rede/bateria | Chaveamento e atualização (simulada) do SOC conforme consumo/geração |
| T4.4 | Integrar decisão à sequência | A esteira só inicia a próxima peça se a decisão liberar |
| T4.5 | Teste dos cenários | Validar comportamento em NORMAL, PONTA e ALERTA_DEMANDA |

### Fase 5 — Integração e Testes de Ponta a Ponta
| ID | Tarefa | Descrição |
|----|--------|-----------|
| T6.1 | Teste integrado | Fluxo completo: OS → ONS → decisão → produção |
| T6.2 | Roteiros de cenário | Executar e documentar: fora de ponta (produz da rede), ponta com bateria, alerta sem bateria (pausa) |
| T6.3 | Ajustes finais | Corrigir bugs de comunicação/lógica encontrados na integração |

### Fase 6 — Documentação e Apresentação
| ID | Tarefa | Descrição |
|----|--------|-----------|
| T7.1 | Documento de requisitos | Consolidar a seção 3 expandida em `docs/requisitos` |
| T7.2 | Documento de design | Arquitetura, decisões e diagramas em `docs/design` |
| T7.3 | Slides finais | Visão macro (BPMN/OPM) + micro (CLP/SCADA) + demonstração dos cenários |
| T7.4 | Gravar demonstração | Vídeo/prints da célula respondendo aos cenários da ONS |