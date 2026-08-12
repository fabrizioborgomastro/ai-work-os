# AI Work OS roadmap

## Separazione rigida tra routing Business e Light

**Stato:** pianificato, non ancora implementato.

### Problema

Kilo assegna a ogni agente un modello predefinito, ma l'override manuale della
sessione ha precedenza sulla configurazione dell'agente. Di conseguenza un
utente può selezionare accidentalmente `light-engineering` mentre usa
`business-engineer`, perdendo per quella sessione le garanzie Business.

### Obiettivo

Impedire tecnicamente che un contesto Business utilizzi route Light o endpoint
free, mantenendo comunque disponibili entrambi i profili sullo stesso computer.

### Implementazione prevista

1. **Profili client separati**
   - profilo Business: espone soltanto `business-engineering` e
     `business-review`;
   - profilo Light: espone soltanto `light-engineering` e `light-review`;
   - comandi di avvio espliciti e portabili, non limitati a Kilo.

2. **Enforcement lato router**
   - credenziali o endpoint distinti per Business e Light;
   - la credenziale Business rifiuta tutte le route Light e tutti gli endpoint
     free;
   - la credenziale Light non concede accesso implicito a materiale o route
     Business;
   - allowlist e limiti di spesa verificabili separatamente.

3. **Controllo preventivo dell'agente**
   - ogni agente verifica, quando il client rende disponibile l'informazione,
     che la route attiva appartenga al proprio profilo;
   - in caso di mismatch non prosegue, non invia contesto e indica il profilo
     corretto;
   - questo controllo è una difesa aggiuntiva, non sostituisce l'enforcement
     del router.

4. **Route Business economica**
   - valutare `business-economy`, composta soltanto da endpoint paid compatibili
     con i requisiti Business;
   - usarla per attività meccaniche o a basso rischio senza ricorrere alle
     route Light.

### Criteri di completamento

- selezionare manualmente `light-engineering` da un profilo Business fallisce
  prima che il prompt venga inoltrato a un modello;
- la combo Light non appare nel selettore del profilo Business;
- nessuna chiave Business autorizza endpoint free;
- i profili possono essere installati e aggiornati dal bootstrap su più client;
- i test automatici verificano almeno un tentativo consentito e uno negato per
  ciascun profilo;
- documentazione e setup report spiegano come passare intenzionalmente da un
  profilo all'altro.

### Vincolo temporaneo

Fino a questa implementazione, il campo `model` degli agenti è un valore
predefinito e non un blocco. L'utente deve evitare manualmente di associare una
route Light a un agente Business e non deve inviare materiale sensibile o
proprietario agli endpoint free.
