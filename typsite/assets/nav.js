// Highlight the header link for the current page.
(() => {
  const here = location.pathname.replace(/\/index(\.html)?$/, "/").replace(/\.html$/, "");
  for (const a of document.querySelectorAll(".header-nav > a")) {
    const url = new URL(a.href, location.href);
    if (url.origin !== location.origin) continue;
    const path = url.pathname.replace(/\.html$/, "");
    if (path === here) a.setAttribute("aria-current", "page");
  }
})();
