# Portabilità tra client agentici

I file in `core/` sono contratti, non configurazioni Kilo. Per portare AI Work OS verso un nuovo client:

1. creare un agente o preset per ogni ruolo necessario usando `core/agents/`;
2. preservare scopo, divieti, bootstrap automatico, input, output e stati di handoff;
3. mappare agente primario, subagente, sola lettura e assenza di tool sui meccanismi del client;
4. mappare le quattro route di `core/ROUTING.md` sul router disponibile;
5. consentire la lettura del core da una directory stabile e impedire che il lavoro ordinario lo modifichi;
6. mantenere `PROJECT.md`, tracker, ADR ed evidence package nel progetto reale;
7. validare il porting con un progetto sintetico prima di fornire accesso a materiale sensibile.

## Client senza agenti nominati

Usare i contratti come system prompt, skill o prompt template. Il passaggio Wayfinder → Engineer può avvenire cambiando preset o iniziando una nuova sessione; la comunicazione resta affidata agli artefatti persistenti.

## Client senza subagenti

Eseguire Architect e Reviewer in sessioni separate. Reviewer deve ricevere soltanto l'evidence package e non avere accesso ai tool.

## Ambiente senza router

Assegnare direttamente il primo modello idoneo a ciascun ruolo e applicare manualmente i fallback. Il processo resta invariato; registrare la mappatura locale senza modificare il core.

## Checklist di conformità

Un adapter è conforme quando:

- un brief ordinario inizializza il profilo senza prompt rituali;
- Wayfinder chiede il tracker e non implementa;
- Engineer verifica la readiness e può rinviare a Wayfinder;
- Architect non implementa;
- Reviewer è tool-free e advisory;
- Business non usa endpoint free;
- Light segnala il confine sui dati sensibili;
- tutti gli handoff sopravvivono al cambio di client o sessione.
