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

**Status:** APPROVED, not approved. The document carries its own in-file
banner (do not remove it) stating it is a prepared draft, not legal advice,
and not yet approved or published. It is linked from the Settings screen in
the scaffold so the required-screen structure exists, but per STANDARDS.md
the app is not submission-ready until this draft is reviewed.

**Blocked on:** Control Room owner request `req_67d52c6ca0` — the owner
needs to review and approve (or request changes to) this custom draft before
it is treated as final. Resume by checking
`python3 control-room/factoryctl.py inbox aurora-forecast` (or the relevant
app id) for the owner's reply, then removing the draft banner and updating
this file once approved.

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


## Status update 2026-08-09

The owner approved the custom privacy policy (Control Room request
`req_67d52c6ca0`) and set the support address to augustin.dev@tutamail.com.
The draft banner has been replaced with an approval note. No lawyer has
reviewed it; the owner accepted that explicitly.
