# Agenti Markdown condivisi

Queste sette definizioni sono l'adapter comune per client con agenti Markdown compatibili. Oggi vengono usate dagli installer Kilo e OpenCode; nessuno dei due è considerato canonico.

I file conservano riferimenti relativi al core per restare distribuibili. `scripts/install_markdown_agents.py` li rende assoluti al momento dell'installazione globale.

Se un client interpreta diversamente una chiave frontmatter, creare una traduzione nel suo adapter senza cambiare il contratto in `core/agents/`.
