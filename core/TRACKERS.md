# Tracker portabile per Wayfinder

Il tracker è una capacità del processo, non del client AI. Nessun ambiente specifico — Kilo, Codex, Claude Code, OpenCode, Cursor o altro — è obbligatorio.

## Scelta iniziale

Se il progetto non registra ancora un tracker in `PROJECT.md` o `docs/agents/issue-tracker.md`, Wayfinder deve chiedere una sola scelta prima di creare la mappa:

1. **Locale Markdown** — mappa e ticket come file versionabili sotto `.wayfinder/`; consigliato per lavoro individuale, offline o senza repository remoto.
2. **GitHub Issues** — mappa e ticket nel repository GitHub; consigliato per collaborazione, assegnazioni, dipendenze e sessioni concorrenti.

Se il tracker è già configurato, riprenderlo senza ripetere la domanda. Il passaggio futuro da locale a GitHub è una migrazione esplicita, mai automatica.

## Collegamento a GitHub indipendente dal client

Dopo la scelta GitHub, rilevare le capacità disponibili senza assumere uno strumento particolare. Usare, in ordine pratico, una via ufficiale già installata e autenticata:

- integrazione GitHub nativa del client;
- GitHub CLI ufficiale (`gh`);
- GitHub API tramite un connettore ufficiale già configurato;
- GitHub MCP Server ufficiale;
- altra integrazione GitHub approvata dall'utente e documentata nel progetto.

La precedenza non impone di sostituire un'integrazione funzionante: scegliere la via ufficiale disponibile che copre repository, issue, commenti, label, assegnazioni e relazioni necessarie. Registrare nel file del tracker quale adapter viene usato, senza salvare credenziali.

Se nessuna via è disponibile, presentare le alternative supportate dall'ambiente corrente e raccomandare quella ufficiale con minore attrito. Chiedere consenso prima di installare software, aggiungere un server MCP o avviare un login. Preferire autenticazione interattiva/OAuth o credential manager; non chiedere token in chat e non scriverli nei file del progetto.

## Repository mancante

La scelta `GitHub Issues` non autorizza da sola a creare o pubblicare un repository. Se manca il remoto, chiedere e confermare:

- account o organizzazione proprietaria;
- nome del repository;
- visibilità, con `private` raccomandato per Business;
- se inizializzare Git e pubblicare i file locali esistenti.

Solo dopo la conferma creare il repository, collegare il remote e inizializzare tracker, label, mappa e ticket. Non rendere pubblico materiale Business per impostazione predefinita.

## Degrado sicuro

Se GitHub non è raggiungibile o l'autenticazione manca, non scegliere silenziosamente il tracker locale e non duplicare la mappa. Conservare il brief, spiegare il blocco e offrire: completare il collegamento, oppure approvare esplicitamente il fallback Locale Markdown.
