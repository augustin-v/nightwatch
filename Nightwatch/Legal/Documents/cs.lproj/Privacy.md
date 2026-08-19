# Zásady ochrany osobních údajů: Aurora Forecast - Nightwatch

**Zásady ochrany osobních údajů pro Aurora Forecast - Nightwatch**

Poslední aktualizace: 2026-08-09

Augustin Villetard („my“, „nás“ nebo „naše“) provozuje Aurora Forecast - Nightwatch („Aplikace“). Tato stránka vysvětluje, jaké informace Aplikace zpracovává, jaké údaje opouštějí vaše zařízení a jaká máte práva.

## Stručně

Aplikace nemá uživatelské účty. Vaše poloha se používá přímo ve vašem zařízení k určení podmínek na obloze nad vámi. Pro získání předpovědi oblačnosti odesíláme **přibližnou** souřadnici (zaokrouhlenou zhruba na 10 km) veřejné meteorologické službě. Pro omezený soubor anonymních produktových událostí provozujeme malou vlastní analytickou službu. Nikdy nedostáváme historii míst, kde jste byli, a nikdy neprodáváme informace o vás.

## Informace, které Aplikace zpracovává

- **Poloha.** S vaším svolením Aplikace čte polohu zařízení, aby vypočítala časy západu slunce a soumraku, polohu Měsíce, pravděpodobnost polární záře ve vaší zeměpisné šířce a požádala o místní předpověď oblačnosti. Vaše přesná poloha se používá **pouze ve vašem zařízení** a ukládá se pouze v něm. Před jakýmkoli síťovým požadavkem se souřadnice zaokrouhlí přibližně na jednu desetinu stupně (asi 10 km) a odešle se pouze tato zaokrouhlená souřadnice. Pokud uložíte místo v době, kdy má Aplikace přístup k poloze, může pro toto uložené místo dál vytvářet předpovědi i poté, co oprávnění k poloze odeberete.
- **Uložená místa.** Ukládají se ve vašem zařízení a nejsou nám předávána.
- **Analytika.** Používáme vlastní službu Factory Analytics hostovanou na Cloudflare Workers a D1, abychom rozuměli tomu, které obrazovky se zobrazují, které funkce se používají a zda uživatel dokončí úvodní nastavení. Události jsou spojeny s náhodným identifikátorem instalace používaným pouze pro analytiku, nikoli s vaším jménem, e-mailem, identifikátorem zařízení Apple ani reklamním identifikátorem. Analytické události **neobsahují** vaše souřadnice, uložená místa ani jiný text zadaný uživatelem.
- **Nákupy a předplatná.** Zpracovávají je Apple a RevenueCat. Vidíme stav předplatného, nikoli vaše platební údaje, které zcela zpracovává Apple.
- **Interakce s paywallem.** Superwall zaznamenává, který paywall jste viděli a co jste na něm udělali.

Vaše osobní údaje neprodáváme a nepoužíváme je k reklamě ani ke sledování napříč aplikacemi.

## Co opouští vaše zařízení a kam to jde

| Co | Kam to jde | Proč |
|---|---|---|
| Zaokrouhlená souřadnice (~10 km) | MET Norway (Norský meteorologický institut) | Hodinová předpověď oblačnosti |
| Žádné údaje související s polohou | NOAA Space Weather Prediction Center | Globální data o polární záři a geomagnetické aktivitě; požadavek neobsahuje polohu |
| Anonymní události používání a identifikátor instalace pouze pro analytiku | Factory Analytics, hostované u Cloudflare | Produktová analytika a agregované měření retence |
| Stav předplatného | RevenueCat, Apple | Oprávnění a účtenky |
| Události paywallu | Superwall | Doručování a testování paywallu |

Meteorologická data MET Norway používáme pod licencí CC BY 4.0. Data o kosmickém počasí poskytuje NOAA SWPC, veřejná služba vlády USA.

## Služby třetích stran

- **Cloudflare** (zpracovatel hostující Factory Analytics): https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (předplatná): https://www.revenuecat.com/privacy
- **Superwall** (paywally): https://superwall.com/privacy
- **MET Norway** (počasí): https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (kosmické počasí): https://www.weather.gov/privacy
- **Apple App Store**: zpracování plateb se řídí zásadami ochrany osobních údajů společnosti Apple.

## Uchovávání dat

Nezpracované události Factory Analytics uchováváme 14 dní. Záznamy na úrovni instalace na serveru se uchovávají až 45 dní pro výpočet agregované retence a poté se odstraňují; dlouhodobé metriky obsahují pouze agregované počty. Náhodný analytický identifikátor uložený ve vašem zařízení v něm zůstane, dokud Aplikaci nebo její data neodstraníte. Údaje o předplatném a paywallu uchovávají Apple, RevenueCat a Superwall podle svých zásad. Údaje o poloze vůbec neuchováváme, protože je nikdy nedostáváme.

## Vaše práva

Pokud se nacházíte v Evropském hospodářském prostoru, Spojeném království nebo jiné jurisdikci se srovnatelnými právními předpisy, máte právo na přístup k osobním údajům, které o vás máme, jejich opravu či vymazání, omezení zpracování nebo vznesení námitky proti zpracování a také právo na přenositelnost údajů. Protože Aplikace nemá účty, údaje, které máme, se omezují na anonymní analytiku a záznamy o předplatném. Chcete-li některé z těchto práv uplatnit nebo požádat o odstranění analytického identifikátoru, napište na augustin.dev@tutamail.com. Odpovíme do 30 dní.

Můžete také:

- kdykoli odvolat oprávnění k poloze v Nastavení iOS (dříve uložená místa zůstanou dostupná);
- zrušit předplatné v nastavení svého Apple ID.

Právním základem pro zpracování analytiky a údajů paywallu je náš oprávněný zájem na provozu a zlepšování Aplikace; právním základem pro zpracování předplatného je plnění naší smlouvy s vámi.

## Soukromí dětí

Aplikace není určena dětem mladším 13 let a vědomě neshromažďujeme osobní údaje dětí mladších 13 let.

## Změny

Tyto zásady můžeme aktualizovat. Změny budou zveřejněny na této URL s novým datem „Poslední aktualizace“.

## Kontakt

augustin.dev@tutamail.com
