# Changelog

Notable hosting, domain, and SEO decisions for `wingsiq-site`. Read this at session start alongside `CLAUDE.md` — it carries the "why" behind config that isn't obvious from the code.

## 2026-10-18 — SEO: removed leftover www references (host drift)

- **Found:** GSC showed 9/14 pages unindexed. The July 27 domain setup is still correct live (`www` → 308 → apex; every sitemap URL returns 200 directly), but two files still pointed at `www`:
  - `index.html`: `og:url`, `og:image`, `twitter:image` were on `https://www.wingsiq.ai/` while its canonical was the apex.
  - `robots.txt`: `Sitemap:` line pointed at `https://www.wingsiq.ai/sitemap.xml`, so every crawl started with a redirect.
- **Fix:** all three tags and the robots `Sitemap:` line now use `https://wingsiq.ai/`. Homepage `lastmod` bumped. No served file references `www` anymore.
- **Not changed:** Vercel Domains (already correct), `vercel.json`, sitemap URL list (no entry redirects).
- **Old `index (1/2/3).html` files:** deleted 2026-06-15, return 404 live, referenced nowhere. Not a current factor.

## 2026-07-27 — SEO: fixed "Duplicate without user-selected canonical" (wingsiq.ai)

- **Root cause:** Vercel had `www.wingsiq.ai` set as Production with the apex
  `wingsiq.ai` redirecting **to** www, while the site's canonical tags pointed at
  the **apex**. Redirect and canonicals contradicted each other → Google couldn't
  pick a canonical → duplicate flag in Search Console.
- **Vercel Domains:** inverted the config — `wingsiq.ai` is now **Production**;
  `www.wingsiq.ai` is a **308 permanent redirect → wingsiq.ai**.
- **`vercel.json`:** added a `redirects` block (`/index.html → /`, permanent);
  preserved the existing `rewrites` array (pretty URLs → `.html` files).
- **Canonical tags:** added/corrected self-referencing canonicals on all six pages,
  pointing to the **pretty apex URLs** (not the `.html` filenames):
  `/`, `/terms`, `/privacy`, `/score`, `/card`, `/preview`.
- **Bug caught in passing:** `preview.html`'s canonical pointed to `/` (homepage)
  instead of `/preview` — corrected. This was itself a likely contributor to the flag.
- **`sitemap.xml`:** updated to list only the bare-apex pretty URLs (was still on
  `www.wingsiq.ai`).
- **Verified live:** `www → https://wingsiq.ai/` (308) and `/index.html →
  https://wingsiq.ai/` both confirmed via curl.
- _Follow-up (owner-side):_ Search Console Validate Fix run; allow 1–2 weeks for
  re-crawl before treating "Pending" as a problem.
- **Rule for next time:** if a "duplicate canonical" flag reappears, first verify
  **host agreement** — domain redirect, canonical tags, and sitemap must all point
  to the same single host (apex, https, pretty URL). See the domain invariant in
  `CLAUDE.md` before changing anything.
