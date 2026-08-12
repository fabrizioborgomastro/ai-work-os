# Adapter Claude Code

Il bootstrap installa soltanto le skill personali AI Work OS e Wayfinder in
`~/.claude/skills/`. Non modifica impostazioni, gateway, credenziali o agenti
personali senza consenso esplicito.

Claude Code supporta subagenti Markdown in `~/.claude/agents/`, con prompt,
tool, permessi e scelta del modello Claude per ruolo. Questo consente di
rappresentare i ruoli AI Work OS e di isolare Architect e Reviewer.

Non consente però di riprodurre fedelmente le combo multi-provider di Kilo.
La documentazione Anthropic supporta gateway in formato compatibile per modelli
Claude e dichiara che il routing di Claude Code verso modelli non-Claude non è
supportato. Panel, giudice e fallback possono quindi usare modelli Claude o
un'orchestrazione esterna, ma non vanno presentati come equivalenti alle combo
Business/Light multi-provider del manifest OmniRoute.

Riferimenti ufficiali:

- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/llm-gateway
