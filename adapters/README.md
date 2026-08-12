# Adapter opzionali

Gli adapter traducono AI Work OS verso un prodotto specifico; non fanno parte del processo canonico.

- `markdown-agents/` — definizioni condivise dai client che supportano agenti Markdown;
- `kilo/` — installazione e mapping Kilo;
- `opencode/` — installazione e mapping OpenCode;
- `pi/` — uso tramite context file, prompt/skill o package Pi;
- `codex/` — skill, subagenti e limiti del routing nativo Codex;
- `claude/` — skill, subagenti e limiti del routing nativo Claude Code;
- `omniroute/` — implementazione delle quattro route con OmniRoute;
- `generic/` — schema per qualsiasi altro client o router.

`compatibility.tsv` e il catalogo machine-readable usato dai due installer. Un
client assente dal catalogo riceve un audit minimo e non viene installato nella
directory generica per supposizione.

Un collega installa soltanto gli adapter che usa. Non modificare un adapter per cambiare il processo: aggiornare prima `core/`, quindi riallineare gli adapter interessati.

## Tracker e integrazioni esterne

`core/TRACKERS.md` definisce il comportamento portabile. Un adattatore può tradurre le operazioni verso gli strumenti disponibili nel client, ma non può rendere obbligatori Kilo, un MCP specifico o una CLI specifica.

Per GitHub, usare una capacità ufficiale già disponibile: integrazione nativa, `gh`, API/connettore ufficiale o GitHub MCP Server ufficiale. I contratti e gli artefatti restano invariati qualunque adapter venga scelto.
