# Integritetspolicy: Aurora Forecast - Nightwatch

**Integritetspolicy för Aurora Forecast - Nightwatch**

Senast uppdaterad: 2026-08-09

Augustin Villetard (”vi”, ”oss” eller ”vår”) driver Aurora Forecast - Nightwatch (”appen”). Den här sidan förklarar vilken information appen hanterar, vilka uppgifter som lämnar din enhet och vilka rättigheter du har.

## Kortversionen

Appen har inga konton. Din plats används på enheten för att avgöra hur förhållandena på himlen ovanför dig blir. För att hämta en molnprognos skickar vi en **ungefärlig** koordinat (avrundad till cirka 10 km) till en offentlig vädertjänst. Vi driver en liten egen analystjänst för en begränsad mängd anonyma produkthändelser. Vi får aldrig någon historik över var du har varit och säljer aldrig information om dig.

## Information som appen hanterar

- **Plats.** Med ditt tillstånd läser appen enhetens plats för att beräkna tider för solnedgång och skymning, månens position, sannolikheten för norrsken på din breddgrad och för att begära en lokal molnprognos. Din exakta plats används **endast på din enhet** och lagras endast på din enhet. Före varje nätverksförfrågan avrundas koordinaten till ungefär en tiondels grad (cirka 10 km), och endast den avrundade koordinaten skickas. Om du sparar en plats medan platsåtkomst är tillgänglig kan appen fortsätta prognostisera för den sparade platsen efter att du återkallat platsbehörigheten.
- **Platser du sparar.** Lagrade på din enhet. Överförs inte till oss.
- **Analys.** Vi använder vår egen Factory Analytics-tjänst, som körs på Cloudflare Workers och D1, för att förstå vilka skärmar som visas, vilka funktioner som används och om introduktionen slutförs. Händelser kopplas till ett slumpmässigt installations-ID som endast används för analys, inte till ditt namn, din e-postadress, Apple-enhetsidentifierare eller annonsidentifierare. Analyshändelser innehåller **inte** dina koordinater, sparade platser eller annan text som användaren skriver in.
- **Köp och prenumerationer.** Hanteras av Apple och RevenueCat. Vi ser prenumerationsstatus, inte dina betalningsuppgifter, som Apple hanterar helt och hållet.
- **Interaktion med betalväggen.** Superwall registrerar vilken betalvägg du såg och vad du gjorde där.

Vi säljer inte dina personuppgifter och använder inte dina data för annonsering eller spårning mellan appar.

## Vad som lämnar din enhet och vart det går

| Vad | Vart det går | Varför |
|---|---|---|
| Avrundad koordinat (~10 km) | MET Norway (Norska meteorologiska institutet) | Timvis molnprognos |
| Inga platsrelaterade uppgifter | NOAA Space Weather Prediction Center | Globala norrskens- och geomagnetiska data; förfrågan innehåller ingen plats |
| Anonyma användningshändelser och ett installations-ID endast för analys | Factory Analytics, driftat av Cloudflare | Produktanalys och aggregerad mätning av retention |
| Prenumerationsstatus | RevenueCat, Apple | Behörigheter och kvitton |
| Betalväggshändelser | Superwall | Leverans och testning av betalväggen |

Väderdata från MET Norway används under CC BY 4.0. Rymdväderdata tillhandahålls av NOAA SWPC, en offentlig tjänst från USA:s regering.

## Tredjepartstjänster

- **Cloudflare** (personuppgiftsbiträde som driftar Factory Analytics): https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (prenumerationer): https://www.revenuecat.com/privacy
- **Superwall** (betalväggar): https://superwall.com/privacy
- **MET Norway** (väder): https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (rymdväder): https://www.weather.gov/privacy
- **Apple App Store**: Apples integritetspolicy reglerar betalningshanteringen.

## Datalagring

Råa Factory Analytics-händelser sparas i 14 dagar. Installationsposter på serversidan sparas i upp till 45 dagar för att beräkna aggregerad retention och tas sedan bort; långlivade mätvärden innehåller endast aggregerade antal. Det slumpmässiga analys-ID som lagras på din enhet finns kvar tills du tar bort appen eller dess data. Prenumerations- och betalväggsdata lagras av Apple, RevenueCat och Superwall enligt deras policyer. Vi lagrar inga platsdata alls, eftersom vi aldrig tar emot dem.

## Dina rättigheter

Om du befinner dig inom Europeiska ekonomiska samarbetsområdet, Storbritannien eller en annan jurisdiktion med jämförbar lagstiftning har du rätt att få tillgång till, rätta, radera, begränsa eller invända mot behandling av personuppgifter som vi har om dig samt rätt till dataportabilitet. Eftersom appen inte har konton är de uppgifter vi har begränsade till anonym analys och prenumerationsposter. För att utöva någon av dessa rättigheter eller be oss radera ditt analys-ID, mejla augustin.dev@tutamail.com. Vi svarar inom 30 dagar.

Du kan också:

- återkalla platsbehörighet när som helst i iOS-inställningarna (tidigare sparade platser finns kvar);
- avsluta din prenumeration i inställningarna för ditt Apple-ID.

Den rättsliga grunden för analys- och betalväggsbehandling är vårt berättigade intresse av att driva och förbättra appen; den rättsliga grunden för prenumerationsbehandling är fullgörandet av vårt avtal med dig.

## Barns integritet

Appen riktar sig inte till barn under 13 år och vi samlar inte medvetet in personuppgifter från barn under 13 år.

## Ändringar

Vi kan uppdatera denna policy. Ändringar publiceras på denna URL med ett nytt datum för ”Senast uppdaterad”.

## Kontakt

augustin.dev@tutamail.com
