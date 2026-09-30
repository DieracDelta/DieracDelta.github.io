# Blog analytics

The blog uses the existing self-hosted Umami instance for **pageviews only**,
with its own website ID. Neither schema loads Google
Analytics or its former `G-PMP32CMWHS` tag. Existing Google Fonts styling is
unchanged; this is not a claim that all Google-hosted resources were removed.
Historical Google Analytics records are not migrated or deleted by this change.

## Configuration and rollout

- Canonical blog: `https://justin.restivo.me` (the GitHub Pages hostname redirects here).
- Public tracker/collector: `https://analytics.restivo.me` (`/script.js` and `/api/send` only).
- Public configuration: `typsite/assets/analytics-config.json` → `/analytics-config.json`.
- Typsite copies the **contents** of `typsite/assets/` to the publication root;
  both schemas use `/analytics.js` and `/analytics.css`, including nested articles.
- Private dashboard: `https://office-desktop.tail5ca7.ts.net:3013`, through Tailscale.

The privacy landmark deliberately uses `div[role="contentinfo"]`: Typsite reserves
`<footer>` as a template directive and removes that tag and its attributes.

The matching `system_config` change contains the same configuration in
`lib/blog-analytics.json`. The existing desktop provisioning service registers
**Justin's Blog** through local PostgreSQL without reading or resetting the
administrator password. Existing website settings are preserved; conflicting
IDs/domains fail instead of overwriting data. Keep the ID identical in both
repositories; this endpoint migration does not create a new ID or reset data.

For the already deployed backend, set up **DNS, rebuild nixos-arm, verify HTTPS,
then publish the blog**. Create a DNS-only A record `analytics.restivo.me` pointing
to ARM's public IPv4 address (`150.136.78.22` at the time of this change), not a
CNAME to another website. Do not add AAAA unless ARM's public IPv6 ingress works.
Caddy provisions HTTPS over the existing public 80/443 ingress. DNS is not managed
by this repository; no DNS records or live systems have been changed.

If the previous backend/site provisioning is not deployed yet, deploy desktop
first. Otherwise desktop does not need rebuilding for this endpoint-only change.
ARM exposes only the tracker and exact-origin collection/preflight for this blog;
all other paths, including the dashboard and admin APIs, return 404. No manual
website creation, API key, or password is required. The old collection route no
longer accepts the blog, so analytics can pause between the ARM rebuild and blog
publication; navigation remains functional.

Branch/PR workflows build only; deployment is restricted to pushes on `master`.
Merging this blog change into `master` publishes it, so finish the infrastructure
rollout first. Do not hand-edit ignored `publish/` output; rebuild from the schemas
and assets.

## Privacy and behavior

`analytics.js` loads the upstream tracker only on HTTPS `justin.restivo.me`, not
previews, other hosts, or plain HTTP. It honors Do Not Track, Global Privacy
Control, and the opt-out in the **Website analytics & privacy** footer. The
preference is stored in this browser's local storage for this origin; clearing
site data removes it. No analytics cookies are set or sent to the collector.

Pageview payloads exclude URL queries/fragments, referrer paths/queries, identity
calls, arbitrary events/properties, performance telemetry, and session recording.
Only the referring website is retained. The reverse proxy also strips HTTP
Referer and cookie/authorization headers before forwarding to Umami. Umami
processes IP/browser information for daily visitor identifiers and approximate
location; raw IP addresses are not stored in its analytics records.

Both managed websites have 90-day live-data retention. The existing local database
copies and encrypted Borg rotation also include the blog (7 daily / 4 weekly /
6 monthly snapshots). Operational logs are separate. Review the footer notice
against actual operations and applicable privacy/consent requirements; cookieless
analytics do not automatically remove those obligations.

If configuration or the collector is unavailable/blocked, the blog remains usable.
Old Google Analytics cookies are not proactively deleted because parent-domain
cookies may be shared with other sites; visitors may clear them in browser settings.

## Checks after deployment

1. Verify **Justin's Blog** appears in Umami with the configured domain and ID.
2. Visit a homepage and article with JavaScript enabled and privacy signals/opt-out
   disabled. Check the separate blog dashboard for pageviews.
3. Network requests should use `https://analytics.restivo.me`, never the private
   dashboard or another website's domain. Cross-origin collection should have a successful OPTIONS preflight
   followed by POST. There must be no Google Analytics/Tag Manager requests.
4. Inspect a payload after visiting a URL with a query/fragment: only the page
   path should appear. `/index.html` is counted as `/`.
5. Opt out, reload, and verify the tracker/collector are no longer requested.
   Repeat with DNT/GPC enabled. Preview hosts must never send analytics.
