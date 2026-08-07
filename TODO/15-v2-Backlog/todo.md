# TODO — 15 v2 Backlog (the fork for everyone)

**Status:** ⬜ v2 only, NOT v1 · **Owner:** deferred until v1 done · Source: OpenCode.md Project Vision

> These are v2 items (or genuine v2 "maybe later" features). Nothing here is built during v1
> unless the human promotes it. v1 = build the full §9 service map, then private v1 + fork v2.

## v2 = the fork for everyone
- [ ] Fork v1 → v2 (public, name TBD at fork time); **private the v1 repo** at that point
- [ ] **install.sh** (the big one) — run on the NixOS live ISO:
  - [ ] forks/clones the repo and creates a GitHub repo on the user's account (IaC bootstrap)
  - [ ] interactively asks: # users, accounts, emails, aliases, which apps, media-server disk layout, Resend/Cloudflare/INWX API tokens, etc.
  - [ ] generates the config + writes secrets to sops
  - [ ] prints the manual steps the user must still do (DNSSEC/DS records at INWX, Speedport DHCP+port forwards, MACs, QR re-scan)
  - [ ] assumes the same service stack as this repo (Resend, Cloudflare, INWX, WireGuard, SNM, …)
  - [ ] declarative account provisioning (occ/CLI oneshots) for zero-touch first boot
- [ ] **Website/blog is NOT in v2** (human ruling) — v2 documents how to add your own blog if wanted
- [ ] General polish: README product-quality, template-clean defaults, provider choices where sensible

## Deferred / "maybe later" (not v1, not necessarily v2)
- [ ] Nextcloud Talk (needs TURN + open ports → violates zero-port rule; **forever**)
- [ ] MeTube / Pinchflat (YouTube downloader)
- [ ] IPTV
- [ ] Headscale + headplane UI (both native, verified 26.05) — IF declarative WG peer mgmt ever becomes a burden
- [ ] Multi-user mailboxes
- [ ] DANE TLSA active once DS published at DENIC (cross-note to §3.7/04-Mail)
- [ ] Nextcloud Office powered by **Euro-Office** (June 2026, ONLYOFFICE-based; not in nixpkgs yet — keep Collabora)

## Dependencies / watch
- Readarr archived upstream — monitor; migration path to rreading-glasses mirror documented
- Shelfarr (276★) packaging status in nixpkgs — watch; would give real ebook/audiobook management (2026-08-08 media decision) — Euro-Office DocumentServer packaging status in nixpkgs — watch for upstream addition
