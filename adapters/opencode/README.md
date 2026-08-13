# Adapter OpenCode

OpenCode supporta agenti Markdown globali o di progetto. AI Work OS raccomanda l'installazione globale, mantenendo il core in una directory separata.

Eseguire dalla root:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Target opencode
```

Lo script genera il dispatcher `ai-work-os` e i sette ruoli nella directory
globale OpenCode a partire dall'adapter Markdown verificato. Selezionare il
dispatcher e scrivere `riprendi` per far scegliere il ruolo dallo stato del
progetto. Dopo l'installazione, adeguare soltanto gli identificatori dei
modelli/provider alle quattro route di `core/ROUTING.md`.

Il bootstrap completo installa le skill in `~/.config/opencode/skills/`, non
nella directory interoperabile condivisa `~/.agents/skills/`.

Se una versione di OpenCode non supporta una chiave frontmatter usata dall'adapter, preservare il contratto equivalente tramite la configurazione JSON del client. Le istruzioni canoniche restano in `core/`.
