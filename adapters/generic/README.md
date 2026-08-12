# Adapter generico

Usare questo percorso quando il client non ha un adapter dedicato.

1. Esporre al client la directory `core/` come istruzioni di sola lettura.
2. Creare i sette ruoli elencati in `core/agents/`, oppure almeno i ruoli necessari al profilo scelto.
3. Per ogni ruolo combinare il contratto specifico con `core/WORKFLOW.md`, `core/TRACKERS.md`, `core/ROUTING.md`, `core/GATES.md` e `core/BUDGETS.md`.
4. Configurare i modelli con i quattro nomi logici o sostituirli con mapping documentati.
5. Applicare i permessi descritti in `AGENT-MAPPING.md`.

Non copiare il core dentro ogni progetto. Nel progetto devono vivere soltanto gli artefatti operativi creati dagli agenti.
