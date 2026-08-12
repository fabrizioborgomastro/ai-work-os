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
- **altro client** — usare `adapters/generic/` e i contratti in `core/agents/`.

Un adapter deve preservare i contratti; può cambiare sintassi, nomi dei tool e modalità di delega.

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

Selezionare `business-wayfinder` e descrivere liberamente il prodotto. L'agente:

1. inizializza `PROJECT.md`;
2. chiede Locale Markdown oppure GitHub Issues;
3. crea la mappa e lavora sulle decisioni;
4. produce `READY_FOR_ENGINEERING` quando il percorso è maturo.

Passare quindi a `business-engineer`, che verifica autonomamente l'handoff prima di implementare.

### Nuovo Light

Selezionare `light-planner`; per attività già chiare e piccole è possibile iniziare direttamente con `light-builder`.

## 5. Verifica dell'installazione

Prima di usare dati sensibili, controllare:

- gli agenti richiamano le quattro route corrette;
- il profilo Business non contiene endpoint free;
- privacy, ZDR/no-training e limiti di spesa sono configurati sul provider;
- reviewer e architect hanno i permessi restrittivi previsti;
- il client può leggere il core ma non modificarlo durante il lavoro ordinario;
- un progetto sintetico attraversa pianificazione, handoff, build e review senza scrivere nella cartella AI Work OS.

Eseguire anche:

```text
python scripts/verify_distribution.py
```
