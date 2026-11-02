(() => {
  const production = location.origin === "https://justin.restivo.me";
  const preferenceKey = "umami.disabled";
  const button = document.querySelector("[data-analytics-toggle]");
  const status = document.querySelector("#analytics-status");
  let optedOut = false;
  let saved = true;
  let loading = false;
  let ready = false;
  let pageviewSent = false;
  let websiteId;
  try { optedOut = Boolean(localStorage.getItem(preferenceKey)); } catch { /* Optional storage. */ }

  const browserOptOut = () => navigator.globalPrivacyControl === true ||
    [navigator.doNotTrack, window.doNotTrack, navigator.msDoNotTrack]
      .some(value => [1, "1", "yes"].includes(value));
  const allowed = () => production && !optedOut && !browserOptOut();
  const render = () => {
    if (!button || !status) return;
    button.hidden = false;
    button.disabled = !production || browserOptOut();
    button.textContent = browserOptOut() ? "Turned off by your browser" :
      optedOut ? "Turn on analytics" : "Turn off analytics";
    status.textContent = !production ? "Analytics only run on justin.restivo.me." :
      browserOptOut() ? "Your browser asked not to be tracked, so analytics are off." :
      optedOut ? (saved ? "Analytics are off in this browser." :
        "Analytics are off for this page, but your browser wouldn't let me save the setting.") :
      "Analytics are on.";
  };
  const referrer = () => {
    try {
      const url = new URL(document.referrer);
      return ["http:", "https:"].includes(url.protocol) && url.hostname !== location.hostname
        ? `${url.protocol}//${url.hostname}/` : "";
    } catch { return ""; }
  };

  // Replace the upstream payload with pageview fields only. Never send identity,
  // event properties, URL queries/fragments, or the referring page's path/query.
  window.blogAnalyticsBeforeSend = (type, payload) => {
    if (!allowed() || !websiteId || type !== "event" || payload?.name !== undefined) return null;
    return {
      website: websiteId,
      hostname: location.hostname,
      url: location.pathname === "/index.html" ? "/" : location.pathname,
      title: document.title,
      referrer: referrer(),
      language: navigator.language,
      screen: `${screen.width}x${screen.height}`,
    };
  };
  const pageview = () => {
    if (!allowed() || !ready || pageviewSent) return;
    pageviewSent = true;
    try { void Promise.resolve(window.umami.track()).catch(() => {}); } catch { /* Optional analytics. */ }
  };
  const start = async () => {
    if (!allowed()) return;
    if (ready) { pageview(); return; }
    if (loading) return;
    loading = true;
    try {
      const response = await fetch("/analytics-config.json", {
        credentials: "omit", referrerPolicy: "no-referrer",
      });
      if (!response.ok) throw new Error("Analytics configuration unavailable");
      const config = await response.json();
      if (config.domain !== location.hostname || config.endpoint !== "https://analytics.restivo.me" ||
        !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(config.websiteId)) {
        throw new Error("Invalid analytics configuration");
      }
      websiteId = config.websiteId;
      if (!allowed()) { loading = false; return; }
      const script = document.createElement("script");
      script.src = `${config.endpoint}/script.js`;
      script.async = true;
      script.crossOrigin = "anonymous";
      script.referrerPolicy = "no-referrer";
      const attributes = {
        "website-id": websiteId, "host-url": config.endpoint, "domains": config.domain,
        "before-send": "blogAnalyticsBeforeSend", "auto-track": "false",
        "auto-pageview": "false", "performance": "false", "exclude-search": "true",
        "exclude-hash": "true", "do-not-track": "true", "fetch-credentials": "omit",
      };
      Object.entries(attributes).forEach(([key, value]) => script.setAttribute(`data-${key}`, value));
      script.onload = () => {
        ready = typeof window.umami?.track === "function";
        loading = false;
        pageview();
      };
      script.onerror = () => { loading = false; };
      document.head.append(script);
    } catch { loading = false; }
  };
  button?.addEventListener("click", () => {
    optedOut = !optedOut;
    saved = true;
    try {
      if (optedOut) localStorage.setItem(preferenceKey, "1");
      else localStorage.removeItem(preferenceKey);
    } catch { saved = false; }
    render();
    if (!optedOut) void start();
  });
  window.addEventListener("storage", event => {
    if (event.key === preferenceKey || event.key === null) {
      try { optedOut = Boolean(localStorage.getItem(preferenceKey)); } catch { return; }
      saved = true;
      render();
      if (!optedOut) void start();
    }
  });
  render();
  void start();
})();
