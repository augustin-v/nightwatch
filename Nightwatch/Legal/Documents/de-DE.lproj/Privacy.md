# Datenschutzrichtlinie: Aurora Forecast - Nightwatch

**Datenschutzrichtlinie für Aurora Forecast - Nightwatch**

Zuletzt aktualisiert: 2026-08-09

Augustin Villetard („wir“, „uns“ oder „unser“) betreibt Aurora Forecast - Nightwatch (die „App“). Auf dieser Seite wird erklärt, welche Informationen die App verarbeitet, welche Daten dein Gerät verlassen und welche Rechte du hast.

## Kurzfassung

Die App verwendet keine Konten. Dein Standort wird auf deinem Gerät genutzt, um die Bedingungen am Himmel über dir zu bestimmen. Um eine Wolkenvorhersage abzurufen, senden wir eine **ungefähre** Koordinate (auf etwa 10 km gerundet) an einen öffentlichen Wetterdienst. Wir betreiben einen kleinen eigenen Analyse-Endpunkt für einen begrenzten Umfang an anonymen Produkt-Ereignissen. Wir erhalten niemals einen Verlauf der Orte, an denen du warst, und verkaufen niemals Informationen über dich.

## Informationen, die die App verarbeitet

- **Standort.** Mit deiner Erlaubnis liest die App den Standort deines Geräts aus, um Sonnenuntergang und Dämmerung, die Mondposition und die Polarlichtwahrscheinlichkeit auf deinem Breitengrad zu berechnen und eine lokale Wolkenvorhersage anzufordern. Dein genauer Standort wird **nur auf deinem Gerät** verwendet und nur dort gespeichert. Vor jeder Netzwerkanfrage wird die Koordinate auf ungefähr ein Zehntelgrad (etwa 10 km) gerundet und nur diese gerundete Koordinate gesendet. Wenn du einen Ort speicherst, während der Standortzugriff verfügbar ist, kann die App auch nach dem Widerruf der Standortberechtigung weiter Vorhersagen für diesen gespeicherten Ort erstellen.
- **Gespeicherte Orte.** Werden auf deinem Gerät gespeichert und nicht an uns übertragen.
- **Analyse.** Wir nutzen unseren eigenen Dienst Factory Analytics, der auf Cloudflare Workers und D1 gehostet wird, um zu verstehen, welche Bildschirme angesehen, welche Funktionen genutzt und ob das Onboarding abgeschlossen wird. Ereignisse sind mit einer zufälligen, ausschließlich für Analysezwecke verwendeten Installationskennung verknüpft, nicht mit deinem Namen, deiner E-Mail-Adresse, deiner Apple-Gerätekennung oder einer Werbekennung. Analyseereignisse enthalten **keine** Koordinaten, gespeicherten Orte oder sonstige vom Benutzer eingegebene Texte.
- **Käufe und Abonnements.** Werden von Apple und RevenueCat verarbeitet. Wir sehen den Abonnementstatus, nicht deine Zahlungsdaten; diese verarbeitet ausschließlich Apple.
- **Paywall-Interaktion.** Superwall zeichnet auf, welche Paywall du gesehen und wie du damit interagiert hast.

Wir verkaufen deine personenbezogenen Daten nicht und verwenden deine Daten nicht für Werbung oder appübergreifendes Tracking.

## Was dein Gerät verlässt und wohin es geht

| Was | Wohin | Warum |
|---|---|---|
| Gerundete Koordinate (~10 km) | MET Norway (Norwegisches Meteorologisches Institut) | Stündliche Wolkenvorhersage |
| Keine standortbezogenen Daten | NOAA Space Weather Prediction Center | Globale Polarlicht- und geomagnetische Daten; die Anfrage enthält keinen Standort |
| Anonyme Nutzungsereignisse und eine nur für Analysen verwendete Installationskennung | Factory Analytics, gehostet bei Cloudflare | Produktanalyse und aggregierte Messung der Nutzerbindung |
| Abonnementstatus | RevenueCat, Apple | Berechtigungen und Belege |
| Paywall-Ereignisse | Superwall | Bereitstellung und Tests der Paywall |

Wetterdaten von MET Norway werden unter CC BY 4.0 verwendet. Weltraumwetterdaten werden von NOAA SWPC, einem öffentlichen Dienst der US-Regierung, bereitgestellt.

## Drittanbieterdienste

- **Cloudflare** (Auftragsverarbeiter und Host von Factory Analytics): https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (Abonnements): https://www.revenuecat.com/privacy
- **Superwall** (Paywalls): https://superwall.com/privacy
- **MET Norway** (Wetter): https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (Weltraumwetter): https://www.weather.gov/privacy
- **Apple App Store**: Für die Zahlungsabwicklung gilt die Datenschutzrichtlinie von Apple.

## Datenspeicherung

Unverarbeitete Factory-Analytics-Ereignisse werden 14 Tage gespeichert. Serverbasierte Datensätze auf Installationsebene werden bis zu 45 Tage gespeichert, um die aggregierte Nutzerbindung zu berechnen, und danach gelöscht; langfristige Kennzahlen enthalten nur aggregierte Zählwerte. Die zufällige Analysekennung auf deinem Gerät bleibt dort, bis du die App oder ihre Daten entfernst. Abonnement- und Paywall-Daten werden von Apple, RevenueCat und Superwall gemäß deren Richtlinien gespeichert. Standortdaten speichern wir überhaupt nicht, da wir sie nie erhalten.

## Deine Rechte

Wenn du dich im Europäischen Wirtschaftsraum, im Vereinigten Königreich oder in einer anderen Rechtsordnung mit vergleichbaren Gesetzen befindest, hast du das Recht auf Auskunft, Berichtigung, Löschung, Einschränkung oder Widerspruch gegen die Verarbeitung personenbezogener Daten, die wir über dich gespeichert haben, sowie auf Datenübertragbarkeit. Da die App keine Konten hat, beschränken sich die von uns gespeicherten Daten auf anonyme Analysedaten und Abonnementdatensätze. Um eines dieser Rechte auszuüben oder die Löschung deiner Analysekennung zu verlangen, schreibe an augustin.dev@tutamail.com. Wir antworten innerhalb von 30 Tagen.

Du kannst außerdem:

- die Standortberechtigung jederzeit in den iOS-Einstellungen widerrufen (zuvor gespeicherte Orte bleiben verfügbar);
- dein Abonnement in den Einstellungen deiner Apple-ID kündigen.

Rechtsgrundlage für die Verarbeitung von Analyse- und Paywall-Daten ist unser berechtigtes Interesse am Betrieb und an der Verbesserung der App; Rechtsgrundlage für die Verarbeitung von Abonnementdaten ist die Erfüllung unseres Vertrags mit dir.

## Datenschutz von Kindern

Die App richtet sich nicht an Kinder unter 13 Jahren und wir erfassen nicht wissentlich personenbezogene Daten von Kindern unter 13 Jahren.

## Änderungen

Wir können diese Richtlinie aktualisieren. Änderungen werden unter dieser URL mit einem neuen Datum unter „Zuletzt aktualisiert“ veröffentlicht.

## Kontakt

augustin.dev@tutamail.com
