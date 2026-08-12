# Adapter Pi

Pi può consumare AI Work OS senza emulare Kilo:

- `AGENTS.md`/`CLAUDE.md` per il contesto persistente;
- prompt template o skill per selezionare un ruolo;
- estensione/subagent package quando serve delega automatica;
- `models.json` per un router OpenAI-compatible.

## Modalità minima

Creare nel profilo Pi un context file che dichiari il percorso di AI Work OS e imponga di leggere il contratto del ruolo scelto. Usare sessioni distinte per Wayfinder, Engineer e Reviewer; gli artefatti nel progetto costituiscono l'handoff.

## Modalità completa

Creare un Pi package con sette prompt/skill e, se desiderato, un'estensione subagent. Il package deve importare i contratti da `core/` e non duplicarne la logica. Reviewer deve essere avviato senza tool e ricevere soltanto l'evidence package.

Per OmniRoute o un altro gateway OpenAI-compatible, configurare i quattro modelli logici nel registro modelli di Pi. MCP è opzionale e riguarda solo capacità esterne, non il funzionamento del workflow.
