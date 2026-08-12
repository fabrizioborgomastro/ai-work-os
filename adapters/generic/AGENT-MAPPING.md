# Mapping minimo dei ruoli

| Ruolo | Tipo | Scrittura codice | Delega |
|---|---|---:|---|
| business-wayfinder | primario | no | ricerca/grilling secondo disponibilità |
| business-engineer | primario | sì | architect e reviewer |
| business-architect | subagente/sessione isolata | no | no |
| business-reviewer | subagente/sessione isolata | no, nessun tool | no |
| light-planner | primario | no | Wayfinder solo se necessario |
| light-builder | primario | sì | reviewer |
| light-reviewer | subagente/sessione isolata | no, nessun tool | no |

Se il client non distingue agenti primari e subagenti, usare sessioni separate e passare gli artefatti previsti dal core.
