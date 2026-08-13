# Adapter Kilo

Kilo usa le definizioni condivise in `adapters/markdown-agents/`. Kilo è opzionale: il core non dipende da questo adapter.

## Installazione

Eseguire dalla root di AI Work OS:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Target kilo
```

Lo script copia gli agenti nella configurazione globale e sostituisce il riferimento al core con il percorso reale di questa installazione. Successivamente registrare nel provider/router di Kilo le quattro route definite in `core/ROUTING.md`.

Per l'uso ordinario selezionare nel picker l'agente `ai-work-os`, non il
built-in `Code`, quindi scrivere `riprendi`. Il dispatcher resta l'agente
principale visibile e delega a Wayfinder, Engineer, Planner o Builder in base a
`PROJECT.md` e agli handoff. I ruoli specifici rimangono selezionabili per
interventi manuali e diagnostica.

Se la sessione parte sul built-in `Code`, il messaggio `riprendi` e anche un
trigger esplicito della skill AI Work OS installata: Code deve leggere lo stato
e delegare al ruolo corretto. Il picker puo continuare a mostrare `Code`, perche
Kilo esegue il ruolo come subagente e non cambia il primary a meta sessione.

Il bootstrap completo installa le skill in `~/.kilo/skills/`, non nella
directory interoperabile condivisa `~/.agents/skills/`.

Verificare con:

```text
kilo config check
kilo agent list
kilo models omniroute
```

L'ultimo comando riguarda solo chi usa OmniRoute.
