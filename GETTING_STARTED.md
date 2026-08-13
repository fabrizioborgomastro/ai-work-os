# Installazione e primo utilizzo

Per l'installazione guidata da un agente, aprire prima [INSTALL.md](INSTALL.md). Questa guida descrive anche il flusso operativo successivo.

## 1. Conservare il sistema separato dai progetti

Posizionare questa cartella in una directory stabile, per esempio:

```text
~/ai-work-os/
```

Non aprirla come progetto operativo e non copiarvi codice applicativo. Il client AI deve lavorare nella cartella del progetto reale e leggere AI Work OS come fonte esterna in sola lettura.

## 2. Collegare il client

Scegliere il percorso più adatto:

- **Kilo** — adapter pronto in `adapters/kilo/`;
- **OpenCode** — guida in `adapters/opencode/`;
- **Pi** — guida in `adapters/pi/`;
- **Codex** — skill portabili e guida ai limiti in `adapters/codex/`;
- **Claude Code** — skill portabili e guida ai limiti in `adapters/claude/`;
- **altro client** — eseguire prima l'audit di compatibilita; usare
  `adapters/generic/` e i contratti in `core/agents/` solo dopo avere verificato
  destinazione skill e capacita effettive.

Un adapter deve preservare i contratti; può cambiare sintassi, nomi dei tool e modalità di delega.

Kilo e OpenCode possono consumare direttamente gli agenti Markdown e i nomi
logici delle combo. Codex e Claude Code supportano skill e subagenti, ma non
replicano automaticamente una combo multi-provider con priorità, panel e
giudice. In quei client il routing va implementato da un gateway compatibile o
da un'orchestrazione esplicita, mantenendo manuale la configurazione di
credenziali e privacy.

## 3. Collegare i modelli

Creare nel router o nel client le quattro route definite in `core/ROUTING.md`:

- `business-engineering`
- `business-review`
- `light-engineering`
- `light-review`

Con OmniRoute seguire `adapters/omniroute/README.md`. Se il client non supporta route, assegnare direttamente i modelli raccomandati e gestire i fallback manualmente.

## 4. Aprire un progetto reale

Aprire nel client la cartella del repository su cui lavorare, non AI Work OS.

### Nuovo Business

In Kilo/OpenCode selezionare `ai-work-os` e descrivere liberamente il prodotto;
nei client che installano solo la skill, chiedere di usare AI Work OS. Il
dispatcher attiva `business-wayfinder`. Il ruolo:

1. inizializza `PROJECT.md`;
2. chiede Locale Markdown oppure GitHub Issues;
3. crea la mappa e lavora sulle decisioni;
4. produce `READY_FOR_ENGINEERING` quando il percorso è maturo.

Quando lo stato diventa `READY_FOR_ENGINEERING`, scrivere `riprendi`: il
dispatcher attiva `business-engineer`, che verifica autonomamente l'handoff
prima di implementare.

### Nuovo Light

Usare lo stesso ingresso `ai-work-os` specificando che il progetto e Light. Il
dispatcher attiva `light-planner`; per attivita gia chiare e piccole puo
delegare direttamente a `light-builder` dopo avere verificato profilo e stato.

In ogni nuova sessione mantenere selezionato `ai-work-os` e scrivere
`riprendi`: non serve ricordare il ruolo corrente.

## 5. Verifica dell'installazione

Prima di usare dati sensibili, controllare:

- gli agenti richiamano le quattro route corrette;
- il profilo Business non contiene endpoint free;
- privacy, ZDR/no-training e limiti di spesa sono configurati sul provider;
- reviewer e architect hanno i permessi restrittivi previsti;
- il client può leggere il core ma non modificarlo durante il lavoro ordinario;
- un progetto sintetico attraversa pianificazione, handoff, build e review senza scrivere nella cartella AI Work OS.

Eseguire anche:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify_distribution.ps1
```

Su macOS/Linux usare `sh scripts/verify_distribution.sh`.
