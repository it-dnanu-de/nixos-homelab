# TODO — 10 Smart Home (Home Assistant)

**Status:** ⬜ not started (v1) · **Owner:** builder · **Module:** `modules/services/smart-home.nix`

> **Half-declared (2026-08-08):** the 10 users (admin + 9 regular) are declared in Nix; everything else (integrations, devices, automations) is configured once via the HA web UI (persists in its config dir — same model as the arrs).

## Home Assistant (`services.home-assistant`)
- [ ] `home.nanulab.de` (VPN-only, user-tier ACL)
- [ ] `trusted_proxies` for nginx
- [ ] **10 users declared** (admin + dumitru/adela/tiberiu/david/ramona/tibisor/iza/kerem/hannah) — matching Authelia/Nextcloud set
- [ ] Config dir: `/var/lib/home-assistant` (default) → restic include; HA manages its own config
- [ ] Onboarding (1% manual): integrations, devices, automations via web UI

## Shared
- [ ] nginx user-tier vhost
- [ ] Restic include state
