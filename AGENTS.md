# AI Work OS — istruzioni per l'agente installatore

Questa cartella è una distribuzione di AI Work OS, non un progetto applicativo. Il suo core deve restare separato dai repository su cui gli agenti lavoreranno.

## Quando l'utente chiede di installare o configurare il sistema

1. Leggi integralmente `INSTALL.md` e `README.md`.
2. Distingui host/editor e runtime agentico target. Se il runtime che ricevera i file non è deducibile con affidabilità, chiedi soltanto il suo nome; non usare l'host come target e non assumere Kilo.
3. Su Windows usa PowerShell; su macOS/Linux usa la shell di sistema. Python non è richiesto né utilizzato.
4. Esegui prima il preflight di compatibilita, indicando esplicitamente il runtime target e, se noto, l'host:

   ```text
   powershell -ExecutionPolicy Bypass -File install.ps1 -Target <runtime> -Host <host> -Analyze
   ```

   Su macOS/Linux usare `sh install.sh --target <runtime> --host <host> --analyze`.

5. Mostra livello workflow, livello routing, limitazioni e cosa verra scritto fuori da questa cartella. Per `adapted` o `skill-only` spiega che le combo non vengono installate e usa l'accettazione esplicita prevista. Per un runtime non catalogato non procedere senza percorso skill verificato e accettazione `unverified`.
6. Applica:

   ```text
   powershell -ExecutionPolicy Bypass -File install.ps1 -Target <runtime> -Host <host> [accettazione richiesta dal preflight]
   ```

   Su macOS/Linux usare `sh install.sh --target <runtime> --host <host> [accettazione richiesta dal preflight]`.

7. Leggi il report prodotto in `~/.ai-work-os/SETUP-REPORT.md` e guida l'utente soltanto nei passaggi rimasti manuali.
8. Esegui `~/.ai-work-os/manage.ps1 -Doctor` su Windows oppure `sh ~/.ai-work-os/manage.sh doctor` su macOS/Linux e i controlli del client disponibili, senza effettuare chiamate a pagamento ai modelli salvo autorizzazione.

## Vincoli

- Non installare MCP, software, plugin o connettori non richiesti dal piano senza consenso.
- Non installare adapter, agenti, prompt o skill per client diversi da quello selezionato esplicitamente.
- Non trattare Cursor, Antigravity, VS Code o un terminale come prova del runtime attivo.
- Non ricadere silenziosamente su `generic`: applica il contratto in `core/COMPATIBILITY.md`.
- Non chiedere token o API key in chat e non inserirli nei file del progetto.
- Non sovrascrivere configurazioni esistenti senza backup.
- Non configurare automaticamente privacy, spesa o pubblicazione di repository: sono scelte che richiedono conferma e verifica nell'account dell'utente.
- Non modificare `core/` durante l'installazione locale.
- Tratta Kilo, OpenCode, Pi, Codex, Claude Code e gli altri client come adapter equivalenti.

## Quando l'utente vuole usare il sistema, non installarlo

Leggi `skills/ai-work-os/SKILL.md` e i contratti in `core/`. Lavora nella cartella del progetto reale, mai dentro questa distribuzione.
