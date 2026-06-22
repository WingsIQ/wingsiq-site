# WingsIQ — Marketing Site (`wingsiq-site`)

## Session start (do this first, every time)
1. **`git pull` before anything else.** This repo has been edited via GitHub web in the past, so origin is often ahead of local. Pulling first prevents the diverged-history mess. Never force-push.
2. **Review what changed recently** (`git log --oneline -10`) so you have context before editing.

## Session end
- **Commit and push.** Vercel auto-deploys `main` → wait for me to confirm before pushing if the change is risky, but normal edits get committed and pushed so they go live.

---

## What this repo is
The **marketing site** for WingsIQ — served at **`wingsiq.ai` / `www.wingsiq.ai`**. Plain **static HTML** (`index.html` is the whole landing page), deployed on **Vercel** (`vercel.json` present), production branch **`main`**.

This is NOT the app. The app is a **separate repo** (`wingsiq-app`) at `app.wingsiq.ai` — Next.js, all the real routes (`/login`, `/simulator`, `/score`, `/weather`, `/hangar`). **Do not add app routes or app logic here.** This repo only markets the app and links into it.

## Who it's for
The new & upcoming pilot, age **25–40**. Copy should feel modern, confident, and benefit-first — not stuffy or FAA-manual dry.

## The product (so links make sense)
WingsIQ is an AI flight-training app. Flagship = a voice **ATC simulator** that grades radio readbacks and rolls everything into a single 0–100 **WingsIQ Score**. The **Weather Decoder** (free) is the top-of-funnel hook: it gets a stranger touching the product, then funnels them toward the paid tools.

## Feature tiles (landing page, in `index.html`)
The top-row tiles link OUT to the app. Current intended left-to-right order:
**ATC Readback Trainer → Weather Decoder → WingsIQ Score.**
- ATC Readback Trainer → `https://app.wingsiq.ai/login`
- Weather Decoder → `https://app.wingsiq.ai/weather` (free — badge should read "Live now" / CTA "Try it free →")
- WingsIQ Score → `https://app.wingsiq.ai/login` _(revisit: ideally `/score` once a logged-in visitor should land on their number)_

## Conventions / gotchas
- **Edit locally in this repo, NOT on GitHub web.** Web editing is what created stray `index.html` copies in Downloads and the ` (1)/(2)` filename gremlins. Local + git only.
- This is the **only real source of the live site.** A loose `index.html` anywhere else (Downloads, etc.) is a stray copy that deploys nowhere — ignore/delete it.
- Match the existing HTML/CSS patterns already in `index.html` — copy the shape of a working neighbor element rather than inventing new structure.
- Keep feature CTAs honest: a tool that's live and free says so; don't leave "Coming soon" on a finished feature.

## Note for the assistant
You cannot see the owner's chat history with Claude (the web assistant) or the `wingsiq-app` repo from here. This file is your only carried-over context for this repo — treat it as the briefing.
