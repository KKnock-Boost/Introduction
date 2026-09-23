# KK Knock Introduction

The public product page for KK Knock, the voice-first capture app for Android. It covers busy
moments when typing is awkward, the KK Capture 1×1 widget, the main features, privacy, getting
started and an FAQ. Every string is available in English and Chinese.

Download buttons link to `/download`. The server redirects that path to the current GitHub
Release.

## What's here

| Path | Purpose |
| --- | --- |
| `site/` | The static page: `index.html`, `coming-soon.html`, `404.html`, CSS, JS, fonts and images |
| `scripts/preview.py` | Local preview with the same headers and `/download` behaviour as the deployed Nginx |
| `scripts/capture-screens.sh` | Regenerates the app screenshots from the app's debug showcase |
| `decDoc/development.md` | Development log |

## Local preview

Development and testing use the `appDev` conda environment:

```bash
conda run -n appDev python scripts/preview.py
```

Open http://127.0.0.1:8765. Until a download URL is set, `/download` shows the coming-soon page.
To try the redirect:

```bash
KK_DOWNLOAD_URL=https://github.com/OWNER/REPO/releases/latest conda run -n appDev python scripts/preview.py
```

There is no build step and no npm. The page loads nothing from other origins.

## Download link

The deployed Nginx reads one environment value, `KK_DOWNLOAD_URL`.

- If it is a plain `https://` URL, `/download` answers `302` to that URL with `Cache-Control: no-store`.
- If it is empty or not a plain `https://` URL, `/download` serves `coming-soon.html`.

The value belongs to the deployment environment. Do not hard-code it in the page.

## Deployment

This repository holds content only. The sibling `backend` repository's `compose.yaml` defines the
`introduction` service. It runs the stock Nginx image, mounts `site/` from this checkout read-only,
and keeps the Nginx config next to it. Content changes go live after a `git pull` here, with no
image rebuild. That repository's deployment guide covers the environment value and hostname
routing.

## Screenshots

App screenshots come only from the Debug build's showcase screen. It renders the real app UI with
invented sample content, so no personal Todos, Thoughts or account details appear. With a phone
running that build connected over adb:

```bash
conda run -n appDev sh scripts/capture-screens.sh        # both languages
conda run -n appDev sh scripts/capture-screens.sh zh     # one language
```

The script crops the status bar and writes 720 px JPEGs to `site/assets/img/screens/<lang>/`.
Review every image before committing it, and never publish screenshots of a real account.

Other images are resized copies of the app's own resources:
- `site/assets/img/capture/`: the KK Capture Ready, Recording and Processing states.
- `site/assets/img/widgets/`: the 4×3 widget previews, which use sample strings.
- `site/assets/img/brand/`: the app icon.

## Content rules

- Keep every claim true to the app:
  - One recording becomes one Todo or one Thought, or nothing.
  - Audio stays on the phone; only the transcript text is sent for sorting.
  - Todos and Thoughts are stored on the phone.
  - The server keeps each capture result for up to 14 days so a retried request is not processed twice.
- Don't mention pricing, an iPhone release, or hands-free use. The in-car example stays framed as
  parked or safely stopped.
- English and Chinese stay paired as sibling `lang="en"` / `lang="zh-CN"` elements.
- When CSS, JS or fonts change, bump the `?v=` query on their URLs. `/assets/` is cached for a day.

## Licenses

Source Serif 4 is bundled under the SIL Open Font License 1.1 (`site/assets/fonts/OFL.txt`).
