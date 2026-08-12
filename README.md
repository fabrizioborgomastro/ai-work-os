# AI Work OS

Per installare da una copia locale o da una repository GitHub, partire da
[`INSTALL.md`](INSTALL.md). Su Windows e disponibile anche `install.ps1`.

Repository canonica: https://github.com/fabrizioborgomastro/ai-work-os

AI Work OS è un sistema operativo portabile per governare progetti software svolti con agenti AI. Non è un'applicazione e non sostituisce il client agentico: definisce ruoli, passaggi di consegne, tracker, gate di qualità, limiti di costo e contratti di routing che possono essere applicati in Kilo, OpenCode, Pi, Codex, Claude Code, Cursor o altri ambienti.

Il sistema offre due profili:

- **Business** — software proprietario, dati sensibili, produzione e decisioni ad alto impatto;
- **Light** — prototipi e progetti non sensibili da completare con pochi dollari.

## Principio fondamentale

`core/` è l'unica fonte canonica. Client AI, router e tracker sono adapter sostituibili:

```text
AI Work OS core
├── client agentico: Kilo | OpenCode | Pi | Codex | altro
├── routing: OmniRoute | router equivalente | modelli diretti
└── tracker: Markdown locale | GitHub Issues | altro
```

Nessuna regola del core richiede Kilo, OmniRoute, MCP o GitHub.

## Cosa distribuire

Condividere l'intera cartella `AI-Work-OS`. Non contiene credenziali, database, cache, dipendenze installate o artefatti di un progetto reale. Ogni collega mantiene una sola copia del sistema e la collega al proprio ambiente; i file operativi vengono creati nei singoli progetti.

## Avvio rapido

1. Aprire questa cartella nel proprio client agentico.
2. Scrivere: `Installa AI Work OS nel client corrente seguendo AGENTS.md`.
3. Seguire i soli passaggi manuali indicati nel report generato.
4. Aprire la cartella del progetto reale nel client.
5. Per un nuovo Business avviare `business-wayfinder`; per un nuovo Light avviare `light-planner`.

Gli agenti inizializzano automaticamente `PROJECT.md`, chiedono il tracker e preparano gli handoff. L'utente deve descrivere l'obiettivo, non ricordare prompt di bootstrap.

Procedura completa e alternativa manuale: [INSTALL.md](INSTALL.md) e [GETTING_STARTED.md](GETTING_STARTED.md).

## Scelta del profilo

| Condizione | Profilo |
|---|---|
| Codice cliente, dati personali, segreti, produzione, pagamenti | Business |
| Prototipo, repository pubblico, dati sintetici, basso rischio | Light |
| Dubbio sulla sensibilità | Business |

Architettura e motivazioni: [ARCHITECTURE.md](ARCHITECTURE.md). Porting verso altri client: [core/PORTABILITY.md](core/PORTABILITY.md).
