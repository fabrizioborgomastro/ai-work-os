# Agenti Markdown condivisi

Queste definizioni sono l'adapter comune per client con agenti Markdown
compatibili: sette ruoli specializzati e il dispatcher principale `ai-work-os`.
Oggi vengono usate dagli installer Kilo e OpenCode; nessuno dei due è
considerato canonico.

Nel flusso ordinario l'utente seleziona `ai-work-os` e scrive `riprendi`. Il
dispatcher segue `core/DISPATCH.md` e richiama il ruolo corretto come subagente.
Solo il dispatcher e visibile come primary; i sette ruoli restano interni.

I file conservano riferimenti relativi al core per restare distribuibili. Gli
installer nativi li rendono assoluti al momento dell'installazione globale.

Se un client interpreta diversamente una chiave frontmatter, creare una traduzione nel suo adapter senza cambiare il contratto in `core/agents/`.
