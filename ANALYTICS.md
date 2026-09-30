# Blog analytics

The blog uses the existing self-hosted Umami instance for **pageviews only**,
with its own website ID, separate from IronMain. Neither schema loads Google
Analytics or its former `G-PMP32CMWHS` tag. Existing Google Fonts styling is
unchanged; this is not a claim that all Google-hosted resources were removed.
Historical Google Analytics records are not migrated or deleted by this change.

## Configuration and rollout

- Canonical blog: `https://justin.restivo.me` (the GitHub Pages hostname redirects here).
- Public tracker/collector: `https://ironmain.dev/analytics`.
- Public configuration: `typsite/assets/analytics-config.json` → `/analytics-config.json`.
- Typsite copies the **contents** of `typsite/assets/` to the publication root;
  both schemas use `/analytics.js` and `/analytics.css`, including nested articles.
- Private dashboard: `https://office-desktop.tail5ca7.ts.net:3013`, through Tailscale.

The privacy landmark deliberately uses `div[role="contentinfo"]`: Typsite reserves
`<footer>` as a template directive and removes that tag and its attributes.

The matching `system_config` change contains the same configuration in
`lib/blog-analytics.json`. Its `ironmain-umami-blog.service` registers **Justin's
Blog** through local PostgreSQL, using the existing IronMain website owner. It
never reads or resets the administrator password. Re-running it preserves existing
website settings; conflicting IDs/domains fail instead of overwriting data.

Deploy **desktop first**, then **nixos-arm**, before publishing this blog change.
Desktop creates the website and accepts the blog's Origin on its private relay.
ARM enables exact-origin CORS/preflight for the public collector. No dashboard or
administration route is made public. No manual website creation, API key, or
password is required. Keep the website ID identical in both repositories.

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
3. Network requests should use the public HTTPS collector, never the private
   dashboard. Cross-origin collection should have a successful OPTIONS preflight
   followed by POST. There must be no Google Analytics/Tag Manager requests.
4. Inspect a payload after visiting a URL with a query/fragment: only the page
   path should appear. `/index.html` is counted as `/`.
5. Opt out, reload, and verify the tracker/collector are no longer requested.
   Repeat with DNT/GPC enabled. Preview hosts must never send analytics.
