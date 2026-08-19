# Personvernerklæring: Aurora Forecast - Nightwatch

**Personvernerklæring for Aurora Forecast - Nightwatch**

Sist oppdatert: 2026-08-09

Augustin Villetard («vi», «oss» eller «vår») driver Aurora Forecast - Nightwatch («appen»). Denne siden forklarer hvilken informasjon appen håndterer, hvilke data som forlater enheten din, og hvilke rettigheter du har.

## Kort fortalt

Appen har ingen kontoer. Posisjonen din brukes på enheten for å finne ut hvordan forholdene på himmelen over deg blir. For å hente et skyvarsel sender vi en **omtrentlig** koordinat (avrundet til rundt 10 km) til en offentlig værtjeneste. Vi driver et lite førsteparts analyse-endepunkt for et begrenset sett med anonyme produkthendelser. Vi mottar aldri en historikk over hvor du har vært, og vi selger aldri informasjon om deg.

## Informasjon appen håndterer

- **Posisjon.** Med din tillatelse leser appen enhetens posisjon for å beregne solnedgang og skumring, månens posisjon, sannsynligheten for nordlys på breddegraden din og for å be om et lokalt skyvarsel. Den nøyaktige posisjonen din brukes **bare på enheten din** og lagres bare på enheten din. Før en nettverksforespørsel avrundes koordinaten til omtrent en tidels grad (rundt 10 km), og bare denne avrundede koordinaten sendes. Hvis du lagrer et sted mens posisjonstilgang er tilgjengelig, kan appen fortsette å lage prognoser for det lagrede stedet etter at du trekker tilbake posisjonstillatelsen.
- **Steder du lagrer.** Lagres på enheten din og overføres ikke til oss.
- **Analyse.** Vi bruker vår egen Factory Analytics-tjeneste, driftet på Cloudflare Workers og D1, for å forstå hvilke skjermer som vises, hvilke funksjoner som brukes og om introduksjonen fullføres. Hendelser knyttes til en tilfeldig installasjons-ID som bare brukes til analyse, ikke til navn, e-postadresse, Apple-enhetsidentifikator eller annonseidentifikator. Analysehendelser inneholder **ikke** koordinatene dine, lagrede steder eller annen tekst skrevet av brukeren.
- **Kjøp og abonnementer.** Håndteres av Apple og RevenueCat. Vi ser abonnementsstatus, ikke betalingsopplysningene dine, som Apple håndterer i sin helhet.
- **Interaksjon med betalingsveggen.** Superwall registrerer hvilken betalingsvegg du så og hva du gjorde der.

Vi selger ikke personopplysningene dine og bruker ikke dataene dine til annonsering eller sporing på tvers av apper.

## Hva som forlater enheten din, og hvor det går

| Hva | Hvor det går | Hvorfor |
|---|---|---|
| Avrundet koordinat (~10 km) | MET Norway (Meteorologisk institutt) | Timevarsel for skydekke |
| Ingen posisjonsrelaterte data | NOAA Space Weather Prediction Center | Globale nordlys- og geomagnetiske data; forespørselen inneholder ingen posisjon |
| Anonyme brukshendelser og en installasjons-ID som bare brukes til analyse | Factory Analytics, driftet av Cloudflare | Produktanalyse og aggregert måling av brukerbevaring |
| Abonnementsstatus | RevenueCat, Apple | Tilganger og kvitteringer |
| Betalingsvegghendelser | Superwall | Levering og testing av betalingsveggen |

Værdata fra MET Norway brukes under CC BY 4.0. Romværdata leveres av NOAA SWPC, en offentlig tjeneste fra amerikanske myndigheter.

## Tredjepartstjenester

- **Cloudflare** (databehandler som drifter Factory Analytics): https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (abonnementer): https://www.revenuecat.com/privacy
- **Superwall** (betalingsvegger): https://superwall.com/privacy
- **MET Norway** (vær): https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (romvær): https://www.weather.gov/privacy
- **Apple App Store**: Apples personvernerklæring gjelder for betalingsbehandlingen.

## Lagring av data

Rå Factory Analytics-hendelser lagres i 14 dager. Installasjonsoppføringer på serversiden lagres i opptil 45 dager for å beregne aggregert brukerbevaring og fjernes deretter; langsiktige målinger inneholder bare aggregerte antall. Den tilfeldige analyse-ID-en som lagres på enheten din, blir der til du fjerner appen eller dataene dens. Abonnements- og betalingsveggdata lagres av Apple, RevenueCat og Superwall som beskrevet i deres retningslinjer. Vi lagrer ikke posisjonsdata i det hele tatt, fordi vi aldri mottar dem.

## Rettighetene dine

Hvis du befinner deg i Det europeiske økonomiske samarbeidsområdet, Storbritannia eller en annen jurisdiksjon med tilsvarende lovgivning, har du rett til innsyn, retting, sletting, begrensning av eller innsigelse mot behandling av personopplysninger vi har om deg, samt dataportabilitet. Fordi appen ikke har kontoer, er dataene vi har begrenset til anonym analyse og abonnementsoppføringer. For å utøve noen av disse rettighetene eller be oss slette analyse-ID-en din, send e-post til augustin.dev@tutamail.com. Vi svarer innen 30 dager.

Du kan også:

- trekke tilbake posisjonstillatelsen når som helst i iOS-innstillinger (tidligere lagrede steder forblir tilgjengelige);
- si opp abonnementet i Apple ID-innstillingene dine.

Det rettslige grunnlaget for analyse- og betalingsveggbehandling er vår berettigede interesse i å drive og forbedre appen; det rettslige grunnlaget for abonnementsbehandling er oppfyllelse av avtalen vår med deg.

## Barns personvern

Appen er ikke rettet mot barn under 13 år, og vi samler ikke bevisst inn personopplysninger fra barn under 13 år.

## Endringer

Vi kan oppdatere denne erklæringen. Endringer publiseres på denne URL-en med en ny «Sist oppdatert»-dato.

## Kontakt

augustin.dev@tutamail.com
