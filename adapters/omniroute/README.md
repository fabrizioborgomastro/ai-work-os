# Adapter OmniRoute

OmniRoute è una possibile implementazione di `core/ROUTING.md`; AI Work OS funziona anche con altri router o con modelli diretti.

`combos.json` contiene una raccomandazione portabile senza connection ID o credenziali. Non importare ciecamente gli slug: cataloghi, prezzi e policy cambiano.

## Configurazione richiesta

1. Creare credenziali separate Business e Light.
2. Applicare alla credenziale Business ZDR/no-training e allowlist dei soli modelli Business.
3. Applicare limiti di spesa separati.
4. Creare le quattro combo con i nomi esatti del manifest.
5. Vincolare ogni step OpenRouter alla credenziale corretta.
6. Per il giudice Kimi Business, usare una connessione dedicata se la versione OmniRoute non consente di associare un `connectionId` a `judgeModel`.
7. Verificare che nessun endpoint free compaia nelle due combo Business.

## Perché non è incluso un installer database

Il database interno di OmniRoute e gli identificatori delle connessioni sono dettagli di implementazione soggetti a migrazioni. AI Work OS non scrive direttamente nel database del router. Configurare tramite interfaccia/API pubblica della versione installata e usare il manifest come specifica verificabile.

## Controllo finale

- `business-engineering`: priority, Sol → DeepSeek → GLM;
- `business-review`: Fusion GLM/DeepSeek/MiMo, giudice Kimi su credenziale Business;
- `light-engineering`: free espliciti → DeepSeek paid floor;
- `light-review`: panel economico, giudice GLM;
- limiti e privacy confermati nel provider, non soltanto nel router.
