# Installare AI Work OS con un agente

## Installazione da GitHub

Quando il progetto e disponibile su GitHub, il destinatario puo scegliere uno
dei due percorsi seguenti.

### Far fare tutto al client agentico

Passare al client il link della repository e scrivere:

```text
Clona questa repository in una posizione stabile del mio profilo:
https://github.com/fabrizioborgomastro/ai-work-os

Poi leggi AGENTS.md, installa AI Work OS nel client che stai usando e
guidami nei soli passaggi manuali rimasti. Non inserire credenziali e non
attivare servizi a pagamento senza il mio consenso.
```

### Installazione PowerShell esplicita

```powershell
git clone https://github.com/fabrizioborgomastro/ai-work-os.git "$HOME\AI-Work-OS"
powershell -ExecutionPolicy Bypass -File "$HOME\AI-Work-OS\install.ps1" -Target kilo
```

`-Client` resta un alias compatibile, ma il nome corrente e `-Target` perche
indica il runtime che ricevera i file. Sostituire `kilo` con `opencode`, `pi`,
`codex` o `claude`.
L'installer è PowerShell nativo e non richiede Python.
La seconda riga puo essere rilanciata dopo un aggiornamento: i file differenti
vengono salvati con un suffisso di backup prima della sostituzione.

Il valore `-Target` è un confine di installazione: vengono scritti soltanto
l'adapter e le skill del client selezionato. Gli altri client eventualmente
rilevati sul computer vengono mostrati a titolo informativo e non vengono
modificati.

Per controllare senza installare:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\AI-Work-OS\install.ps1" -Target kilo -Analyze
```

Non consigliamo `irm ... | iex`: scaricare o clonare prima la repository rende
il codice ispezionabile e mantiene esplicita la provenienza dell'installer.

## Percorso raccomandato

1. Estrarre o clonare questa cartella in una posizione stabile.
2. Aprire **questa cartella una sola volta** nel proprio client agentico.
3. Scrivere:

   ```text
   Installa AI Work OS nel client che sto usando. Leggi AGENTS.md,
   esegui il bootstrap e guidami nei soli passaggi manuali rimasti.
   ```

Il client leggerà `AGENTS.md`, identificherà il proprio adapter e avvierà
l'installer nativo del sistema operativo.

## Cosa automatizza il bootstrap

| Client | Installazione automatica |
|---|---|
| Kilo | sette agenti Markdown globali + skill in `~/.kilo/skills/` |
| OpenCode | sette agenti Markdown globali + skill in `~/.config/opencode/skills/` |
| Pi | skill in `~/.pi/agent/skills/` + sette prompt di ruolo |
| Codex | skill personali AI Work OS e Wayfinder |
| Claude Code | skill personali AI Work OS e Wayfinder |
| altro | audit minimo; installazione bloccata finche non viene indicato un percorso skill esplicito |

In tutti i casi vengono creati anche `~/.ai-work-os/SETUP-REPORT.md` e
`~/.ai-work-os/install.json`. Nessun file viene scritto nelle configurazioni
degli altri client.

Non esiste piu una destinazione `generic` implicita. Per un runtime non
catalogato bisogna indicare esplicitamente la directory supportata dal client e
accettare che la classificazione sia ancora non verificata.

## Host, runtime e compatibilita

L'editor non e necessariamente il client che deve ricevere l'installazione:

```text
host/editor -> runtime target -> adapter -> routing
Cursor      -> Claude Code    -> skill   -> esterno/manuale
```

Esempio di sola analisi:

```powershell
.\install.ps1 -Analyze -Host cursor -Target claude
```

Claude Code viene classificato `skill-only`: AI Work OS puo installare le skill,
ma non puo riprodurre automaticamente le combo multiprovider. Dopo avere letto
l'avviso, l'installazione richiede:

```powershell
.\install.ps1 -Host cursor -Target claude -AcceptLimitedCompatibility
```

Per un client non catalogato:

```powershell
.\install.ps1 -Analyze -Target nuovo-client
.\install.ps1 -Target nuovo-client -SkillPath "C:\percorso\verificato\skills" `
  -WorkflowCapability skill-only -RoutingCapability external-manual -AcceptUnverified
```

L'installer non consulta Internet. L'audit distingue fatti verificati, inferiti
e sconosciuti; il catalogo locale si trova in `adapters/compatibility.tsv`.

Quando il workflow e installabile ma il routing e `external-manual`, il
preflight segnala esplicitamente che combo, fallback e panel multiprovider non
sono disponibili finche non viene configurato un routing compatibile. Propone
OmniRoute, un router equivalente oppure una mappatura manuale supportata dal
runtime. Il suggerimento non autorizza l'installer a installare software,
provider o credenziali.

Il bootstrap non installa provider, non inserisce credenziali e non effettua chiamate ai modelli.
La copia Wayfinder installata conserva separatamente la licenza MIT originale;
consultare `THIRD_PARTY_NOTICES.md`.

## Passaggi che restano intenzionalmente manuali

- scegliere router e modelli;
- configurare le quattro route in `core/ROUTING.md`;
- inserire credenziali attraverso il credential manager del client/provider;
- impostare budget, ZDR/no-training e allowlist Business;
- scegliere e autenticare l'integrazione GitHub se richiesta;
- autorizzare eventuali plugin, MCP o pubblicazione di repository.

Questi passaggi vengono elencati nel report locale con riferimenti ai file pertinenti.

## Uso manuale del bootstrap

### Windows PowerShell

Analisi senza modifiche:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/bootstrap.ps1 -Target codex
```

Installazione:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/bootstrap.ps1 -Target codex -Apply -AcceptLimitedCompatibility
```

### macOS e Linux

Analisi senza modifiche:

```sh
sh install.sh --target codex --analyze
```

Installazione:

```sh
sh install.sh --target codex --accept-limited-compatibility
```

Python non è richiesto né utilizzato. Se il target non viene indicato,
l'installer accetta soltanto `AI_WORK_OS_TARGET` oppure un unico runtime
catalogato presente in `PATH`; in ogni situazione ambigua richiede `-Target` o
`--target`. L'host non viene mai scelto come destinazione implicita.

## Gestire l'installazione

I comandi possono essere eseguiti da qualsiasi cartella nel terminale.

Windows PowerShell:

```powershell
& "$HOME\.ai-work-os\manage.ps1" -Status
& "$HOME\.ai-work-os\manage.ps1" -Compatibility
& "$HOME\.ai-work-os\manage.ps1" -Doctor
& "$HOME\.ai-work-os\manage.ps1" -Update -DryRun
& "$HOME\.ai-work-os\manage.ps1" -Uninstall -DryRun
```

macOS/Linux:

```sh
sh "$HOME/.ai-work-os/manage.sh" status
sh "$HOME/.ai-work-os/manage.sh" compatibility
sh "$HOME/.ai-work-os/manage.sh" doctor
sh "$HOME/.ai-work-os/manage.sh" update --dry-run
sh "$HOME/.ai-work-os/manage.sh" uninstall --dry-run
```

`Status` fornisce il riepilogo, `Compatibility` ricorda host, target e limiti,
`Doctor` elenca file mancanti o modificati,
`Update` reinstalla dalla copia locale corrente e `Uninstall` rimuove soltanto
i file che corrispondono ancora agli hash installati. Togliere `-DryRun` o
`--dry-run` soltanto dopo aver controllato il piano.

Per destinazioni non standard usare gli installer specifici o seguire `adapters/generic/README.md`.
