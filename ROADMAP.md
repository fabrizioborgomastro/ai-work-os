# AI Work OS roadmap

## Installazione interattiva guidata

**Stato:** pianificato, non ancora implementato.

### Problema

L'installazione corrente e sicura e analizza separatamente host, runtime,
adapter e routing, ma l'utente deve ancora conoscere parametri come `-Host`,
`-Target` e le accettazioni di compatibilita. Una richiesta generica fatta a
un'estensione agentica potrebbe inoltre non comunicare chiaramente
all'installer quale runtime sta eseguendo l'operazione.

### Obiettivo

Offrire una procedura guidata che rilevi il contesto, chieda soltanto le scelte
ambigue e costruisca un piano comprensibile prima di qualsiasi scrittura.

Comandi previsti:

```powershell
.\install.ps1 -Interactive
```

```sh
./install.sh --interactive
```

### Esperienza prevista

1. mostrare host/editor rilevato e chiederne conferma;
2. elencare i runtime agentici rilevati senza confondere host ed estensioni;
3. chiedere il runtime target se non e univoco;
4. mostrare compatibilita workflow e routing separatamente;
5. spiegare cosa manca senza router: combo, fallback e panel multiprovider;
6. proporre OmniRoute, un router equivalente, una mappatura manuale oppure
   l'installazione del solo workflow;
7. elencare tutti i percorsi che verranno modificati e i client che non
   verranno toccati;
8. richiedere conferma prima dell'installazione e un consenso distinto prima
   di installare o configurare componenti esterni.

La modalita interattiva deve riutilizzare lo stesso preflight degli installer
non interattivi: non deve introdurre una seconda logica di compatibilita.

### Criteri di completamento

- funziona con PowerShell su Windows e shell POSIX su macOS/Linux;
- gestisce almeno Kilo dentro Antigravity, OpenCode dentro VS Code e Claude
  Code dentro Cursor;
- in caso di piu runtime non sceglie automaticamente;
- un client sconosciuto resta bloccato finche destinazione e capacita non sono
  state verificate;
- la scelta "solo workflow" dichiara esplicitamente l'assenza del routing;
- nessun router, provider, plugin, MCP o credenziale viene installato senza un
  consenso separato;
- i test dimostrano che vengono modificati soltanto il runtime scelto e lo
  stato `~/.ai-work-os/`.

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
