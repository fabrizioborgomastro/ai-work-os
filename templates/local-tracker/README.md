# Tracker Wayfinder locale

Quando il progetto sceglie Locale Markdown, creare:

```text
.wayfinder/<nome-mappa>/MAP.md
.wayfinder/<nome-mappa>/tickets/<ticket>.md
```

`MAP.md` contiene Destination, Notes, Decisions so far, Not yet specified e Out of scope. Ogni ticket contiene Question, Type, Status, Assignee e Blocks/Blocked by. La risoluzione vive nel ticket; la mappa conserva soltanto una sintesi con link relativo.

Per collaborazione concorrente preferire GitHub Issues o un tracker con assegnazioni e dipendenze native.
