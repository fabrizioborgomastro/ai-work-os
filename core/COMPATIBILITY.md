# Contratto di compatibilita

La compatibilita di AI Work OS riguarda una combinazione, non il solo editor:

```text
host/editor -> runtime agentico -> adapter AI Work OS -> routing
```

L'host descrive dove gira il terminale o l'estensione. Il **target** identifica
invece il runtime che deve ricevere i file. Aprire Claude Code nel terminale di
Cursor significa quindi `host=cursor` e `target=claude`: nessun file deve essere
installato in Cursor, Kilo o negli altri runtime.

## Livelli del workflow

- `native`: ruoli distinti installabili nel formato nativo previsto dall'adapter;
- `adapted`: il workflow e riprodotto tramite primitive differenti, per esempio prompt;
- `skill-only`: il runtime riceve le skill, ma non l'intero modello di agenti nativi;
- `unverified`: destinazione o capacita non sono state verificate;
- `unsupported`: le capacita minime richieste non sono disponibili.

Il routing e valutato separatamente: `native-combo`, `external-manual`, `unknown`
o `unsupported`. Installare una skill non dimostra che combo, provider, fallback,
privacy e budget siano configurati.

## Risoluzione del target

L'installer usa, nell'ordine:

1. `-Target` / `--target` esplicito;
2. la dichiarazione `AI_WORK_OS_TARGET` impostata dal runtime chiamante;
3. l'unico runtime catalogato trovato in `PATH`;
4. nessuna scelta automatica se i candidati sono zero o piu di uno.

Host ed editor non vengono mai usati come destinazione implicita.

## Runtime non catalogati

Un nome sconosciuto produce un audit minimo con evidenze `VERIFIED`, `INFERRED`
e `UNKNOWN`. L'analisi non scrive file. Per autorizzare l'installazione servono
una directory skill esplicita e l'accettazione della compatibilita non verificata.
L'installer non interroga Internet e non inventa percorsi convenzionali.

Il catalogo locale e `adapters/compatibility.tsv`. Le righe verificate devono
indicare data e documento di evidenza; un aggiornamento delle capacita di un
client richiede l'aggiornamento congiunto di catalogo, adapter e test.
