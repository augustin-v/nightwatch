# Informativa sulla privacy: Aurora Forecast - Nightwatch

**Informativa sulla privacy per Aurora Forecast - Nightwatch**

Ultimo aggiornamento: 2026-08-09

Augustin Villetard ("noi", "ci" o "nostro") gestisce Aurora Forecast - Nightwatch (l'"App"). Questa pagina spiega quali informazioni gestisce l'App, quali dati lasciano il tuo dispositivo e quali sono i tuoi diritti.

## In breve

L'App non usa account. La tua posizione viene utilizzata sul dispositivo per determinare cosa accadrà nel cielo sopra di te. Per ottenere una previsione delle nuvole inviamo una coordinata **approssimativa** (arrotondata a circa 10 km) a un servizio meteorologico pubblico. Gestiamo un piccolo endpoint di analisi proprietario per un insieme limitato di eventi di prodotto anonimi. Non riceviamo mai una cronologia dei luoghi in cui sei stato e non vendiamo mai informazioni su di te.

## Informazioni gestite dall'App

- **Posizione.** Con il tuo permesso, l'App legge la posizione del dispositivo per calcolare gli orari di tramonto e crepuscolo, la posizione della Luna, la probabilità di aurora alla tua latitudine e per richiedere una previsione locale delle nuvole. La posizione precisa viene utilizzata **solo sul tuo dispositivo** e viene memorizzata solo sul tuo dispositivo. Prima di qualsiasi richiesta di rete, la coordinata viene arrotondata a circa un decimo di grado (circa 10 km) e viene inviata solo quella coordinata arrotondata. Se salvi un luogo mentre l'accesso alla posizione è disponibile, l'App può continuare a fornire previsioni per quel luogo salvato anche dopo la revoca del permesso di localizzazione.
- **Luoghi salvati.** Vengono memorizzati sul tuo dispositivo. Non vengono trasmessi a noi.
- **Analisi.** Utilizziamo il nostro servizio proprietario Factory Analytics, ospitato su Cloudflare Workers e D1, per capire quali schermate vengono visualizzate, quali funzioni vengono utilizzate e se l'onboarding viene completato. Gli eventi sono associati a un identificatore di installazione casuale usato solo per l'analisi, non al tuo nome, indirizzo email, identificatore del dispositivo Apple o identificatore pubblicitario. Gli eventi di analisi **non** includono coordinate, luoghi salvati o altro testo inserito dall'utente.
- **Acquisti e abbonamenti.** Sono gestiti da Apple e RevenueCat. Vediamo lo stato dell'abbonamento, non i dati di pagamento, che sono gestiti interamente da Apple.
- **Interazione con il paywall.** Superwall registra quale paywall hai visualizzato e cosa hai fatto al suo interno.

Non vendiamo le tue informazioni personali e non utilizziamo i tuoi dati per pubblicità o tracciamento tra app.

## Cosa lascia il tuo dispositivo e dove viene inviato

| Cosa | Dove viene inviato | Perché |
|---|---|---|
| Coordinata arrotondata (~10 km) | MET Norway (Istituto meteorologico norvegese) | Previsione oraria della copertura nuvolosa |
| Nessun dato relativo alla posizione | NOAA Space Weather Prediction Center | Dati globali su aurora e attività geomagnetica; la richiesta non contiene la posizione |
| Eventi di utilizzo anonimi e identificatore di installazione usato solo per l'analisi | Factory Analytics, ospitato da Cloudflare | Analisi del prodotto e misurazione aggregata della fidelizzazione |
| Stato dell'abbonamento | RevenueCat, Apple | Diritti di accesso e ricevute |
| Eventi del paywall | Superwall | Distribuzione e test del paywall |

I dati meteorologici di MET Norway sono utilizzati con licenza CC BY 4.0. I dati di meteorologia spaziale sono forniti da NOAA SWPC, un servizio pubblico del governo degli Stati Uniti.

## Servizi di terze parti

- **Cloudflare** (responsabile del trattamento che ospita Factory Analytics): https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (abbonamenti): https://www.revenuecat.com/privacy
- **Superwall** (paywall): https://superwall.com/privacy
- **MET Norway** (meteo): https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (meteo spaziale): https://www.weather.gov/privacy
- **Apple App Store**: il trattamento dei pagamenti è disciplinato dall'informativa sulla privacy di Apple.

## Conservazione dei dati

Gli eventi grezzi di Factory Analytics vengono conservati per 14 giorni. I record a livello di installazione sul server vengono conservati fino a 45 giorni per calcolare la fidelizzazione aggregata e poi rimossi; le metriche a lungo termine contengono solo conteggi aggregati. L'identificatore casuale di analisi memorizzato sul dispositivo rimane finché non rimuovi l'App o i relativi dati. I dati relativi ad abbonamenti e paywall sono conservati da Apple, RevenueCat e Superwall secondo le rispettive informative. I dati di posizione non vengono conservati da noi, perché non li riceviamo mai.

## I tuoi diritti

Se ti trovi nello Spazio economico europeo, nel Regno Unito o in un'altra giurisdizione con una normativa comparabile, hai il diritto di accedere, rettificare, cancellare, limitare o opporti al trattamento dei dati personali che deteniamo su di te, nonché il diritto alla portabilità dei dati. Poiché l'App non dispone di account, i dati che deteniamo sono limitati ad analisi anonime e registri relativi agli abbonamenti. Per esercitare uno di questi diritti o chiederci di eliminare il tuo identificatore di analisi, scrivi a augustin.dev@tutamail.com; risponderemo entro 30 giorni.

Puoi inoltre:

- revocare in qualsiasi momento il permesso di localizzazione nelle Impostazioni di iOS (i luoghi salvati in precedenza resteranno disponibili);
- annullare l'abbonamento nelle impostazioni del tuo Apple ID.

La base giuridica per il trattamento dei dati di analisi e del paywall è il nostro legittimo interesse a gestire e migliorare l'App; la base giuridica per il trattamento degli abbonamenti è l'esecuzione del contratto con te.

## Privacy dei minori

L'App non è rivolta a minori di 13 anni e non raccogliamo consapevolmente informazioni personali di minori di 13 anni.

## Modifiche

Potremmo aggiornare questa informativa. Le modifiche vengono pubblicate a questo URL con una nuova data di "Ultimo aggiornamento".

## Contatti

augustin.dev@tutamail.com
