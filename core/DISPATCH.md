# Dispatch universale del workflow

Il dispatcher `ai-work-os` e l'ingresso consigliato per una nuova sessione.
Lo stesso contratto viene applicato dalla skill AI Work OS quando `riprendi`
viene scritto da un agente generico come Code o Build. L'ingresso non
implementa, pianifica o revisiona direttamente: legge lo stato persistente del
progetto e delega una sola volta al ruolo operativo corretto.

## Fonti di stato

Leggere nell'ordine:

1. `PROJECT.md` per profilo e stato dichiarati;
2. tracker registrato e relativa mappa/ticket attivo;
3. handoff, ADR ed evidence package pertinenti;
4. stato reale del repository, soltanto per rilevare contraddizioni evidenti.

Non considerare affidabile il titolo della chat o la memoria della sessione
precedente. Non copiare interi documenti sensibili nel messaggio al subagente:
il ruolo delegato puo leggerli direttamente nel workspace.

## Tabella di dispatch

| Profilo | Stato | Ruolo |
|---|---|---|
| Business | `UNASSESSED`, `PLANNING`, `WAYFINDING`, `NEEDS_WAYFINDING` | `business-wayfinder` |
| Business | `READY_FOR_ENGINEERING`, `ENGINEERING`, `REVIEW` | `business-engineer` |
| Light | `UNASSESSED`, `PLANNING`, `WAYFINDING`, `NEEDS_WAYFINDING` | `light-planner` |
| Light | `READY_FOR_BUILD`, `BUILDING`, `REVIEW` | `light-builder` |

Per `COMPLETE`, verificare se il tracker contiene lavoro riaperto o incompleto.
Se non esiste, non delegare: dichiarare che il progetto risulta completo e
chiedere il nuovo obiettivo. Se stato dichiarato e artefatti si contraddicono,
scegliere il ruolo prudente di pianificazione e segnalare la discrepanza.

## Progetto non inizializzato

Se `PROJECT.md` manca:

- per `riprendi` o richieste equivalenti, cercare soltanto artefatti AI Work OS
  riconoscibili; se non esistono, dire che non c'e uno stato riprendibile e
  chiedere se inizializzare il progetto;
- per una nuova richiesta esplicitamente Light e non sensibile, delegare a
  `light-planner`;
- negli altri casi delegare a `business-wayfinder`, applicando il default
  Business quando la sensibilita e incerta.

## Contratto di delega

Invocare esattamente un ruolo per richiesta ordinaria. Passargli la richiesta
originale, il profilo e lo stato rilevati, il percorso degli artefatti utili e
le eventuali contraddizioni; non svolgere prima una versione parallela del
lavoro. Il ruolo delegato deve verificare autonomamente readiness e repository.

Il selettore dell'interfaccia resta sul primary corrente (`ai-work-os`, Code o
Build): il ruolo corretto viene eseguito come subagente. L'utente non deve
cambiare agente quando lo stato passa da pianificazione a implementazione; una
nuova richiesta `riprendi` provoca un nuovo dispatch basato sullo stato
aggiornato. Non dichiarare che il selettore e stato modificato automaticamente.
