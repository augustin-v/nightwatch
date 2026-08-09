# Privacy Policy: Aurora Forecast - Nightwatch


**Privacy Policy for Aurora Forecast - Nightwatch**

Last updated: 2026-08-09

Augustin Villetard ("we," "us," or "our") operates Aurora Forecast - Nightwatch
(the "App"). This page explains what information the App handles, what leaves
your device, and what your rights are.

## The short version

The App has no accounts. Your location is used on your device to work out what
the sky will do above you. To fetch a cloud forecast we send an **approximate**
coordinate (rounded to roughly 10 km) to a public weather service. We operate a
small first-party analytics endpoint for bounded, anonymous product events. We
never receive a history of where you have been, and we never sell anything
about you.

## Information the App handles

- **Location.** With your permission, the App reads your device location to
  compute sunset and twilight times, moon position, aurora probability at your
  latitude, and to request a local cloud forecast. Your precise location is
  used **only on your device** and is stored only on your device. Before any
  network request, the coordinate is rounded to approximately one tenth of a
  degree (about 10 km), and only that rounded coordinate is sent. If you save a
  place while location access is available, the App can keep forecasting for
  that saved place after you revoke location permission.
- **Places you save.** Stored on your device. Not transmitted to us.
- **Analytics.** We use our first-party Factory Analytics service, hosted on
  Cloudflare Workers and D1, to understand screens viewed, features used, and
  onboarding completion. Events are tied to a random analytics-only
  installation identifier, not your name, email, Apple device identifier, or
  advertising identifier. Analytics events do **not** include your coordinates,
  saved places, or other user-entered text.
- **Purchases and subscriptions.** Handled by Apple and RevenueCat. We see
  subscription status, not your payment details, which Apple handles entirely.
- **Paywall interaction.** Superwall records which paywall you saw and what you
  did with it.

We do not sell your personal information, and we do not use your data for
advertising or cross-app tracking.

## What leaves your device, and to whom

| What | Where it goes | Why |
|---|---|---|
| Rounded coordinate (~10 km) | MET Norway (Norwegian Meteorological Institute) | Hourly cloud-cover forecast |
| Nothing location-related | NOAA Space Weather Prediction Center | Global aurora and geomagnetic data; the request contains no location |
| Anonymous usage events and an analytics-only installation identifier | Factory Analytics, hosted by Cloudflare | Product analytics and aggregate retention measurement |
| Subscription state | RevenueCat, Apple | Entitlements and receipts |
| Paywall events | Superwall | Paywall delivery and testing |

Weather data from MET Norway is used under CC BY 4.0. Space weather data is
provided by NOAA SWPC, a US government public service.

## Third-party services

- **Cloudflare** (processor hosting Factory Analytics): https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (subscriptions): https://www.revenuecat.com/privacy
- **Superwall** (paywalls): https://superwall.com/privacy
- **MET Norway** (weather): https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (space weather): https://www.weather.gov/privacy
- **Apple App Store**: Apple's privacy policy governs payment processing.

## Data retention

Raw Factory Analytics events are retained for 14 days. Server-side
installation-level records are retained for up to 45 days to calculate
aggregate retention, then removed; long-lived metrics contain aggregate counts
only. The random analytics identifier stored on your device remains there until
you remove the App or its data. Subscription and paywall data are retained by
Apple, RevenueCat, and Superwall as described in their policies. Location data
is not retained by us at all, because we never receive it.

## Your rights

If you are in the European Economic Area, the United Kingdom, or another
jurisdiction with comparable law, you have the right to access, correct, delete,
restrict, or object to processing of personal data we hold about you, and to
data portability. Because the App has no accounts, the data we hold is limited
to anonymous analytics and subscription records. To exercise any of these
rights, or to ask us to delete your analytics identifier, email
augustin.dev@tutamail.com and we will respond within 30 days.

You can also:

- revoke location permission at any time in iOS Settings (previously saved
  places remain available);
- cancel your subscription in your Apple ID settings.

The legal basis for analytics and paywall processing is our legitimate interest
in operating and improving the App; the legal basis for subscription processing
is performance of our contract with you.

## Children's privacy

The App is not directed at children under 13 and we do not knowingly collect
personal information from children under 13.

## Changes

We may update this policy. Changes are posted at this URL with a new "Last
updated" date.

## Contact

augustin.dev@tutamail.com
