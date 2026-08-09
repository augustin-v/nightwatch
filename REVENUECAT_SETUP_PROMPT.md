# RevenueCat setup for Nightwatch — prompt for a fresh session

Paste everything below the line into a new Claude Code session. It needs the
`revenuecat` MCP server, which is already installed at user scope
(`https://mcp.revenuecat.ai/mcp`). The first tool call will trigger an OAuth
prompt in the browser; approve it with the RevenueCat account that owns the
other factory apps.

Do not let that session touch the Nightwatch source. Its only job is account
state in RevenueCat. The mastermind session wires the SDK.

---

Use the `revenuecat` MCP server to set up a new RevenueCat project for an iOS
app that is already live in App Store Connect. Do the account work only. Do not
edit any Swift code, any Xcode project, or anything in `~/coding/Nightwatch`.

**The app**

- Display name: Nightwatch (App Store title "Aurora Forecast - Nightwatch")
- Bundle id: `com.augustinv.nightwatch`
- App Store Connect app id: `6799616622`
- Apple team id: `N462N35929`

**Products, already created and approved in App Store Connect**

Both live in subscription group `22297381` ("Nightwatch"), and both are
currently in `MISSING_METADATA` because they still need a review screenshot,
which is expected at this stage and does not block RevenueCat.

| Product identifier | Duration | US price |
|---|---|---|
| `com.augustinv.nightwatch.annual` | 1 year | $39.99 |
| `com.augustinv.nightwatch.weekly` | 1 week | $9.99 |

**What to create**

1. A RevenueCat project named `Nightwatch`.
2. An iOS app in it for bundle id `com.augustinv.nightwatch`.
3. Both products above, imported or created against that app.
4. One entitlement with the identifier **`pro`** — exactly that string, lower
   case. It must match the Superwall entitlement already configured under
   project 28487, or the two systems will disagree about who has paid.
5. Attach **both** products to the `pro` entitlement. Weekly and annual grant
   the same access; the only difference is price and duration.
6. An offering with identifier `default`, containing two packages: the annual
   product as the **annual** package and the weekly product as the **weekly**
   package. The app reads this offering by identifier, so the name matters.

**What to report back**

- The **public SDK key** for the iOS app. It starts with `appl_`. This is the
  one value the app needs; it is a client credential and is safe to paste.
- The project id and app id.
- Whether the App Store Connect in-app purchase key (the `.p8` used for server
  notifications and receipt validation) is already uploaded to this RevenueCat
  project, and if not, exactly which screen uploads it. That upload is an owner
  action and is expected to remain outstanding.
- Anything you could not create through the MCP, with the exact reason.

Do not paste any secret key, `sk_` key, or `.p8` contents into your reply.
