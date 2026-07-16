# OPL — Célula de Manufatura Energeticamente Autônoma
**Frente A · Processo & Documentação (Fase 1 — T1.2 · OPM)**

> Contraparte textual do OPD. Objetos e processos em destaque; estados entre aspas.

## Objetos e seus estados
1. **Ordem de Serviço** pode estar "Recebida", "Em produção", "Concluída" ou "Faturada".
2. **Estado da ONS** pode estar "Normal", "Ponta" ou "Alerta de Demanda".
3. **Bateria** exibe o SOC, que pode estar "Suficiente" ou "Insuficiente".
4. **Peças** podem estar "Bruta", "Usinada", "Aprovada" ou "Reprovada".

## Processos e seus links
5. **Decidir** requer a **Ordem de Serviço** (instrumento) e tem como condições o **Estado da ONS**, a **Tarifa** e a **Bateria**.
6. **Decidir** invoca **Consumir Energia**.
7. **Consumir Energia** requer a **Rede Elétrica**, o **Inversor** e a **Bateria** (instrumentos).
8. **Consumir Energia** invoca **Produzir**.
9. **Produzir** é executado pelo **CLP** (agente) e requer a **Estação de Usinagem** e o **Sensor** (instrumentos).
10. **Produzir** afeta as **Peças** (de "Bruta" para "Usinada", "Aprovada" ou "Reprovada").
11. **Produzir** invoca **Registrar**.
12. **Registrar** gera o **Registro de Produção**.
13. **Faturar** afeta a **Ordem de Serviço** (para "Faturada").
