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
powershell -ExecutionPolicy Bypass -File "$HOME\AI-Work-OS\install.ps1" -Client kilo
```

Sostituire `kilo` con `opencode`, `pi`, `codex`, `claude` oppure `generic`.
La seconda riga puo essere rilanciata dopo un aggiornamento: i file differenti
vengono salvati con un suffisso di backup prima della sostituzione.

Per controllare senza installare:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\AI-Work-OS\install.ps1" -Client kilo -DryRun
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

Il client leggerà `AGENTS.md`, identificherà il proprio adapter e avvierà `scripts/bootstrap.py`.

## Cosa automatizza il bootstrap

| Client | Installazione automatica |
|---|---|
| Kilo | sette agenti Markdown globali + skill portabile |
| OpenCode | sette agenti Markdown globali + skill portabile |
| Pi | skill portabile + sette prompt di ruolo |
| Codex | skill personale AI Work OS |
| Claude Code | skill personale AI Work OS |
| altro | skill Agent Skills standard e report di porting |

Il bootstrap non installa provider, non inserisce credenziali e non effettua chiamate ai modelli.

## Passaggi che restano intenzionalmente manuali

- scegliere router e modelli;
- configurare le quattro route in `core/ROUTING.md`;
- inserire credenziali attraverso il credential manager del client/provider;
- impostare budget, ZDR/no-training e allowlist Business;
- scegliere e autenticare l'integrazione GitHub se richiesta;
- autorizzare eventuali plugin, MCP o pubblicazione di repository.

Questi passaggi vengono elencati nel report locale con riferimenti ai file pertinenti.

## Uso manuale del bootstrap

Analisi senza modifiche:

```text
python scripts/bootstrap.py --client auto
```

Installazione esplicita:

```text
python scripts/bootstrap.py --client kilo --apply
python scripts/bootstrap.py --client opencode --apply
python scripts/bootstrap.py --client pi --apply
python scripts/bootstrap.py --client codex --apply
python scripts/bootstrap.py --client claude --apply
python scripts/bootstrap.py --client generic --apply
```

Per destinazioni non standard usare gli installer specifici o seguire `adapters/generic/README.md`.
