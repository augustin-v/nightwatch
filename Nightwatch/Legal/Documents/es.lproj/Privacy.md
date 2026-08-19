# Política de privacidad: Aurora Forecast - Nightwatch

**Política de privacidad de Aurora Forecast - Nightwatch**

Última actualización: 2026-08-09

Augustin Villetard («nosotros», «nos» o «nuestro») opera Aurora Forecast - Nightwatch (la «App»). Esta página explica qué información gestiona la App, qué datos salen de tu dispositivo y cuáles son tus derechos.

## En resumen

La App no tiene cuentas. Tu ubicación se utiliza en tu dispositivo para determinar qué ocurrirá en el cielo sobre ti. Para obtener un pronóstico de nubosidad enviamos unas coordenadas **aproximadas** (redondeadas a unos 10 km) a un servicio meteorológico público. Operamos un pequeño servicio propio de analítica para un conjunto limitado de eventos anónimos del producto. Nunca recibimos un historial de los lugares en los que has estado y nunca vendemos información sobre ti.

## Información que gestiona la App

- **Ubicación.** Con tu permiso, la App consulta la ubicación del dispositivo para calcular la puesta de sol y el crepúsculo, la posición de la Luna, la probabilidad de aurora en tu latitud y solicitar un pronóstico local de nubosidad. Tu ubicación precisa se utiliza **solo en tu dispositivo** y se almacena únicamente en tu dispositivo. Antes de cualquier solicitud de red, las coordenadas se redondean aproximadamente a una décima de grado (unos 10 km) y solo se envían esas coordenadas redondeadas. Si guardas un lugar mientras está disponible el acceso a la ubicación, la App puede seguir generando pronósticos para ese lugar guardado después de que revoques el permiso de ubicación.
- **Lugares que guardas.** Se almacenan en tu dispositivo. No se nos transmiten.
- **Analítica.** Utilizamos nuestro servicio propio Factory Analytics, alojado en Cloudflare Workers y D1, para entender qué pantallas se ven, qué funciones se usan y si se completa el proceso de bienvenida. Los eventos se asocian a un identificador de instalación aleatorio utilizado únicamente para analítica, no a tu nombre, correo electrónico, identificador de dispositivo de Apple ni identificador publicitario. Los eventos de analítica **no** incluyen tus coordenadas, lugares guardados ni ningún otro texto introducido por el usuario.
- **Compras y suscripciones.** Las gestionan Apple y RevenueCat. Vemos el estado de la suscripción, no tus datos de pago, que Apple gestiona por completo.
- **Interacción con el paywall.** Superwall registra qué paywall viste y qué hiciste en él.

No vendemos tu información personal ni utilizamos tus datos para publicidad o seguimiento entre aplicaciones.

## Qué sale de tu dispositivo y adónde va

| Qué | Adónde va | Por qué |
|---|---|---|
| Coordenadas redondeadas (~10 km) | MET Norway (Instituto Meteorológico Noruego) | Pronóstico horario de nubosidad |
| Nada relacionado con la ubicación | NOAA Space Weather Prediction Center | Datos globales de auroras y actividad geomagnética; la solicitud no contiene ubicación |
| Eventos de uso anónimos y un identificador de instalación solo para analítica | Factory Analytics, alojado por Cloudflare | Analítica del producto y medición agregada de retención |
| Estado de la suscripción | RevenueCat, Apple | Derechos de acceso y recibos |
| Eventos del paywall | Superwall | Entrega y pruebas del paywall |

Los datos meteorológicos de MET Norway se utilizan bajo CC BY 4.0. Los datos de meteorología espacial los proporciona NOAA SWPC, un servicio público del Gobierno de Estados Unidos.

## Servicios de terceros

- **Cloudflare** (encargado del tratamiento que aloja Factory Analytics): https://www.cloudflare.com/privacypolicy/
- **RevenueCat** (suscripciones): https://www.revenuecat.com/privacy
- **Superwall** (paywalls): https://superwall.com/privacy
- **MET Norway** (meteorología): https://www.met.no/en/About-us/privacy
- **NOAA SWPC** (meteorología espacial): https://www.weather.gov/privacy
- **Apple App Store**: el tratamiento de pagos se rige por la política de privacidad de Apple.

## Conservación de datos

Los eventos sin procesar de Factory Analytics se conservan durante 14 días. Los registros de instalación del servidor se conservan hasta 45 días para calcular la retención agregada y después se eliminan; las métricas de larga duración solo contienen recuentos agregados. El identificador aleatorio de analítica almacenado en tu dispositivo permanece allí hasta que elimines la App o sus datos. Apple, RevenueCat y Superwall conservan los datos de suscripción y paywall según se describe en sus políticas. Nosotros no conservamos datos de ubicación, porque nunca los recibimos.

## Tus derechos

Si te encuentras en el Espacio Económico Europeo, el Reino Unido u otra jurisdicción con una legislación comparable, tienes derecho a acceder, corregir, eliminar, limitar u oponerte al tratamiento de los datos personales que tengamos sobre ti, así como a la portabilidad de los datos. Como la App no tiene cuentas, los datos que tenemos se limitan a analítica anónima y registros de suscripción. Para ejercer cualquiera de estos derechos o pedirnos que eliminemos tu identificador de analítica, escribe a augustin.dev@tutamail.com y responderemos en un plazo de 30 días.

También puedes:

- revocar el permiso de ubicación en cualquier momento desde Ajustes de iOS (los lugares guardados anteriormente seguirán disponibles);
- cancelar tu suscripción en los ajustes de tu Apple ID.

La base jurídica para el tratamiento de analítica y paywall es nuestro interés legítimo en operar y mejorar la App; la base jurídica para el tratamiento de suscripciones es la ejecución de nuestro contrato contigo.

## Privacidad de menores

La App no está dirigida a menores de 13 años y no recopilamos de forma consciente información personal de menores de 13 años.

## Cambios

Podemos actualizar esta política. Los cambios se publicarán en esta URL con una nueva fecha de «Última actualización».

## Contacto

augustin.dev@tutamail.com
