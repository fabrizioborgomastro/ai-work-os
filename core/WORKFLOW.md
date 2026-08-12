# Workflow canonico

1. **Classify** — scegliere Business o Light e registrarlo in `PROJECT.md`.
2. **Wayfind/Plan** — scegliere o riprendere il tracker secondo `core/TRACKERS.md`; se esistono decisioni aperte, creare o aggiornare una mappa; non implementare.
3. **Design** — produrre ADR e acceptance criteria per le decisioni chiuse.
4. **Build** — implementare la più piccola unità verificabile.
5. **Verify** — eseguire test, lint, type-check, build e controlli pertinenti.
6. **Review** — creare un evidence package e attivare la review soltanto ai gate.
7. **Decide** — verificare i rilievi, applicare solo quelli supportati e rieseguire i controlli.
8. **Record** — aggiornare tracker, ADR, changelog e budget.

Un agente non può dichiarare superato un gate soltanto perché un altro modello lo afferma: servono evidenze riproducibili.
