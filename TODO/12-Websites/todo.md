# TODO — 12 Websites (Hugo — v2, NOT v1)

**Status:** ⬜ **v2** (human ruling 2026-08-08: Hugo moved to v2) · **Owner:** deferred · **File refs:** `websites/dnanu.de/`

> The website/blog is NOT in v2's default (human ruling) and is a personal add-on in v1's successor.
> Decision: **Hugo site → v2**. `websites/dnanu.de/` stays as a versioned placeholder.

## When we build it (v2)
- [ ] `hugo.toml` + `content/_index.md` (portfolio landing)
- [ ] 5 sections mapping to email aliases: `wealth/`, `health/`, `it/`, `creative/`, `academic/` (each `_index.md` + `blog/*.md`)
- [ ] `layouts/` custom theme (desktop + mobile responsive) + `static/`
- [ ] Activation script: `hugo build` → `/var/www/dnanu.de`
- [ ] nginx dnanu.de vhost (already exists as placeholder on 127.0.0.1:8080) → point at Hugo output

## autoconfig (v1 — already wired)
- [x] `autoconfig.dnanu.de/mail/config-v1.1.xml` served by the blogs vhost (Thunderbird auto-setup) — exists in mail.nix/nginx
