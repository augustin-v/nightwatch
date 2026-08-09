# Legal document status

## Privacy policy — custom draft, approved by the owner on 2026-08-09

`Nightwatch/Legal/Documents/Privacy.md` is a **custom-drafted** privacy
policy, not a filled-in copy of `factory/legal/privacy-policy-template.md`.

**Why:** the factory's shared privacy template explicitly refuses to cover
apps that use location data or that need GDPR data-subject-rights language
(see "When this template is not enough" in
`factory/legal/privacy-policy-template.md`). Aurora Forecast - Nightwatch
does both — it reads device location on-device and sends a rounded
coordinate to MET Norway for cloud forecasts, and ships in EEA/UK
storefronts where GDPR rights language is required. Per STANDARDS.md §6
(scaffold step) this is an escalation to custom legal drafting, not a
placeholder-fill.

**Status:** APPROVED by the owner and published at
https://augustin-v.github.io/nightwatch/privacy/. The bundled document carries
the same approved policy. No lawyer has reviewed it; the owner accepted that
explicitly.

## Terms of use — filled from the shared template

`Nightwatch/Legal/Documents/Terms.md` is a straightforward fill of
`factory/legal/terms-template.md` — no escalation was needed since Terms of
Use as templated covers subscriptions generically without the
location/GDPR gap that blocks the privacy policy. Filled values:

- `{{APP_NAME}}` → Aurora Forecast - Nightwatch
- `{{DEVELOPER_NAME}}` → Augustin Villetard
- `{{DATE}}` → 2026-08-09
- `{{BRIEF_ONE_LINE_DESCRIPTION_OF_APP_PURPOSE}}` → forecasting aurora
  visibility conditions
- `{{GOVERNING_JURISDICTION}}` → France
- `{{SUPPORT_EMAIL}}` → augustin.dev@tutamail.com
- Free-trial section: removed (no free trial is offered)
- Health/fitness/wellness disclaimer: removed (not applicable)
- Added an explicit price line ($9.99/week, $39.99/year) since the shared
  template has no price placeholder and 03_scaffold.md asked for the actual
  tier prices to be stated.

No literal `{{...}}` remains in either document.
