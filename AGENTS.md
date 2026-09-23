# Introduction Site Repository Instructions

Read `../PROJECT_CONTEXT.md`, `../ARCHITECTURE.md`, `../DECISIONS.md` (ADR-056) and `../CURRENT_STATE.md`
before material work. Verify task-relevant claims against the current code of the app and backend.

This is a **public** repository (`KKnock-Boost/Introduction`).

**Keep out of this repo:**
- Private hostnames and deployment details.
- Tokens and `.env` values.
- Anything from the private repositories beyond what the page itself shows.

**Stack:**
- Static site only: plain HTML/CSS/JS in `site/`.
- No build step and no npm dependencies.
- No requests to other origins (fonts, images, scripts, analytics) and no cookies.
- `localStorage` holds only the language choice (`kk-lang`).
- No inline `<script>` and no `style` attributes. The CSP is `default-src 'self'` in both
  `../backend/deploy/introduction.conf.template` and `scripts/preview.py`; keep the two, and the
  `/download` rules, in sync.

**Page content:**
- Every visible string exists in English and Chinese as sibling `lang="en"` / `lang="zh-CN"` elements.
  Language-specific images are paired the same way with `loading="lazy"`.
- App screenshots come only from the phone's debug `ShowcaseActivity` via `scripts/capture-screens.sh`.
  Never use a real account. Review every image before committing.
- Claims must match the app and the ADRs:
  - One capture becomes one Todo, one Thought, or nothing.
  - Audio stays on the phone; only the transcript text is sent.
  - Todos and Thoughts are stored on the phone.
  - The server keeps capture results for up to 14 days for retry idempotency.
- Don't claim pricing, iPhone availability, or hands-free / voice-assistant use. The in-car example stays
  framed as parked or safely stopped, with its safety note.
- The product name on the page is **KK Knock**. The launcher label is `KKKnockBoost`, so setup steps use that label.
- Download CTAs link to `/download`. Its target comes only from `KK_DOWNLOAD_URL` in the deployment
  environment. Never hard-code a release URL in the page.

**Serving:**
- This repo is content only. There is no Dockerfile here; `../backend/compose.yaml` serves `site/`
  read-only with the stock Nginx image.
- Nginx serves static files only. Do not proxy Backend or Manager routes on this hostname.
- Bump the `?v=` query on asset URLs when CSS, JS or fonts change.

Commands (conda `appDev`):

```bash
conda run -n appDev python scripts/preview.py
conda run -n appDev sh scripts/capture-screens.sh
```

Deployment is owned by `../backend/compose.yaml`; follow `../backend/deploy/README.md`.
