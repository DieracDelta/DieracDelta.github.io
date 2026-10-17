#!/usr/bin/env python3
"""Finish the Typsite output for search engines; run after `typsite c`.

Typsite has no sitemap support and names the homepage /index, so this:
- points the homepage's canonical and og:url at https://justin.restivo.me/
- writes sitemap.xml listing every page with a canonical URL and no noindex,
  dated by the last git commit touching its Typst source.
"""

import html.parser
import pathlib
import subprocess
import sys
from xml.sax.saxutils import escape

SITE = "https://justin.restivo.me"


class Head(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.canonical = None
        self.robots = ""

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "link" and attrs.get("rel") == "canonical":
            self.canonical = attrs.get("href")
        if tag == "meta" and attrs.get("name") == "robots":
            self.robots = attrs.get("content") or ""


def last_commit_date(source):
    if not source.is_file():
        return None
    date = subprocess.run(
        ["git", "log", "-1", "--format=%cs", "--", str(source)],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    return date or None


def main(publish="publish", root="root"):
    publish, root = pathlib.Path(publish), pathlib.Path(root)

    home = publish / "index.html"
    text = home.read_text()
    home.write_text(text.replace(f'"{SITE}/index"', f'"{SITE}/"'))
    head = Head()
    head.feed(home.read_text())
    if head.canonical != f"{SITE}/":
        sys.exit(f"homepage canonical is {head.canonical!r}; did the schema change?")

    entries = []
    for page in sorted(publish.rglob("*.html")):
        head = Head()
        head.feed(page.read_text())
        if not head.canonical or "noindex" in head.robots.lower():
            continue
        path = page.relative_to(publish).with_suffix("")
        expected = f"{SITE}/" if path.as_posix() == "index" else f"{SITE}/{path.as_posix()}"
        if head.canonical != expected:
            sys.exit(f"{page}: canonical {head.canonical!r}, expected {expected!r}")
        entries.append((expected, last_commit_date(root / path.with_suffix(".typ"))))

    if not entries:
        sys.exit("no indexable pages found")
    urls = []
    for url, lastmod in entries:
        date = f"\n    <lastmod>{lastmod}</lastmod>" if lastmod else ""
        urls.append(f"  <url>\n    <loc>{escape(url)}</loc>{date}\n  </url>\n")
    (publish / "sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "".join(urls)
        + "</urlset>\n"
    )
    print(f"sitemap.xml: {len(entries)} pages")


if __name__ == "__main__":
    main(*sys.argv[1:])
