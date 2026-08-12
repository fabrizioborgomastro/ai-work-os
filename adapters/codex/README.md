# Adapter Codex

Il bootstrap installa soltanto le skill personali AI Work OS e Wayfinder in
`~/.codex/skills/`. Non modifica `~/.codex/config.toml`, non registra provider
e non crea subagenti senza consenso esplicito.

Codex supporta ruoli di subagente configurabili con file TOML separati e può
assegnare modello e reasoning per ruolo. Supporta inoltre provider personalizzati
configurati a livello utente, ma il protocollo previsto è Responses.

Queste capacità permettono di rappresentare Architect, Reviewer e altri ruoli
isolati. Non equivalgono però alle combo Kilo:

- priority/fallback tra più modelli non viene creato dall'installazione della skill;
- panel parallelo e giudice richiedono orchestrazione multi-agent esplicita;
- un gateway esterno è utilizzabile soltanto se compatibile con il protocollo
  richiesto da Codex;
- credenziali, provider, budget e policy dati restano configurazioni manuali.

Per questo l'installazione predefinita conserva i ruoli come contratti nel core
e lascia al client principale l'attivazione del ruolo corretto. Un futuro
adapter nativo potrà generare configurazioni di subagenti dopo una scelta
esplicita dell'utente, senza toccare provider o credenziali.

Riferimenti ufficiali:

- https://learn.chatgpt.com/docs/agent-configuration/subagents
- https://learn.chatgpt.com/docs/config-file/config-reference
