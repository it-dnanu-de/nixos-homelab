# TODO — 07 Downloads & VPN

**Status:** ⬜ not started (build step 6) · **Owner:** vpn-confinement + downloader modules · **Modules:** `modules/services/vpn.nix`, `qbittorrent.nix`, `sabnzbd.nix`, `slskd.nix`

> VPN-Confinement flake input (network namespaces — NOT containers, per §1). All downloaders run confined behind AirVPN WireGuard. Web UIs via VPN bridge IP.

## VPN-Confinement (`vpnNamespaces.wg`)
- [ ] `vpnNamespaces.wg.wireguardConfigFile` from sops `airvpn_wg_conf`
- [ ] `portMappings` for web UIs (bridged IPs)
- [ ] `openVPNPorts` = AirVPN forwarded port
- [ ] `systemd.services.{qbittorrent,sabnzbd,slskd}.vpnConfinement`
- [ ] AirVPN static port forward (wg-quick) — 1% manual in AirVPN dashboard
- [ ] **Torrent IP-leak test** after deploy (§13)

## qBittorrent (`services.qbittorrent`)
- [ ] Confined in VPN namespace
- [ ] listen port = AirVPN forwarded port
- [ ] Data dir `/slow/downloads/qbittorrent`
- [ ] Web UI on VPN bridge IP

## SABnzbd (`services.sabnzbd`)
- [ ] Confined
- [ ] `/slow/downloads/sabnzbd`
- [ ] Connect to indexers

## slskd (`services.slskd`) — OPTIONAL (2026-08-08)
- [ ] Decision: keep slskd as a music downloader (Lidarr→slskd for missing albums) or drop it (qBit/SAB cover everything)
- [ ] If kept: confined, creds via `environmentFile` = sops `slskd_env` (SLSKD_SLSK_USERNAME/PASSWORD)
- [ ] soularr bridge is DROPPED regardless (no beets/soularr layer — see 08)

## Shared
- [ ] `media` supplementary group on download dirs
- [ ] *arr hardlink source readiness (`/slow/downloads/*` on same pool as shared-media)
