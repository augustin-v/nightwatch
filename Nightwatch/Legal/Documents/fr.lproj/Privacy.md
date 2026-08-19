# Politique de confidentialité : Aurora Forecast - Nightwatch

**Politique de confidentialité d’Aurora Forecast - Nightwatch**

Dernière mise à jour : 2026-08-09

Augustin Villetard (« nous », « notre » ou « nos ») exploite Aurora Forecast - Nightwatch (l’« App »). Cette page explique quelles informations l’App traite, quelles données quittent votre appareil et quels sont vos droits.

## En bref

L’App ne comporte aucun compte. Votre position est utilisée sur votre appareil pour déterminer les conditions du ciel au-dessus de vous. Pour obtenir des prévisions de couverture nuageuse, nous envoyons une coordonnée **approximative** (arrondie à environ 10 km) à un service météorologique public. Nous exploitons un petit service d’analyse propriétaire pour un ensemble limité d’événements produit anonymes. Nous ne recevons jamais l’historique des lieux où vous vous êtes rendu et nous ne vendons jamais d’informations vous concernant.

## Informations traitées par l’App

- **Position.** Avec votre autorisation, l’App lit la position de votre appareil afin de calculer les heures de coucher du soleil et de crépuscule, la position de la Lune, la probabilité d’aurore à votre latitude et de demander des prévisions locales de couverture nuageuse. Votre position précise est utilisée **uniquement sur votre appareil** et n’est stockée que sur celui-ci. Avant toute requête réseau, la coordonnée est arrondie à environ un dixième de degré (environ 10 km) et seule cette coordonnée arrondie est envoyée. Si vous enregistrez un lieu lorsque l’accès à la position est disponible, l’App peut continuer à fournir des prévisions pour ce lieu après la révocation de l’autorisation de localisation.
- **Lieux enregistrés.** Ils sont stockés sur votre appareil et ne nous sont pas transmis.
- **Analyse.** Nous utilisons notre service propriétaire Factory Analytics, hébergé sur Cloudflare Workers et D1, afin de comprendre les écrans consultés, les fonctionnalités utilisées et l’achèvement de l’onboarding. Les événements sont associés à un identifiant d’installation aléatoire réservé à l’analyse, et non à votre nom, adresse e-mail, identifiant d’appareil Apple ou identifiant publicitaire. Les événements d’analyse **n’incluent pas** vos coordonnées, vos lieux enregistrés ni tout autre texte saisi par l’utilisateur.
- **Achats et abonnements.** Ils sont gérés par Apple et RevenueCat. Nous voyons l’état de votre abonnement, pas vos informations de paiement, qui sont entièrement traitées par Apple.
- **Interaction avec le paywall.** Superwall enregistre quel paywall vous avez vu et les actions que vous y avez effectuées.

Nous ne vendons pas vos informations personnelles et nous n’utilisons pas vos données à des fins publicitaires ou de suivi entre applications.

## Ce qui quitte votre appareil et sa destination

| Donnée | Destination | Motif |
|---|---|---|
| Coordonnée arrondie (~10 km) | MET Norway (Institut météorologique norvégien) | Prévisions horaires de couverture nuageuse |
| Aucune donnée liée à la position | NOAA Space Weather Prediction Center | Données mondiales sur les aurores et l’activité géomagnétique ; la requête ne contient aucune position |
| Événements d’utilisation anonymes et identifiant d’installation réservé à l’analyse | Factory Analytics, hébergé par Cloudflare | Analyse produit et mesure agrégée de la rétention |
| État de l’abonnement | RevenueCat, Apple | Droits d’accès et reçus |
| Événements du paywall | Superwall | Diffusion et tests du paywall |

Les données météorologiques de MET Norway sont utilisées sous licence CC BY 4.0. Les données de météo spatiale sont fournies par NOAA SWPC, un service public du gouvernement des États-Unis.

## Services tiers

- **Cloudflare** (sous-traitant hébergeant Factory Analytics) : https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (abonnements) : https://www.revenuecat.com/privacy
- **Superwall** (paywalls) : https://superwall.com/privacy
- **MET Norway** (météo) : https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (météo spatiale) : https://www.weather.gov/privacy
- **Apple App Store** : la politique de confidentialité d’Apple régit le traitement des paiements.

## Conservation des données

Les événements bruts de Factory Analytics sont conservés pendant 14 jours. Les enregistrements côté serveur au niveau de l’installation sont conservés jusqu’à 45 jours afin de calculer la rétention agrégée, puis supprimés ; les métriques conservées à long terme ne contiennent que des décomptes agrégés. L’identifiant d’analyse aléatoire stocké sur votre appareil y reste jusqu’à ce que vous supprimiez l’App ou ses données. Les données d’abonnement et de paywall sont conservées par Apple, RevenueCat et Superwall conformément à leurs politiques. Nous ne conservons aucune donnée de localisation, car nous ne la recevons jamais.

## Vos droits

Si vous vous trouvez dans l’Espace économique européen, au Royaume-Uni ou dans une autre juridiction disposant d’une législation comparable, vous avez le droit d’accéder aux données personnelles que nous détenons à votre sujet, de les rectifier ou de les supprimer, d’en limiter le traitement ou de vous y opposer, ainsi que le droit à la portabilité des données. L’App ne comportant aucun compte, les données que nous détenons se limitent à des données d’analyse anonymes et à des dossiers d’abonnement. Pour exercer l’un de ces droits ou nous demander de supprimer votre identifiant d’analyse, écrivez à augustin.dev@tutamail.com ; nous répondrons sous 30 jours.

Vous pouvez également :

- révoquer l’autorisation d’accès à la position à tout moment dans les Réglages iOS (les lieux enregistrés auparavant restent disponibles) ;
- annuler votre abonnement dans les réglages de votre identifiant Apple.

La base juridique du traitement des données d’analyse et de paywall est notre intérêt légitime à exploiter et améliorer l’App ; la base juridique du traitement des abonnements est l’exécution de notre contrat avec vous.

## Vie privée des enfants

L’App ne s’adresse pas aux enfants de moins de 13 ans et nous ne collectons pas sciemment d’informations personnelles concernant des enfants de moins de 13 ans.

## Modifications

Nous pouvons mettre à jour cette politique. Les modifications seront publiées à cette URL avec une nouvelle date de « Dernière mise à jour ».

## Contact

augustin.dev@tutamail.com
