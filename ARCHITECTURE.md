# Architettura di AI Work OS

## Separazione tra processo, agenti e routing

Il sistema ha tre livelli:

1. **Core portabile** — contratti, gate, budget, evidence package e stato del progetto. Non contiene sintassi Kilo o OmniRoute.
2. **Agenti** — ruoli distinti per pianificazione, implementazione e review. Ogni ruolo ha un contratto di input/output verificabile.
3. **Adapter** — traducono i contratti verso client, router e tracker specifici.
4. **Routing** — quattro route logiche indipendenti dal router. Cambiare provider non cambia il processo.

Questa separazione impedisce dipendenze da Kilo, OpenCode, Pi, OmniRoute o GitHub. Un altro ambiente deve tradurre i file in `core/agents/`, preservare permessi e handoff e mappare le route su modelli equivalenti.

## Wayfinder

Wayfinder viene usato secondo il principio **plan, don't do**:

- nomina una destinazione;
- crea una mappa sul tracker;
- tratta decisioni, non tranche di implementazione;
- lavora al massimo un ticket decisionale per sessione, salvo ticket di ricerca;
- passa all'esecuzione soltanto quando non restano decisioni architetturali necessarie.

Al primo utilizzo Wayfinder chiede se usare Markdown locale o GitHub Issues. La modalità di collegamento a GitHub è scelta tra le integrazioni ufficiali disponibili nel client; MCP è opzionale. La scelta e l'adapter sono registrati nel progetto.

## Business

Flusso:

```text
business-wayfinder -> handoff persistente -> business-engineer
                                              ├─ business-architect
                                              ├─ test e verifiche
                                              └─ business-reviewer ai gate
```

Routing operativo `business-engineering`:

1. GPT-5.6 Sol Medium — implementazione principale e tool use;
2. DeepSeek V4 Flash paid — fallback di coding economico;
3. GLM-5.2 — fallback lungo e agentico;
4. Kimi K3 — escalation complementare, normalmente riservata al giudizio Fusion.

Review `business-review`:

- panel: GLM-5.2, DeepSeek V4 Flash paid, MiMo V2.5 Pro;
- giudice esplicito: Kimi K3;
- quorum minimo: 2.

Kimi non è nel panel: viene chiamato una volta per sintetizzare, riducendo costo e duplicazione. Sol non viene duplicato nel panel, aumentando l'indipendenza della review.

**Confine di sicurezza:** Business non contiene endpoint free. Prima di inviare materiale sensibile bisogna applicare e verificare ZDR/no-training sul provider, escludere `.env`, segreti, dump, log e dati cliente, e sanitizzare l'evidence package. `paid` non equivale automaticamente a `private`.

## Light

Flusso:

```text
light-planner -> light-builder -> test locali -> light-reviewer (solo se utile)
```

Routing operativo `light-engineering`:

1. DeepSeek V4 Flash Free;
2. Laguna S 2.1 Free;
3. Nemotron 3 Ultra Free;
4. DeepSeek V4 Flash paid come paid floor.

Review `light-review`:

- panel: Laguna S Free, Nemotron 3 Ultra Free, MiMo V2.5 Pro paid;
- giudice: GLM-5.2;
- quorum minimo: 1 per degradare senza bloccare il lavoro.

Gli endpoint gratuiti sono intenzionalmente espliciti: nessun router casuale, risultati più riproducibili. Il paid floor impedisce che una quota free esaurita lasci il progetto incompleto. Kimi è escluso dal percorso Light ordinario e rimane un'escalation manuale.

## Budget

I limiti sono limiti di processo, non garanzie del provider:

- Business: Sol Medium di default; High/Max solo dietro escalation; Fusion solo ai gate; evidence package mirato.
- Light: target di progetto iniziale `$5`, soft stop `$3`, hard stop `$5`; review massima una volta per milestone; niente repository intero nel prompt.

I prezzi e la disponibilità cambiano. `core/ROUTING.md` definisce i ruoli stabili; l'adapter del router registra gli slug verificati e deve essere ricontrollato prima di ogni nuova installazione.
