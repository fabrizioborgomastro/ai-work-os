# Contratti di routing

I nomi delle route sono API logiche di AI Work OS. Il router è sostituibile e i modelli possono cambiare; restano stabili finalità, privacy e comportamento.

## `business-engineering`

- uso: Wayfinder, architettura e implementazione Business;
- strategia: priorità/fallback, non panel;
- requisiti: tool use affidabile, reasoning, nessun endpoint free, policy privacy Business;
- profilo raccomandato: GPT-5.6 Sol come primario; DeepSeek V4 Flash e GLM-5.2 come complementari economici; Kimi K3 come escalation opzionale.

## `business-review`

- uso: review indipendente ai gate;
- strategia: panel parallelo più giudice esplicito;
- requisiti: nessun endpoint free, panel di 2–3 famiglie diverse, giudice non duplicato nel panel, tool disabilitati;
- profilo raccomandato: GLM-5.2, DeepSeek V4 Flash e MiMo V2.5 Pro; Kimi K3 come giudice;
- quorum minimo: 2.

## `light-engineering`

- uso: pianificazione e build Light;
- strategia: free espliciti in priorità, poi paid floor economico;
- requisiti: mai usare su materiale sensibile o proprietario;
- profilo raccomandato: DeepSeek V4 Flash Free, Laguna S Free, Nemotron Free, DeepSeek V4 Flash paid.

## `light-review`

- uso: review mirata di milestone Light;
- strategia: piccolo panel economico più giudice;
- profilo raccomandato: Laguna S Free, Nemotron Free e MiMo V2.5 Pro; GLM-5.2 come giudice;
- quorum minimo: 1.

## Sostituzione dei modelli

Un adapter può sostituire un modello quando non è disponibile, purché documenti:

- ruolo sostituito;
- costo e contesto;
- capacità di tool/reasoning;
- politica dati e training;
- data dell'ultima verifica.

Per Business, `paid` non implica `private`: ZDR/no-training e provider eleggibili devono essere verificati separatamente.
