# Tietosuojakäytäntö: Aurora Forecast - Nightwatch

**Aurora Forecast - Nightwatch -sovelluksen tietosuojakäytäntö**

Viimeksi päivitetty: 2026-08-09

Augustin Villetard (”me”, ”meitä” tai ”meidän”) ylläpitää Aurora Forecast - Nightwatch -sovellusta (”Sovellus”). Tällä sivulla kerrotaan, mitä tietoja Sovellus käsittelee, mitä tietoja poistuu laitteeltasi ja mitä oikeuksia sinulla on.

## Lyhyesti

Sovelluksessa ei ole käyttäjätilejä. Sijaintiasi käytetään laitteellasi sen arvioimiseen, millaiset olosuhteet taivaalla ovat yläpuolellasi. Pilviennusteen hakemista varten lähetämme julkiselle sääpalvelulle **likimääräisen** koordinaatin (pyöristettynä noin 10 km:n tarkkuuteen). Ylläpidämme pientä omaa analytiikkapalvelua rajattua määrää anonyymejä tuotetapahtumia varten. Emme koskaan saa historiaa siitä, missä olet ollut, emmekä koskaan myy sinua koskevia tietoja.

## Sovelluksen käsittelemät tiedot

- **Sijainti.** Luvallasi Sovellus lukee laitteen sijainnin laskeakseen auringonlaskun ja hämärän ajat, Kuun sijainnin, revontulten todennäköisyyden leveysasteellasi sekä hakeakseen paikallisen pilviennusteen. Tarkkaa sijaintiasi käytetään **vain laitteellasi** ja se tallennetaan vain laitteellesi. Ennen verkkopyyntöä koordinaatti pyöristetään noin kymmenesosa-asteen tarkkuuteen (noin 10 km), ja vain tämä pyöristetty koordinaatti lähetetään. Jos tallennat paikan sijaintiluvan ollessa käytössä, Sovellus voi jatkaa ennustamista tälle tallennetulle paikalle sen jälkeen, kun poistat sijaintiluvan.
- **Tallentamasi paikat.** Tallennetaan laitteellesi. Niitä ei lähetetä meille.
- **Analytiikka.** Käytämme omaa Factory Analytics -palveluamme, joka toimii Cloudflare Workers- ja D1-palveluissa, ymmärtääksemme katsottuja näyttöjä, käytettyjä ominaisuuksia ja perehdytyksen valmistumista. Tapahtumat liitetään satunnaiseen, vain analytiikkaa varten käytettävään asennustunnisteeseen, ei nimeesi, sähköpostiosoitteeseesi, Apple-laitetunnisteeseesi tai mainostunnisteeseen. Analytiikkatapahtumat **eivät** sisällä koordinaattejasi, tallennettuja paikkoja tai muuta käyttäjän kirjoittamaa tekstiä.
- **Ostot ja tilaukset.** Apple ja RevenueCat käsittelevät ne. Näemme tilauksen tilan, emme maksutietojasi, jotka Apple käsittelee kokonaisuudessaan.
- **Maksumuurin käyttö.** Superwall tallentaa, minkä maksumuurin näit ja mitä teit siinä.

Emme myy henkilötietojasi emmekä käytä tietojasi mainontaan tai sovellusten väliseen seurantaan.

## Mitä laitteeltasi lähtee ja minne

| Mitä | Minne se menee | Miksi |
|---|---|---|
| Pyöristetty koordinaatti (~10 km) | MET Norway (Norjan ilmatieteen laitos) | Tuntikohtainen pilvisyysennuste |
| Ei sijaintiin liittyviä tietoja | NOAA Space Weather Prediction Center | Maailmanlaajuiset revontuli- ja geomagneettiset tiedot; pyyntö ei sisällä sijaintia |
| Anonyymit käyttötapahtumat ja vain analytiikkaan käytettävä asennustunniste | Factory Analytics, Cloudflaren isännöimä | Tuoteanalytiikka ja käyttäjäpysyvyyden koottu mittaus |
| Tilauksen tila | RevenueCat, Apple | Käyttöoikeudet ja kuitit |
| Maksumuuritapahtumat | Superwall | Maksumuurin toimittaminen ja testaus |

MET Norwayn säätietoja käytetään CC BY 4.0 -lisenssillä. Avaruussäätiedot tarjoaa NOAA SWPC, Yhdysvaltain hallinnon julkinen palvelu.

## Kolmansien osapuolten palvelut

- **Cloudflare** (Factory Analyticsin käsittelijä ja isännöijä): https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (tilaukset): https://www.revenuecat.com/privacy
- **Superwall** (maksumuurit): https://superwall.com/privacy
- **MET Norway** (sää): https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (avaruussää): https://www.weather.gov/privacy
- **Apple App Store**: Applen tietosuojakäytäntö koskee maksujen käsittelyä.

## Tietojen säilytys

Factory Analyticsin raakatapahtumia säilytetään 14 päivää. Palvelimella olevia asennustason tietueita säilytetään enintään 45 päivää koottujen käyttäjäpysyvyyslukujen laskemiseksi, minkä jälkeen ne poistetaan; pitkäaikaiset mittarit sisältävät vain koottuja lukumääriä. Laitteellesi tallennettu satunnainen analytiikkatunniste säilyy siellä, kunnes poistat Sovelluksen tai sen tiedot. Apple, RevenueCat ja Superwall säilyttävät tilaus- ja maksumuuritietoja omien käytäntöjensä mukaisesti. Emme säilytä sijaintitietoja lainkaan, koska emme koskaan saa niitä.

## Oikeutesi

Jos olet Euroopan talousalueella, Yhdistyneessä kuningaskunnassa tai muulla vastaavan lainsäädännön alueella, sinulla on oikeus päästä käsiksi hallussamme oleviin henkilötietoihisi, oikaista tai poistaa niitä, rajoittaa niiden käsittelyä tai vastustaa sitä sekä siirtää tietosi. Koska Sovelluksessa ei ole käyttäjätilejä, hallussamme olevat tiedot rajoittuvat anonyymiin analytiikkaan ja tilaustietoihin. Jos haluat käyttää jotakin näistä oikeuksista tai pyytää analytiikkatunnisteesi poistamista, lähetä sähköpostia osoitteeseen augustin.dev@tutamail.com. Vastaamme 30 päivän kuluessa.

Voit myös:

- peruuttaa sijaintiluvan milloin tahansa iOS:n Asetuksissa (aiemmin tallennetut paikat säilyvät käytettävissä);
- peruuttaa tilauksesi Apple ID -asetuksissa.

Analytiikan ja maksumuurin käsittelyn oikeusperuste on oikeutettu etumme Sovelluksen ylläpitämiseen ja parantamiseen; tilaustietojen käsittelyn oikeusperuste on kanssasi tehdyn sopimuksen täytäntöönpano.

## Lasten yksityisyys

Sovellusta ei ole suunnattu alle 13-vuotiaille emmekä tietoisesti kerää alle 13-vuotiaiden henkilötietoja.

## Muutokset

Voimme päivittää tätä käytäntöä. Muutokset julkaistaan tässä URL-osoitteessa uuden ”Viimeksi päivitetty” -päivämäärän kanssa.

## Yhteystiedot

augustin.dev@tutamail.com
