# Adapter OpenCode

OpenCode supporta agenti Markdown globali o di progetto. AI Work OS raccomanda l'installazione globale, mantenendo il core in una directory separata.

Eseguire dalla root:

```powershell
python scripts/install_markdown_agents.py --client opencode
```

Lo script genera i sette agenti nella directory globale OpenCode a partire dall'adapter Markdown verificato. Dopo l'installazione, adeguare soltanto gli identificatori dei modelli/provider alle quattro route di `core/ROUTING.md`.

Se una versione di OpenCode non supporta una chiave frontmatter usata dall'adapter, preservare il contratto equivalente tramite la configurazione JSON del client. Le istruzioni canoniche restano in `core/`.
