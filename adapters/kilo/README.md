# Adapter Kilo

Kilo usa le definizioni condivise in `adapters/markdown-agents/`. Kilo è opzionale: il core non dipende da questo adapter.

## Installazione

Eseguire dalla root di AI Work OS:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Client kilo
```

Lo script copia gli agenti nella configurazione globale e sostituisce il riferimento al core con il percorso reale di questa installazione. Successivamente registrare nel provider/router di Kilo le quattro route definite in `core/ROUTING.md`.

Il bootstrap completo installa le skill in `~/.kilo/skills/`, non nella
directory interoperabile condivisa `~/.agents/skills/`.

Verificare con:

```text
kilo config check
kilo agent list
kilo models omniroute
```

L'ultimo comando riguarda solo chi usa OmniRoute.
