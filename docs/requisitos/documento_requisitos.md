# Documento de Requisitos Detalhado

## Projeto Final — Sistemas de Integração e Automação Industrial

**Projeto:** Célula de Manufatura Energeticamente Autônoma
**Disciplina:** Sistemas de Integração e Automação Industrial
**Versão:** 1.0
**Data:** 02/07/2026

---

## 1. Introdução

Este documento apresenta os requisitos detalhados do projeto **Célula de Manufatura Energeticamente Autônoma**, desenvolvido como projeto final da disciplina de Sistemas de Integração e Automação Industrial.

O sistema proposto consiste em uma célula de manufatura simulada, composta por uma linha de transporte, estação de processamento, inspeção de qualidade, separação de peças aprovadas e rejeitadas, além de integração com lógica de decisão energética. A célula deve decidir automaticamente se deve produzir utilizando energia da rede, utilizar bateria ou pausar a produção, considerando fatores como tarifa de energia, estado da ONS, horário de ponta, estado de carga da bateria e existência de ordem de serviço pendente.

O objetivo do documento é formalizar os requisitos funcionais, requisitos não funcionais, regras de negócio, restrições, entradas, saídas e critérios de aceitação necessários para orientar o desenvolvimento, validação e apresentação do sistema.

---

## 2. Objetivo do Sistema

O objetivo principal do sistema é demonstrar a integração entre automação industrial, controle em CLP, supervisão SCADA, banco de dados, simulação de planta industrial e tomada de decisão energética.

A célula deve ser capaz de:

* Receber uma ordem de serviço.
* Executar a produção de peças em uma linha simulada.
* Inspecionar peças e separar aprovadas de refugos.
* Monitorar consumo energético, tarifa, SOC da bateria e estado da ONS.
* Decidir automaticamente entre produzir pela rede, produzir pela bateria ou pausar.
* Registrar dados de produção, consumo e eventos em banco de dados.
* Exibir informações operacionais e energéticas em uma interface supervisória.

---

## 3. Escopo do Projeto

### 3.1 Dentro do escopo

Fazem parte do escopo do projeto:

* Modelagem do processo produtivo.
* Simulação de uma linha de manufatura.
* Controle sequencial da esteira e estações da célula.
* Implementação de lógica de decisão energética.
* Simulação de dados da ONS.
* Integração com CLP.
* Integração com SCADA.
* Registro de dados em banco SQL.
* Apresentação de indicadores de produção e energia.
* Geração de histórico para auditoria.

### 3.2 Fora do escopo

Não fazem parte do escopo:

* Uso de equipamentos industriais reais.
* Integração com ONS real.
* Medição física real de energia.
* Controle de uma usina solar real.
* Controle de uma bateria física real.
* Implementação de segurança industrial certificada.
* Otimização avançada por inteligência artificial.

---

## 4. Visão Geral da Arquitetura

O sistema será dividido nos seguintes módulos:

1. **Planta simulada:** representa a linha de manufatura, sensores, atuadores, esteiras, estação de processamento e separação de peças.
2. **CLP:** executa a lógica de controle sequencial, intertravamentos e decisão energética.
3. **Simulador ONS:** fornece dados simulados de estado da rede, tarifa e horário.
4. **SCADA:** permite supervisão do processo, visualização de alarmes, indicadores e comandos.
5. **Banco de dados SQL:** registra ordens de serviço, produção, consumo energético e eventos da ONS.
6. **Interface de operação:** permite acompanhar o estado da célula, produção e decisões tomadas.

---

## 5. Atores do Sistema

| Ator           | Descrição                                                                                                            |
| -------------- | -------------------------------------------------------------------------------------------------------------------- |
| Operador       | Usuário que acompanha a produção, cria ou acompanha ordens de serviço e visualiza alarmes.                           |
| CLP            | Responsável pelo controle da planta, leitura de sensores, acionamento de atuadores e execução das regras de decisão. |
| Simulador ONS  | Módulo que fornece informações simuladas sobre tarifa, horário e condição da rede elétrica.                          |
| SCADA          | Sistema de supervisão que exibe informações do processo e permite acompanhamento da célula.                          |
| Banco de Dados | Sistema responsável por armazenar informações históricas de produção, consumo e eventos.                             |

---

## 6. Requisitos Funcionais

### RF-01 — Gerenciar Ordem de Serviço

**Descrição:**
O sistema deve permitir o registro e acompanhamento de uma ordem de serviço contendo cliente, quantidade solicitada, quantidade produzida, quantidade de refugo, status e custo total.

**Entradas:**
Cliente, quantidade pedida e comando de início de produção.

**Saídas:**
Status da ordem de serviço, quantidade produzida, quantidade rejeitada e custo acumulado.

**Prioridade:** Alta.

**Critério de aceitação:**
Ao iniciar uma ordem de serviço, o sistema deve alterar seu status para em produção e atualizar os dados conforme as peças forem processadas.

---

### RF-02 — Verificar existência de OS pendente

**Descrição:**
O sistema deve verificar se existe uma ordem de serviço aberta ou em produção antes de liberar o início de uma nova peça.

**Entradas:**
Status da ordem de serviço e quantidade pendente.

**Saídas:**
Sinal de autorização ou bloqueio de produção.

**Prioridade:** Alta.

**Critério de aceitação:**
A célula só deve iniciar uma nova peça se existir quantidade pendente na ordem de serviço.

---

### RF-03 — Ler estado da ONS

**Descrição:**
O sistema deve receber do simulador ONS o estado atual da rede elétrica, podendo assumir estados como normal, horário de ponta ou alerta de demanda.

**Entradas:**
Estado informado pelo simulador ONS.

**Saídas:**
Estado da rede disponível para a lógica de decisão energética.

**Prioridade:** Alta.

**Critério de aceitação:**
Quando o estado da ONS for alterado no simulador, o CLP deve considerar essa informação antes de iniciar o próximo ciclo de produção.

---

### RF-04 — Ler tarifa de energia

**Descrição:**
O sistema deve ler a tarifa de energia vigente, informada pelo simulador ONS, e utilizá-la no cálculo de custo de produção por peça.

**Entradas:**
Tarifa vigente em R$/kWh.

**Saídas:**
Tarifa atual disponível para cálculo energético.

**Prioridade:** Alta.

**Critério de aceitação:**
Ao alterar a tarifa no simulador, o custo por peça calculado pelo sistema deve refletir o novo valor.

---

### RF-05 — Monitorar SOC da bateria

**Descrição:**
O sistema deve monitorar o estado de carga da bateria, representado em porcentagem.

**Entradas:**
SOC atual da bateria.

**Saídas:**
Valor de SOC exibido no SCADA e utilizado na decisão energética.

**Prioridade:** Alta.

**Critério de aceitação:**
Se o SOC estiver abaixo do limite mínimo definido, o sistema não deve permitir produção utilizando bateria.

---

### RF-06 — Decidir fonte de energia

**Descrição:**
O sistema deve decidir automaticamente se a célula irá produzir utilizando energia da rede, energia da bateria ou se deverá pausar a produção.

**Entradas:**
Estado da ONS, tarifa, SOC da bateria, existência de OS pendente e parâmetros energéticos da célula.

**Saídas:**
Comando de produção pela rede, produção pela bateria ou pausa.

**Prioridade:** Alta.

**Critério de aceitação:**
Em condição normal, o sistema deve permitir produção pela rede. Em horário de ponta ou alerta de demanda, o sistema deve avaliar o SOC e decidir entre bateria ou pausa.

---

### RF-07 — Executar sequência da esteira

**Descrição:**
O sistema deve controlar a sequência da esteira, transportando a peça entre as etapas de entrada, processamento, inspeção e saída.

**Entradas:**
Sensores de presença, comando de liberação de peça e estado da decisão energética.

**Saídas:**
Acionamento da esteira e avanço da peça pelas etapas.

**Prioridade:** Alta.

**Critério de aceitação:**
A peça deve percorrer a sequência correta da linha apenas quando a produção estiver liberada.

---

### RF-08 — Executar processamento da peça

**Descrição:**
O sistema deve simular a etapa de processamento ou usinagem da peça, considerada a etapa de maior consumo energético da célula.

**Entradas:**
Peça posicionada na estação de processamento e autorização de produção.

**Saídas:**
Peça processada e liberada para inspeção.

**Prioridade:** Alta.

**Critério de aceitação:**
A etapa de processamento deve ser executada somente quando a célula estiver autorizada a produzir.

---

### RF-09 — Inspecionar qualidade da peça

**Descrição:**
O sistema deve inspecionar a peça processada e classificá-la como aprovada ou refugo.

**Entradas:**
Sinal do sensor de inspeção ou condição simulada de qualidade.

**Saídas:**
Resultado da inspeção: aprovada ou refugo.

**Prioridade:** Alta.

**Critério de aceitação:**
Toda peça processada deve receber uma classificação antes de ser encaminhada à saída correta.

---

### RF-10 — Separar peça aprovada e refugo

**Descrição:**
O sistema deve direcionar automaticamente peças aprovadas para a saída de produto final e peças rejeitadas para a área de refugo.

**Entradas:**
Resultado da inspeção.

**Saídas:**
Acionamento do mecanismo de separação.

**Prioridade:** Alta.

**Critério de aceitação:**
Peças aprovadas e refugadas devem ser contabilizadas separadamente.

---

### RF-11 — Contabilizar produção

**Descrição:**
O sistema deve atualizar a quantidade de peças produzidas e refugadas após cada ciclo finalizado.

**Entradas:**
Pulso de peça concluída e resultado da inspeção.

**Saídas:**
Quantidade produzida, quantidade de refugo e progresso da OS.

**Prioridade:** Alta.

**Critério de aceitação:**
Ao finalizar uma peça, o sistema deve atualizar automaticamente os contadores de produção.

---

### RF-12 — Calcular custo por peça

**Descrição:**
O sistema deve calcular o custo energético por peça com base na potência da estação, tempo de ciclo, tarifa e eficiência considerada.

**Entradas:**
Potência, tempo de ciclo, tarifa e eficiência.

**Saídas:**
Custo estimado por peça.

**Prioridade:** Média.

**Critério de aceitação:**
O custo por peça deve ser atualizado sempre que a tarifa ou os parâmetros energéticos forem alterados.

---

### RF-13 — Registrar produção no banco de dados

**Descrição:**
O sistema deve registrar no banco de dados cada peça finalizada, informando ordem de serviço, resultado, fonte de energia, custo por peça e tempo de ciclo.

**Entradas:**
Dados do ciclo de produção.

**Saídas:**
Registro na tabela de produção.

**Prioridade:** Alta.

**Critério de aceitação:**
Cada peça finalizada deve gerar um registro persistente no banco de dados.

---

### RF-14 — Registrar consumo energético

**Descrição:**
O sistema deve registrar periodicamente informações de consumo energético, incluindo potência, energia consumida, fonte de energia, SOC da bateria e geração solar simulada.

**Entradas:**
Dados energéticos da célula.

**Saídas:**
Registro na tabela de consumo.

**Prioridade:** Média.

**Critério de aceitação:**
O banco deve possuir histórico de consumo suficiente para análise posterior.

---

### RF-15 — Registrar eventos da ONS

**Descrição:**
O sistema deve registrar eventos relacionados ao estado da ONS, tarifa vigente e ação tomada pela célula.

**Entradas:**
Estado da ONS, tarifa e decisão energética.

**Saídas:**
Registro de evento no banco de dados.

**Prioridade:** Média.

**Critério de aceitação:**
Cada mudança relevante de estado ou decisão energética deve ser registrada para auditoria.

---

### RF-16 — Exibir status no SCADA

**Descrição:**
O sistema deve exibir no SCADA o estado atual da célula, incluindo produção, OS, fonte de energia, estado da ONS, tarifa, SOC e alarmes.

**Entradas:**
Variáveis do CLP, banco e simulador ONS.

**Saídas:**
Telas supervisórias atualizadas.

**Prioridade:** Alta.

**Critério de aceitação:**
O operador deve conseguir visualizar claramente se a célula está produzindo, pausada, usando rede ou usando bateria.

---

### RF-17 — Gerar alarmes operacionais

**Descrição:**
O sistema deve gerar alarmes quando houver condição crítica, como SOC baixo, alerta de demanda, produção pausada ou ausência de ordem de serviço.

**Entradas:**
Estados operacionais e energéticos.

**Saídas:**
Alarmes exibidos no SCADA.

**Prioridade:** Média.

**Critério de aceitação:**
Condições críticas devem ser sinalizadas ao operador de forma clara.

---

### RF-18 — Finalizar ordem de serviço

**Descrição:**
O sistema deve finalizar a ordem de serviço quando a quantidade produzida atingir a quantidade solicitada.

**Entradas:**
Quantidade pedida e quantidade produzida.

**Saídas:**
Status da OS alterado para concluída.

**Prioridade:** Alta.

**Critério de aceitação:**
Ao atingir a quantidade solicitada, o sistema não deve iniciar novas peças para a mesma OS.

---

## 7. Requisitos Não Funcionais

### RNF-01 — Modularidade

O sistema deve ser organizado em módulos independentes, separando lógica de decisão energética, controle da esteira, comunicação ONS, supervisão e banco de dados.

**Prioridade:** Alta.

---

### RNF-02 — Clareza e manutenibilidade

O código e os documentos devem ser escritos de forma clara, comentada e organizada, permitindo entendimento por todos os integrantes do grupo.

**Prioridade:** Alta.

---

### RNF-03 — Rastreabilidade

Os requisitos devem estar relacionados às funcionalidades implementadas no CLP, SCADA, simulador e banco de dados.

**Prioridade:** Alta.

---

### RNF-04 — Simulação

O sistema deve ser validado por meio de simulação, sem necessidade de equipamentos industriais reais.

**Prioridade:** Alta.

---

### RNF-05 — Persistência de dados

As informações relevantes de produção, consumo e eventos devem ser armazenadas de forma persistente em banco SQL.

**Prioridade:** Alta.

---

### RNF-06 — Tempo de resposta

A decisão energética deve ser tomada antes do início de um novo ciclo de produção, evitando que a célula inicie uma peça em condição energética inadequada.

**Prioridade:** Média.

---

### RNF-07 — Segurança lógica

O sistema deve evitar comandos conflitantes, como uso simultâneo indevido de rede e bateria para a mesma função de alimentação simulada.

**Prioridade:** Alta.

---

### RNF-08 — Portabilidade

Sempre que possível, os módulos devem ser implementados de forma que possam ser adaptados para outros bancos SQL, simuladores ou ambientes de supervisão.

**Prioridade:** Baixa.

---

## 8. Regras de Negócio

### RN-01 — Produção condicionada à OS

A célula somente pode iniciar a produção se existir uma ordem de serviço aberta ou em produção com quantidade pendente.

---

### RN-02 — Produção em condição normal

Quando o estado da ONS estiver normal, a célula pode produzir utilizando energia da rede.

---

### RN-03 — Produção em horário de ponta

Quando o sistema estiver em horário de ponta, a célula deve avaliar a tarifa e o SOC da bateria antes de iniciar uma nova peça.

---

### RN-04 — Uso da bateria

A bateria só pode ser utilizada se o SOC estiver acima do limite mínimo configurado.

---

### RN-05 — Pausa energética

Se a ONS estiver em alerta de demanda ou horário de ponta e a bateria não possuir SOC suficiente, o sistema deve pausar o início de novas peças.

---

### RN-06 — Não interrupção de peça em processamento

Caso uma peça já esteja em processamento, a pausa energética não deve interromper abruptamente o ciclo atual. A decisão de pausa deve impedir o início da próxima peça.

---

### RN-07 — Registro obrigatório de produção

Toda peça concluída deve gerar registro de produção, contendo resultado, fonte de energia e custo estimado.

---

### RN-08 — Registro obrigatório de evento energético

Toda decisão relevante de produzir pela rede, produzir pela bateria ou pausar deve ser registrada para rastreabilidade.

---

## 9. Requisitos de Dados

### RD-01 — Ordem de Serviço

O sistema deve armazenar:

* Identificador da OS.
* Cliente.
* Quantidade solicitada.
* Quantidade produzida.
* Quantidade de refugo.
* Status.
* Custo total.
* Data de criação.
* Data de conclusão.

---

### RD-02 — Produção

O sistema deve armazenar:

* Identificador da produção.
* Ordem de serviço associada.
* Data e hora do ciclo.
* Resultado da peça.
* Fonte de energia utilizada.
* Custo por peça.
* Tempo de ciclo.

---

### RD-03 — Consumo Energético

O sistema deve armazenar:

* Potência instantânea.
* Energia consumida.
* Fonte de energia.
* SOC da bateria.
* Geração solar simulada.
* Data e hora da amostra.

---

### RD-04 — Evento ONS

O sistema deve armazenar:

* Estado da ONS.
* Tarifa vigente.
* Ação tomada pelo sistema.
* Data e hora do evento.

---

## 10. Requisitos de Interface SCADA

### RI-01 — Tela geral da célula

A interface deve mostrar:

* Estado da célula.
* Esteira em operação ou parada.
* Etapa atual da peça.
* Quantidade produzida.
* Quantidade de refugo.
* Status da OS.

---

### RI-02 — Tela energética

A interface deve mostrar:

* Estado da ONS.
* Tarifa atual.
* Fonte de energia em uso.
* SOC da bateria.
* Geração solar simulada.
* Custo por peça.

---

### RI-03 — Tela de alarmes

A interface deve mostrar alarmes como:

* SOC baixo.
* Alerta de demanda.
* Produção pausada.
* OS inexistente.
* Falha ou ausência de comunicação.

---

### RI-04 — Histórico

A interface deve permitir consulta ou visualização de registros históricos de produção, consumo e eventos energéticos.

---

## 11. Requisitos de Comunicação

### RC-01 — Comunicação com simulador ONS

O CLP ou sistema intermediário deve receber dados simulados da ONS, incluindo estado da rede, tarifa e horário.

---

### RC-02 — Comunicação entre CLP e planta simulada

O CLP deve trocar sinais com a planta simulada, lendo sensores e acionando atuadores.

---

### RC-03 — Comunicação com banco de dados

O sistema deve registrar informações relevantes em banco SQL para posterior consulta e auditoria.

---

### RC-04 — Comunicação com SCADA

O SCADA deve ler variáveis operacionais e energéticas para exibição ao operador.

---

## 12. Restrições do Projeto

* O projeto deve ser desenvolvido em ambiente simulado.
* A lógica principal deve ser compatível com controle industrial em CLP.
* A planta deve representar uma linha de manufatura simples e compreensível.
* A decisão energética deve ser baseada em regras claras e justificáveis.
* O banco de dados deve armazenar dados suficientes para demonstrar histórico e rastreabilidade.
* A interface supervisória deve priorizar clareza para apresentação acadêmica.

---

## 13. Critérios Gerais de Aceitação

O projeto será considerado funcional se:

1. Uma ordem de serviço puder ser acompanhada do início ao fim.
2. A linha simulada processar peças em sequência.
3. As peças forem classificadas como aprovadas ou refugo.
4. O sistema decidir corretamente entre rede, bateria e pausa.
5. O estado da ONS e a tarifa influenciarem a decisão.
6. O SOC da bateria impedir uso inadequado da bateria.
7. O SCADA exibir informações operacionais e energéticas.
8. O banco SQL registrar produção, consumo e eventos.
9. A célula parar de iniciar novas peças quando a OS for concluída.
10. O sistema apresentar rastreabilidade suficiente para explicar as decisões tomadas.

---

## 14. Matriz de Rastreabilidade

| Requisito | Módulo relacionado                |
| --------- | --------------------------------- |
| RF-01     | Banco de dados, SCADA             |
| RF-02     | CLP, ordem de serviço             |
| RF-03     | Simulador ONS, CLP                |
| RF-04     | Simulador ONS, decisão energética |
| RF-05     | Gestão de energia, SCADA          |
| RF-06     | CLP, decisão energética           |
| RF-07     | CLP, planta simulada              |
| RF-08     | CLP, planta simulada              |
| RF-09     | Planta simulada, inspeção         |
| RF-10     | Planta simulada, atuadores        |
| RF-11     | CLP, banco de dados               |
| RF-12     | Decisão energética                |
| RF-13     | Banco de dados                    |
| RF-14     | Banco de dados, gestão de energia |
| RF-15     | Banco de dados, ONS               |
| RF-16     | SCADA                             |
| RF-17     | SCADA, CLP                        |
| RF-18     | Ordem de serviço, CLP             |

---

## 15. Glossário

| Termo             | Descrição                                                                        |
| ----------------- | -------------------------------------------------------------------------------- |
| CLP               | Controlador Lógico Programável, responsável pela automação da célula.            |
| SCADA             | Sistema supervisório usado para monitoramento e operação.                        |
| ONS               | Operador Nacional do Sistema Elétrico, representado no projeto por um simulador. |
| SOC               | State of Charge, estado de carga da bateria em porcentagem.                      |
| OS                | Ordem de Serviço.                                                                |
| Refugo            | Peça rejeitada após inspeção de qualidade.                                       |
| Tarifa            | Valor da energia elétrica utilizado no cálculo de custo.                         |
| Horário de ponta  | Período de maior custo ou maior demanda energética.                              |
| Alerta de demanda | Estado crítico simulado da rede elétrica.                                        |

---

## 16. Histórico de Versões

| Versão | Data       | Descrição                                            | Autor             |
| ------ | ---------- | ---------------------------------------------------- | ----------------- |
| 1.0    | 02/07/2026 | Criação inicial do documento de requisitos detalhado | Equipe do projeto |
