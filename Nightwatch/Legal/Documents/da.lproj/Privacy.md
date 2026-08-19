# Privatlivspolitik: Aurora Forecast - Nightwatch

**Privatlivspolitik for Aurora Forecast - Nightwatch**

Senest opdateret: 2026-08-09

Augustin Villetard ("vi", "os" eller "vores") driver Aurora Forecast - Nightwatch ("appen"). Denne side forklarer, hvilke oplysninger appen håndterer, hvilke data der forlader din enhed, og hvilke rettigheder du har.

## Kort fortalt

Appen har ingen konti. Din placering bruges på din enhed til at vurdere forholdene på himlen over dig. For at hente en skyprognose sender vi en **omtrentlig** koordinat (afrundet til cirka 10 km) til en offentlig vejrtjeneste. Vi driver et lille førsteparts-analyseendepunkt til et begrænset sæt anonyme produkthændelser. Vi modtager aldrig en historik over, hvor du har været, og vi sælger aldrig oplysninger om dig.

## Oplysninger, som appen håndterer

- **Placering.** Med din tilladelse læser appen enhedens placering for at beregne tider for solnedgang og tusmørke, Månens position, sandsynligheden for nordlys på din breddegrad og for at anmode om en lokal skyprognose. Din præcise placering bruges **kun på din enhed** og gemmes kun på din enhed. Før en netværksanmodning afrundes koordinaten til cirka en tiendedel grad (omkring 10 km), og kun denne afrundede koordinat sendes. Hvis du gemmer et sted, mens placeringsadgang er tilgængelig, kan appen fortsætte med at lave prognoser for det gemte sted, efter at du tilbagekalder placeringstilladelsen.
- **Steder, du gemmer.** Gemmes på din enhed og overføres ikke til os.
- **Analyse.** Vi bruger vores egen Factory Analytics-tjeneste, som hostes på Cloudflare Workers og D1, til at forstå, hvilke skærme der ses, hvilke funktioner der bruges, og om onboarding gennemføres. Hændelser knyttes til en tilfældig installationsidentifikator, der kun bruges til analyse, ikke til dit navn, din e-mailadresse, Apple-enhedsidentifikator eller annonceidentifikator. Analysehændelser indeholder **ikke** dine koordinater, gemte steder eller anden tekst indtastet af brugeren.
- **Køb og abonnementer.** Håndteres af Apple og RevenueCat. Vi ser abonnementsstatus, ikke dine betalingsoplysninger, som Apple håndterer fuldt ud.
- **Interaktion med betalingsvæggen.** Superwall registrerer, hvilken betalingsvæg du så, og hvad du gjorde på den.

Vi sælger ikke dine personoplysninger og bruger ikke dine data til annoncering eller sporing på tværs af apps.

## Hvad der forlader din enhed, og hvor det sendes hen

| Hvad | Hvor det sendes hen | Hvorfor |
|---|---|---|
| Afrundet koordinat (~10 km) | MET Norway (Norsk Meteorologisk Institut) | Timebaseret prognose for skydække |
| Ingen placeringsrelaterede data | NOAA Space Weather Prediction Center | Globale nordlys- og geomagnetiske data; anmodningen indeholder ingen placering |
| Anonyme brugshændelser og en installationsidentifikator kun til analyse | Factory Analytics, hostet af Cloudflare | Produktanalyse og aggregeret måling af fastholdelse |
| Abonnementsstatus | RevenueCat, Apple | Adgangsrettigheder og kvitteringer |
| Betalingsvægshændelser | Superwall | Levering og test af betalingsvæggen |

Vejrdata fra MET Norway bruges under CC BY 4.0. Rumvejrsdata leveres af NOAA SWPC, en offentlig tjeneste fra den amerikanske regering.

## Tredjepartstjenester

- **Cloudflare** (databehandler, der hoster Factory Analytics): https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (abonnementer): https://www.revenuecat.com/privacy
- **Superwall** (betalingsvægge): https://superwall.com/privacy
- **MET Norway** (vejr): https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (rumvejr): https://www.weather.gov/privacy
- **Apple App Store**: Apples privatlivspolitik gælder for betalingsbehandlingen.

## Opbevaring af data

Rå Factory Analytics-hændelser opbevares i 14 dage. Installationsposter på serversiden opbevares i op til 45 dage for at beregne aggregeret fastholdelse og fjernes derefter; langsigtede målinger indeholder kun aggregerede antal. Den tilfældige analyseidentifikator, der er gemt på din enhed, bliver der, indtil du fjerner appen eller dens data. Abonnements- og betalingsvægsdata opbevares af Apple, RevenueCat og Superwall som beskrevet i deres politikker. Vi opbevarer slet ikke placeringsdata, fordi vi aldrig modtager dem.

## Dine rettigheder

Hvis du befinder dig i Det Europæiske Økonomiske Samarbejdsområde, Storbritannien eller en anden jurisdiktion med sammenlignelig lovgivning, har du ret til adgang, rettelse, sletning, begrænsning af eller indsigelse mod behandling af personoplysninger, vi har om dig, samt dataportabilitet. Da appen ikke har konti, er de data, vi har, begrænset til anonym analyse og abonnementsregistre. For at udøve nogen af disse rettigheder eller bede os om at slette din analyseidentifikator kan du sende en e-mail til augustin.dev@tutamail.com. Vi svarer inden for 30 dage.

Du kan også:

- tilbagekalde placeringstilladelsen når som helst i iOS-indstillingerne (tidligere gemte steder forbliver tilgængelige);
- opsige dit abonnement i dine Apple ID-indstillinger.

Retsgrundlaget for analyse- og betalingsvægsbehandling er vores legitime interesse i at drive og forbedre appen; retsgrundlaget for abonnementsbehandling er opfyldelse af vores aftale med dig.

## Børns privatliv

Appen er ikke rettet mod børn under 13 år, og vi indsamler ikke bevidst personoplysninger fra børn under 13 år.

## Ændringer

Vi kan opdatere denne politik. Ændringer offentliggøres på denne URL med en ny "Senest opdateret"-dato.

## Kontakt

augustin.dev@tutamail.com
