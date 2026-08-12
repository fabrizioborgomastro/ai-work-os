# AI Work OS — istruzioni per l'agente installatore

Questa cartella è una distribuzione di AI Work OS, non un progetto applicativo. Il suo core deve restare separato dai repository su cui gli agenti lavoreranno.

## Quando l'utente chiede di installare o configurare il sistema

1. Leggi integralmente `INSTALL.md` e `README.md`.
2. Identifica il client agentico corrente. Se non è deducibile con affidabilità, chiedi soltanto il nome del client; non assumere Kilo.
3. Verifica che Python 3 sia disponibile.
4. Esegui prima il bootstrap in modalità analisi:

   ```text
   python scripts/bootstrap.py --client <client>
   ```

5. Mostra sinteticamente cosa verrà scritto fuori da questa cartella. Se l'utente ha già chiesto esplicitamente di installare, procedi; altrimenti chiedi conferma.
6. Applica:

   ```text
   python scripts/bootstrap.py --client <client> --apply
   ```

7. Leggi il report prodotto in `~/.ai-work-os/SETUP-REPORT.md` e guida l'utente soltanto nei passaggi rimasti manuali.
8. Esegui i controlli del client disponibili, senza effettuare chiamate a pagamento ai modelli salvo autorizzazione.

## Vincoli

- Non installare MCP, software, plugin o connettori non richiesti dal piano senza consenso.
- Non chiedere token o API key in chat e non inserirli nei file del progetto.
- Non sovrascrivere configurazioni esistenti senza backup.
- Non configurare automaticamente privacy, spesa o pubblicazione di repository: sono scelte che richiedono conferma e verifica nell'account dell'utente.
- Non modificare `core/` durante l'installazione locale.
- Tratta Kilo, OpenCode, Pi, Codex, Claude Code e gli altri client come adapter equivalenti.

## Quando l'utente vuole usare il sistema, non installarlo

Leggi `skills/ai-work-os/SKILL.md` e i contratti in `core/`. Lavora nella cartella del progetto reale, mai dentro questa distribuzione.
