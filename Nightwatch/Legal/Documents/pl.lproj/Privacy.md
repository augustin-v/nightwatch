# Polityka prywatności: Aurora Forecast - Nightwatch

**Polityka prywatności aplikacji Aurora Forecast - Nightwatch**

Ostatnia aktualizacja: 2026-08-09

Augustin Villetard („my”, „nas” lub „nasz”) prowadzi aplikację Aurora Forecast - Nightwatch („Aplikacja”). Na tej stronie wyjaśniamy, jakie informacje przetwarza Aplikacja, jakie dane opuszczają Twoje urządzenie oraz jakie masz prawa.

## W skrócie

Aplikacja nie korzysta z kont użytkowników. Twoja lokalizacja jest używana na urządzeniu do określenia warunków na niebie nad Tobą. Aby pobrać prognozę zachmurzenia, wysyłamy **przybliżone** współrzędne (zaokrąglone do około 10 km) do publicznej usługi pogodowej. Prowadzimy niewielki, własny punkt analityczny do ograniczonego zestawu anonimowych zdarzeń produktowych. Nigdy nie otrzymujemy historii miejsc, w których byłeś(-aś), i nigdy nie sprzedajemy informacji o Tobie.

## Informacje przetwarzane przez Aplikację

- **Lokalizacja.** Za Twoją zgodą Aplikacja odczytuje lokalizację urządzenia, aby obliczać godziny zachodu słońca i zmierzchu, pozycję Księżyca, prawdopodobieństwo zorzy na Twojej szerokości geograficznej oraz pobierać lokalną prognozę zachmurzenia. Dokładna lokalizacja jest używana **wyłącznie na Twoim urządzeniu** i tylko tam jest przechowywana. Przed każdym żądaniem sieciowym współrzędne są zaokrąglane do około jednej dziesiątej stopnia (około 10 km) i wysyłana jest wyłącznie ta zaokrąglona wartość. Jeśli zapiszesz miejsce, gdy dostęp do lokalizacji jest dostępny, Aplikacja może nadal tworzyć prognozy dla tego miejsca po cofnięciu uprawnienia do lokalizacji.
- **Zapisane miejsca.** Są przechowywane na Twoim urządzeniu. Nie są przesyłane do nas.
- **Analityka.** Korzystamy z własnej usługi Factory Analytics, hostowanej w Cloudflare Workers i D1, aby rozumieć, które ekrany są oglądane, z jakich funkcji użytkownicy korzystają i czy kończą onboarding. Zdarzenia są powiązane z losowym identyfikatorem instalacji używanym wyłącznie do analityki, a nie z Twoim imieniem i nazwiskiem, adresem e-mail, identyfikatorem urządzenia Apple ani identyfikatorem reklamowym. Zdarzenia analityczne **nie** zawierają współrzędnych, zapisanych miejsc ani innego tekstu wprowadzanego przez użytkownika.
- **Zakupy i subskrypcje.** Są obsługiwane przez Apple i RevenueCat. Widzimy status subskrypcji, ale nie dane płatnicze, które są w całości obsługiwane przez Apple.
- **Interakcje z paywallem.** Superwall rejestruje, który paywall został Ci pokazany i jakie działania zostały na nim wykonane.

Nie sprzedajemy Twoich danych osobowych i nie wykorzystujemy danych do reklam ani śledzenia między aplikacjami.

## Co opuszcza Twoje urządzenie i dokąd trafia

| Co | Dokąd trafia | Dlaczego |
|---|---|---|
| Zaokrąglone współrzędne (~10 km) | MET Norway (Norweski Instytut Meteorologiczny) | Godzinowa prognoza zachmurzenia |
| Brak danych związanych z lokalizacją | NOAA Space Weather Prediction Center | Globalne dane o zorzy i aktywności geomagnetycznej; żądanie nie zawiera lokalizacji |
| Anonimowe zdarzenia użycia i identyfikator instalacji używany tylko do analityki | Factory Analytics, hostowane przez Cloudflare | Analityka produktu i zagregowany pomiar retencji |
| Stan subskrypcji | RevenueCat, Apple | Uprawnienia i potwierdzenia zakupu |
| Zdarzenia paywalla | Superwall | Wyświetlanie i testowanie paywalla |

Dane pogodowe MET Norway są wykorzystywane na licencji CC BY 4.0. Dane o pogodzie kosmicznej dostarcza NOAA SWPC, publiczna usługa rządu USA.

## Usługi zewnętrzne

- **Cloudflare** (podmiot przetwarzający hostujący Factory Analytics): https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (subskrypcje): https://www.revenuecat.com/privacy
- **Superwall** (paywalle): https://superwall.com/privacy
- **MET Norway** (pogoda): https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (pogoda kosmiczna): https://www.weather.gov/privacy
- **Apple App Store**: przetwarzanie płatności podlega polityce prywatności Apple.

## Przechowywanie danych

Surowe zdarzenia Factory Analytics są przechowywane przez 14 dni. Rekordy instalacji po stronie serwera są przechowywane do 45 dni w celu obliczenia zagregowanej retencji, a następnie usuwane; długoterminowe metryki zawierają wyłącznie zagregowane wartości. Losowy identyfikator analityczny zapisany na Twoim urządzeniu pozostaje tam do chwili usunięcia Aplikacji lub jej danych. Dane o subskrypcjach i paywallu są przechowywane przez Apple, RevenueCat i Superwall zgodnie z ich zasadami. Nie przechowujemy danych lokalizacyjnych, ponieważ nigdy ich nie otrzymujemy.

## Twoje prawa

Jeśli przebywasz w Europejskim Obszarze Gospodarczym, Wielkiej Brytanii lub innej jurysdykcji z porównywalnymi przepisami, masz prawo dostępu do swoich danych osobowych, ich sprostowania, usunięcia, ograniczenia przetwarzania, wniesienia sprzeciwu wobec przetwarzania oraz prawo do przenoszenia danych. Ponieważ Aplikacja nie ma kont użytkowników, dane, które posiadamy, ograniczają się do anonimowych danych analitycznych i zapisów dotyczących subskrypcji. Aby skorzystać z tych praw lub poprosić o usunięcie identyfikatora analitycznego, napisz na adres augustin.dev@tutamail.com. Odpowiemy w ciągu 30 dni.

Możesz również:

- w dowolnym momencie cofnąć uprawnienie do lokalizacji w Ustawieniach iOS (wcześniej zapisane miejsca pozostaną dostępne);
- anulować subskrypcję w ustawieniach swojego Apple ID.

Podstawą prawną przetwarzania danych analitycznych i danych dotyczących paywalla jest nasz prawnie uzasadniony interes w prowadzeniu i ulepszaniu Aplikacji; podstawą prawną przetwarzania danych dotyczących subskrypcji jest wykonanie umowy z Tobą.

## Prywatność dzieci

Aplikacja nie jest skierowana do dzieci poniżej 13 roku życia i świadomie nie zbieramy danych osobowych dzieci poniżej 13 roku życia.

## Zmiany

Możemy aktualizować tę politykę. Zmiany są publikowane pod tym adresem URL wraz z nową datą „Ostatniej aktualizacji”.

## Kontakt

augustin.dev@tutamail.com
