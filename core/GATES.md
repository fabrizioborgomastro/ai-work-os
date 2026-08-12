# Gate

## Gate obbligatori Business

- architettura con almeno due alternative credibili;
- autenticazione, autorizzazione, privacy, pagamenti o segreti;
- schema dati, migrazione o cancellazione dati;
- cambiamenti con impatto operativo, affidabilità o scalabilità;
- release di una milestone o modifica ampia e trasversale.

## Gate Light

La review è richiesta solo per una release o per un rischio reale. Bug locale, refactor piccolo e prototipo possono terminare dopo test adeguati.

## Evidence package

Usare `templates/EVIDENCE_PACKAGE.md`. Deve essere autosufficiente ma piccolo: diff e frammenti pertinenti, non il repository intero. Il reviewer non dispone di tool e non deve colmare lacune inventando fatti.
